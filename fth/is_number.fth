: IS-NUMBER? ( is_number ) ( c-addr u -- n ~0 | c-addr u 0 )
	IS-CHAR? IF1 2RDROP -1 EXIT THEN1
	2DUP
	BASE @ >R >BASE BASE !
	>SIGN >R
	DUP 0> IF2
		0 DUP 2SWAP
		>NUMBER NIP NIP IF3
			DROP
			RDROP
			0
		ELSE3
			NIP NIP
			R> IF3 NEGATE THEN3
			-1
		THEN3
	ELSE2
		2DROP
		RDROP
		0
	THEN2
	R> BASE !
;
