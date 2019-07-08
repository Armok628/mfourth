m4_include(.edit_warning)m4_dnl
m4_include(cmacros.m4)m4_dnl
#include "3lib.h"

	/* Data types */

#include <stdint.h>
#if INTPTR_MAX > 0xFFFFFFFF
typedef int64_t cell_t;
typedef uint64_t ucell_t;
#elif INTPTR_MAX > 0xFFFF
typedef int32_t cell_t;
typedef uint32_t ucell_t;
#else
typedef int16_t cell_t;
typedef uint16_t ucell_t;
#endif

typedef struct link_s {
	struct link_s *prev;
	char *name;
	cell_t len;
} link_t;

typedef void (*prim_t)(cell_t *,cell_t *,cell_t *);

	/* Stacks */

#define STACK_SIZE (1<<10)
#define USER_AREA_SIZE (1<<12)
cell_t stack[STACK_SIZE];
cell_t rstack[STACK_SIZE];
cell_t uarea[USER_AREA_SIZE];
#define EOS(s) &s[sizeof(s)/sizeof(*s)]

	/* Kernel structure */

#define push(s,v) (*(--s)=(cell_t)(v))
#define pop(s) (*(s++))

void next(cell_t *ip,cell_t *sp,cell_t *rp)
{
	(*(prim_t *)ip)(ip+1,sp,rp);
}

/*see word.m4 for macro definitions*/
m4_cword(EXIT,exit)
{
	ip=(cell_t *)pop(rp);
	next(ip,sp,rp);
}
m4_cword(DOCOL,docol)
{
	push(rp,ip+1);
	next((cell_t *)*ip,sp,rp);
}
m4_cword(DOLIT,dolit)
{
	push(sp,*ip);
	next(ip+1,sp,rp);
}

	/* 3lib bindings */

m4_cword(BYE,bye)
{
	(void)ip; (void)sp; (void)rp;
	bye();
}
m4_cword(RX,rx)
{
	push(sp,rx());
	next(ip,sp,rp);
}
m4_cword(TX,tx)
{
	tx((char)pop(sp));
	next(ip,sp,rp);
}

	/* Branching */

m4_cword(BRANCH,branch)
{
	ip=(cell_t *)((cell_t)ip+(cell_t)*ip);
	next(ip,sp,rp);
}
m4_cword(0BRANCH,zbranch)
{
	if (pop(sp)==0)
		ip=(cell_t *)((cell_t)ip+(cell_t)*ip);
	else
		ip++;
	next(ip,sp,rp);
}
m4_cword(EXECUTE,execute)
{
	push(rp,ip);
	next((cell_t *)*sp,sp+1,rp);
}

	/* Register manipulation */

m4_regops(ip)
m4_regops(sp)
m4_regops(rp)

	/* Stack manipulation */

m4_cword(DUP,dup)
{
	sp[-1]=sp[0];
	next(ip,sp-1,rp);
}
m4_cword(DROP,drop)
{
	next(ip,sp+1,rp);
}
m4_cword(SWAP,swap)
{
	register cell_t tmp=sp[1];
	sp[1]=sp[0];
	sp[0]=tmp;
	next(ip,sp,rp);
}
m4_cword(ROT,rot)
{
	register cell_t c=sp[2],b=sp[1],a=sp[0];
	sp[2]=b;
	sp[1]=a;
	sp[0]=c;
	next(ip,sp,rp);
}

m4_cword(NIP,nip)
{
	sp[1]=sp[0];
	next(ip,sp+1,rp);
}
m4_cword(TUCK,tuck)
{
	register cell_t b=sp[1],a=sp[0];
	sp[1]=a;
	sp[0]=b;
	sp[-1]=a;
	next(ip,sp-1,rp);
}
m4_cword(OVER,over)
{
	sp[-1]=sp[1];
	next(ip,sp-1,rp);
}
m4_cword(-ROT,unrot)
{
	register cell_t c=sp[2],b=sp[1],a=sp[0];
	sp[2]=a;
	sp[1]=c;
	sp[0]=b;
	next(ip,sp,rp);
}

m4_cword(2DROP,ddrop)
{
	next(ip,sp+2,rp);
}
/* TODO: More double-cell words */

	/* Return stack manipulation */

m4_cword(>R,to_r)
{
	push(rp,pop(sp));
	next(ip,sp,rp);
}
m4_cword(R>,r_from)
{
	push(sp,pop(rp));
	next(ip,sp,rp);
}
m4_cword(R@,rfetch)
{
	push(sp,rp[0]);
	next(ip,sp,rp);
}
m4_cword(RDROP,rdrop)
{
	next(ip,sp,rp+1);
}

	/* Arithmetic */

m4_cword(+,add) m4_2op(+)
m4_cword(-,sub) m4_2op(-)
m4_cword(*,mul) m4_2op(*)
m4_cword(/,div) m4_2op(/)
m4_cword(MOD,mod) m4_2op(%)
m4_cword(LSHIFT,lsh) m4_2op(<<)
m4_cword(RSHIFT,rsh) m4_2op(>>)
m4_cword(AND,and) m4_2op(&)
m4_cword(OR,or) m4_2op(|)
m4_cword(XOR,xor) m4_2op(^)

