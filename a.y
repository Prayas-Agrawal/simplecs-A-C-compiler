%token IDENTIFIER INTEGER_NUMBER FLOAT_NUMBER PLUS MINUS STAR DIV IF ELSE FOR WHILE DO INT FLOAT CHAR EQ EQEQ GEQ LEQ GT LT
%token TWC NEQ BITAND BITOR BITNOT BITXOR AND OR NOT MOD EXTERN LONG SHORT DOUBLE PRINTF PERCENTD
%token VOID SWITCH CASE STRUCT BREAK CONTINUE RETURN STRLITERAL CHARLITERAL INC DEC ARROW SIZEOF DEFAULT
%token SCANF SCANFFS
%left LT GT
%left LEQ GEQ
%left OR 
%left EQEQ NEQ TWC
%left AND ARROW
%left PLUS MINUS
%left STAR DIV MOD



%{
    #include <bits/stdc++.h>
    #include <cassert>
    #include "helper.h"
    #include "tree.h"
    #include "symbolTable.h"
    #include "logging.h"
    
    using namespace std;
    void yyerror(char*);
    int yylex(void);
    extern int yylineno;
    extern FILE* yyin;
    int intDeclarations = 0;
    char mytext[1024];
    

    string newLabel() {
        static int LabelId = 0;
        return ".L" + to_string (++LabelId);
    }

    string makeIns (string com, string op1, string op2) {
        return "\t" + com + "\t" + op1 +  ", " + op2 + "\n";
    }
    string makeIns (string com, string op1) {
        return "\t" + com + "\t" + op1 +   "\n";
    }
    string putLabel (string L) {
        return L + ":\n";
    }


    string makeCompare (string jump_ins) {
        string L1 = newLabel();
        string L2 = newLabel();

        string res = "";
        res += makeIns ("cmpl", "%ebx", "%eax");
        res += makeIns(jump_ins, L1);
        res += makeIns ("movl", "$0", "%eax");
        res += makeIns ("jmp", L2);
        res += putLabel (L1);
        res += makeIns ("movl", "$1", "%eax");
        res += putLabel (L2);

        return res;
    } 
    

    SymbolTableClass symbolTable;


    extern char* yytext;
    treeNode* ast;   // pointer to the root of the final abstract syntax tree   
    vector<treeNode*> treeNode::treeNodeList;
%}

%union {
    class treeNode* node;
}

%type <node> program
%type <node> decl_list
%type <node> decl
%type <node> struct_decl
%type <node> var_decl
%type <node> type_spec
%type <node> extern_spec
%type <node> func_decl
%type <node> params
%type <node> params1
%type <node> param_list
%type <node> param
%type <node> stmt_list
%type <node> stmt
// %type <node> expr_stmt
%type <node> print_stmt
%type <node> scanf_stmt
%type <node> format_specifier
%type <node> scanf_format_specifier
%type <node> compound_stmt
%type <node> local_decls
%type <node> local_decl
%type <node> if_stmt
%type <node> return_stmt
%type <node> assign_stmt
%type <node> incr_stmt
%type <node> decr_stmt
%type <node> expr
%type <node> Pexpr
%type <node> integerLit
%type <node> floatLit
%type <node> identifier
%type <node> arg_list
%type <node> args

%type <node> IDENTIFIER
%type <node> INTEGER_NUMBER
%type <node> FLOAT_NUMBER
%type <node> PRINTF
%type <node> SCANF
%type <node> PERCENTD
%type <node> SCANFFS
%type <node> PLUS
%type <node> MINUS
%type <node> STAR
%type <node> DIV
%type <node> IF
%type <node> ELSE
%type <node> FOR
%type <node> WHILE
%type <node> DO
%type <node> INT
%type <node> FLOAT
%type <node> CHAR
%type <node> EQ
%type <node> EQEQ
%type <node> GEQ
%type <node> LEQ
%type <node> GT
%type <node> LT
%type <node> TWC
%type <node> NEQ
%type <node> BITAND
%type <node> BITOR
%type <node> BITNOT
%type <node> BITXOR
%type <node> AND
%type <node> OR
%type <node> NOT
%type <node> MOD
%type <node> EXTERN
%type <node> LONG
%type <node> SHORT
%type <node> DOUBLE
%type <node> VOID
%type <node> SWITCH
%type <node> CASE
%type <node> STRUCT
%type <node> BREAK
%type <node> CONTINUE
%type <node> RETURN
%type <node> STRLITERAL
%type <node> CHARLITERAL
%type <node> INC
%type <node> DEC
%type <node> ARROW
%type <node> SIZEOF
%type <node> DEFAULT
%type <node> '['
%type <node> ']'
%type <node> '('
%type <node> ')'
%type <node> ';'
%type <node> ','
%type <node> ':'
%type <node> '{'
%type <node> '}'
%type <node> '.'
%%

