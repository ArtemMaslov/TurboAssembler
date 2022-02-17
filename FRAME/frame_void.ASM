.model tiny
.code

org 100h

locals __

x0				    = 16d	; Frame left top corner x
y0				    = 10d	; Frame left top corner y
				    
Width			    = 16d	; Frame width with borders
Height			    = 6d	; Frame height with borders

ScreenWidth         = 80d
ScreenHeight        = 25d

SymHorLine			= 0CDh
SymVerLine			= 0BAh
SymTopLeftCorner	= 0C9h
SymTopRightCorner	= 0BBh
SymBotLeftCorner	= 0C8h
SymBotRightCorner	= 0BCh
SymSpace			= ' '

AttrBackground      = 03Fh ; 0111 0000
AttrShadow			= 08Fh ; 1000 1111
AttrFrame			= 07Bh ; 1011 1011 

VideoSeg			= 0B800h

.getch	macro
		nop
		xor ah, ah
		int 16h
		nop
		endm

Start:			
		
		call DrawFrame
		
		mov ax, 4c00h				; exit(0);
		int 21h	
		
;--------------------------------------------------------------------
; Draws frame
; Entry: 
; Destr: ax, cx, bx, dx, di, si
;--------------------------------------------------------------------
DrawFrame	proc
		
		; Init Frame
		mov ax, VideoSeg
		mov es, ax
		
		mov dx, y0 * ScreenWidth * 2d + x0 * 2d
		mov ah, AttrBackground
		
		; Draw top line
		mov si, offset StrTopLine
		mov di, dx
		mov cx, 12d
		
		call DrawFrameRow
		
		; Draw center part
		mov bx, Height - 2d
		
__loop:
		add dx, 2d * ScreenWidth
		mov si, offset StrCenterLine
		mov di, dx
		mov cx, 12d
		
		call DrawFrameRow
		
		dec bx
		
		ja __loop
		
		; Draw bottom line
		add dx, 2 * ScreenWidth
		mov si, offset StrBotLine
		mov di, dx
		mov cx, 12d
		
		call DrawFrameRow
		
		.getch
		
		ret
DrawFrame	endp
		
;--------------------------------------------------------------------
; Draws horizontal line
; Entry: 
;		 ah = sym attr
;		 cx = length of line
;		 di = address of start line in video seg
;		 si = address of string of chars to be printed
;		 es = video segment
; Destr: al, cx, si, di
;--------------------------------------------------------------------
DrawFrameRow	proc
		
		mov al, byte ptr [si]
		mov es:[di], ax
		
		add di, 2
		inc si
		
		mov al, byte ptr [si]
		
__loop:
		mov es:[di], ax
		add di, 2
		dec cx
		
		ja __loop
		
		inc si
		mov al, byte ptr [si]
		mov es:[di], ax
		
__exit:
		ret
DrawFrameRow	endp
		
		
StdStrTopLine          db SymTopLeftCorner, SymHorLine, SymTopRightCorner
StdStrCenterLine       db SymVerLine, ' ', SymVerLine
StdStrBotLine          db SymBotLeftCorner, SymHorLine, SymBotRightCorner

StrTopLine          db SymTopLeftCorner, SymHorLine, SymTopRightCorner
StrCenterLine       db SymVerLine, ' ', SymVerLine
StrBotLine          db SymBotLeftCorner, SymHorLine, SymBotRightCorner

end Start