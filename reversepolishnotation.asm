TITLE String Primitives and Macros    (Proj6_haydekev.asm)

; Author: Kevin Hayden
; Last Modified: 3/13/2022
; OSU email address: haydekev@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:    6            Due Date: 3/13/2022
; Description: Program that collects 10 integers as input from the user
;	as string, is converted to ASCII and Ints to be modified to generate a
;	sum and average before being returned as statistics to the user.  Utilizes
;	two MACROS and two required Procedures in additon to two extra Procedures.

INCLUDE Irvine32.INC

; Constants
ARRAYSIZE	=	10
MAXNUM		=	2147483647
MINNUM		=	-2147483648

; --------------------------------------------------------------------------------
; Name: mGetString
;
; Description:		Receives user keyboard input inot memory then returns bytes
;					read.
;
; Preconditions:	Validly invoked by ReadVal PROC.
;
; Receives:			CALL from ReadVal PROC.
;
; Returns:			User input collected as string input.
; --------------------------------------------------------------------------------

mGetString			MACRO		promptAddr, buffer_size

	PUSH		EDX
	PUSH		ECX
	MOV			EDX, promptAddr
	MOV			ECX, buffer_size
	CALL		ReadString
	POP			ECX
	POP			EDX

ENDM

; --------------------------------------------------------------------------------
; Name: mDisplayString
;
; Description:		Prints the string stored in memory location by reference.
;
; Preconditions:	Valid input in register called by MACRO.
;
; Receives:			CALL from main or procedures.
;
; Returns:			The string held at specific memory location.
; --------------------------------------------------------------------------------

mDisplayString		MACRO		stringAddress

	PUSH		EDX
	MOV			EDX, stringAddress
	CALL		WriteString
	POP			EDX

ENDM

.data

; Variable Definitions
titleMsg	BYTE		"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 13, 10
			BYTE		"Written by: Kevin Hayden", 0
ex_1		BYTE		"**EC: Numbers each line of user input and displays running subtotal of valid numbers.", 0
introMsg	BYTE		"Please provide 10 signed decimal integers.", 13, 10
			BYTE		"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting ", 13, 10
			BYTE		"the raw numbers I will display a list of the integers, their sum, and their avg value.", 0

promptMsg	BYTE		"Please enter a signed number: ", 0
subtotalMsg	BYTE		"Running subtotal: ", 0
numsMsg		BYTE		"You entered the following numbers: ", 0
sumMsg		BYTE		"The sum of these numbers is: ", 0
avgMsg		BYTE		"The truncated avg is: ", 0
errorMsg	BYTE		"ERROR: You did not enter a signed number or your number was too big.", 0
againMsg	BYTE		"Please try again: ", 0
comma		BYTE		", ", 0
period		BYTE		". ", 0
byeMsg		BYTE		"Thanks for playing!", 0

buffer		BYTE		250 DUP(0)
userInput	SDWORD		25 DUP(?)
numCount	DWORD		10
arr			DWORD		10 DUP(0)
sum			SDWORD		?
avg			SDWORD		?
subtotal	SDWORD		?
lineNum		DWORD		1

.code

main PROC

; Introduction
		PUSH	OFFSET titleMsg					; EBP+16
		PUSH	OFFSET introMsg					; EBP+12
		PUSH	OFFSET ex_1						; EBP+8
		CALL	Introduction					; PROC to display startup

		MOV		ECX, ARRAYSIZE					; Loop counter = 10.
		MOV		EDI, OFFSET arr					; Array to be stored in EDI. (Start of the arr)

; Collect User Input LOOP
	_InputLoop:
		MOV		EAX, lineNum					; lineNum begins at 1
		PUSH	EAX
		PUSH	OFFSET userInput				; PUSH userInput address
		CALL	WriteVal						; PROC: for line numbering

		mDisplayString	OFFSET period
		mDisplayString	OFFSET promptMsg
	
		PUSH	OFFSET subtotal					; EBP+24
		PUSH	OFFSET againMsg					; EBP+20
		PUSH	OFFSET errorMsg					; EBP+16
		PUSH	OFFSET buffer					; EBP+12
		PUSH	SIZEOF buffer					; EBP+8
		CALL	ReadVal							; PROC: read user input
		
		mDisplayString	OFFSET subtotalMsg		; MACRO: "Running subtotal: "
		PUSH	subtotal						; EBP+12
		PUSH	OFFSET userInput				; EBP+8
		CALL	WriteVal						; PROC: Display running subtotal retrieved from MACRO
		CALL	CrLf
		
		INC		lineNum							; INC line count for next LOOP
		MOV		EAX, DWORD PTR buffer			; Set buffer for iteration
		MOV		[EDI], EAX						; Set value of current element to place in arr
		ADD		EDI, 4							; Move to next element
		LOOP	_InputLoop						; LOOP until 10 integers passed