program: decl_list  {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("program", v);

                        $$ -> append($1);
                        ast = $$;
                        purgeUnusedVars(symbolTable);

                    };

decl_list: decl_list decl   { 
                                vector<treeNode*> v = {$1, $2};
                                $$ = new treeNode("decl_list", v);
                                

                                $$->append($1);
                                $$->append($2); 
                            }

         | decl {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("decl_list", v); 
                
                    $$->append($1);
                };
         
decl: var_decl  {   
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("decl", v); 
                    $$->lineNum = $1->lineNum;
                }

    | func_decl {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("decl", v);
                    $$->lineNum = $1->lineNum;

                    $$->append($1);
                    // symbolTable.decrementScope();
                };


var_decl: type_spec identifier ';'  {
                                        $3 = new treeNode(";");
                                        vector<treeNode*> v = {$1, $2, $3};
                                        $$ = new treeNode("var_decl", v); 
                                        $$->lineNum = $2->lineNum;
                                    }

        | type_spec identifier ',' var_decl {
                                                $3 = new treeNode(",");
                                                vector<treeNode*> v = {$1, $2, $3, $4};
                                                $$ = new treeNode("var_decl", v);
                                                $$->lineNum = $2->lineNum;
                                            }   

        | type_spec identifier '[' integerLit ']' ';'   {
                                                            $3 = new treeNode("["); $5 = new treeNode("]"); $6 = new treeNode(";");
                                                            vector<treeNode*> v = {$1, $2, $3, $4, $5, $6};
                                                            $$ = new treeNode("var_decl", v);
                                                            $$->lineNum = $2->lineNum;
                                                        }
    
        | type_spec identifier '[' integerLit ']' ',' var_decl  {
                                                                    $3 = new treeNode("["); $5 = new treeNode("]"); $6 = new treeNode(",");
                                                                    vector<treeNode*> v = {$1, $2, $3, $4, $5, $6, $7};
                                                                    $$ = new treeNode("var_decl", v);
                                                                    $$->lineNum = $2->lineNum;
                                                                };

type_spec: extern_spec VOID {
                                $2 = new treeNode("VOID");
                                vector<treeNode*> v = {$1, $2}; 
                                $$ = new treeNode("type_spec", v); 
                                
                            }
         | extern_spec INT  {
                                $2 = new treeNode("INT");
                                vector<treeNode*> v = {$1, $2}; 
                                $$ = new treeNode("type_spec", v);
                                $$ -> lexValue = "int";
                                
                            }

         | extern_spec FLOAT    {
                                    $2 = new treeNode("FLOAT");
                                    vector<treeNode*> v = {$1, $2}; 
                                    $$ = new treeNode("type_spec", v);
                                }

         | extern_spec VOID STAR {
                                    $2 = new treeNode("VOID"); $3 = new treeNode("STAR");
                                    vector<treeNode*> v = {$1, $2, $3}; 
                                    $$ = new treeNode("type_spec", v);
                                }

         | extern_spec INT STAR {
                                    $2 = new treeNode("INT"); $3 = new treeNode("STAR");
                                    vector<treeNode*> v = {$1, $2, $3}; 
                                    $$ = new treeNode("type_spec", v);
                                }

         | extern_spec FLOAT STAR {
                                    $2 = new treeNode("FLOAT"); $3 = new treeNode("STAR");
                                    vector<treeNode*> v = {$1, $2, $3}; 
                                    $$ = new treeNode("type_spec", v);
                                  }

         | STRUCT identifier    {
                                    $1 = new treeNode("STRUCT");
                                    vector<treeNode*> v = {$1, $2};
                                    $$ = new treeNode("type_spec", v); 
                                }
         | STRUCT identifier STAR   {
                                        $1 = new treeNode("STRUCT"); $3 = new treeNode("STAR");
                                        vector<treeNode*> v = {$1, $2, $3};
                                        $$ = new treeNode("type_spec", v);
                                    };

