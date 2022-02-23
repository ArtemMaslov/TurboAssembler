.model tiny
.code

org 100h

locals __

;--------------------------------------------------------------------
;--------------------------------------------------------------------
.getch	macro
		nop
		xor ah, ah
		int 16h
		nop
		endm
;--------------------------------------------------------------------
;--------------------------------------------------------------------


;--------------------------------------------------------------------
; Main
; CmdLine:
; 	type <border-style> <message> <header>
; CmdArgs:
;
; 	type:
; 		0 - custom style. border style must be entered.
;		1 - one bordered frame
;		2 - two bordered frame
;		3 - arithmetic frame.
;
; 	border-style (optional):
; 		can be entered if type equal 0.
; 		format:
;			abc123ABC
;		resulted frame:
;			abbbbbbbbbc
;			12222222221
;			12222222221
;			12222222221
;			12222222221
;			ABBBBBBBBBC
;
;	message:
;		some string $-terminated.
;
;	header:
;		some string $-terminated.
; 
; ExitCodes:
;	0 - no errors
;	1 - incorrect type (input)
;	2 - incorrect border style (input)
;	3 - incorrect string input
;--------------------------------------------------------------------
Start:

		call ParseCmd
		call DrawFrame
				
		.getch
		
		mov ax, 4c00h				; exit(0);
		int 21h	

;--------------------------------------------------------------------
; Parse args from command line
;
; Entry: null
;
; Destr: bx, dl, ax
;--------------------------------------------------------------------
PrintCmd	proc
		
		mov bx, 00h
		
__loop:
		mov ah, 02h
		mov dl, byte ptr [bx + 080h]
		
		; if (dl == '\r') return;
		cmp dl, 0dh
		jne __endif
		ret
__endif:
		; putc();
		int 21h
		
		inc bx
		
		cmp bx, 80h
		jbe __loop
		
		.getch
		
		ret
PrintCmd	endp

;--------------------------------------------------------------------
; Parse args from command line
;
; Entry: null
;
; Destr: si, bx, cx, ax, dx
;--------------------------------------------------------------------
ParseCmd	proc
		
		mov bx, 82h ; Cmd first char address
				
		call ParseFrameType
		
		call ParseString
		
		cmp cx, 00h
		je __exit
		
		mov word ptr [offset PtrMessage], dx
		mov word ptr [offset LenMessage], cx
		
		add cx, FramePadding * 02h
		mov word ptr [offset FrameWidth], cx
		
		; Incorrect string
		; puts();
		; mov ah, 40h
		; mov bx, 0002h				; stderr
		; mov cx, Error_String_Len
		; mov dx, offset Error_String
		; int 21h
		; 
		; mov ax, 4c03h				; exit(3);
		; int 21h
__exit:
		ret
ParseCmd	endp

;--------------------------------------------------------------------
; Parse  $-terminated string.
;
; Entry: bx - ptr to cmd str
;
; Error: cx = 0 string wasn't found
;
; Out:   dx = address of string start
;		 cx = string length
;
; Destr: bx, dx, cx
;--------------------------------------------------------------------
ParseString		proc
		
		mov dx, bx
		mov cx, 00h
		
		dec bx
__loop:
		inc bx
		inc cx
		
		cmp word ptr [bx], '$$'
		je __exit
				
		cmp bx, 100h
		jb __loop
		
__incorrect_string:
		mov cx, 00h
		ret
__exit:
		sub cx, 01h
		ret
ParseString		endp

;--------------------------------------------------------------------
; Parses frame type
;
; Entry: bx - ptr to cmd str
;
; Out:   PtrBorderStyleArg = style format string
;
; Error: 1 - incorrect type
;
; Destr: si, bx, cx, ax, dx
;--------------------------------------------------------------------
ParseFrameType	proc

		mov dl, byte ptr [bx]
		
		; after type must be space or '\r' if arg is the last
		
		; char c = [bx + 01h]
		; if (c != '\r' && c != ' ') return error;
		cmp byte ptr [bx + 01h], 0Dh
		je __switch
		cmp byte ptr [bx + 01h], 20h	; space
		jne __incorrect_type
		
__switch:
		add bx, 02h
		
		cmp dl, '0'
		je __custom
		
		cmp dl, '1'
		je __one_border
		
		cmp dl, '2'
		je __two_borders
		
		cmp dl, '3'
		je __arithmetic_borders
		
		; Incorrect type

__incorrect_type:		
		mov ah, 09h
		mov dx, offset Error_Type
		int 21h
		
		mov ax, 4c01h				; exit(1);
		int 21h
		
__two_borders:
		mov word ptr [offset PtrBorderStyleArg], offset TwoBordFrameStyle
		
		ret
__custom:
		call ParseBorderStyle
		
		ret
__one_border:
		mov word ptr [offset PtrBorderStyleArg], offset OneBordFrameStyle

		ret
__arithmetic_borders:
		mov word ptr [offset PtrBorderStyleArg], offset ArithFrameStyle

		ret

