.model tiny
.code

locals __

org 100h

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
start:

		call Set_Int09
		
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

Override_Int09		proc
		push ax di es
		
		mov ax, VideoSeg
		mov es, ax
		
		mov di, 02d * (ScreenWidth * 05d + 20d)
		mov ah, AttrBackground
		
		in al, 60h	; read key
		mov es:[di], ax
		
		cmp al, HotKey
		je __hotkey
		
		pop es di ax
		
		; Run old int handler
		db 0EAh		; FAR JMP
Old_Int09:
		dd 00
		
__hotkey:			
		; Run my int handler
		
		push cx bx dx si
		call DrawFrame
		call DrawRegisters
		pop si dx bx cx
		
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



DrawRegisters		proc
		
		mov cx, 5d
		mov ah, AttrBackground
		mov si, offset RegAx
		mov di, 02d * ((y0 + FramePadding)* ScreenWidth + x0 + FramePadding)
		
		call DrawText
		
		mov ax, 0deadh
		
		call VideoItoaHex
		
		ret
DrawRegisters		endp

;--------------------------------------------------------------------
; Draws frame
;
; Entry: PtrBorderStyleArg - address of style string
;
; Destr: ax, cx, bx, dx, di, si
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
;		 ax - source number
;		 di - string destination
;
; Destr: ax, bx, cl
;--------------------------------------------------------------------
VideoItoaHex			proc
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
		
		ret
VideoItoaHex			endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
		
TwoBordFrameStyle	db 0c9h, 0cdh, 0bbh
					db 0bah, ' ',  0bah ; 0b0h
					db 0c8h, 0cdh, 0bch
					
HexConvert	db '0123456789ABCDEF'
RegAx		db 'ax = '
RegBx		db 'bx = '

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
y0				    = 3d			; Frame left top corner y

; !!! Little endian
FrameWidth			= 13d			; Frame width  with borders
FrameHeight		    = 14d			; Frame height with borders
FramePadding		= 2d 

HotKey				= 03Ch

;--------------------------------------------------------------------
;--------------------------------------------------------------------

programm_end:

end start