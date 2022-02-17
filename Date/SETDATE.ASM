.model tiny
.code

org 100h

Start:			mov ah, 2bh
				
				mov cx, 2016d ; set year
				mov dh, 10    ; set month
				mov dl, 19    ; set day
				
				int 21h       ; set date
				
				mov ax, 4c00h
				int 21h	      ; exit
				
end Start