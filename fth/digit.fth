: DIGIT ( digit ) ( char -- val )
	48 -
	DUP 0 < IF1
		EXIT
	ELSE1 DUP 10 > IF2
		7 -
	ELSE2
		EXIT
	THEN1 THEN2
	DUP 0 < IF3
		EXIT
	ELSE3 DUP 35 > IF4
		32 -
	ELSE4
		EXIT
	THEN3 THEN4
;