; Display LOOP
		MOV		ECX, ARRAYSIZE					; Set LOOP counter
		MOV		ESI, OFFSET arr					; arr pointed to by ESI
		MOV		EBX, 0							; initialize for addition

		CALL	CrLf
		mDisplayString   OFFSET numsMsg			; "You entered the following numbers: "

	_SubtotalSum:
		MOV		EAX, [ESI]						; Next number in arr moves into EAX
		ADD		EBX, EAX						; Add next number in arr to current
		PUSH	EAX								; PUSH EAX for finding sum
		PUSH	OFFSET userInput				; Push userInput address
		CALL	WriteVal						; PROC
		CMP		ECX, 1							; Check numbers displayed
		JE		_EndDisplay						; If 10 reached, skip comma
		JG		_Comma							; If not, print comma

	_Comma:                  
		mDisplayString	OFFSET comma			; ", "

	_EndDisplay:
		ADD		ESI, 4							; Move to next element in arr
		LOOP	_SubtotalSum					; LOOP if ECX not 0

; Calculate Sum
		PUSH	OFFSET sumMsg					; EBP+24
		PUSH	OFFSET userInput				; EBP+20
		PUSH	OFFSET arr						; EBP+16
		PUSH	ARRAYSIZE						; EBP+12
		PUSH	sum								; EBP+8
		CALL	DisplaySum						; PROC

; Calculate Average
		PUSH	OFFSET userInput				; EBP+20
		PUSH	OFFSET avgMsg					; EBP+16
		PUSH	ARRAYSIZE						; EBP+12
		PUSH	sum								; EBP+8
		CALL	DisplayAvg						; PROC
		CALL	CrLf

; Farewell
		PUSH	OFFSET byeMsg					; EBP+8
		CALL	Farewell

	Invoke ExitProcess,0						; exit to operating system

main ENDP

; --------------------------------------------------------------------------------
; Name: Introduction
;
; Description:		Procedure to display introduction to user.  EDX register used
;					to display byte strings.
;
; Preconditions:	Called by main procedure.  Runs automatically at program
;					start.
;
; Postconditions:	EDX register is changed, stack frame updated.
;
; Receives:			PUSHs from main and CALL from main.
;
; Returns:			Changes EDX register for display purposes, moves EIP forward.
; --------------------------------------------------------------------------------

Introduction PROC

; Create Stack Frame
		PUSH	EBP
		MOV		EBP, ESP

; Display Program Title
		MOV		EDX, [EBP+16]					; titleMsg
		
		mDisplayString	EDX

		CALL	CrLf
		CALL	CrLf

; Display Program Instructions
		MOV		EDX, [EBP+12]					; introMsg

		mDisplayString	EDX

		CALL	CrLf
		CALL	CrLf

; Display Program Instructions
		MOV		EDX, [EBP+8]					; ex_1

		mDisplayString	EDX

		CALL	CrLf
		CALL	CrLf

		POP		EBP
		RET		8

Introduction ENDP

; --------------------------------------------------------------------------------
; Name: ReadVal
;
; Description:		Procedure to invoke mGetString MACRO to get user input as a
;					string of digits.
;
; Preconditions:	Called by main procedure.  Runs automatically during user
;					input LOOP.
;
; Postconditions:	Converts string of ASCII digits to SDWORD and validates user
;					input.
;
; Receives:			PUSHs from main.
;
; Returns:			Modifies userInput arr and registers for conversion.
; --------------------------------------------------------------------------------

