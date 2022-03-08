.model tiny
.code

locals __

org 100h

;--------------------------------------------------------------------
;--------------------------------------------------------------------
.NewLine macro
		nop
		; putc('\n');
		mov ah, 02h
		mov dl, 0Ah ; '\n'
		int 21h
		nop
		endm
		
.TestInput macro
		nop
		; puts ("Input:");
		mov si, offset StrInput
		call PrintString
		
		nop
		endm
		
.TestResult macro
		nop
		; puts ("Result:");
		mov si, offset StrResult
		call PrintString
		
		nop
		endm
		
.TestStart macro
		nop
		; puts (tests description)
		mov si, offset StrTestDescr
		call PrintString
		nop
		endm
		
.TestSep macro
		nop
		mov si, offset StrTestSeparator
		call PrintString
		nop
		endm
		
.getch	macro
		nop
		xor ah, ah
		int 16h
		nop
		endm
		
.HorizontalSep macro
		nop
		mov si, offset HorSep
		call PrintString
		nop
		endm
;--------------------------------------------------------------------
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
start:
	
	call GeneralUnitTest
	
	; exit (0);
	mov ax, 4c00h
	int 21h
		
;--------------------------------------------------------------------
; Measure string length. String must be '\0'-terminated
;
; Entry: si - string address
;
; Out:	 bx - string length without '\0'
;
; Destr: bx
;--------------------------------------------------------------------
StrLen proc
		
		mov bx, 00h
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [si + bx], 00h
		jne __loop
				
		ret
StrLen endp

;--------------------------------------------------------------------
; Find symbol in the string
;
; Entry: 
;		 si - string address
;		 al - symbol to be found
;
; Out:	 bx - ptr of symbol or 0000 if symbol wasn't found.
;
; Destr: bx
;--------------------------------------------------------------------
StrChr proc
		
		mov bx, si
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [bx], al
		je __sym_found
		
		cmp byte ptr [bx], 00h
		jne __loop
		
		; Symbol wasn't found
		mov bx, 00h
		
		ret
		
		; Symbol was found 
__sym_found:

		ret
StrChr endp

;--------------------------------------------------------------------
; Copy si to di. si - '\0'-terminated string.
;
; Entry:
;		 si - source string
;		 di - destination string
;		 
; Out:	 bx - string length with '\0'
;
; Destr: bx, al
;--------------------------------------------------------------------
StrCpy proc
		
		mov bx, 00h
		mov al, 00h
		
		dec bx
__loop:
		inc bx
		
		mov al, byte ptr [si + bx]
		mov byte ptr [di + bx], al

		cmp byte ptr [si + bx], 00h
		jne __loop
		
		inc bx
		
		ret
StrCpy endp

;--------------------------------------------------------------------
; Copy n symbols from si to di. si - '\0'-terminated string.
;
; Entry:
;		 si - source string
;		 di - destination string
;		 cx - count symbols to copy
;
; Out:   bx - number of copied symbols
;
; Destr: bx, al
;--------------------------------------------------------------------
StrNCpy proc
		
		mov bx, 00h
		mov al, 00h
		
		cmp cx, 00h
		je __exit
		
		dec cx
				
		dec bx
__loop:
		inc bx
		
		mov al, byte ptr [si + bx]
		mov byte ptr [di + bx], al

		cmp byte ptr [si + bx], 00h
		je __exit
		
		cmp bx, cx
		jb __loop
		
		inc bx
__exit:
		mov byte ptr [di + bx], 00h
		
		ret
StrNCpy endp

;--------------------------------------------------------------------
; Compares strings
;
; Entry:
;		 si - source string
;		 di - destination string
;
; Out:	 al == 0 if si == di
;		 al == 1 if si >  di
;		 al == 2 if si <  di
;
; Destr: bx, al
;--------------------------------------------------------------------
StrCmp proc
		
		mov al, 00h
		mov bx, 00h
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [si + bx], 00h
		je __si_is_null
		
		cmp byte ptr [di + bx], 00h
		je __si_more
		
		mov al, byte ptr [di + bx]
		cmp byte ptr [si + bx], al
		je __loop
		ja __si_more
		
		; si < di
		mov al, 02h
		ret
		
