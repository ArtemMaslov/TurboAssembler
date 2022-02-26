.model tiny
.code

locals __

org 100h

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
start:
		
		call Set_KeyboardInterrupt
		call Set_TimerInterrupt
		
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
Set_KeyboardInterrupt proc
		
		xor bx, bx
		mov es, bx
		mov bx, 9 * 4 ; address of interupt 9
		mov ax, cs
		
		cli
		
		; Save old int handler
		mov dx, word ptr es:[bx]
		mov word ptr [offset Old_Int09]      , dx
		
		mov dx, word ptr es:[bx + 02h]
		mov word ptr [offset Old_Int09 + 02h], dx
		
		; Write new int handler
		mov word ptr es:[bx]      , offset Override_KeyboardInterrupt
		mov word ptr es:[bx + 02h], ax
		
		sti
		
		ret
Set_KeyboardInterrupt endp

;--------------------------------------------------------------------
; Overrides 08h interrupt (timer)
;
; Destr: ax, bx, dx, es
;--------------------------------------------------------------------
Set_TimerInterrupt proc
		
		; Save old handler
		mov ax, 3508h
		int 21h
		
		mov word ptr [offset Old_Int08], bx
		mov word ptr [offset Old_Int08 + 02h], es
		
		; Set new handler
		mov ax, 2508h
		mov dx, offset Override_TimerInterrupt
		int 21h
		
		ret
Set_TimerInterrupt endp

;--------------------------------------------------------------------
; Int 09 handler (keyboard)
;
; Destr: null
;--------------------------------------------------------------------
Override_KeyboardInterrupt proc
		push ax di es
		
		mov ax, VideoSeg
		mov es, ax
		
		mov di, 02d * (ScreenWidth * 05d + 20d)
		mov ah, AttrBackground
		
		in al, 60h	; read key
		
		; mov es:[di], ax
		
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
		
		cmp al, 00h
		je __disable_frame
		
		; Enable frame
		push cx si dx
		
		call SaveVideoSeg
		
		pop dx si cx
		
		jmp __exit
		
__disable_frame:
		; Disable frame
		push si cx dx
		
		mov si, offset FrameOldVideo
		call DrawVideoSeg
		
		pop dx cx si
		
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
Override_KeyboardInterrupt endp

;--------------------------------------------------------------------
; Int 08 handler (timer)
;
; Destr: null
;--------------------------------------------------------------------
Override_TimerInterrupt proc

		; Run old int handler
		pushf ; Simulate interrupt
		call dword ptr cs:[Old_Int08]
		
		; Run my handler
		cmp byte ptr cs:[FrameEnabled], 00h
		ja __enable_frame
		
		iret
		
__enable_frame:
		
		push es si di dx cx bx ax
		
		call SaveDeltas
		
		mov ax, cs
		mov es, ax
		
		cmp byte ptr cs:[RegistersEnabled], 00h
		je __break
				
		call DrawFrame
		call DrawRegisters
		
__break:
		
		mov si, offset FrameVideoSeg
		call DrawVideoSeg
		
		pop ax bx cx dx di si es
		
		iret
Override_TimerInterrupt endp

;--------------------------------------------------------------------
; Saves frame's screen part (video-memory) to FrameOldVideo
;
; Destr: es, ax, cx, si, di, dx
;--------------------------------------------------------------------
SaveVideoSeg proc
		mov ax, VideoSeg
		mov es, ax
		
		mov dx, FrameHeight
		mov di, offset FrameOldVideo
		mov si, 02d * ((y0 * ScreenWidth) + x0)
		
__loop1:
		mov cx, FrameWidth
__loop2:
		mov ax, word ptr es:[si]
		add si, 02h
		
		mov word ptr cs:[di], ax
		add di, 02h
		
		dec cx
		ja __loop2
		
		add si, 02d * (ScreenWidth - FrameWidth)
		
		dec dx
		cmp dx, 00h
		ja __loop1
				
		ret
SaveVideoSeg endp

;--------------------------------------------------------------------
; Saves external vide memory changes
;
; Destr: ax, es, dx, di, si, cx
;--------------------------------------------------------------------
SaveDeltas proc
		mov ax, VideoSeg
		mov es, ax
		
		mov dx, FrameHeight
		mov di, offset FrameVideoSeg
		mov si, 02d * ((y0 * ScreenWidth) + x0)
		
__loop1:
		mov cx, FrameWidth
__loop2:
		mov ax, word ptr es:[si]
		add si, 02h
		
		cmp ax, word ptr cs:[di]
		je __continue
		
		mov word ptr cs:[di + FrameVideoMemorySize], ax
		
__continue:
		add di, 02h
		dec cx
		
		ja __loop2
		
		add si, 02d * (ScreenWidth - FrameWidth)
		
		dec dx
		cmp dx, 00h
		ja __loop1
				
		ret
SaveDeltas endp

