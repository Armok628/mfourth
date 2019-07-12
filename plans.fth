: COMPILE,
	DUP CELL+ @
	[ ' EXIT @ ] LITERAL = IF
		@ , EXIT
	THEN
	[ ' DOCOL @ ] LITERAL , ,
		
: REFILL
	SOURCE-ID IF
		0 EXIT
	THEN 
	TIB /TIB ACCEPT
	SOURCE# !
	DROP
	-1
;
1 CELL 3 LSHIFT 1- LSHIFT CONSTANT IMMEDIACY
: IMMEDIATE IMMEDIACY LATEST @ 2 CELLS + +! ;
: LINK>NAME ( link -- c-addr u )
	CELL+ DUP @ SWAP
	CELL+ @ IMMEDIACY INVERT AND
;
: LINK>XT 3 CELLS + ;
: COMPARE-# ( c-addr1 c-addr2 u -- -1|0|1 )
	BEGIN DUP 0>= WHILE
		>R
		OVER C@ OVER C@ -
		1 MIN -1 MAX
		DUP 0<> IF
			RDROP NIP NIP EXIT
		THEN
		DROP
		1+ SWAP 1+ SWAP
		R> 1-
	REPEAT
	2DROP
	0
;
: COMPARE ( c-addr1 u1 c-addr2 u2 -- -1|0|1 )
	ROT SWAP
	2DUP MIN
	-ROT >R >R
	COMPARE-#
	DUP IF
		RDROP RDROP
		EXIT
	THEN
	DROP
	R> R> -
	1 MIN -1 MAX
;
: FOUND-XT? ( c-addr u -- xt ~0 | c-addr u 0 )
	LATEST @
	BEGIN DUP 0<> WHILE
		>R
		2DUP R@ LINK>NAME
		COMPARE 0= IF
			2DROP
			R> LINK>XT
			-1 EXIT
		THEN
		R> @
	REPEAT
	0
;
: IS-IMMEDIATE? ( xt -- xt flag )
	DUP 2 CELLS - @
	IMMEDIACY AND
;
: HANDLE-XT ( xt -- )
	STATE @ IF
		IS-IMMEDIATE? IF
			EXECUTE
		ELSE
			COMPILE,
		THEN
	ELSE
		EXECUTE
	THEN
;
: EXTRACT ( c-addr u -- c-addr+1 u-1 char )
	OVER C@ >R 1 /STRING R>
;
: DIGIT ( char -- val )
	[CHAR] 0 -
	DUP 0 < IF
		EXIT
	ELSE DUP 10 > IF
		[ CHAR A CHAR 0 - 10 - ] LITERAL -
	ELSE
		EXIT
	THEN THEN
	DUP 0 < IF
		EXIT
	ELSE DUP 35 > IF
		[ CHAR a CHAR A - ] LITERAL -
	ELSE
		EXIT
	THEN THEN
;
: >BASE ( c-addr u -- c-addr u base )
	OVER C@ CASE
		[CHAR] $ OF 1 /STRING 16 ENDOF
		[CHAR] # OF 1 /STRING 10 ENDOF
		[CHAR] % OF 1 /STRING 2 ENDOF
		BASE @ SWAP
	ENDCASE
;
: >SIGN ( c-addr u -- c-addr u sign )
	OVER C@ [CHAR] - = DUP IF
		>R 1 /STRING R>
	THEN
;
: >NUMBER ( d c-addr u -- d c-addr u )
	BEGIN
		DUP 0>
	WHILE
		EXTRACT DIGIT
		DUP 0< OVER BASE @ >= OR IF
			DROP
			EXIT
		THEN
		>R
		2SWAP
		BASE @ UM* DROP >R BASE @ UM* R> +
		R> M+
		2SWAP
	REPEAT
;
: >CHAR ( c-addr u -- c-addr u 0 | char ~0 )
	DUP 3 <> IF 0 EXIT THEN
	>R
	DUP C@ [CHAR] ' = OVER 2 + C@ [CHAR] ' = AND IF
		1+ C@
		RDROP -1
	ELSE
		R> 0
	THEN
;
: IS-NUMBER? ( c-addr u -- n ~0 | c-addr u 0 )
	>CHAR IF -1 EXIT THEN
	2DUP
	>BASE BASE DUP @ >R !
	>SIGN >R
	0 0 2SWAP
	>NUMBER NIP NIP IF
		DROP
		RDROP
		0
	ELSE
		NIP NIP
		R> IF NEGATE THEN
		-1
	THEN
	R> BASE !
;
: HANDLE-# ( n -- )
	STATE @ IF
		POSTPONE LITERAL
	THEN
;
: /STRING ( c-addr u n -- c-addr+n u-n )
	>R SWAP R@ + SWAP R> -
;
: SKIP-UNTIL ( c-addr u xt -- c-addr u )
	>R
	BEGIN
		DUP 0<= IF RDROP EXIT THEN
		OVER C@ R@ EXECUTE IF RDROP EXIT THEN
		1 /STRING
	AGAIN
;
32 CONSTANT BL
: WHITESPACE BL <= ;
: NOT-WHITESPACE BL > ;
: PARSE-NAME ( -- c-addr u )
	SOURCE >IN @ /STRING
	['] NOT-WHITESPACE SKIP-UNTIL
	2DUP
	['] WHITESPACE SKIP-UNTIL
	NIP -
	2DUP + SOURCE& @ - >IN !
;
: TYPE
	BEGIN
		DUP 0>
	WHILE
		OVER C@ EMIT
		1 /STRING
	REPEAT
;
: INTERPRET-NAME ( c-addr u -- n ~0 | c-addr u 0 )
	FOUND-XT? IF
		HANDLE-XT
		EXIT
	THEN
	IS-NUMBER? IF
		HANDLE-#
		EXIT
	THEN
	TYPE [CHAR] ? EMIT CR
	ABORT
;
: INTERPRET
	BEGIN
		PARSE-NAME
		DUP
	WHILE
		INTERPRET-NAME
	REPEAT
	2DROP
;
: EVALUATE
	SOURCE >IN @
	>R >R >R
	SOURCE! 0 >IN !
	INTERPRET
	R> R> R>
	>IN ! SOURCE!
;
: QUIT
	R0 RP!
	BEGIN
		REFILL
		INTERPRET
	AGAIN
;
: ABORT S0 SP! QUIT ;
