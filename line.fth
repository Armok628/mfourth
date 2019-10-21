REQUIRE term.fth

: SLIDE-RIGHT ( str pos cnt -- str pos cnt+1 )
	2DUP - NEGATE 2>R ( str pos ) ( R: cnt cnt-pos )
	2DUP + DUP 1+ R> ( str pos str+pos str+pos+1 cnt-pos ) ( R: cnt )
	CMOVE> ( str pos ) ( R: cnt ) 
	R> 1+ ( str pos cnt+1 )
;

: INSERT-CHARACTER ( str pos cnt char -- str pos+1 cnt )
	2OVER + C!
	>R 1+ R>
;

: HANDLE-PRINTABLE ( str pos cnt char -- str pos+1 cnt+1 )
	\ Print the character
	>R R@ EMIT
	\ Reprint the rest of the string
	CSI SCP CSI CUH
	2DUP - NEGATE 2>R
	2DUP + R> TYPE R>
	CSI RCP CSI CUS
	\ Insert the character into string memory
	SLIDE-RIGHT
	R> INSERT-CHARACTER
;

: SLIDE-LEFT ( str pos cnt -- str pos-1 cnt-1 )
	2DUP - NEGATE 2>R
	2DUP + DUP 1- R>
	CMOVE ( str pos ) ( R: cnt )
	1- R> 1-
;

: HANDLE-BACKSPACE ( str pos cnt -- str pos-1 cnt-1 )
	\ Slide the string over in memory
	SLIDE-LEFT
	\ Reprint the rest of the string one place left
	CSI CUB CSI SCP CSI CUH
	2DUP - NEGATE 2>R
	2DUP + R> TYPE R>
	BL EMIT
	CSI RCP CSI CUS
;

: HANDLE-CONTROL ( str pos cnt char -- str pos cnt flag )
	DUP 27 = IF \ Escape sequences, i.e. arrow keys
		DROP
		KEY DUP [CHAR] [ <> IF
			UNKEY
			FALSE EXIT
		ELSE
			DROP
		THEN
		>R KEY CASE
		[CHAR] D OF \ Left arrow
			1- DUP 0 MAX
			TUCK = IF CSI CUB THEN
		ENDOF
		[CHAR] C OF \ Right arrow
			1+ DUP R@ MIN
			TUCK = IF CSI CUF THEN
		ENDOF
		ENDCASE R>
		FALSE EXIT
	THEN
	CASE \ General non-printable character handling
		4 OF TRUE ENDOF
		10 OF CR TRUE ENDOF
		127 OF OVER 0> IF HANDLE-BACKSPACE THEN FALSE ENDOF
		>R FALSE R>
	ENDCASE
;

: LINE-EDIT ( c-addr u -- u )
	>R 0 0
	BEGIN ( str pos cnt ) ( R: max )
		BEGIN
			KEY DUP BL 126 WITHIN
		WHILE
			OVER R@ < IF HANDLE-PRINTABLE ELSE DROP THEN
		REPEAT
		HANDLE-CONTROL
	UNTIL ( str pos cnt ) ( R: max )
	RDROP NIP
;
