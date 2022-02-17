.MODEL tiny
.CODE
ORG 100h

locals __

;--------------------------------------------------------------------
; Main
;--------------------------------------------------------------------
START:							
		; puts(Today is); 
		MOV ah, 09h
		MOV dx, offset HelloStr
		INT 21h
		
		; Prepare in stack month, day and day of week fields
		XOR cx, cx
		PUSH cx
		PUSH cx
		PUSH cx
		
		; Get system date
		MOV ah, 2ah
		INT 21h
		
		MOV bx, sp
		MOV [bx + 04h], al 		; day of week
		MOV [bx + 02h], cx		; year
		MOV [bx],       dh    	; month
		
		MOV ah, 00h
		MOV al, dl         		; day
		
		; Print day
		CALL PrintDateNum
		
		MOV dx, '.'				; putc('.');
		MOV ah, 02h
		INT 21h
		
		POP ax
		
		; Print month
		CALL PrintDateNum
		
		MOV dx, '.'				; putc('.');
		MOV ah, 02h
		INT 21h
		
		POP ax
		
		; Print year
		CALL PrintDateNum
		
		MOV dx, offset Sep	    ; puts(', ');
		MOV ah, 09h
		INT 21h
		
		POP ax
		
		; Print day of week
		CALL PrintDayOfWeek
		
		MOV ax, 4c00h			; exit(0);
		INT 21h

;--------------------------------------------------------------------
; Print decimal number to console.
; Entry: 
;		ax - number to be printed.
; Destr: ax, dx, cx, bx
;--------------------------------------------------------------------
PrintDateNum:
		PUSH bp
		MOV  bp, sp
		
		; putc('0;); Print lead 0, if number < 10.
		CMP ax, 0Ah
		JAE __date_num_init
		
		PUSH ax
		MOV dx, '0'
		MOV ah, 02h 			; putc(dx);
		INT 21h
		POP ax
		
__date_num_init:
		MOV cx, ax 				; cx = num
		MOV ax, 0001h
		MOV bx, 000Ah
		MOV dx, 0000h
		
		; Find the ax = 10^n, there n - number of digits in cx:
		; Let  cx == 1234567d
		; Then ax == 1000000d
__loop1:			
		MUL bx
		CMP ax, cx
		JBE __loop1
		; Let cx == 1234567d
		; Now ax == 10000000d
		; So let's divide ax by 10d
		DIV bx
		
		; Let cx == 1234567d
		; Now ax == 1000000d
		
		; (ax, cx) = (cx, ax);
		MOV bx, ax
		MOV ax, cx
		MOV cx, bx
				
		; ax == number;
		; cx == 10^n;
		; Print number to console
__loop2:
		DIV cx
		; ax = ax / cx;
		; dx = ax % cx;
		; cx == 10^n;
		
		PUSH dx
		PUSH cx
		
		; dx is digit to be printed
		MOV dx, ax
		ADD dx, 30h 			; Convert digit to ascii-char.
		MOV ah, 02h 			; putc(dx);
		INT 21h
		
		; cx /= 10.
		xor dx, dx				; dx is used in division
		POP ax
		MOV bx, 000Ah
		DIV bx
		MOV cx, ax 				; cx = 10^(n-1)
		
		POP ax					; ax = number
		
		CMP cx, 00h				; while (cx > 0);
		JA __loop2
					
		MOV sp, bp
		POP bp
		RET
			
;--------------------------------------------------------------------
; Prints day of week: Monday, Tuesday, ...
; Entry: 
;		al - number of day of week (0 - sunday, 1 - monday, ..., 6 - saturday)
; Destr: ax, dx
;--------------------------------------------------------------------
PrintDayOfWeek:
		; if (day is Saturday)
		CMP al, 06h
		JE __Sat
		; else if (day is Friday)
		CMP al, 05h
		JE __Fri
		; else if (day is Thursday)
		CMP al, 04h
		JE __Thu
		; else if (day is Wednesday)
		CMP al, 03h
		JE __Wed
		; else if (day is Tuesday)
		CMP al, 02h
		JE __Tue
		; else if (day is Monday)
		CMP al, 01h
		JE __Mon
		; else day is Sunday
__Sun:								; day number is 0
		MOV ah, 09h
		MOV dx, offset Sunday
		INT 21h
		
		RET
__Sat:								; day number is 6
		MOV ah, 09h
		MOV dx, offset Saturday
		INT 21h
		
		RET
__Fri:								; day number is 5
		MOV ah, 09h
		MOV dx, offset Friday
		INT 21h

		RET
__Thu:								; day number is 4
		MOV ah, 09h
		MOV dx, offset Thursday
		INT 21h

		RET
__Wed:								; day number is 3
		MOV ah, 09h
		MOV dx, offset Wednesday
		INT 21h

		RET
__Tue:								; day number is 2
		MOV ah, 09h
		MOV dx, offset Tuesday
		INT 21h

		RET
__Mon:								; day number is 1
		MOV ah, 09h
		MOV dx, offset Monday
		INT 21h
		
		RET
	
Sep         DB ", $"
Monday		DB "Monday!$"
Tuesday		DB "Tuesday!$"
Wednesday	DB "Wednesday!$"
Thursday	DB "Thursday!$"
HelloStr	DB "Today is $"
Friday		DB "Friday$"
Saturday	DB "Saturday$"
Sunday      DB "Sunday$"

END			START 