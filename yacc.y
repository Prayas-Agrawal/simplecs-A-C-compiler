/*
 * =====================================================================================
 *
 *       Filename:  yacc.y
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  25/09/20 08:59:45 PM IST
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Prayas Agrawal
 *
 * =====================================================================================
 */
%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>
	#include <unistd.h>
	#include "yaccHelper.h"
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <fcntl.h>
	#include <string.h>

	void yyerror(char *);
	int yylex(void);
	char mytext[100];
	
	struct node* rootTree;
	struct node* mainTree;
	extern struct list * ifTrees;
	extern struct list * whileTrees;
	extern struct list * switchTrees;

%}
%union
{
	int ival;
	float fval;
	struct node* nodePtr;
}

%token <nodePtr> IDENTIFIER INTEGERLIT FLOATLIT INT FLOAT VOID
%token <nodePtr> INCREMENT DECREMENT
%token <nodePtr> EQ
%token <nodePtr> GT GE LT LE NE EQEQ TWC
%token <nodePtr> ARROWOP DOTOP
%token <nodePtr> IF DO FOR ELSE CASE BREAK WHILE SWITCH DEFAULT CONTINUE
%token <nodePtr> STRUCT SIZEOF RETURN
%token <nodePtr> EXTERN PRINTF
%token <nodePtr> AND OR DECFOR
%token <nodePtr> PLUS MINUS STAR DIVIDE MOD NOT UnAND BrOPEN BrCLOSE
%token <nodePtr> SqOPEN SqCLOSE CurlOPEN CurlCLOSE
%token <nodePtr> SEMICOLON COLON COMMA


%type <nodePtr> program decl_list decl struct_decl var_decl type_spec extern_spec
%type <nodePtr> func_decl params params_list param stmt_list stmt while_stmt
%type <nodePtr> dowhile_stmt print_stmt format_specifier compound_stmt
%type <nodePtr> local_decls local_decl if_stmt return_stmt break_stmt continue_stmt
%type <nodePtr> switch_stmt compound_case single_case default_case assign_stmt incr_stmt
%type <nodePtr> decr_stmt expr Pexpr integerLit floatLit identifier arg_list args


%left COMMA
%right EQ
%left GT GE LT LE NE TWC EQEQ 
%left PLUS MINUS
%left STAR DIVIDE
%right UnAND
%left BrOPEN BrCLOSE ARROWOP DOTOP INCREMENT DECREMENT

%%
program:
	decl_list
		{
			$$ = makeNode("program", 1, $1);
			rootTree = $$;
		}
;

decl_list:
	decl_list decl 
		{$$ = makeNode("decl_list", 2, $1, $2);}
	|
	decl
		{$$ = makeNode("decl_list", 1, $1);}

;

decl:
	var_decl
		{$$ = makeNode("decl", 1, $1);}
	| 
	func_decl
		{$$ = makeNode("decl", 1, $1);}
	|
	struct_decl
		{$$ = makeNode("decl", 1, $1);}
;

struct_decl:
	STRUCT identifier CurlOPEN local_decls CurlCLOSE SEMICOLON
		{
			$$ = makeNode("struct_decl", 6, $1, $2, $3, $4, $5, $6);
		}
;

var_decl:
	type_spec identifier SEMICOLON
		{
			$$ = makeNode("var_decl", 3, $1, $2, $3);		
		}
	|
	type_spec identifier COMMA var_decl
		{
			$$ = makeNode("var_decl", 4, $1, $2, $3, $4);		
		}
	|
	type_spec identifier SqOPEN integerLit SqCLOSE SEMICOLON
		{
			$$ = makeNode("var_decl", 6, $1, $2, $3, $4, $5, $6);		
		}
	|
	type_spec identifier SqOPEN integerLit SqCLOSE COMMA var_decl
		{
			$$ = makeNode("var_decl", 7, $1, $2, $3, $4, $5, $6, $7);		
		}
;