__si_more:	; si > di
		mov al, 01h
		ret
		
__si_is_null:	; si == 0
		
		cmp byte ptr [di + bx], 00h
		je __equal
		
		; si == 0, di != 0 => di > si
		mov al, 02h
		
		ret
		
__equal:		; di == 0, si == 0 => si == di
		mov al, 00h
		
		ret
StrCmp endp

;--------------------------------------------------------------------
; Prints string to screen
;
; Entry:
;		 si - source string
;
; Destr: bx, ah, dl
;--------------------------------------------------------------------
PrintString proc
		
		mov bx, 00h
		jmp __condition
		
		; for (; condition; step) {body}
__body:
		mov ah, 02h ; putc(dl);
		int 21h
		
__step:
		inc bx
				
__condition:
		mov dl, byte ptr [si + bx]
		
		cmp dl, 00h ; dl == '\0'?
		jne __body
		
		ret
PrintString endp

;--------------------------------------------------------------------
; Convert alpha to number
;
; Entry:
;		 si - ptr to source string
;
; Out:	 ax - out number
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
Atoi proc
		
		mov dx, 00h
		mov ax, 00h
		mov bx, 00h
		mov cx, 10d
		
		; 2^16 = 65 536
		cmp byte ptr [si + bx], 00h
		je __exit
		
		jmp __body
		
__step:
		mul cx
__body:
		mov dh, 00h
		mov dl, byte ptr [si + bx]
		sub dx, '0'
		
		add ax, dx
				
		inc bx
		
		cmp bx, 05h ; 65536 - max number length
		jae __exit
		
		cmp byte ptr [si + bx], 00h
		jne __step
		
__exit:
		ret
Atoi endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
; Itoa functions area
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; Convert decimal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaDec proc
		
		push ax
		mov bx, 00h
		mov cx, 10d
		
		jmp __num_len
		
__step1:
		inc bx
		
__num_len:
		mov dx, 00h
		div cx
		
		cmp ax, 00h
		ja __step1
		
		pop ax
		mov byte ptr [si + bx + 01], 00h ; null-terminator
		
__loop:
		mov dx, 00h
		div cx
		
		add dl, '0'
		mov byte ptr [si + bx], dl
		
		dec bx
		
		cmp ax, 00h
		ja __loop
		
		ret
ItoaDec endp

;--------------------------------------------------------------------
; Convert hexidecimal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cl
;--------------------------------------------------------------------
ItoaHex proc
		push bp
		mov bp, 05h ; number length
		
		mov byte ptr [si + bp + 01], 00h ; null-terminator
		
__loop:
		mov bx, ax
		and bx, 000Fh ; bit mask = 0b1111
		
		mov cl, byte ptr [offset HexConvert + bx]
		mov byte ptr [si + bp], cl
		
		; step
		dec bp
		shr ax, 04h ; div 16
		
		cmp bp, 01h
		ja __loop
		
		mov word ptr [si + bp - 01h], 'x0'
		
		pop bp
		ret
ItoaHex endp

;--------------------------------------------------------------------
; Convert octal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, dl
;--------------------------------------------------------------------
ItoaOct proc
		mov bx, 08h ; number length
		
		mov byte ptr [si + bx + 01], 00h ; null-terminator
__loop:
		mov dl, al
		and dl, 07h ; bit mask
		
		add dl, '0'
		
		mov byte ptr [si + bx], dl
		
		; step
		dec bx
		shr ax, 03h ; div 8
		
		cmp bx, 01h
		ja __loop
		
		mov word ptr [si + bx - 01h], 'q0'
		
		ret
