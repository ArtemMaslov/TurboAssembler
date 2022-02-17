model .tiny
.code

locals __

org 100h

start:



	mov ax, 4c00h
	int 21h
	
;--------------------------------------------------------------------
; Measure string length. String must be '\0'-terminated
;
; Entry: si - string address
;
; Out:	 cx - string length without '\0'
;
; Destr: cx
;--------------------------------------------------------------------
StrLen			proc
		
		mov cx, 00h
		dec cx
		
__loop:
		inc cx
		
		cmp byte ptr [si + cx], 00h
		jne __loop
				
		ret
StrLen			endp

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
; Copy si to di. si - '\0'-terminated string.
;
; Entry:
;		 si - source string
;		 di - destination string
;
; Destr: bx
;--------------------------------------------------------------------
StrCpy			proc
		
		mov bx, 00h
		dec bx
		
__loop:
		inc bx
		
		mov [di + bx], [si + bx]

		cmp [si + bx], 00h
		jne __loop
		
		ret
StrCpy			endp

;--------------------------------------------------------------------
; Copy n symbols from si to di. si - '\0'-terminated string.
;
; Entry:
;		 si - source string
;		 di - destination string
;		 cx - count symbols to copy
;
; Destr: bx
;--------------------------------------------------------------------
StrNCpy			proc
		
		mov bx, 00h
		dec bx
		
__loop:
		inc bx
		
		mov [di + bx], [si + bx]

		cmp [si + bx], 00h
		je __exit
		
		cmp bx, cx
		jb __loop
		
__exit:
		
		ret
StrNCpy			endp

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
; Destr: bx
;--------------------------------------------------------------------
StrCmp			proc:
		
		mov bx, 00h
		dec bx
		
__loop:
		inc bx
		
		cmp [si + bx], 00h
		je __si_is_null
		
		cmp [di + bx], 00h
		je __di_is_null
		
		cmp [si + bx], [di + bx]
		je __loop
		
		
__si_is_null:	; si == 0
		
		cmp [di + bx], 00h
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
; Convert alpha to number
;
; Entry:
;		 si - source string
;
; Out:	 
;
; Destr: 
;--------------------------------------------------------------------
Atoi			proc


Atoi			endp

;--------------------------------------------------------------------
; Convert number to alpha
;
; Entry:
;		 ax - source number
;
; Out:	 
;
; Destr: 
;--------------------------------------------------------------------
Atoi			proc


Atoi			endp
	
end start