ReadVal PROC

	LOCAL	signFlag: DWORD, subTotl: DWORD, bffer: DWORD

		;PUSH	EBP								; Save from CALL
		;MOV		EBP, ESP						; Point to stack
		PUSHAD									; PUSH registers on stack
		MOV		signFlag, 1

	_Start:
		MOV		EDX, [EBP+12]					; buffer
		MOV		ECX, [EBP+8]					; SIZEOF buffer
		MOV		EDI, [EBP+24]					; subtotal

	_Next:	mGetString EDX, ECX					; MACRO: receive integer from user as string
		MOV		ESI, EDX						; Move address of userInput into ESI
		MOV		EAX, 0							; Reset for next element
		MOV		ECX, 0							; Reset for next element
		MOV		EBX, 10							; Initialize for multiplication

; Load string by single char
	_ConvertString:
		LODSB									; Loads from memory
		CMP		EAX, 0							; Check if end of string
		JE		_End							; End of string

; Sign Check
	_CheckSign:
		CMP		EAX, 45							; Compare to "-" / ASCII (45)
		JE		_Negative
		CMP		EAX, 43							; Compare to "+" / ASCII (43)
		JE		_Positive
		JMP		_Validation

; Negative Integer
	_Negative:
		MOV		signFlag, 0
		DEC		ECX
		JMP		_Continue

; Positive Integer
	_Positive:
		DEC		ECX

; Finished Handling Signs
	_Continue:
		CLD
		LODSB

; Validate within range
	_Validation:
		CMP		EAX, 48							; Compare to "0" / ASCII (48)
		JL		_Invalid						; Less than 0 is out of range
		CMP		EAX, 57							; Compare to "9" / ASCII (57)
		JG		_Invalid						; Greater than 9 is out of range

; Begin calculation for conversion.
		SUB		EAX, 48							; Subtract 48 to convert to integer
		XCHG	EAX, ECX
		IMUL	EBX								; x10 for digit
		JC		_Invalid						; Invalid if carry flag is set
		JNC		_Total							; Valid
	
; Invalid user input
	_Invalid:
		MOV		EDX, [EBP+16]					; errorMsg
		mDisplayString	EDX
		CALL	CrLf
		MOV		EDX, [EBP+20]					; againMSG
		mDisplayString	EDX
		JMP		_Start							; Return to Start

; Valid Input Received
	_Total:
		ADD		EAX, ECX						; Running total
		XCHG	EAX, ECX						; Exchange registers for next iteration
		JMP		_ConvertString					; Load next
	
; End of reading and conversion
	_End:
		ADD		subtotal, ECX					; Store sum in subtotal
		XCHG	ECX, EAX						; Exchange registers
		CMP		signFlag, 0
		MOV		DWORD PTR buffer, EAX			; Save new user input in variable
		
		POPAD									; Restore Registers
		;POP		EBP								; Restore EBP
		RET		8								; Restore Stack

ReadVal ENDP

; --------------------------------------------------------------------------------
; Name: WriteVal
;
; Description:		Procedure to convert an SDWORD integer to string of ASCII
;					digits.  Invokes mDisplayString Macro to print to output.
;
; Preconditions:	Called by main procedure.  Runs automatically during user
;					input LOOP.
;
; Postconditions:	Converts integers to string for output.
;
; Receives:			PUSHs from main.
;
; Returns:			Modifies userInput arr and registers for conversion.
; --------------------------------------------------------------------------------

WriteVal PROC

; Set up stack frame
		PUSH	EBP								; Save from CALL
		MOV		EBP, ESP						; Point to stack
		PUSHAD									; PUSH registers on Stack

; Set for looping through the integer
		MOV		EAX, [EBP+12]					; Move Subtotal for conversion
		MOV		EDI, [EBP+8]					; Move user input address for string storage
		MOV		EBX, 10							; Set for each Write
		PUSH	0								; Initialize for each Write