ItoaOct endp

;--------------------------------------------------------------------
; Convert binary number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaBin proc
		mov bx, 00h
		mov cx, 8000h ; 0b10...0 (count ('0') == 15)
		
		mov word ptr [si + bx], 'b0'
		
		add bx, 02h
		
__loop:
		mov dx, ax
		and dx, cx
		
		cmp dx, 00h
		je __putc0
		
		mov byte ptr [si + bx], '1'
		jmp __step
__putc0:
		mov byte ptr [si + bx], '0'
		
__step: ; step
		inc bx
		shr cx, 01h ; div 2
		
		cmp cx, 00h
		ja __loop
		
		mov byte ptr [si + bx], 00h ; null-terminator
		
		ret
ItoaBin endp
	
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
; Cdecl functions area
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; Measure string length. String must be '\0'-terminated
;
; Entry: first arg - string address
;
; Out:	 bx - string length without '\0'
;
; Destr: bx
;--------------------------------------------------------------------
Cdecl_StrLen proc
		push bp
		mov bp, sp
		
		push si
		
		mov si, word ptr [bp + 04h]
		
		call StrLen
		
		pop si
		
		pop bp
		ret 2*1
Cdecl_StrLen endp

;--------------------------------------------------------------------
; Find symbol in the string
;
; Entry: 1 arg - string address
;		 2 arg - symbol to be found
;
; Out:	 bx - ptr of symbol or 0000 if symbol wasn't found.
;
; Destr: bx
;--------------------------------------------------------------------
	
Cdecl_StrChr proc
		push bp
		mov bp, sp
		
		push si ax
		
		mov si, word ptr [bp + 04h]
		mov al, byte ptr [bp + 06h]
		
		call StrChr
		
		pop ax si
		
		pop bp
		ret 2*2
Cdecl_StrChr endp

;--------------------------------------------------------------------
; Find symbol in the string
;
; Entry: 1 arg - string address
;		 2 arg - symbol to be found
;
; Out:	 bx - ptr of symbol or 0000 if symbol wasn't found.
;
; Destr: bx
;--------------------------------------------------------------------
	
Pascal_StrChr proc
		push bp
		mov bp, sp
		
		push si ax
		
		mov al, byte ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call StrChr
		
		pop ax si
		
		pop bp
		ret 2*2
Pascal_StrChr endp

;--------------------------------------------------------------------
; Copy source string to destination string. si - '\0'-terminated string.
;
; Entry: 1 arg - source string
;		 2 arg - destination string
;		 
; Out:	 bx - string length with '\0'
;
; Destr: bx
;--------------------------------------------------------------------
Cdecl_StrCpy proc
		push bp
		mov bp, sp
		
		push si di ax
		
		mov si, word ptr [bp + 04h]
		mov di, word ptr [bp + 06h]
		
		call StrCpy
		
		pop ax di si
		
		pop bp
		ret 2*2
Cdecl_StrCpy endp

;--------------------------------------------------------------------
; Copy si to di. si - '\0'-terminated string.
;
; Entry: 1 arg - source string
;		 2 arg - destination string
;		 
; Out:	 bx - string length with '\0'
;
; Destr: bx
;--------------------------------------------------------------------
Pascal_StrCpy proc
		push bp
		mov bp, sp
		
		push si di ax
		
		mov di, word ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call StrCpy
		
		pop ax di si
		
		pop bp
		ret 2*2
Pascal_StrCpy endp

;--------------------------------------------------------------------
; Copy n symbols from si to di. si - '\0'-terminated string.
;
; Entry: 1 arg - source string
;		 2 arg - destination string
;		 3 arg - count symbols to copy
;
; Out:   bx - number of copied symbols
;
; Destr: bx
;--------------------------------------------------------------------
Cdecl_StrNCpy proc
		push bp
		mov bp, sp
		
		push si di cx ax
		
		mov si, word ptr [bp + 04h]
		mov di, word ptr [bp + 06h]
		mov cx, word ptr [bp + 08h]
		
		call StrNCpy
		
		pop ax cx di si
		
		pop bp
		ret 2*3