;--------------------------------------------------------------------
; Draws FrameVideoSeg to screen (video-memory)
;
; Entry: si - video array
;
; Destr: es, ax, di, si, cx, dx
;--------------------------------------------------------------------
DrawVideoSeg proc
		
		mov ax, VideoSeg
		mov es, ax
		
		mov dx, FrameHeight
		; mov si, offset FrameVideoSeg
		mov di, 02d * ((y0 * ScreenWidth) + x0)
		
__loop1:
		mov cx, FrameWidth
__loop2:
		mov ax, word ptr cs:[si]
		add si, 02h
		
		stosw
		
		dec cx
		ja __loop2
		
		add di, 02d * (ScreenWidth - FrameWidth)
		
		dec dx
		cmp dx, 00h
		ja __loop1
		
		ret
DrawVideoSeg endp

;--------------------------------------------------------------------
; Draws registers into frame
;
; Entry:
;		 es - code segment
;
; Destr: ax, bx, cx, dx, si, di
;--------------------------------------------------------------------
DrawRegisters proc
		push bp
		mov bp, sp
		add bp, 04h
		
		mov ah, AttrBackground
		mov si, offset Regs1
		mov di, 02d * (01d * FrameWidth + FramePadding) + offset FrameVideoSeg
		
		; <Draw Registers
		mov cx, Regs1Count
		call DrawRegisterBlock
				
		add di, 02d * FrameWidth
		mov cx, Regs2Count
		call DrawRegisterBlock
		
		add di, 02d * FrameWidth
		mov cx, Regs3Count
		call DrawRegisterBlock
		
		add di, 02d * FrameWidth
		mov cx, Regs4Count
		call DrawRegisterBlock
		; Draw Registers/>
		
		; <Draw separators
		mov si, offset SeparatorFrameStyle
		
		mov di, 02d * ((01d + Regs1Count) * FrameWidth) + offset FrameVideoSeg
		mov cx, FrameWidth
		call DrawFrameRow
		
		mov di, 02d * ((01d + Regs1Count + 01d + Regs2Count) * FrameWidth) + offset FrameVideoSeg
		mov cx, FrameWidth
		call DrawFrameRow
		
		mov di, 02d * ((01d + Regs1Count + 01d + Regs2Count + 01d + Regs3Count) * FrameWidth) + offset FrameVideoSeg
		mov cx, FrameWidth
		call DrawFrameRow
		; Draw separators/>
		
		pop bp
		ret
DrawRegisters endp

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
DrawRegisterBlock proc
		
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
		
		push ax cx di
		add di, 02h
		push [bp]
		
		call VideoItoaHex
		
		add bp, 02
		pop di cx ax
		
		dec cx
		add di, 02d * (FrameWidth - 04d)
		
		cmp cx, 00h
		ja __loop
		
		ret
DrawRegisterBlock endp

;--------------------------------------------------------------------
; Draws frame
;
; Entry:
;		 es - code segment
;
; Destr: ax, bx, cx, dx, di, si, es
;--------------------------------------------------------------------
DrawFrame proc
		; Set attribute
		mov di, offset FrameVideoSeg
		mov ah, AttrBackground
		
		; Draw top line
		mov cx, word ptr FrameWidth
		mov si, offset TwoBordFrameStyle
		
		call DrawFrameRow
		
		; Draw center part
		mov bx, FrameHeight	- 02h
		add si, 03h
		
__loop:
		;add dx, 02h * FrameWidth
		;mov di, dx
		mov cx, word ptr FrameWidth
		
		call DrawFrameRow
		
		dec bx
		
		ja __loop
		
		; Draw bottom line
		;add dx, 02h * FrameWidth
		add si, 03h
		;mov di, dx
		mov cx, word ptr FrameWidth
		
		call DrawFrameRow
				
__exit:
		ret
DrawFrame endp

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
DrawText proc

__loop:
		mov al, byte ptr cs:[si]
		mov es:[di], ax
		
		inc si
		add di, 02h
		dec cx
		
		ja __loop
		
		ret
DrawText endp
		
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
DrawFrameRow proc
		
		mov al, byte ptr cs:[si]
		stosw
		
		inc si
		mov al, byte ptr cs:[si]
		sub cx, 02d
		
__loop:
		stosw
		dec cx
		
		ja __loop
		
		inc si
		mov al, byte ptr cs:[si]
		
		stosw
		
		sub si, 02h
		
		ret
DrawFrameRow endp

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
; Destr: ax, bx, cx, di
;--------------------------------------------------------------------
VideoItoaHex proc
		push bp
		mov bp, sp
		
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
		
		pop bp
		ret 2 * 1
VideoItoaHex endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
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
FrameWidth			= 15d			; Frame width  with borders
FrameHeight		    = 18d			; Frame height with borders
FramePadding		= 2d 

HotKeyVisibility	= 03Ch			; 'F2' - change visibility of frame
HotKeySleep			= 03Bh			; 'F1' - stops changing registers

FrameVideoMemorySize = (FrameWidth * FrameHeight * 02d)

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

FrameVideoSeg		db FrameVideoMemorySize dup(0)

FrameOldVideo		db FrameVideoMemorySize dup(0)

;--------------------------------------------------------------------
;--------------------------------------------------------------------

programm_end:

end start