; Convert numbers in arr to String
	_ConvertToString:
		MOV		EDX, 0							; Reset EDX to 0
		DIV		EBX
		ADD		EDX, 48							; Add 48 to convert to string
		PUSH	EDX								; PUSH next element/integer
		CMP		EAX, 0							; Check for end of nums
		JNE		_ConvertToString				; If at end of nums, jump back

	_FillArray:
		POP		[EDI]							; Release numbers from stack
		MOV		EAX, [EDI]						; Move next integer into EAX
		INC		EDI								; INC EDI as bytes by 1
		CMP		EAX, 0							; Check if end of string
		JNE		_FillArray
		MOV		EDX, [EBP+8]					; Copy userInput arr address to EDX
		
		MOV		EDX, [EBP+8]					; Write userInput arr contents
		mDisplayString	EDX

		POPAD									; Restore Registers
		POP		EBP								; Restore EBP
		RET		8								; Restore Stack

WriteVal ENDP

; --------------------------------------------------------------------------------
; Name: DisplaySum
;
; Description:		Procedure to calculate sum of integers for user.  
;
; Preconditions:	Called by main procedure.  Once correct amount of user input
;					is gathered, runs in main.
;
; Postconditions:	Registers changed, stack frame updated.  Sum is returned.
;
; Receives:			PUSHs from main and CALL from main.
;
; Returns:			Sum of user input integers.
; --------------------------------------------------------------------------------

DisplaySum PROC

		PUSH	EBP
		MOV		EBP, ESP
		MOV		EDI, [EBP+16]						; arr
		MOV		ECX, [EBP+12]						; ARRAYSIZE
		MOV		EBX, [EBP+8]						; sum

	_SumLoop:
		MOV		EAX, [EDI]							; Move current value into EAX
		ADD		EBX, EAX							; Add current value to next element in arr
		ADD		EDI, 4								; Move to next element in arr
		LOOP	_SumLoop							; LOOP until all added
		CALL	CrLf
		
		MOV		EDX, [EBP+24]						; sumMsg
		mDisplayString	EDX							; "The sum of these numbers is: "
		
		MOV		EAX, EBX
		PUSH	EAX									; EAX holds the sum

		MOV		EDX, [EBP+20]						; Write userInput arr contents
		PUSH	EDX									; PUSH userInput
		CALL	WriteVal							; PROC: Display sum
		CALL	CrLf
		MOV		sum, EBX							; Store complete sum from ebx into variable

		POP		EBP									; Restore EBP
		RET		8									; Restore system stack

DisplaySum ENDP

; --------------------------------------------------------------------------------
; Name: DisplayAvg
;
; Description:		Procedure to calculate average of integers for user.  
;
; Preconditions:	Called by main procedure.  Once correct amount of user input
;					is gathered, runs in main.
;
; Postconditions:	Registers changed, stack frame updated.  Average is returned.
;
; Receives:			PUSHs from main and CALL from main.
;
; Returns:			Average of user input integers.
; --------------------------------------------------------------------------------

DisplayAvg PROC

		PUSH	EBP
		MOV		EBP, ESP
		MOV		ESI, [EBP+20]						; userInput
		MOV		EBX, [EBP+12]						; ARRAYSIZE
		MOV		EAX, [EBP+8]						; Sum
		MOV		EDX, 0								; Initial remainder of 0
		CDQ
		IDIV	EBX

		MOV		EDX, [EBP+16]						; avgMsg
		mDisplayString	EDX							; "The truncated average is: "

		PUSH	EAX									; PUSH truncated avg from EAX
		PUSH	ESI									; PUSH address of userInput
		CALL	WriteVal							; PROC; Display truncated avg
		CALL	CrLf
		
		POP		EBP									; Restore EBP
		RET		8									; Restore system stack

DisplayAvg ENDP

; --------------------------------------------------------------------------------
; Name: Farewell
;
; Description:		Procedure to display a farewell message to user.  EDX register
;					is used for printing byte string.
;
; Preconditions:	Called by main procedure.  This procedure runs automatically
;					after having a string pushed to it by the main procedure.
;
; Postconditions:	EDX register changes.
;
; Receives:			PUSH from main and CALL from main.
;
; Returns:			Changes EDX register to print byte string, moves EIP forward.
; --------------------------------------------------------------------------------

Farewell PROC

; Create Stack Frame
	PUSH		EBP
	MOV			EBP, ESP

; Display Program End
	MOV			EDX, [EBP+8]						; byeMsg
	mDisplayString	EDX								; "Thanks for playing!"

	CALL		CrLf
	CALL		CrLf

	POP			EBP
	RET			4

Farewell ENDP

END main