Cdecl_StrNCpy endp

;--------------------------------------------------------------------
; Copy n symbols from si to di. si - '\0'-terminated string.
;
; Entry: 1 arg - source string
;		 2 arg - destination string
;		 3 arg - count symbols to copy
;
; Out:   bx - number of copied symbols
;
; Destr: bx, al
;--------------------------------------------------------------------
Pascal_StrNCpy proc
		push bp
		mov bp, sp
		
		push si di cx ax
		
		mov cx, word ptr [bp + 04h]
		mov di, word ptr [bp + 06h]
		mov si, word ptr [bp + 08h]
		
		call StrNCpy
		
		pop ax cx di si
		
		pop bp
		ret 2*3
Pascal_StrNCpy endp

;--------------------------------------------------------------------
; Compares strings
;
; Entry: 1 arg - source string
;		 2 arg - destination string
;
; Out:	 al == 0 if si == di
;		 al == 1 if si >  di
;		 al == 2 if si <  di
;
; Destr: al
;--------------------------------------------------------------------
Cdecl_StrCmp proc
		push bp
		mov bp, sp
		
		push bx si di
		
		mov si, word ptr [bp + 04h]
		mov di, word ptr [bp + 06h]
		
		call StrCmp
		
		pop di si bx
		
		pop bp
		ret 2*2
Cdecl_StrCmp endp

;--------------------------------------------------------------------
; Convert alpha to number
;
; Entry: 1 arg - source string
;
; Out:	 ax - out number
;
; Destr: ax
;--------------------------------------------------------------------
Cdecl_Atoi proc
		push bp
		mov bp, sp
		
		push bx cx dx si
		
		mov si, word ptr [bp + 04h]
		
		call Atoi
		
		pop si dx cx bx
		
		pop bp
		ret 2*1
Cdecl_Atoi endp
	
;--------------------------------------------------------------------
; Convert decimal number to alpha
;
; Entry: 1 arg - source number
;		 2 arg - string destination
;
; Destr: null
;--------------------------------------------------------------------
Cdecl_ItoaDec proc
		push bp
		mov bp, sp
		
		push ax bx cx dx si
		
		mov ax, word ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call ItoaDec
		
		pop si dx cx bx ax
		
		pop bp
		ret 2*2
Cdecl_ItoaDec endp
	
;--------------------------------------------------------------------
; Convert hexidecimal number to alpha
;
; Entry: 1 arg - source number
;		 2 arg - string destination
;
; Destr: null
;--------------------------------------------------------------------
Cdecl_ItoaHex proc
		push bp
		mov bp, sp
		
		push ax bx cx si
		
		mov ax, word ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call ItoaHex
		
		pop si cx bx ax
		
		pop bp
		ret 2*2
Cdecl_ItoaHex endp

;--------------------------------------------------------------------
; Convert octal number to alpha
;
; Entry: 1 arg - source number
;		 2 arg - string destination
;
; Destr: null
;--------------------------------------------------------------------
Cdecl_ItoaOct proc
		push bp
		mov bp, sp
		
		push ax bx dx si
		
		mov ax, word ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call ItoaOct
		
		pop si dx bx ax
		
		pop bp
		ret 2*2
Cdecl_ItoaOct endp

;--------------------------------------------------------------------
; Convert binary number to alpha
;
; Entry: 1 arg - source number
;		 2 arg - string destination
;
; Destr: null
;--------------------------------------------------------------------
Cdecl_ItoaBin proc
		push bp
		mov bp, sp
		
		push ax bx cx dx si
		
		mov ax, word ptr [bp + 04h]
		mov si, word ptr [bp + 06h]
		
		call ItoaBin
		
		pop si dx cx bx ax
		
		pop bp
		ret 2*2
