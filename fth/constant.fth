: CONSTANT ( constant ) ( x -- )
	PARSE-NAME MAKE-HEADER
	( POSTPONE ) LITERAL
	['] EXIT COMPILE,
;
