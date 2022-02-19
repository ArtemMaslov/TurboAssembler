.model tiny
.code

locals __

org 100h

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
start:

	call ItoaUnitTests

	mov ax, 4c00h
	int 21h
	
;--------------------------------------------------------------------
; Test StrLen function
;
; Destr: cx, bp, si, bx
;--------------------------------------------------------------------
StrLenUnitTests	proc
		
		mov cx, 00h
		mov bp, 00h
		
__loop:
		mov si, word ptr [offset StrPtrs + bp]
		
		call StrLen
		
		inc cx
		add bp, 2
		
		cmp cx, StrCount
		jb __loop
		
		ret
StrLenUnitTests endp
	
;--------------------------------------------------------------------
; Measure string length. String must be '\0'-terminated
;
; Entry: si - string address
;
; Out:	 bx - string length without '\0'
;
; Destr: bx
;--------------------------------------------------------------------
StrLen			proc
		
		mov bx, 00h
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [si + bx], 00h
		jne __loop
				
		ret
StrLen			endp
	
;--------------------------------------------------------------------
; Test StrChr function
;
; Destr: bx, al, si
;--------------------------------------------------------------------
StrChrUnitTests	proc
		
		mov si, offset Str1
		
		mov al, '1'
		call StrChr
		
		mov al, '2'
		call StrChr
		
		mov al, '6'
		call StrChr
		
		mov al, '9'
		call StrChr
		
		mov al, '0'
		call StrChr
		
		mov al, 'a'
		call StrChr

		mov si, offset Str6
		
		mov al, 'q'
		call StrChr
		
		mov al, ' '
		call StrChr
		
		mov al, 'y'
		call StrChr
		
		mov al, 't'
		call StrChr
		
		mov al, 'e'
		call StrChr
		
		ret
StrChrUnitTests endp

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
StrChr			proc
		
		mov bx, si
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [bx], al
		je __sym_found
		
		cmp byte ptr [bx], 00h
		jne __loop
		
		; Symbol wasn't found
		mov bx, 00
		
		ret
		
		; Symbol was found 
__sym_found:

		ret
StrChr			endp

;--------------------------------------------------------------------
; Test StrCpy function
;
; Destr: si, di, bx, al, bp, cx
;--------------------------------------------------------------------
StrCpyUnitTests	proc
		
		mov cx, 00h
		mov bp, 00h
		
		mov di, offset Array
		
__loop:
		mov si, word ptr [offset StrPtrs + bp]
		
		call StrCpy
		add di, bx
		add bp, 2
		
		inc cx
		
		cmp cx, StrCount
		jb __loop
		
		ret
StrCpyUnitTests endp

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
StrCpy			proc
		
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
StrCpy			endp

;--------------------------------------------------------------------
; Test StrNCpy function
;
; Destr: si, di, bx, al, bp, cx
;--------------------------------------------------------------------
StrNCpyUnitTests	proc
		
		mov bx, 00h
		
		mov si, offset Str1
		mov di, offset Array
		mov cx, 00h
		
		call StrNCpy
		
		mov cx, 1d
		call StrNCpy
		
		mov cx, 5d
		call StrNCpy
		
		mov cx, 10d
		call StrNCpy
		
		mov cx, 20d
		call StrNCpy
		
		mov si, offset Str3
		
		mov cx, 0d
		call StrNCpy
		
		mov cx, 1d
		call StrNCpy
		
		mov cx, 5d
		call StrNCpy
		
		mov si, offset Str6
		
		mov cx, 5d
		call StrNCpy
		
		mov cx, 8d
		call StrNCpy		
		
		ret
StrNCpyUnitTests endp

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
StrNCpy			proc
		
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
		ret
StrNCpy			endp

;--------------------------------------------------------------------
; Test StrCmp function
;
; Destr: si, bx, al, di
;--------------------------------------------------------------------
StrCmpUnitTests	proc
		
		mov si, offset Str1
		mov di, offset Str2
		
		call StrCmp ; 2
		
		mov di, offset Str1
		mov si, offset Str2
		
		call StrCmp ; 1
		
		mov si, offset StrCmp1
		mov di, offset StrCmp2
		
		call StrCmp ; 2
		
		mov si, offset StrCmp1
		mov di, offset StrCmp3
		
		call StrCmp ; 2
		
		mov si, offset Str6
		mov di, offset StrCmp4
		
		call StrCmp ; 1
		
		mov si, offset Str3
		mov di, offset Str3
		
		call StrCmp ; 0
		
		mov si, offset Str2
		mov di, offset Str2
		
		call StrCmp ; 0
		
		mov si, offset Str1
		mov di, offset Str5
		
		call StrCmp ; 2
		
		mov si, offset Str5
		mov di, offset Str1
		
		call StrCmp ; 1
		
		ret
StrCmpUnitTests endp

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
StrCmp			proc
		
		mov al, 00h
		mov bx, 00h
		
		dec bx
__loop:
		inc bx
		
		cmp byte ptr [si + bx], 00h
		je __si_is_null
		
		cmp byte ptr [di + bx], 00h
		je __di_is_null
		
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
		
__di_is_null:	; di == 0, si != 0 => si > di
		mov al, 01h
		
		ret
