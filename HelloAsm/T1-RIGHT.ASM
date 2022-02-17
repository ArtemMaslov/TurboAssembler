.model tiny
.code

org 100h

Start:			mov ah, 09h
			mov dx, offset HelloStr
			int 21h

			mov ah, 4Ch
			int 21h

HelloStr 		db "Hello DOS!$"

end Start