m4_cword(NEGATE,neg) m4_1op(-)
m4_cword(INVERT,not) m4_1op(~)
m4_cword(1+,incr) m4_1op(1+)
m4_cword(1-,decr) m4_1op(-1+)

m4_cword(/MOD,divmod)
{
	register cell_t a=sp[1],b=sp[0];
	sp[1]=a%b;
	sp[0]=a/b;
	next(ip,sp,rp);
}

m4_cword(ABS,abs)
{
	if (sp[0]<0)
		sp[0]=-sp[0];
	next(ip,sp,rp);
}
m4_cword(MAX,max)
{
	sp[1]=sp[0]>sp[1]?sp[0]:sp[1];
	next(ip,sp+1,rp);
}
m4_cword(MIN,min)
{
	sp[1]=sp[0]<sp[1]?sp[0]:sp[1];
	next(ip,sp+1,rp);
}

	/* Comparisons */

m4_cword(=,eq) m4_2op(==,-)
m4_cword(<>,neq) m4_2op(!=,-)
m4_cword(>,gt) m4_2op(>,-)
m4_cword(>=,gte) m4_2op(>=,-)
m4_cword(<,lt) m4_2op(<,-)
m4_cword(<=,lte) m4_2op(<=,-)

m4_cword(U>,ugt) m4_2op(>,-,u)
m4_cword(U>=,ugte) m4_2op(>=,-,u)
m4_cword(U<,ult) m4_2op(<,-,u)
m4_cword(U<=,ulte) m4_2op(<=,-,u)

m4_cword(0=,zeq) m4_1op(!,-)
m4_cword(0<>,zneq) m4_1op(,-,!=0)
m4_cword(0>,zgt) m4_1op(,-,>0)
m4_cword(0>=,zgte) m4_1op(,-,>=0)
m4_cword(0<,zlt) m4_1op(,-,<0)
m4_cword(0<=,zlte) m4_1op(,-,<=0)

	/* Miscellaneous constants/variables */

m4_constant(CELL,cell,sizeof(cell_t))
m4_constant(S0,s_naught,EOS(stack))
m4_constant(R0,r_naught,EOS(rstack))
m4_constant(D0,d_naught,uarea)
m4_variable(DP,dp,uarea)

	/* Memory access */

m4_cword(@,fetch)
{
	sp[0]=*(cell_t *)sp[0];
	next(ip,sp,rp);
}
m4_cword(!,store)
{
	*(cell_t *)sp[0]=sp[1];
	next(ip,sp+2,rp);
}
m4_cword(+!,addstore)
{
	*(cell_t *)sp[0]+=sp[1];
	next(ip,sp+2,rp);
}

m4_cword(C@,charfetch)
{
	sp[0]=*(char *)sp[0];
	next(ip,sp,rp);
}
m4_cword(C!,charstore)
{
	*(char *)sp[0]=(char)sp[1];
	next(ip,sp+2,rp);
}

m4_cword(CELL+,cell_add)
{
	sp[0]+=sizeof(cell_t);
	next(ip,sp,rp);
}
m4_cword(CELLS,cells)
{
	sp[0]*=sizeof(cell_t);
	next(ip,sp,rp);
}

m4_forthword(HERE,here,
	NP(dp),P(fetch),P(exit)
)
m4_forthword(ALLOT,allot,
	NP(dp),P(addstore),P(exit)
)
m4_forthword(`,',comma,
	NP(here),P(store),NP(cell),NP(allot),P(exit)
)
m4_forthword(`C,',charcomma,
	NP(here),P(charstore),PL(1),NP(allot),P(exit)
)

	/* Parsing */

#define TIB_SIZE (1<<10)
char tib[TIB_SIZE];
m4_constant(TIB,tib,tib)
m4_constant(/TIB,per_tib,TIB_SIZE)
m4_variable(SOURCE&,source_addr,tib);
m4_variable(``SOURCE#'',source_len,0);
m4_variable(>IN,in,0)


m4_forthword(SOURCE,source,
	NP(source_addr),P(fetch),NP(source_len),P(fetch),P(exit)
)
m4_forthword(SOURCE!,sourcestore,
	NP(source_len),P(store),NP(source_addr),P(store),P(exit)
)
m4_forthword(SOURCE-ID,source_id,
	NP(source_addr),P(fetch),NP(tib),P(eq),P(exit)
)
m4_forthword(ACCEPT,accept,
	P(to_r),PL(0),
	m4_BEGIN_AGAIN(`
		P(dup),P(rfetch),P(gte),m4_IF(`P(nip),P(rdrop),P(exit)'),
		P(swap),
		P(rx),P(dup),PL(10),P(lte),m4_IF(`P(drop),P(rdrop),P(exit)'),
		P(over),P(store),P(incr),P(swap),P(incr)
	')
)

	/* Entry */

/*`
m4_forthword(CR,cr,
	PL(10),P(tx),P(exit)
)
m4_forthword(`',entry,
	PL(33),m4_BEGIN_WHILE_REPEAT(`P(dup),PL(127),P(lt)',`P(dup),P(tx),P(incr)'),NP(cr),P(bye)
)
'*/

m4_forthword(`',entry,
	PL(tib),PL(TIB_SIZE),NP(accept),P(bye)
)

void _start(void)
{
	next((cell_t *)X(entry),EOS(stack),EOS(rstack));
	bye();
}
m4_include(.edit_warning)m4_dnl