type_spec:

	extern_spec VOID
		{
			$$ = makeNode("type_spec", 2, $1, $2);
		}
	|
	extern_spec INT
		{
			$$ = makeNode("type_spec", 2, $1, $2);
		}
	|
	extern_spec FLOAT
		{
			$$ = makeNode("type_spec", 2, $1, $2);
		}
	|
	extern_spec VOID STAR
		{
			$$ = makeNode("type_spec", 3, $1, $2, $3);
		}
	|
	extern_spec INT STAR
		{
			$$ = makeNode("type_spec", 3, $1, $2, $3);
		}
	|
	extern_spec FLOAT STAR
		{
			$$ = makeNode("type_spec", 3, $1, $2, $3);
		}
	|
	STRUCT identifier
		{
			$$ = makeNode("type_spec", 2, $1, $2);
		}
	|
	STRUCT identifier STAR
		{
			$$ = makeNode("type_spec", 3, $1, $2, $3);
		}
;
//check
//TODO: testcase4 gives "wrong" answer when empty production is 2 leveled
extern_spec:
	EXTERN 
		{
			$$ = makeNode("extern_spec", 1, $1);
		}
	| 
	/*empty*/
		{
			struct node* temp = mkEmp();
			$$ = makeNode("extern_spec", 1, temp);
			//$$ = mkEmp();
		}
;

func_decl:
	type_spec identifier BrOPEN params BrCLOSE compound_stmt
		{	
			$$ = makeNode("func_decl", 6, $1, $2, $3, $4, $5, $6);

			
			if(strcmp($2->child[0]->name, "main")==0)
				{
					mainTree = $$;
				}
		}
;
//check
params:
	params_list 
		{$$ = makeNode("params", 1, $1);}
	|
	/*empty*/
		{
			struct node* temp = mkEmp();
			$$ = makeNode("params", 1, temp);
		}
;

params_list:
	params_list COMMA param
		{
			$$ = makeNode("params_list", 3,  $1, $2, $3);
		} 
	| 
	param
		{
			$$ = makeNode("params_list", 1, $1);
		}
;

param:
	type_spec identifier
		{
			$$ = makeNode("param", 2, $1, $2);
		}
	|
	type_spec identifier SqOPEN SqCLOSE
		{
			$$ = makeNode("param", 4, $1, $2, $3, $4);
		}
;

stmt_list:
	stmt_list stmt 
		{$$ = makeNode("stmt_list", 2, $1, $2);}
	| 
	stmt
		{$$ = makeNode("stmt_list", 1, $1);}
;

stmt:
	assign_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	compound_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	if_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	while_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	switch_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	return_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	break_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	continue_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	dowhile_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	print_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	incr_stmt
		{$$ = makeNode("stmt", 1, $1);}
	|
	decr_stmt
		{$$ = makeNode("stmt", 1, $1);}
;

while_stmt:
	WHILE BrOPEN expr BrCLOSE stmt
		{
			$$ = makeNode("WhileStmt", 3, $1, $3, $5);
			a2t(whileTrees, $$);
		}
;
//check
dowhile_stmt:
	DO stmt WHILE BrOPEN expr BrCLOSE SEMICOLON
		{
			$$ = makeNode("doWhile_stmt", 5, $1, $2, $3, $5, $7);
		}
;

print_stmt:
	PRINTF BrOPEN format_specifier COMMA identifier BrCLOSE SEMICOLON
		{
			$$ = makeNode("print_stmt", 4, $1, $3, $5, $7);
		}
;

format_specifier:
	DECFOR
		{
			$$ = makeNode("format_specifier", 1, $1);
		}
;

compound_stmt:
	CurlOPEN local_decls stmt_list CurlCLOSE
		{
			$$ = makeNode("compound_stmt", 4, $1, $2, $3, $4);
		}
;
//check
local_decls:
	local_decls local_decl 
		{
			$$ = makeNode("local_decls", 2, $1, $2);
		}
	|
	/*empty*/
		{
			struct node* temp = mkEmp();
			$$ = makeNode("local_decls", 1, temp);
		}
;