Cdecl_ItoaBin endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
; Test functions area
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

GeneralUnitTest proc
		
		.HorizontalSep
		mov si, offset StrLenName
		call PrintString
		.HorizontalSep
		
		call StrLenUnitTests
		
		.HorizontalSep
		mov si, offset StrChrName
		call PrintString
		.HorizontalSep
		
		call StrChrUnitTests
		
		.HorizontalSep
		mov si, offset StrCpyName
		call PrintString
		.HorizontalSep
		
		call StrCpyUnitTests
		
		.HorizontalSep
		mov si, offset StrNCpyName
		call PrintString
		.HorizontalSep
		
		call StrNCpyUnitTests
		
		.HorizontalSep
		mov si, offset StrCmpName
		call PrintString
		.HorizontalSep
		
		call StrCmpUnitTests
		
		.HorizontalSep
		mov si, offset AtoiName
		call PrintString
		.HorizontalSep
		
		call AtoiUnitTests
		
		.HorizontalSep
		mov si, offset ItoaName
		call PrintString
		.HorizontalSep
		
		call ItoaUnitTests
		
		ret
GeneralUnitTest endp

;--------------------------------------------------------------------
; Test StrLen function
;
; Destr: cx, bp, si, bx
;--------------------------------------------------------------------
StrLenUnitTests proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine
		
__loop:
		.TestInput
		
		mov si, word ptr [offset StrPtrs + bp]
		call PrintString ; puts input str
		.NewLine
		
		call StrLen
		
		; convert result to string
		mov ax, bx
		mov si, offset Array
		call ItoaDec
		; puts result
		call PrintString
		
		; puts right answer
		.TestSep
		
		mov si, word ptr [offset StrLenPtrs + bp]
		call PrintString
		
		.NewLine
		
		.getch
		; step
		add bp, 02
		
		cmp bp, 02d * StrLenTestCount
		jb __loop
		
		ret
StrLenUnitTests endp

;--------------------------------------------------------------------
; Test StrChr function
;
; Destr: bx, al, si
;--------------------------------------------------------------------
StrChrUnitTests	proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine

__loop:
		.TestInput
		; puts input str
		mov si, word ptr [StrChrInputStrings + bp]
		call PrintString
		
		.TestSep
		; puts input char
		mov ah, 02h
		mov dl, byte ptr [StrChrInputChars + bp]
		int 21h
		
		.NewLine
		
		mov si, word ptr [StrChrInputStrings + bp]
		mov al, byte ptr [StrChrInputChars + bp]
		
		call StrChr
		
		; convert result to string
		mov ax, bx
		cmp ax, 00h ; sym wasn't found
		je __itoa
		sub ax, si
__itoa:
		mov si, offset Array
		call ItoaDec
		; puts result
		call PrintString
		
		; puts right answer
		.TestSep
		
		mov ax, bp
		shl ax, 1 ; mul 2
		add ax, offset StrChrRes
		mov si, ax
		call PrintString
		
		.NewLine
		
		.getch
		; step
		add bp, 02
		
		cmp bp, 02d * StrChrTestCount
		jb __loop
		
		ret
StrChrUnitTests endp


;--------------------------------------------------------------------
; Test StrCpy function
;
; Destr: si, di, bx, al, bp, cx
;--------------------------------------------------------------------
StrCpyUnitTests	proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine

		mov di, offset Array
__loop:
		.TestInput
		; puts input str
		mov si, word ptr [offset StrPtrs + bp]
		call PrintString
		
		.NewLine
		
		mov al, byte ptr [StrChrInputChars + bp]
		
		call StrCpy
		
		mov si, di
		; puts result
		call PrintString
				
		.NewLine
		
		.getch
		
		; step
		add bp, 02
		
		cmp bp, 02d * StrCpyTestCount
		jb __loop
		
		ret