extern_spec: EXTERN {
                        $1 = new treeNode("EXTERN");
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("extern_spec", v);
                    }
           |    {
                    auto x = new treeNode("epsilon");
                    vector<treeNode*> v = {x};
                    $$ = new treeNode("extern_spec", v);
                };

func_decl: type_spec identifier '(' params1 ')' compound_stmt    
{
    $3 = new treeNode("("); $5 = new treeNode(")");
    vector<treeNode*> v = {$1, $2, $3, $4, $5, $6};
    $$ = new treeNode("func_decl", v);      
    if($2->lexValue == "main") {

    }
    $$->putLabel($2->lexValue);
    $$->makeIns("pushq", "%rbp");
    //$$->append($4);

    $$->makeIns("movq", "%rsp", "%rbp");
    string offset = "$" + to_string(8*intDeclarations + 16);
    $$->makeIns("subq", offset, "%rsp");
    $$->append($6);
    $$->makeIns("leave");
    $$->makeIns("ret");
    purgeUnusedVars(symbolTable);

    symbolTable.decrementScope();
};

params1: {symbolTable.incrementScope();} params {
            
            $$ = $2;
            
    }

params: param_list  {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("params", v);
                        $$->val = $1->val;
                        $$->append($1);
                    } 
      | {
          auto x = new treeNode("epsilon");
          vector<treeNode*> v = {x};
          $$ = new treeNode("params", v);
          $$->val = 0;
        
        };

param_list: param_list ',' param    {
                                        $2 = new treeNode(",");
                                        vector<treeNode*> v = {$1, $2, $3};
                                        $$ = new treeNode("param_list", v);
                                        $$->val = $1->val + 1;
                                        $$->append($1);
                                        $$->append($3);
                                    }
          | param   {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("param_list", v);
                        $$->val = 1;
                        $$->append($1);
                    };

param: type_spec identifier {
                                vector<treeNode*> v = {$1, $2};
                                $$ = new treeNode("param", v);
                            
                                if ($1 -> lexValue == "int") {
                                    intDeclarations++;
                                    symbolTable.put($2->lexValue, $2->lineNum);
                                    // cout << "Identifier::" << $2->lexValue << endl;
                                    //$$->makeIns("popq", "%rax");
                                    //string arg2 = "-" + to_string(offset) + "(%rsp)";
                                    //$$->makeIns("movl", "%eax", arg2);

                                }
                            }
     | type_spec identifier '[' ']' {
                                        $3 = new treeNode("["); $4 = new treeNode("]");
                                        vector<treeNode*> v = {$1, $2, $3, $4};
                                        $$ = new treeNode("param", v);

                                        if ($1 -> lexValue == "int") {
                                            intDeclarations++;
                                            symbolTable.put($2->lexValue, $2->lineNum);
                                            // cout << "Identifier::" << $2->lexValue << endl;
                                        }
                                    
                                    }
    | type_spec 

;
stmt_list: stmt_list stmt   {
                                vector<treeNode*> v = {$1, $2};
                                $$ = new treeNode("stmt_list", v);
                                $$->append($1);
                                $$->append($2);
                            }
         | stmt {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("stmt_list", v);
                
                    $$->append($1);
                    
                };

stmt: assign_stmt   {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("stmt", v);
                        $$->lineNum = $1->lineNum;
                    
                        $$->append($1);
                    }
    | {symbolTable.incrementScope();} compound_stmt {
                        vector<treeNode*> v = {$2};
                        $$ = new treeNode("stmt", v);
                        purgeUnusedVars(symbolTable);
                        symbolTable.decrementScope();

                        $$->append($2);
                    }
    | if_stmt   {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("stmt", v);
                    $$->lineNum = $1->lineNum;
                
                    $$->append($1);
                }
    | return_stmt   {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("stmt", v);
                        $$->append($1);
                        $$->lineNum = $1->lineNum;
                    }
   
    | print_stmt    {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("stmt", v);
                        $$->lineNum = $1->lineNum;
                    
                        $$->append($1);
                    }
    | scanf_stmt {
    			 vector<treeNode*> v = {$1};
                        $$ = new treeNode("stmt", v);
                        $$->lineNum = $1->lineNum;
                    
                        $$->append($1);
   		  }
    | incr_stmt {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("stmt", v);
                    $$->lineNum = $1->lineNum;

                    $$->append($1);
                }  
    | decr_stmt {   
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("stmt", v);
                    $$->lineNum = $1->lineNum;
                
                    $$->append($1);
                }; 