local_decl:
	type_spec identifier SEMICOLON
		{
			$$ = makeNode("local_decl", 3, $1, $2, $3);
		}
	|
	type_spec identifier SqOPEN expr SqCLOSE SEMICOLON
		{
			$$ = makeNode("local_decl", 6, $1, $2, $3, $4, $5, $6);
		}
;

if_stmt:
	IF BrOPEN expr BrCLOSE stmt
		{
			$$ = makeNode("ifStmt", 5, $1, $2, $3, $4, $5); 
			a2t(ifTrees, $$);
		}
	|
	IF BrOPEN expr BrCLOSE stmt ELSE stmt
		{
			$$ = makeNode("ifStmt", 7, $1, $2, $3, $4, $5, $6, $7); 
			a2t(ifTrees, $$);
		}
		
;

return_stmt:
	RETURN SEMICOLON	
		{
			$$ = makeNode("return_stmt", 2, $1, $2);
		}
	|
	RETURN expr SEMICOLON
		{
			$$ = makeNode("return_stmt", 3, $1, $2, $3);
		}
;

break_stmt:
	BREAK SEMICOLON
		{
			$$ = makeNode("break_stmt", 2, $1, $2);
		}
;

continue_stmt:
	CONTINUE SEMICOLON
		{
			$$ = makeNode("continue_stmt", 2, $1, $2);
		}
;

switch_stmt:
	SWITCH BrOPEN expr BrCLOSE CurlOPEN compound_case default_case CurlCLOSE
		{
			$$ = makeNode("switch_stmt", 7, $1, $2, $3, $4, $5, $6, $7);
			a2t(switchTrees, $$);
		}
;

compound_case:
	single_case compound_case 
		{$$ = makeNode("compound_case", 2, $1, $2);}
	| 
	single_case
		{$$ = makeNode("compound_case", 1, $1);}
;

single_case:
	CASE integerLit COLON stmt_list
		{
			$$ = makeNode("default_case", 4, $1, $2, $3, $4);
		}
;

default_case:
	DEFAULT COLON stmt_list
		{
			$$ = makeNode("default_case", 3, $1, $2, $3);
		}
;
//redone
assign_stmt:
	identifier EQ expr SEMICOLON
		{
			struct node* temp = makeNode(op_EQ, 2, $1, $3);

			$$ = makeNode("assgn_stmt", 2, temp, $4); 
		}
	|
	//TODO: weird
	identifier SqOPEN expr SqCLOSE EQ expr SEMICOLON
		{
			$$ = makeNode("assgn_stmt", 4, $1, $3, $6, $7); 
		}
	|
	identifier ARROWOP identifier EQ expr SEMICOLON
		{

			struct node* temp = makeNode(op_EQ, 4, $1, $2, $3, $5);

			$$ = makeNode("assgn_stmt", 2, temp, $6); 
		}
	|
	identifier DOTOP identifier EQ expr SEMICOLON
		{
			struct node* temp = makeNode(op_EQ, 4, $1, $2, $3, $5);

			$$ = makeNode("assgn_stmt", 2, temp, $6); 
		}
;

incr_stmt:
	identifier INCREMENT SEMICOLON
		{
			$$ = makeNode("incr_stmt", 3, $2, $1, $3);
		}
;

decr_stmt:
	identifier DECREMENT SEMICOLON
		{
			$$ = makeNode("decr_stmt", 3, $2, $1, $3);
		}
;