StrCpyUnitTests endp

;--------------------------------------------------------------------
; Test StrNCpy function
;
; Destr: si, di, bx, al, bp, cx
;--------------------------------------------------------------------
StrNCpyUnitTests proc
		
		
		mov bp, 00h
		
		.TestStart
		.NewLine

		mov di, offset Array
__loop:
		.TestInput
		; puts input str
		mov si, word ptr [StrNCpyInputStrings + bp]
		call PrintString
		
		.TestSep
		; puts input string length
		mov si, offset Array
		mov ax, word ptr [StrNCpyInputLength + bp]
		call ItoaDec
		; puts result
		call PrintString
		
		.NewLine
		
		mov si, word ptr [StrNCpyInputStrings + bp]
		mov cx, word ptr [StrNCpyInputLength + bp]
		
		call StrNCpy
		push bx
		
		mov si, di
		; puts result
		call PrintString
				
		.NewLine
		
		.getch
		
		; step
		add bp, 02
		pop bx
		add di, bx
		
		cmp bp, 02d * StrNCpyTestCount
		jb __loop
		
		ret
StrNCpyUnitTests endp

;--------------------------------------------------------------------
; Test StrCmp function
;
; Destr: si, bx, al, di
;--------------------------------------------------------------------
StrCmpUnitTests proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine

		mov di, offset Array
__loop:
		.TestInput
		.NewLine
		
		; puts input str1
		mov si, word ptr [StrCmpInputStr1 + bp]
		call PrintString
		
		.NewLine
		
		; puts input str2
		mov si, word ptr [StrCmpInputStr2 + bp]
		call PrintString
		
		.NewLine
		
		mov si, word ptr [StrCmpInputStr1 + bp]
		mov di, word ptr [StrCmpInputStr2 + bp]
		
		call StrCmp
		
		; puts result
		mov dl, al
		add dl, '0'
		mov ah, 02h
		int 21h
		
		; print right answer
		.TestSep
		
		mov dl, byte ptr [StrCmpRes + bp]
		mov ah, 02h
		int 21h
		
		.NewLine
		
		.getch
		
		; step
		add bp, 02
		
		cmp bp, 02d * StrCmpTestCount
		jb __loop
		
		ret
StrCmpUnitTests endp

;--------------------------------------------------------------------
; Test Atoi function
;
; Destr: bp, si, ax, bx, cx, dx
;--------------------------------------------------------------------
AtoiUnitTests proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine
__loop:
		.TestInput
		; print input string
		mov si, word ptr [offset StrNums + bp]
		call PrintString
		
		.NewLine
		
		call Atoi
		
		; convert result to string
		mov si, offset Array
		call ItoaDec
		; print number
		call PrintString
		
		.NewLine
		
		.getch
		
		; step		
		add bp, 02h

		cmp bp, StrNumsCount * 02h
		jb __loop
						
		ret
AtoiUnitTests endp
	
;--------------------------------------------------------------------
; Test Itoa function
; To use:
;		1. Delete empty Itoa function
;		2. Rename ItoaX function to Itoa. Where X in {Dec, Bin, Oct, Hex}.
;
; Destr: si, ax, bx, cx, dx, bp
;--------------------------------------------------------------------
ItoaUnitTests proc
		
		mov bp, 00h
		
		.TestStart
		.NewLine
		
__loop:
		call _ItoaUnitTests_Input
		
		call _ItoaUnitTests_Func
		
		.getch
		
		; step		
		add bp, 02h

		cmp bp, StrNumsCount * 02h
		jb __loop
						
		ret
ItoaUnitTests endp