StrCmp			endp

;--------------------------------------------------------------------
; Test Atoi function
;
; Destr: bp, si, ax, bx, cx, dx
;--------------------------------------------------------------------
AtoiUnitTests	proc
		
		mov bp, 00h
		jmp __body
		
__loop:
		add bp, 2
__body:
		mov si, word ptr [offset StrNums + bp]
		
		call Atoi

		cmp bp, StrNumsCount * 2
		jb __loop
						
		ret
AtoiUnitTests endp

;--------------------------------------------------------------------
; Convert alpha to number
;
; Entry:
;		 si - source string
;
; Out:	 ax - out number
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
Atoi			proc
		
		mov dx, 00h
		mov ax, 00h
		mov bx, 00h
		mov cx, 0Ah
		
		; 2^16 = 65 536
		cmp byte ptr [si + bx], 00h
		je __exit
		
		jmp __body
		
__step:
		mul cx
__body:
		mov dh, 00h
		mov dl, byte ptr [si + bx]
		sub dx, 30h
		
		add ax, dx
				
		inc bx
		
		cmp bx, 05h
		jae __exit
		
		cmp byte ptr [si + bx], 00h
		jne __step
		
__exit:
		ret
Atoi			endp

;--------------------------------------------------------------------
; Test Itoa function
;
; Destr: si, ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaUnitTests	proc
		
		mov si, offset Array
		
		mov ax, 65535
		call Itoa
				
		mov ax, 0
		call Itoa
				
		mov ax, 1
		call Itoa
		
		mov ax, 123
		call Itoa
		
		mov ax, 653
		call Itoa
		
		mov ax, 0804
		call Itoa
		
		mov ax, 1000
		call Itoa
		
		mov ax, 736
		call Itoa
		
		mov ax, 1353
		call Itoa
		
		mov ax, 60000
		call Itoa
						
		ret
ItoaUnitTests endp

;--------------------------------------------------------------------
; Convert decimal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaDec			proc
		
		push ax
		mov bx, 00h
		mov cx, 000Ah
		
		jmp __num_len
		
__step1:
		inc bx
		
__num_len:
		mov dx, 00h
		div cx
		
		cmp ax, 00h
		ja __step1
		
		pop ax
		
__loop:
		mov dx, 00h
		div cx
		
		mov byte ptr [si + bx], dl
		
		dec bx
		
		cmp ax, 00h
		ja __loop
		
		ret
ItoaDec			endp

;--------------------------------------------------------------------
; Convert hexidecimal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaHex			proc
		mov bx, 00h
		mov cx, 0F000h
						
__loop:
		mov dx, ax
		and dx, cx
		
		cmp dx, 00h
		je __putc0
		
		mov byte ptr [si + bx], 31h
		jmp __step
__putc0:
		mov byte ptr [si + bx], 30h
		
__step:
		inc bx
		shr cx, 01h
		
		cmp cx, 00h
		ja __loop
		
		ret
ItoaHex			endp

;--------------------------------------------------------------------
; Convert octal number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
Itoa			proc
		mov bx, 00h
		mov cx, 8000h
		
		mov dx, ax
		and dx, cx
		
		cmp dx, 00h
		je __putc0
		
		mov byte ptr [si + bx], 31h
		jmp __init
__putc0:
		mov byte ptr [si + bx], 30h
		
__init:
		inc bx
		mov cx, 7000h
		
__loop:
		mov dx, ax
		and dx, cx
		
		cmp dx, 00h
		je __putc0
		
		mov byte ptr [si + bx], 31h
		jmp __step
__putc0:
		mov byte ptr [si + bx], 30h
		
__step:
		inc bx
		shr cx, 03h
		
		cmp cx, 00h
		ja __loop
		
		ret
Itoa			endp

;--------------------------------------------------------------------
; Convert binary number to alpha
;
; Entry:
;		 ax - source number
;		 si - string destination
;
; Destr: ax, bx, cx, dx
;--------------------------------------------------------------------
ItoaBin			proc
		mov bx, 00h
		mov cx, 8000h
						
__loop:
		mov dx, ax
		and dx, cx
		
		cmp dx, 00h
		je __putc0
		
		mov byte ptr [si + bx], 31h
		jmp __step
__putc0:
		mov byte ptr [si + bx], 30h
		
__step:
		inc bx
		shr cx, 01h
		
		cmp cx, 00h
		ja __loop
		
		ret
ItoaBin			endp
	
;--------------------------------------------------------------------
; Data Area
;--------------------------------------------------------------------

			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h
			db 00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

StrPtrs		dw Str1
			dw Str2
			dw Str3
			dw Str4
			dw Str5
			dw Str6
		
StrCount	= 05h
		
StrNums		dw StrNum1
			dw StrNum2
			dw StrNum3
			dw StrNum4
			dw StrNum5
			dw StrNum6
			dw StrNumA

StrNumsCount = 07h
MaxNumLen	 = 06h
	
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

StrNum1		db "1234", 00h
StrNum2		db "65535", 00h
StrNum3		db "0", 00h
StrNum4		db "0123", 00h
StrNum5		db "10000", 00h
StrNum6		db "10010", 00h
StrNumA		db "12a54", 00h

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