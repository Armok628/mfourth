: REFILL ( refill ) ( -- flag )
	SOURCE-ID IF
		0 EXIT
	THEN 
	TIB /TIB ACCEPT
	SOURCE# !
	DROP
	-1
;