;--------------------------------------------------------------------
; Part of ItoaUnitTests function. Do not use this.
;--------------------------------------------------------------------
_ItoaUnitTests_Input proc
		.NewLine
		.TestInput
		.NewLine
		
		; print input strings
		mov si, word ptr [StrNums + bp]
		call PrintString
		
		.NewLine
		
		mov si, word ptr [BinStrNums + bp]
		call PrintString
		
		mov si, word ptr [OctStrNums + bp]
		call PrintString
		
		mov si, word ptr [HexStrNums + bp]
		call PrintString
		
		.NewLine
		
		ret
_ItoaUnitTests_Input endp

;--------------------------------------------------------------------
; Part of ItoaUnitTests function. Do not use this.
;--------------------------------------------------------------------
_ItoaUnitTests_Func proc
		
		.TestResult
		.NewLine
		
		mov si, offset Array
		
		mov ax, word ptr [DecNums + bp]
		call ItoaDec
		
		call PrintString
		.NewLine
		
		mov ax, word ptr [DecNums + bp]
		call ItoaBin
		
		call PrintString
		.NewLine
		
		mov ax, word ptr [DecNums + bp]
		call ItoaOct
		
		call PrintString
		.NewLine
		
		mov ax, word ptr [DecNums + bp]
		call ItoaHex
		
		call PrintString
		.NewLine
		
		ret
_ItoaUnitTests_Func endp

;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
; Data area
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h
		
HexConvert	db '0123456789ABCDEF'
		
StrCount	= 06h

StrPtrs		dw Str1
			dw Str2
			dw Str3
			dw Str4
			dw Str5
			dw Str6
			
StrLenPtrs  dw StrLenRes1
			dw StrLenRes2
			dw StrLenRes3
			dw StrLenRes4
			dw StrLenRes5
			dw StrLenRes6
			
StrLenTestCount = 6
StrCpyTestCount = 6
			
StrChrInputStrings:
			dw Str1
			dw Str1
			dw Str1
			dw Str1
			dw Str1
			dw Str1
			dw Str6
			dw Str6
			dw Str6
			dw Str6
			dw Str6
			
StrChrTestCount = 11d

StrChrInputChars:
			db '1',  00h
			db '2',  00h
			db '6',  00h
			db '9',  00h
			db '0',  00h
			db 'a',  00h
			db 'q',  00h
			db 020h, 00h ; space
			db 'y',  00h
			db 't',  00h
			db 'e',  00h
			
StrChrRes	dd '0'
			dd '1'
			dd '5'
			dd '8'
			dd '9'
			dd '0'
			dd '4'
			dd '3'
			dd '31' ; 13 little endian
			dd '42' ; 24 
			dd '6'
	
StrNCpyTestCount = 9d

StrNCpyInputStrings:
			dw Str1
			dw Str1
			dw Str1
			dw Str1
			dw Str3
			dw Str3
			dw Str3
			dw Str6
			dw Str6
			
StrNCpyInputLength:
			dw 01d
			dw 05d
			dw 10d
			dw 20d
			dw 00d
			dw 01d
			dw 05d
			dw 05d
			dw 08d
			
StrCmpTestCount = 9

StrCmpInputStr1:
			dw Str1
			dw Str2
			dw StrCmp1
			dw StrCmp1
			dw Str6
			dw Str3
			dw Str2
			dw Str1
			dw Str5
			
StrCmpInputStr2:
			dw Str2
			dw Str1
			dw StrCmp2
			dw StrCmp3
			dw StrCmp4
			dw Str3
			dw Str2
			dw Str5
			dw Str1
			
StrCmpRes	db '2', 00h
			db '1', 00h
			db '2', 00h
			db '2', 00h
			db '1', 00h
			db '0', 00h
			db '0', 00h
			db '2', 00h
			db '1', 00h
				
StrNumsCount = 06h

StrNums		dw StrNum1
			dw StrNum2
			dw StrNum3
			dw StrNum4
			dw StrNum5
			dw StrNum6
			
BinStrNums	dw BinStrNum1
			dw BinStrNum2
			dw BinStrNum3
			dw BinStrNum4
			dw BinStrNum5
			dw BinStrNum6
			
