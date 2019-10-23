: DO ( do )
	['] 2>R COMPILE,
	0
	MARK<
; IMMEDIATE

: ?DO ( qdo )
	['] 2>R COMPILE,
	['] 2R@ COMPILE,
	['] <> COMPILE,
	DOLIT 0BRANCH , MARK> ( POSTPONE IF )
	MARK< ( POSTPONE BEGIN )
; IMMEDIATE

: ITERATE-LOOP ( iterate_loop ) ( -- flag ) ( R: i' i -- i' i+1 )
	R>
	R> 1+ >R 2R@ =
	SWAP >R
;
: ITERATE-+LOOP ( iterate_plusloop ) ( n -- flag ) ( R: i' i -- i' i+n )
	R> SWAP
	R@ + DUP R>
	R@ < SWAP R@ < XOR
	-ROT >R >R
;

: LOOP-LIKE ( loop_like )
	COMPILE,
	DOLIT 0BRANCH , <RESOLVE ( POSTPONE UNTIL )
	?DUP IF
		>RESOLVE ( POSTPONE THEN )
	THEN
	['] UNLOOP COMPILE,
;

: LOOP ( loop )
	['] ITERATE-LOOP LOOP-LIKE
; IMMEDIATE
: +LOOP ( plus_loop )
	['] ITERATE-+LOOP LOOP-LIKE
; IMMEDIATE
: UNLOOP ( unloop ) ( R: i i' -- )
	2RDROP
;
