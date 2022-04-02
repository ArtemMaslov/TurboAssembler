.model tiny
.code
org 100h

start:
	xor ax, ax
	xor dx, dx
	nop	


	mov ax, 4c00h
	int 21h

end start