print_stmt: PRINTF '(' format_specifier ',' identifier ')' ';'  
{
    $1 = new treeNode("PRINTF"); $2 = new treeNode("("); $4 = new treeNode(",");
    $6 = new treeNode(")"); $7 = new treeNode(";");
    vector<treeNode*> v = {$1, $2, $3, $4, $5, $6, $7};
    $$ = new treeNode("print_stmt", v);
    $$->lineNum = $5->lineNum;
    
    struct attr* sym = symbolTable.getSymbolAttr($5->lexValue);
    if(sym->isStaticallyDefined == 1)
    {
    	    constantPropogation($5->lineNum, $5->lexValue, sym->staticValue);
	    string arg2 = "$" + to_string(sym->staticValue);
	    $$->makeIns("movl", arg2, "%esi");
	    $$->makeIns("leaq", ".LC0(%rip)", "%rdi");
	    $$->makeIns("movl", "$0", "%eax");
	    $$->makeIns("call", "printf@PLT");
    }
    else
    {
	    int offset = symbolTable.get( $5->lexValue );
	    string arg2 = "-" + to_string(offset) + "(%rbp)";
	    $$->makeIns("movl", arg2, "%esi");
	    $$->makeIns("leaq", ".LC0(%rip)", "%rdi");
	    $$->makeIns("movl", "$0", "%eax");
	    $$->makeIns("call", "printf@PLT");
    }
    
    

};

scanf_stmt: SCANF '(' scanf_format_specifier ',' BITAND identifier ')' ';'
{

    $1 = new treeNode("SCANF"); $2 = new treeNode("("); $4 = new treeNode(",");
    $5 = new treeNode("&"); $7 = new treeNode(")"); $8 = new treeNode(";");
    vector<treeNode*> v = {$1, $2, $3, $4, $5, $6, $7, $8};
    $$ = new treeNode("scanf_stmt", v);
    
    int offset = symbolTable.setDefinedFlagAndAllocStack( $6->lexValue );
    string arg2 = "-" + to_string(offset) + "(%rbp)";
    $$->makeIns("leaq", arg2, "%esi");
    $$->makeIns("movl", ".LC1", "%rdi");
    $$->makeIns("movl", "$0", "%eax");
    $$->makeIns("call", "__isoc99_scanf");
};

scanf_format_specifier: SCANFFS  {
                                $1 = new treeNode("SCANFFS");
                                vector<treeNode*> v = {$1};
                                $$ = new treeNode("scanf_format_specifier", v);
                            };

format_specifier: PERCENTD  {
                                $1 = new treeNode("PERCENTD");
                                vector<treeNode*> v = {$1};
                                $$ = new treeNode("format_specifier", v);
                            };

compound_stmt: '{' local_decls stmt_list '}'    {
                                                    $1 = new treeNode("{"); $4 = new treeNode("}");
                                                    vector<treeNode*> v = {$1, $2, $3, $4};
                                                    $$ = new treeNode("compound_stmt", v);
                                                    $$->append($2);
                                                    $$->append($3);
                                                };

local_decls: local_decls local_decl {
                                        vector<treeNode*> v = {$1, $2};
                                        $$ = new treeNode("local_decls", v);
                                        $$->append($1);
                                        $$->append($2);
                                    } 
           |    {
                    auto x = new treeNode("epsilon");
                    vector<treeNode*> v = {x};
                    $$ = new treeNode("local_decls", v);
                };

local_decl: type_spec identifier ';'    {
                                            $3 = new treeNode(";");
                                            vector<treeNode*> v = {$1, $2, $3};
                                            $$ = new treeNode("local_decl", v);
                                            $$->lineNum = $2->lineNum;
                                            
                                            if ($1 -> lexValue == "int") {

                                                symbolTable.put($2->lexValue, $2->lineNum);
                                            }
                                        };

