/*
 * =====================================================================================
 *
 *       Filename:  a2.l
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  24/09/20 05:21:17 PM IST
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Prayas Agrawal
 *
 * =====================================================================================
 */
%{
	#include <stdlib.h>
	#include "y.tab.h"
	#include "sym.h"
	void yyerror(char *);
	extern char mytext[];
	extern struct node* mkL(char*);
	#define MKLEAF(x) yylval.nodePtr = mkL(x);
	
%}


delim [ \t\n]

ws {delim}+

letter [A-Za-z]

digit [0-9]

id (_|{letter})(_|{letter}|{digit})*

floatNumber ({digit}*(\.{digit}+)((E|e)[+-]?{digit}+)?)

singleLineComment \/\/.*

integer (0x{digit}+)|({digit}+)|({digit}*((E|e)[+-]?{digit}+)?)

%%

{singleLineComment}	{}

if		{MKLEAF("if"); return IF;}
do		{MKLEAF("do"); return DO;}
for		{MKLEAF("for"); return FOR;}
else		{MKLEAF("else"); return ELSE;}
case 		{MKLEAF("case"); return CASE;}
break		{MKLEAF("break"); return BREAK;}	
while 		{MKLEAF("while"); return WHILE;}
switch		{MKLEAF("switch"); return SWITCH;}
default	{MKLEAF("default"); return DEFAULT;}
continue	{MKLEAF("continue"); return CONTINUE;}

return		{MKLEAF("return"); return RETURN;}

struct		{MKLEAF("struct"); return STRUCT;}

sizeof		{MKLEAF("sizeof"); return SIZEOF;}

extern		{MKLEAF("extern"); return EXTERN;}

printf		{MKLEAF("printf"); return PRINTF;}

"int"		{MKLEAF("int"); return INT;}

"void"		{MKLEAF("void"); return VOID;}

"float"	{MKLEAF("float"); return FLOAT;}

{id}		{ MKLEAF(strdup(yytext)); return IDENTIFIER; }

=		{ MKLEAF("="); return EQ; }

\,		{ MKLEAF(","); return COMMA;}

{floatNumber}	{ MKLEAF("floatNUM"); return FLOATLIT; }

{integer}	{ MKLEAF("intNUM"); return INTEGERLIT; }

"++"            {MKLEAF("++"); return INCREMENT;}

"--"            {MKLEAF("--"); return DECREMENT;}

">"             {MKLEAF(">"); return GT;}

">="            {MKLEAF(">="); return GE;}

"<"             {MKLEAF("<"); return LT;}

"<="            {MKLEAF("<="); return LE;}

"!="            {MKLEAF("!="); return NE;}

"=="		{MKLEAF("=="); return EQEQ;}

"<=>"           {MKLEAF("<=>"); return TWC;}

"->"            {MKLEAF("->"); return ARROWOP;}

"."             {MKLEAF("."); return DOTOP;}

"&&"		{MKLEAF("&&"); return AND;}

"||"            {MKLEAF("||"); return OR;} 

"%d"		{MKLEAF("\%d"); return DECFOR;}

"+"		{MKLEAF("+"); return PLUS;}
"-"		{MKLEAF("-"); return MINUS;}
"*"		{MKLEAF("*"); return STAR;}
\/		{MKLEAF("/"); return DIVIDE;}
"%"		{MKLEAF("%"); return MOD;}
"&"		{MKLEAF("&"); return UnAND;}
"!"		{MKLEAF("!"); return NOT;}




\(		{MKLEAF("("); return BrOPEN;}

\)		{MKLEAF(")"); return BrCLOSE;}

\{		{MKLEAF("{"); return CurlOPEN;}

\}		{MKLEAF("}"); return CurlCLOSE;}


"["		{MKLEAF("["); return SqOPEN;}

"]"		{MKLEAF("]"); return SqCLOSE;}

";"		{MKLEAF(";"); return SEMICOLON;}

":"		{MKLEAF(":"); return COLON;}

\n	|
.	;
%%

int yywrap(void) {
    return 1;
}