ParseFrameType	endp

;--------------------------------------------------------------------
; Parses border style
;
; Entry: dl - style index
;		 bx - ptr to cmd str
;
; Out:   PtrBorderStyleArg = style format string
;
; Error: 2 - incorrect border style
;
; Destr: si, bx, cx, ax, dx
;--------------------------------------------------------------------
ParseBorderStyle	proc
		
		mov word ptr [offset PtrBorderStyleArg], bx
		
		mov cx, 00h
__loop:
		mov al, byte ptr [bx]
		
		; if (ax != number) return error;
		; cmp al, 30h
		; jb  __incorrect_border_style
		; cmp al, 39h
		; jbe __next
		
		cmp al, 0Dh
		jne __next
		
		; Incorrect border style
__incorrect_border_style:
		mov ah, 09h
		mov dx, offset Error_BorderStyle
		int 21h
		
		mov ax, 4c02h				; exit(2);
		int 21h	
		
__next:
		
		inc bx
		inc cx
		
		cmp cx, 09h
		jb __loop
		
		; after type must be space or '\r' if arg is the last
		
		; char c = [bx + 01h]
		; if (c != '\r' && c != ' ') return error;
		cmp byte ptr [bx], 0Dh
		je __exit
		cmp byte ptr [bx], 20h	; space
		jne __incorrect_border_style

__exit:
		inc bx
		ret
ParseBorderStyle	endp

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
		
		; ax = (ScreenWidth - FrameWidth) / 2 => x0
		mov ax, ScreenWidth
		sub ax, word ptr[offset FrameWidth]
		
		mov bx, 0002h
		div bl
		
		; x0 = 2 * a
		mov ah, 00h
		mul bl
		
		mov word ptr [offset x0], ax
		
		; Set attribute
		mov dx, 02h * (y0 * ScreenWidth)
		add dx, word ptr [offset x0]
		mov ah, AttrBackground
		
		; Draw top line
		mov di, dx
		mov cx, word ptr [offset FrameWidth]
		mov si, word ptr [offset PtrBorderStyleArg]
		
		call DrawFrameRow
		
		; Draw center part
		mov bx, FrameHeight	- 02h
		add si, 03h
		
__loop:
		add dx, 02h * ScreenWidth
		mov di, dx
		mov cx, word ptr [offset FrameWidth]
		
		call DrawFrameRow
		
		dec bx
		
		ja __loop
		
		; Draw bottom line
		add dx, 02h * ScreenWidth
		add si, 03h
		mov di, dx
		mov cx, word ptr [offset FrameWidth]
		
		call DrawFrameRow
		
		; DrawText
		
		cmp word ptr [offset PtrMessage], 00h
		je __exit
		
		mov si, word ptr [offset PtrMessage]
		mov dx, 02h * ((01h + FramePadding) + (y0 + 01h) * ScreenWidth)
		add dx, word ptr [offset x0]
		mov di, dx
		mov cx, word ptr [offset LenMessage]
		
		call DrawText
		
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
		mov al, byte ptr [si]
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
		
		mov al, byte ptr [si]
		mov es:[di], ax
		
		add di, 02h
		inc si
		
		mov al, byte ptr [si]
		
__loop:
		mov es:[di], ax
		add di, 02h
		dec cx
		
		ja __loop
		
		inc si
		mov al, byte ptr [si]
		mov es:[di], ax
		
		sub si, 02h
		
		ret
DrawFrameRow	endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
		
		
OneBordFrameStyle	db 0dah, 0c4h, 0bfh
					db 0b3h, 020h, 0b3h
					db 0c0h, 0c4h, 0d9h
					
TwoBordFrameStyle	db 0c9h, 0cdh, 0bbh
					db 0bah, 0b0h, 0bah
					db 0c8h, 0cdh, 0bch
					
ArithFrameStyle	    db 02bh, 05fh, 02bh
					db 07ch, 020h, 07ch
					db 02bh, 05fh, 02bh
					
;--------------------------------------------------------------------
; Global variables
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

PtrBorderStyleArg	db 00h, 00h

PtrMessage			db 00h, 00h
LenMessage			db 00h, 00h

PtrHeader			db 00h, 00h		
LenHeader			db 00h, 00h		

x0				    db 00h, 00h		; Frame left top corner x
y0				    = 6d			; Frame left top corner y

; !!! Little endian
FrameWidth			db 32d, 00h		; Frame width  with borders
FrameHeight		    = 6d			; Frame height with borders
FramePadding		= 6d 
					
;--------------------------------------------------------------------
;--------------------------------------------------------------------

Text				db "Hello world!$"
TextLength			= 12d

Error_Type			db "Type argument must be number in [0; 3].$"
Error_BorderStyle	db "Border argument must be string, length == 9.$"
Error_String		db "String must be ended with '$'"
Error_String_Len	=  29d

;--------------------------------------------------------------------
;--------------------------------------------------------------------

end Start