if_stmt: IF '(' expr ')' stmt   {
                                    $1 = new treeNode("IF");
                                    $2 = new treeNode("("); $4 = new treeNode(")");
                                    vector<treeNode*> v = {$1, $2, $3, $4, $5};
                                    $$ = new treeNode("if_stmt", v);
                                    $$->lineNum = $3->lineNum;

				     if($3->isLitOrStaticDefined == 1)
				     {
				     	if($3->val > 0)
				     	{
				     	  $$->append($5);
				     	  logIfSimpl(1, $$->lineNum);
				     	}
				     	else
				     	{
				     	  //no op
				     	  logIfSimpl(0, $$->lineNum);
				     	  //dontOptimiseIfBlockFlag = 1;
				     	}
				     }
				     else
				     {
	                              string end = newLabel();
	                              $$->append($3);
	                              $$->makeIns("cmpl", "$0", "%eax");
	                              $$->makeIns("je", end);
	                              $$->append($5);
	                              $$->putLabel(end);
		                     }
                                }
       | IF '(' expr ')' stmt ELSE stmt {
                                            $1 = new treeNode("IF");
                                            $2 = new treeNode("("); $4 = new treeNode(")"); $6 = new treeNode("ELSE");
                                            vector<treeNode*> v = {$1, $2, $3, $4, $5, $6, $7};
                                            $$ = new treeNode("if_stmt", v);
                                            $$->lineNum = $3->lineNum;
                                        
                                            if($3->isLitOrStaticDefined == 1)
					     {
					      	if($3->val > 0)
					     	{
					     	  $$->append($5);
					     	  logIfSimpl(1, $$->lineNum);
					     	}
					     	else
					     	{
                                                $$->append($7);
                                                logIfSimpl(0, $$->lineNum);
					     	}
					     }
					     else
					     {
                                              string els = newLabel();
                                              string end = newLabel();
                                              $$->append($3);
                                              $$->makeIns("cmpl", "$0", "%eax");
                                              $$->makeIns("je", els);
                                              $$->append($5);
                                              $$->makeIns("jmp", end);
                                              $$->putLabel(els);
                                              $$->append($7);
                                              $$->putLabel(end);       
				             }
                                        };

return_stmt: RETURN ';' { 
                            $1 = new treeNode("RETURN"); $2 = new treeNode(";");
                            vector<treeNode*> v = {$1, $2};
                            $$ = new treeNode("return_stmt", v);
                            $$->makeIns("leave");
                            $$->makeIns("ret");
                            $$->lineNum = $1->lineNum;
                            
                        }
           | RETURN expr ';'    {
                                    $1 = new treeNode("RETURN"); $3 = new treeNode(";");
                                    vector<treeNode*> v = {$1, $2, $3};
                                    $$ = new treeNode("return_stmt", v);
                                    $$->lineNum = $1->lineNum;
                                
                                    $$->append($2);
                                    $$->makeIns("leave");
                                    $$->makeIns("ret");  
                                };



assign_stmt: identifier EQ expr ';' {
                                        vector<treeNode*> u = {$1, $3};
                                        $2 = new treeNode("EQ", u);
                                        $4 = new treeNode(";");
                                        vector<treeNode*> v = {$2, $4};
                                        $$ = new treeNode("assign_stmt", v);
                                        $$->lineNum = $1->lineNum;
                                        symbolTable.setDefinedFlagAndAllocStack($1->lexValue);
                                        
                                        struct attr* sym = symbolTable.getSymbolAttr($1->lexValue);
                                        if($3->isLitOrStaticDefined == 1)
                                        {
                                        
                                        	
                                        	sym->isStaticallyDefined = 1;
                                        	sym->staticValue = $3->val;
                                        }
                                        
                                        else
                                        {
                                        	sym->isStaticallyDefined = 0;
                                        }
                                        
                                        
                                        int offset = symbolTable.get( $1->lexValue );
                                        
                                        string arg2 = "-" + to_string(offset) + "(%rbp)";
                                        
                                        $$->append($3);
                                        $$->makeIns("movl", "%eax", arg2);


                                    };

incr_stmt: identifier INC ';'   {
                                    $3 = new treeNode(";");
                                    $2 = new treeNode("INC");
                                    vector<treeNode*> v = {$1, $2, $3};
                                    $$ = new treeNode("incr_stmt", v);

                                    int offset = symbolTable.get( $1->lexValue );
                                    string arg2 = "-" + to_string(offset) + "(%rbp)";
                                    $$->makeIns("addl", "$1", arg2);


                                };

decr_stmt: identifier DEC ';'   {
                                    $3 = new treeNode(";");
                                    $2 = new treeNode("DEC");
                                    vector<treeNode*> v = {$1, $2, $3};
                                    $$ = new treeNode("decr_stmt", v);

                                    int offset = symbolTable.get( $1->lexValue );
                                    string arg2 = "-" + to_string(offset) + "(%rbp)";
                                    $$->makeIns("subl", "$1", arg2);
                                };

