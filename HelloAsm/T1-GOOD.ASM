.model tiny
.code

org 100h

Start:			mov ah, 09h
			mov dx, offset HelloStr
			int 21h

			mov ax, 4C00h
			int 21h

HelloStr 		db "Hello DOS!$"

end Start