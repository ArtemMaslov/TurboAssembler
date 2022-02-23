.model tiny
.code

locals __

org 100h

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
start:

		call Set_Int09
		call Set_Int08
		
		; call DrawFrame
		
		; Terminate and stay resident
		mov ax, 3100h
		mov dx, offset programm_end
		and dx, 0Fh
		
		cmp dx, 00h
		ja __extra_parag
		
		; dx % 16 == 0
		mov dx, offset programm_end
		shr dx, 4
		
		int 21h

__extra_parag:

		mov dx, offset programm_end
		shr dx, 04h
		inc dx
		
		int 21h
	

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; Overrides 09h interrupt (keyboard)
;
; Destr: ax, bx, dx, es
;--------------------------------------------------------------------
Set_Int09			proc
		
		xor bx, bx
		mov es, bx
		mov bx, 9 * 4
		mov ax, cs
		
		cli
		
		; Save old int handler
		mov dx, word ptr es:[bx]
		mov word ptr [offset Old_Int09]      , dx
		
		mov dx, word ptr es:[bx + 02h]
		mov word ptr [offset Old_Int09 + 02h], dx
		
		; Write new int handler
		mov word ptr es:[bx]      , offset Override_Int09
		mov word ptr es:[bx + 02h], ax
		
		sti
		
		ret
Set_Int09			endp

;--------------------------------------------------------------------
; Overrides 08h interrupt (timer)
;
; Destr: ax, bx, dx, es
;--------------------------------------------------------------------
Set_Int08			proc
		
		; Save old handler
		mov ax, 3508h
		int 21h
		
		mov word ptr [offset Old_Int08], bx
		mov word ptr [offset Old_Int08 + 02h], es
		
		; Set new handler
		mov ax, 2508h
		mov dx, offset Override_Int08
		int 21h
		
		ret
Set_Int08			endp

;--------------------------------------------------------------------
; Int 09 handler
;
; Destr: null
;--------------------------------------------------------------------
Override_Int09		proc
		push ax di es
		
		mov ax, VideoSeg
		mov es, ax
		
		mov di, 02d * (ScreenWidth * 05d + 20d)
		mov ah, AttrBackground
		
		in al, 60h	; read key
		mov es:[di], ax
		
		cmp al, HotKeyVisibility
		je __visibility
		
		cmp al, HotKeySleep
		je __sleep
		
		pop es di ax
		
		; Run old int handler
		db 0EAh		; FAR JMP
Old_Int09:
		dd 00
		
__visibility:			
		; Change frame visibility
		mov al, byte ptr cs:[FrameEnabled]
		not al
		mov byte ptr cs:[FrameEnabled], al
		
		jmp __exit
		
__sleep:
		; Change registers displaying state
		mov al, byte ptr cs:[RegistersEnabled]
		not al
		mov byte ptr cs:[RegistersEnabled], al
		
__exit:
		; Set signal to keyboard controller
		in al, 61h
		mov ah, al
		
		or al, 80h	; set enable kdb bit
		out 61h, al
		
		mov al, ah	; write original value
		out 61h, al
		
		; Send End-of-interupt signal
		mov al, 20h
		out 20h, al
		
		pop es di ax
		iret
Override_Int09		endp

;--------------------------------------------------------------------
; Int 08 handler
;
; Destr: null
;--------------------------------------------------------------------
Override_Int08		proc

		; Run old int handler
		pushf ; Simulate interrupt
		call dword ptr cs:[Old_Int08]
		
		; Run my handler
		cmp byte ptr cs:[FrameEnabled], 00h
		ja __enable_frame
		
		; Disable frame
		
		iret
		
__enable_frame:
		
		push es si di dx cx bx ax
		
		call DrawFrame
		
		cmp byte ptr cs:[RegistersEnabled], 00h
		je __break
		
		call DrawRegisters
		
__break:
		pop ax bx cx dx di si es
		
		iret
Override_Int08		endp

