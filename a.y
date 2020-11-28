
%token FILENAME
%token NUMBER





%{
	#include <stdlib.h>
	#include <stdio.h>
    	#include "helper.h"
    	#include "debug.h"
	using namespace std;
	void yyerror(char*);
	int yylex(void);
	extern int yylineno;
	char mytext[1024];

	extern char* yytext;
   
%}

%union {
	int number;
	char* lexval;
}


%type <node> '}'
%type <node> '.'
%%

flipbook:	
	items   
	{
		//TODO: make pdf
		
		makePdf();
	}
	
;

items:
	item items 
	{}
	|
	item
	{}

;

item:
	NUMBER NUMBER FNAME
	{
		DBG(printf("parsed item %d %d %s", $1, $2, $3));
		addPages($1, $2, $3);
	}

;

%%



void yyerror(char* s) {
    printAST(ast);
    printf("***parsing terminated*** [syntax error]::%s \n", s);
    exit(0);
}

int main() {

    initFlipbook();
    
    yyparse();
    

    std::ofstream out("assembly.s");
    out << prefix;
    out.close();
    
    return 0;
}