//redone
expr:
	Pexpr LT Pexpr 
		{
			struct node* temp = makeNode(op_LT, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 

		}
	| 
	Pexpr GT Pexpr
		{
			struct node* temp = makeNode(op_GT, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr LE Pexpr 
		{
			struct node* temp = makeNode(op_LE, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	Pexpr GE Pexpr
		{
			struct node* temp = makeNode(op_GE, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr OR Pexpr 
		{
			struct node* temp = makeNode(op_OR, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	//TODO: check
	SIZEOF BrOPEN Pexpr BrCLOSE
		{
			$$ = makeNode("expr", 4, $1, $2, $3, $4); 
		}
	|
	Pexpr EQEQ Pexpr 
		{
			struct node* temp = makeNode(op_EQEQ, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	Pexpr NE Pexpr
		{
			struct node* temp = makeNode(op_NE, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	Pexpr TWC Pexpr
		{
			struct node* temp = makeNode(op_TWC, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr AND Pexpr
		{
			struct node* temp = makeNode(op_AND, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr ARROWOP Pexpr
		{
			struct node* temp = makeNode(op_ARROWOP, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr PLUS Pexpr 
		{
			struct node* temp = makeNode(op_PLUS, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr MINUS Pexpr
		{
			struct node* temp = makeNode(op_MINUS, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|
	Pexpr STAR Pexpr 
		{
			struct node* temp = makeNode(op_STAR, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	Pexpr DIVIDE Pexpr 
		{
			struct node* temp = makeNode(op_DIVIDE, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	| 
	Pexpr MOD Pexpr
		{
			struct node* temp = makeNode(op_MOD, 2, $1, $3);

			$$ = makeNode("expr", 1, temp); 
		}
	|	
	NOT Pexpr 
		{
			$$ = makeNode("expr", 2, $2, $1);
		}
	| 
	MINUS Pexpr 
		{
			$$ = makeNode("expr", 2, $2, $1);
		}
	| 
	PLUS Pexpr
		{
			
			$$ = makeNode("expr", 2, $2, $1);
		} 
	|
	STAR Pexpr 
		{
			$$ = makeNode("expr", 2, $2, $1);
		}
	| 
	UnAND Pexpr
		{
			$$ = makeNode("expr", 2, $2, $1);
		}
	|
	Pexpr
		{$$ = makeNode("expr", 1, $1);}
	|
	identifier BrOPEN args BrCLOSE
		{	
			$$ = makeNode("expr", 4, $1, $2, $3, $4);	
		}
	|
	identifier SqOPEN expr SqCLOSE
		{
			$$ = makeNode("expr", 4, $1, $2, $3, $4);	
		}
;

Pexpr:
	integerLit	
		{$$ = makeNode("Pexpr", 1, $1);}
	|
	floatLit	
		{$$ = makeNode("Pexpr", 1, $1);}
	|
	identifier	
		{$$ = makeNode("Pexpr", 1, $1);}
	|
	BrOPEN expr BrCLOSE	
		{
			$$ = makeNode("Pexpr", 3, $1, $2, $3);
		}
;

integerLit:
	INTEGERLIT	
		{
			$$ = makeNode("integerLit", 1, $1);
		}
;

floatLit:
	FLOATLIT
		{
			$$ = makeNode("floatLit", 1, $1);
		}
;

identifier:
	IDENTIFIER
		{
			$$ = makeNode("identifier", 1, $1);
		}
;

arg_list:
	arg_list COMMA expr 
		{
			$$ = makeNode("arg_list", 3, $1, $2, $3);
		}
	| 
	expr
		{$$ = makeNode("arg_list", 1, $1);}
;
//check
args:
	arg_list 
		{$$ = makeNode("args", 1, $1);}
	|
	/*empty*/
		{
			struct node* temp = mkEmp();
			$$ = makeNode("args", 1, temp);
		}
;

%%

void 
yyerror(char *s) 
{
	fprintf(stderr, "%s\n", s);
}

int 
main(int argc, char* argv[]) 
{
	initTrees();

	if(yyparse()==0){
		int max = 0;
		longestPath(rootTree, &max);
		printf("ROOT TREE MAX HEIGHT: %d\n", max);
		printf("IF TREE MAX HEIGHT: %d\n", longestPathList(ifTrees));
		printf("WHILE TREE MAX HEIGHT: %d\n", longestPathList(whileTrees));
		printf("SWITCH TREE MAX HEIGHT: %d\n", longestPathList(switchTrees));
		
		int mainMax = 0;
		longestPath(mainTree, &mainMax);
		printf("MAIN TREE MAX HEIGHT: %d\n", mainMax);
		//printTree(mainTree);
		
	} //0 is success
	

	return 0;
}