OctStrNums	dw OctStrNum1
			dw OctStrNum2
			dw OctStrNum3
			dw OctStrNum4
			dw OctStrNum5
			dw OctStrNum6
			
HexStrNums	dw HexStrNum1
			dw HexStrNum2
			dw HexStrNum3
			dw HexStrNum4
			dw HexStrNum5
			dw HexStrNum6

MaxNumLen	 = 06h

StrTestDescr: 	
			db "UnitTests: function_result / right_answer", 00h
StrTestSeparator:
			db " / ", 00h

StrInput	db "Input: ", 00h
StrResult	db "Result: ", 00h
			
Str1		db "1234567890", 00h
Str2		db "q", 00h
Str3		db 00h
Str4		db "12", 00h
Str5		db "1234567890123456789012345678901234567890", 00h
Str6		db "asd qwe gsf hy qe gxc z tg qe", 00h
		
StrCmp1		db "1234567890", 00h
StrCmp2		db "12345a7890", 00h
StrCmp3		db "1234567890a", 00h
StrCmp4		db "asd qwe", 00h
		
DecNums		dw 1234d
			dw 65535d
			dw 0d
			dw 123d
			dw 10000d
			dw 10010d
		
StrNum1		db "1234" , 00h
StrNum2		db "65535", 00h
StrNum3		db "0"    , 00h
StrNum4		db "0123" , 00h
StrNum5		db "10000", 00h
StrNum6		db "10010", 00h

; 0Ah == '\n'
BinStrNum1	db "bin: 0000 0100 1101 0010", 0Ah, 00h
BinStrNum2	db "bin: 1111 1111 1111 1111", 0Ah, 00h
BinStrNum3	db "bin: 0000 0000 0000 0000", 0Ah, 00h
BinStrNum4	db "bin: 0000 0000 0111 1011", 0Ah, 00h
BinStrNum5	db "bin: 0010 0111 0001 0000", 0Ah, 00h
BinStrNum6	db "bin: 0010 0111 0001 1010", 0Ah, 00h
					 
OctStrNum1	db "oct: 2322"  , 0Ah, 00h
OctStrNum2	db "oct: 177777", 0Ah, 00h
OctStrNum3	db "oct: 0"     , 0Ah, 00h
OctStrNum4	db "oct: 173"   , 0Ah, 00h
OctStrNum5	db "oct: 23420" , 0Ah, 00h
OctStrNum6	db "oct: 23432" , 0Ah, 00h
					 
HexStrNum1	db "hex: 04 D2", 0Ah, 00h
HexStrNum2	db "hex: FF FF", 0Ah, 00h
HexStrNum3	db "hex: 00 00", 0Ah, 00h
HexStrNum4	db "hex: 00 7B", 0Ah, 00h
HexStrNum5	db "hex: 27 10", 0Ah, 00h
HexStrNum6	db "hex: 27 1A", 0Ah, 00h

StrLenRes1	db "10", 00h
StrLenRes2	db "1",  00h
StrLenRes3	db "0",  00h
StrLenRes4	db "2",  00h
StrLenRes5	db "40", 00h
StrLenRes6	db "29", 00h

StrLenName	db "StrLen unit tests" , 0Ah, 00h
StrChrName	db "StrChr unit tests" , 0Ah, 00h
StrCpyName	db "StrCpy unit tests" , 0Ah, 00h
StrNCpyName	db "StrNCpy unit tests", 0Ah, 00h
StrCmpName	db "StrCmp unit tests" , 0Ah, 00h
AtoiName	db "Atoi unit tests"   , 0Ah, 00h
ItoaName	db "Itoa unit tests"   , 0Ah, 00h

HorSep		db "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", 0Ah, 00h
		
			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h
;			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
;			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			
;--------------------------------------------------------------------
; Array Area
;--------------------------------------------------------------------
	
Array:		db 256d dup(0FFh)


end start