expr: Pexpr LT Pexpr    {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("LT", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_LT, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("jl"));
			     }
                        }
    | Pexpr GT Pexpr    {   
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("GT", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_GT, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("jg"));
			     }
                        }
    | Pexpr LEQ Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("LEQ", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_LEQ, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("jle"));
			     }

                        }
    | Pexpr GEQ Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("GEQ", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_GEQ, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("jge"));
			     }

                        }
    | Pexpr OR Pexpr    {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("OR", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_OR, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("orl", "%ebx", "%eax");
			     }

                        }
    | SIZEOF '(' Pexpr ')'  {
                                $1 = new treeNode("SIZEOF"); $2 = new treeNode("("); $4 = new treeNode(")");
                                vector<treeNode*> v = {$1, $2, $3, $4};
                                $$ = new treeNode("expr", v);

                                $$->makeIns("movl", "$4", "%eax");

                            }
    | Pexpr EQEQ Pexpr  {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("EQEQ", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_EQEQ, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("je"));
			     }


                        }
    | Pexpr NEQ Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("NEQ", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_NEQ, $$, $1, $3);
			       
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->append(makeCompare("jne"));
			     }

                        }
    | Pexpr TWC Pexpr {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("TWC", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

                            string less = newLabel();
                            string more = newLabel();
                            string end = newLabel();
                            
			     
			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_TWC, $$, $1, $3);
			       
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");

                              $$->makeIns ("cmpl", "%ebx", "%eax");
                              $$-> makeIns("jl", less);

                              $$-> makeIns ("cmpl", "%ebx", "%eax");
                              $$-> makeIns("jg", more);

                              $$->makeIns("movl", "$0", "%eax");
                              $$-> makeIns("jmp", end);

                              $$->putLabel(more);
                              $$->makeIns("movl", "$1", "%eax");
                              $$-> makeIns("jmp", end);

                              $$->putLabel(less);
                              $$->makeIns("movl", "$-1", "%eax");
                              $$-> makeIns("jmp", end);
  
                              $$->putLabel(end);
			     }

                        }
    | Pexpr AND Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("AND", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;
                            
			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_AND, $$, $1, $3);
			     
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("andl", "%ebx", "%eax");
			     }

                        }
    | Pexpr ARROW Pexpr {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("ARROW", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);


                        }
    | Pexpr PLUS Pexpr  {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("PLUS", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_PLUS, $$, $1, $3);
			       
			     else
			     {
                              $$->append($3);
                              $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("addl", "%ebx", "%eax");
			     }
                        }
    | Pexpr MINUS Pexpr {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("MINUS", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			     {
			       constantFolding(_MINUS, $$, $1, $3);
			     }
			       
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("subl", "%ebx", "%eax");
			     }

                        }
    | Pexpr STAR Pexpr  {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("STAR", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

			     if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       constantFolding(_STAR, $$, $1, $3);

			     else if(($1->isLitOrStaticDefined != 1) && ($3->isLitOrStaticDefined != 1))
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("imul", "%ebx", "%eax");
			     }
			     else
			       strengthReduction($$, $1, $3);

                        }
    | Pexpr DIV Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("DIV", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

                            if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       if($3->val !=0)
			         constantFolding(_DIV, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("movl", "$0" ,"%edx");
                              $$->makeIns("idivl", "%ebx");
			     }

                        }
    | Pexpr MOD Pexpr   {
                            vector<treeNode*> u = {$1, $3};
                            $2 = new treeNode("MOD", u);
                            vector<treeNode*> v = {$2};
                            $$ = new treeNode("expr", v);
                            $$->lineNum = $1->lineNum;

                            if(($1->isLitOrStaticDefined==1) && ($3->isLitOrStaticDefined==1))
			       if($3->val != 0)
			         constantFolding(_MOD, $$, $1, $3);
			     else
			     {
			       $$->append($3);
			       $$->isLitOrStaticDefined=0;
                              $$->makeIns("pushq", "%rax");
                              $$->append($1);
                              $$->makeIns("popq", "%rbx");
                              $$->makeIns("movl", "$0" ,"%edx");
                              $$->makeIns("idivl", "%ebx");
                              $$->makeIns("movl", "%edx" ,"%eax");
			     }
                        }
    | NOT Pexpr {
                    $1 = new treeNode("NOT");
                    vector<treeNode*> v = {$1, $2};
                    $$ = new treeNode("expr", v);
                    $$->lineNum = $2->lineNum;

     	            if($2->isLitOrStaticDefined == 1)
		       constantFolding(_NOT, $$, $2);
		       
		    else
		    {
                     $$->append($2);
                     $$->isLitOrStaticDefined=0;
                     $$->makeIns("movl", "%eax", "%ebx");
                     $$->makeIns("xorl", "%eax", "%eax");
                     $$->makeIns("test", "%ebx", "%ebx");
                     $$->makeIns("sete", "%al");
		    }

                }
    | MINUS Pexpr   {
                        $1 = new treeNode("MINUS");
                        vector<treeNode*> v = {$1, $2};
                        $$ = new treeNode("expr", v);
                        $$->lineNum = $2->lineNum;

     	                if($2->isLitOrStaticDefined == 1)
		          constantFolding(_MINUS, $$, $2);
		          
		         else
		         {
			   $$->append($2);
			   $$->isLitOrStaticDefined=0;
                          $$->makeIns("negl", "%eax");
		         }

                    }
    | PLUS Pexpr    {
                        $1 = new treeNode("PLUS");
                        vector<treeNode*> v = {$1, $2};
                        $$ = new treeNode("expr", v);
                        $$->lineNum = $2->lineNum;

     	                if($2->isLitOrStaticDefined == 1)
		          constantFolding(_PLUS, $$, $2);
		          
		        else
		        {
		          $$->append($2);
		          $$->isLitOrStaticDefined=0;
		        }
                        
                    }
    | STAR Pexpr    {
                        $1 = new treeNode("STAR");
                        vector<treeNode*> v = {$1, $2};
                        $$ = new treeNode("expr", v);
                        $$->lineNum = $2->lineNum;
                        //Incorrect
                        $$->append($2);
                    }
    | BITAND Pexpr  {   
                        $1 = new treeNode("BITAND");
                        vector<treeNode*> v = {$1, $2};
                        $$ = new treeNode("expr", v);
                        $$->lineNum = $2->lineNum;
                    }
    | Pexpr {
                vector<treeNode*> v = {$1};
                $$ = new treeNode("expr", v);
                $$->lineNum = $1->lineNum;
                
                $$->append($1);

                if($1->isLitOrStaticDefined == 1)
		 {
	           $$->val = $1->val;
	           $$->isLitOrStaticDefined = 1;
	         }
	        else
                {
                	$$->isLitOrStaticDefined = 0;
                }
            };