;--------------------------------------------------------------------
; Draws registers into frame
;
; Entry:
;		 es - Video segment
;
; Destr: ax, bx, cx, dx, si, di
;--------------------------------------------------------------------
DrawRegisters		proc
		push bp
		mov bp, sp
		add bp, 04h
		
		mov ah, AttrBackground
		mov si, offset Regs1
		mov di, 02d * ((y0 + 01d) * ScreenWidth + x0 + FramePadding)
		
		; <Draw Registers
		mov cx, Regs1Count
		call DrawRegisterBlock
				
		add di, 02d * ScreenWidth
		mov cx, Regs2Count
		call DrawRegisterBlock
		
		add di, 02d * ScreenWidth
		mov cx, Regs3Count
		call DrawRegisterBlock
		
		add di, 02d * ScreenWidth
		mov cx, Regs4Count
		call DrawRegisterBlock
		; Draw Registers/>
		
		; <Draw separators
		mov si, offset SeparatorFrameStyle
		
		mov di, 02d * ((y0 + 01d + Regs1Count) * ScreenWidth + x0)
		mov cx, FrameWidth
		call DrawFrameRow
		
		mov di, 02d * ((y0 + 01d + Regs1Count + 01d + Regs2Count) * ScreenWidth + x0)
		mov cx, FrameWidth
		call DrawFrameRow
		
		mov di, 02d * ((y0 + 01d + Regs1Count + 01d + Regs2Count + 01d + Regs3Count) * ScreenWidth + x0)
		mov cx, FrameWidth
		call DrawFrameRow
		; Draw separators/>
		
		pop bp
		ret
DrawRegisters		endp

;--------------------------------------------------------------------
; Draws registers block into frame
;
; Entry:
;		 ah - background attribute
;		 cx - registers count
;		 si - registers array address
;		 di - video address
;
; Destr: al, bx, cx, dx, si, di
;--------------------------------------------------------------------
DrawRegisterBlock	proc
		
__loop:
		; Print '<reg> =', where <reg> = ax, bx, cx, ...
		mov al, byte ptr cs:[si]
		inc si
		stosw
		
		mov al, byte ptr cs:[si]
		inc si
		stosw
		
		mov al, 20h		; space ' '
		stosw
		
		mov al, '='
		stosw
		; Print '<reg> =', where <reg> = ax, bx, cx, ...	
		
		add di, 02h
		push [bp]
		
		call VideoItoaHex
		
		add bp, 02
		sub di, 02h
		
		dec cx
		add di, 02d * (ScreenWidth - 04d)
		
		cmp cx, 00h
		ja __loop
		
		ret
DrawRegisterBlock	endp

;--------------------------------------------------------------------
; Draws frame
;
; Entry: PtrBorderStyleArg - address of style string
;
; Destr: ax, bx, cx, dx, di, si, es
;--------------------------------------------------------------------
DrawFrame	proc
		
		; Init Frame
		mov ax, VideoSeg
		mov es, ax
				
		; Set attribute
		mov dx, 02h * (y0 * ScreenWidth)
		add dx, word ptr 02h * x0
		mov ah, AttrBackground
		
		; Draw top line
		mov di, dx
		mov cx, word ptr FrameWidth
		mov si, offset TwoBordFrameStyle
		
		call DrawFrameRow
		
		; Draw center part
		mov bx, FrameHeight	- 02h
		add si, 03h
		
__loop:
		add dx, 02h * ScreenWidth
		mov di, dx
		mov cx, word ptr FrameWidth
		
		call DrawFrameRow
		
		dec bx
		
		ja __loop
		
		; Draw bottom line
		add dx, 02h * ScreenWidth
		add si, 03h
		mov di, dx
		mov cx, word ptr FrameWidth
		
		call DrawFrameRow
				
__exit:
		ret
DrawFrame	endp

;--------------------------------------------------------------------
; Draws text
;
; Entry: 
;		 ah = sym attr
;		 cx = string length
;		 di = address of start line in video seg
;		 si = address of string of chars to be printed
;		 es = video segment
;
; Destr: al, cx, si, di
;--------------------------------------------------------------------
DrawText	proc

__loop:
		mov al, byte ptr cs:[si]
		mov es:[di], ax
		
		inc si
		add di, 02h
		dec cx
		
		ja __loop
		
		ret
DrawText	endp
		
;--------------------------------------------------------------------
; Draws horizontal line
;
; Entry: 
;		 ah = sym attr
;		 cx = length of line
;		 di = address of start line in video seg
;		 si = address of string of chars to be printed
;		 es = video segment
;
; Destr: al, cx, di, not si, 
;--------------------------------------------------------------------
DrawFrameRow	proc
		
		mov al, byte ptr cs:[si]
		mov es:[di], ax
		
		add di, 02h
		inc si
		
		mov al, byte ptr cs:[si]
		
__loop:
		mov es:[di], ax
		add di, 02h
		dec cx
		
		ja __loop
		
		inc si
		mov al, byte ptr cs:[si]
		mov es:[di], ax
		
		sub si, 02h
		
		ret
DrawFrameRow	endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; Convert hexidecimal number to alpha
;
; Entry:
;		 1 arg - source number
;		 di    - string destination
;
; Destr:
;--------------------------------------------------------------------
VideoItoaHex			proc
		push bp
		mov bp, sp
		push ax bx cx di 
		
		mov ax, [bp + 04h]
		mov cx, 05d
		add di, 10d
		
__loop:
		mov bx, ax
		and bx, 000Fh
		
		mov dl, byte ptr cs:[offset HexConvert + bx]
		mov byte ptr es:[di], dl
		
		; step
		dec cx
		sub di, 02d
		shr ax, 04d
		
		cmp cx, 01d
		ja __loop
		
		mov byte ptr es:[di - 02h], '0'
		mov byte ptr es:[di], 'x'
		
		pop di cx bx ax
		pop bp
		ret 2 * 1
VideoItoaHex			endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

FrameEnabled		db 00h
RegistersEnabled	db 0FFh

Old_Int08			dd 00h
		
TwoBordFrameStyle	db 0c9h, 0cdh, 0bbh
					db 0bah, ' ',  0bah ; 0b0h
					db 0c8h, 0cdh, 0bch
					
SeparatorFrameStyle db 0c7h, 0c4h, 0b6h
					
HexConvert			db '0123456789ABCDEF'
		
Regs1Count  		= 4
Regs1				db 'ax'
					db 'bx'
					db 'cx'
					db 'dx'
					
Regs2Count  		= 2
Regs2				db 'si'
					db 'di'
					
Regs3Count  		= 3
Regs3				db 'bp'
					db 'sp'
					db 'ip'
					
Regs4Count  		= 4
Regs4				db 'ds'
					db 'es'
					db 'ss'
					db 'cs'

FrameVideoSeg		db FrameWidth * FrameHeight * 2 dup(0)

;--------------------------------------------------------------------
;--------------------------------------------------------------------

ScreenWidth         = 80d
ScreenHeight        = 25d

SymHorLine			= 0CDh
SymVerLine			= 0BAh
SymTopLeftCorner	= 0C9h
SymTopRightCorner	= 0BBh
SymBotLeftCorner	= 0C8h
SymBotRightCorner	= 0BCh
SymSpace			= ' '

AttrBackground      = 02Eh ; 0010 1110

VideoSeg			= 0B800h

;--------------------------------------------------------------------
;--------------------------------------------------------------------

x0				    = 62d			; Frame left top corner x
y0				    = 1d			; Frame left top corner y

; !!! Little endian
FrameWidth			= 13d			; Frame width  with borders
FrameHeight		    = 18d			; Frame height with borders
FramePadding		= 2d 

HotKeyVisibility	= 03Ch			; 'F2' - change visibility of frame
HotKeySleep			= 03Bh			; 'F1' - stops changing registers

;--------------------------------------------------------------------
;--------------------------------------------------------------------

programm_end:

end start