Pexpr: integerLit   {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("Pexpr", v);

                        string num = "$" + $1->lexValue;
                        $$->makeIns("movl", num , "%eax");
                        $$->val = stoi ($1->lexValue);
                        $$->isLitOrStaticDefined = 1;
                        $$->lineNum = $1->lineNum;
                    
                    }
     | floatLit {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("Pexpr", v);
                }
     | identifier   {
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("Pexpr", v);

                        int offset = symbolTable.get( $1->lexValue );
                        string arg1 = "-" + to_string(offset) + "(%rbp)";
                        $$->makeIns("movl", arg1, "%eax");
                        
                        struct attr* sym = symbolTable.getSymbolAttr($1->lexValue);
                        if(sym->isStaticallyDefined == 1)
                        {
                        	$$->isLitOrStaticDefined = 1;

                        	$$->val = sym->staticValue;
                        	constantPropogation($1->lineNum, $1->lexValue, sym->staticValue);
                        	//printf(" %s is statically defined as %d\n", (char*)&($1->lexValue)[0], $$->val);
                        }
                        else
                        {
                        	$$->isLitOrStaticDefined = 0;
                        }
                        $$->lineNum = $1->lineNum;

                    }
     | '(' expr ')' {
                        $1 = new treeNode("("); $3 = new treeNode(")");
                        vector<treeNode*> v = {$1, $2, $3};
                        $$ = new treeNode("Pexpr", v);
                        $$->lineNum = $2->lineNum;
                        
                        if($2->isLitOrStaticDefined == 1)
                        {
                        	$$->isLitOrStaticDefined = 1;
                        	$$->val = $2->val;
                        }
                        else
                        {
                        	$$->isLitOrStaticDefined = 0;
                        }
                        
                        treeNode* subtreePtr = findSubTree(symbolTable, treeNode::treeNodeList, $2);
                        if(subtreePtr != NULL) 
                        {
                        	//printf("found subtree %d of %d\n", subtreePtr->lineNum, $$->lineNum);
                        	//commonSubExprElimination(treeNode::treeNodeList, $$);
                        	//$$->append();
                        }

                        else
                        {
		                $$->append($2);
                        }
                    };
    
integerLit: INTEGER_NUMBER  {
                                //$1 = new treeNode("INTEGER_NUMBER");
                                vector<treeNode*> v = {$1};
                                $$ = new treeNode("integerLit", v);
                                string temp(mytext);
                                $$->lexValue = temp;
                                $$->lineNum = $1->lineNum;

                            };

floatLit: FLOAT_NUMBER  {
                            //$1 = new treeNode("FLOAT_NUMBER");
                            vector<treeNode*> v = {$1};
                            $$ = new treeNode("floatLit", v);
                            string temp(mytext);
                            $$->lexValue = temp;
                            $$->lineNum = $1->lineNum;

                        };

identifier: IDENTIFIER  {
                            //$1 = new treeNode("IDENTIFIER");
                            vector<treeNode*> v = {$1};
                            $$ = new treeNode("identifier", v);
                            string temp(mytext);
                            $$->lexValue = temp;
                            $$->lineNum = $1->lineNum;

                        } 
          | PRINTF  {
                        $1 = new treeNode("IDENTIFIER");
                        vector<treeNode*> v = {$1};
                        $$ = new treeNode("identifier", v);
                        $$->lexValue = "printf";
                    };

arg_list: arg_list ',' expr {
                                $2 = new treeNode(",");
                                vector<treeNode*> v = {$1, $2, $3};
                                $$ = new treeNode("arg_list", v);

                                $$->append($1);
                                $$->append($3);
                                $$->makeIns("subq", "$4", "%rsp");
                                $$->makeIns("movl", "%eax", "0(%rsp)");
                                $$->val = $1->val + 1;
                            }
        | expr  {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("arg_list", v);
                    $$->val = 1;

                    $$->append($1);
                    $$->makeIns("subq", "$4", "%rsp");
                    $$->makeIns("movl", "%eax", "0(%rsp)");

                };

args: arg_list  {
                    vector<treeNode*> v = {$1};
                    $$ = new treeNode("args", v);
                
                    $$->makeIns("pushq", "$0");
                    $$->makeIns("pushq", "$0");
                    $$->append($1);
                    $$->val = $1->val;                

                    string arg1 = "$" + to_string(4*($$->val) + 16);
                    $$->makeIns("addq", arg1, "%rsp");
                }
    |   {
            auto x = new treeNode("epsilon");
            vector<treeNode*> v = {x};
            $$ = new treeNode("args", v);
        };

%%


void printAST() {   // not a pretty printer
    queue<treeNode*> q;
    ast->level = 0;
    q.push(ast);
    int previous_level = 0;
    while(!q.empty()) {
        auto curr = q.front();
        q.pop();
        if(curr->level > previous_level) {
            cout << endl;
            previous_level = curr->level;
        }
        cout << curr->nodeName;
        for(int i = 0; i < 5; i++) {
            cout << ' ';
        }
        for(auto& child : curr->children) {
            child->level = 1 + curr->level;
            q.push(child);
        }
    }
    cout << endl;
}

void printAST(treeNode* root, string prefix = "", bool isLast = true) {
    if(root == NULL) {
        return;
    }
    cout << prefix;
    if(isLast) {
        cout << "└───────";
    }
    else {
        cout << "├───────";
    }
    cout << root->nodeName << endl;
    for(int i = 0; i < root->children.size(); i++) {
        if(i == root->children.size() - 1) {
            printAST(root->children[i], prefix + "|        ", true);
        }
        else {
            printAST(root->children[i], prefix + "|        ", false);
        }
    }
}

void yyerror(char* s) {
    printAST(ast);
    printf("***parsing terminated*** [syntax error]::%s \n", s);
    exit(0);
}

int main() {
    initLog("summary.txt");
    
    yyparse();
    string prefix = "";
    prefix += "\t.text\n";
    prefix += "\t.section   .rodata\n";
    prefix += ".LC0:\n";
    prefix += "\t.string \"%d\\n\" \n";
    prefix += ".LC1:\n";
    prefix += "\t.string \"%d\" \n";
    prefix += "\t.text\n";
    prefix += "\t.globl  main\n";
    prefix += "\t.type	main, @function\n";

    //cout << prefix << ast->code << endl;
    
    logAll();
    saveLog();
    
    prefix += ast->code;
    std::ofstream out("assembly.s");
    out << prefix;
    out.close();
    
    return 0;
}
