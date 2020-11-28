#include<bits/stdc++.h>
#include <cassert>
#include "tree.h"
#include "symbolTable.h"
#include "logging.h"

#ifndef HEADER_HELPER
#define HEADER_HELPER

#define DBG(x) ((void)0)
#ifndef DBG
#define DBG(x) x
#endif

#define _UN		0
#define _EQEQ		1
#define _GT		2
#define _GEQ		3
#define _LT		4
#define _LEQ		5
#define _NEQ		6
#define _PLUS		7
#define _MINUS		8
#define _STAR		9
#define _DIV		10
#define _MOD		11
#define _OR		12
#define _TWC		13
#define _AND		14
#define _NOT		15
#define _SIZEOF	16



#define _INT		201
#define _ID		202
#define _EXPR		203

#define BUF 		1<<8
#define SHORTBUF 	1<<4
using namespace std;


void constantPropogation(int lineNum, string var, int val)
{
	logConstProp(lineNum, var, val);

}

void constantFolding(int op, treeNode* lhs, treeNode* lOp, treeNode* rOp)
{

	switch(op)
	{
	
		case _LT:
			lhs->val = lOp->val < rOp->val;
			break;
			
			
		case _GT:
			lhs->val = lOp->val > rOp->val;
			break;
	
		case _LEQ:
			lhs->val = lOp->val <= rOp->val;
			break;

	
		case _GEQ:
			lhs->val = lOp->val >= rOp->val;
			break;

	
		case _OR:
			lhs->val = lOp->val || rOp->val;
			break;

	
		case _SIZEOF:
			//TODO
			//lhs->val = lOp->val + rOp->val;
			break;

	
		case _EQEQ:
			lhs->val = (lOp->val == rOp->val);
			break;

	
		case _NEQ:
			lhs->val = (lOp->val != rOp->val);
			break;

	
		case _TWC:
			lhs->val = 1*(lOp->val > rOp->val) + (-1)*(lOp->val < rOp->val);
			break;

	
		case _AND:
			lhs->val = lOp->val && rOp->val;
			break;

	
		case _PLUS:
			lhs->val = lOp->val + rOp->val;
			break;

	
		case _MINUS:
			lhs->val = lOp->val - rOp->val;
			break;

	
		case _STAR:
			lhs->val = lOp->val * rOp->val;
			break;
			
		case _DIV:
			lhs->val = lOp->val / rOp->val;
			break;
			
		case _MOD:
			lhs->val = lOp->val % rOp->val;
			break;

	}
	
	char buf[BUF];
	sprintf(buf, "$%d", lhs->val);
	lhs->isLitOrStaticDefined = 1;
	lhs->timesExprFolded = lOp->timesExprFolded + rOp->timesExprFolded + 1;
	lhs->makeIns("movl", buf, "%eax");
	
	DBG(printf(
		"binary constant folding of %s(%d) and %s(%d) at line %d, with expr folded %d times\n", 
		(char*)&(lOp->nodeName)[0], 
		lOp->val, 
		(char*)&(rOp->nodeName)[0], 
		rOp->val, 
		lhs->lineNum,
		lhs->timesExprFolded
	  )
	);
	
	logConstantFolding(lhs);
}

void constantFolding(int op, treeNode* lhs, treeNode* oprnd)
{
	//TODO: log

	switch(op)
	{
	
		case _NOT:
			lhs->val = !(oprnd->val);
			break;
			
		case _MINUS:
			lhs->val = -(oprnd->val);
			break;
				
		case _PLUS:
			lhs->val = +(oprnd->val);
			break;
				
	}
	
	char buf[BUF];
	sprintf(buf, "$%d", lhs->val);
	lhs->isLitOrStaticDefined = 1;
	lhs->timesExprFolded = oprnd->timesExprFolded + 1;
	lhs->makeIns("movl", buf, "%eax");
	
	DBG(printf("unary constant folding of %s(%d) at line %d\n", (char*)&(oprnd->nodeName)[0], oprnd->val, lhs->lineNum ));
	
	logConstantFolding(lhs);
}

void strengthReduction(treeNode* lhs, treeNode* lOp, treeNode* rOp)
{

        
	if(lOp->isLitOrStaticDefined)
	{
		double exp = log2((double)lOp->val);
		if(ceil(exp) == floor(exp))
		{
			logStrengthReduction(lhs->lineNum, exp);
			char buf[BUF];
			sprintf(buf, "$%d", (int)exp);
			lhs->isLitOrStaticDefined = 0;
			lhs->append(rOp);
			lhs->makeIns("pushq", "%rax");
			lhs->makeIns("movl", buf, "%ebx");
			lhs->makeIns("shl", "%ebx", "%eax");
		}
		else
		{
                       lhs->append(rOp);
                	lhs->makeIns("pushq", "%rax");
                       lhs->append(lOp);
                       lhs->makeIns("popq", "%rbx");
                       lhs->makeIns("imul", "%ebx", "%eax");
		}
	}
	else if(rOp->isLitOrStaticDefined)
	{
		double exp = log2((double)rOp->val);
		if(ceil(exp)== floor(exp))
		{
			logStrengthReduction(lhs->lineNum, exp);
			char buf[BUF];
			sprintf(buf, "$%d", (int)exp);
			lhs->isLitOrStaticDefined = 0;
			lhs->append(lOp);
			lhs->makeIns("pushq", "%rax");
			lhs->makeIns("movl", buf, "%ebx");
			lhs->makeIns("shl", "%ebx", "%eax");
		}
		else
		{
			lhs->append(rOp);
                       lhs->makeIns("pushq", "%rax");
                       lhs->append(lOp);
                       lhs->makeIns("popq", "%rbx");
                       lhs->makeIns("imul", "%ebx", "%eax");
		}
	}

}

void purgeUnusedVars(SymbolTableClass& symbolTable)
{
	//DBG(printf("inside unused func, symboltable size is %ld\n", (symbolTable.ST).size()));
	//map<string, int> unusedVars;
	for(int i=0; i<(symbolTable.ST).size(); i++)
	{
		//DBG(printf("symbol table has %d elements\n", symbolTable.ST[1].size()));
		for(auto it = (symbolTable.ST[i]).begin(); it != (symbolTable.ST[i]).end(); ++it)
		{		

				if((it->first)[0] != NULL)
				{
					//DBG(printf("checking  unsed %s\n", (char*)&(it->first)[0]));
					if((it->second).isDefined <= 0)
					{
						//TODO: log
						//DBG(printf("logging unsed %s\n", (char*)&(it->first)[0]));
						logUnusedVar(it->first, (it->second).order);
						//symbolTable.ST[i].erase(it);
					}
				}
		}
	}
}

int bfs(SymbolTableClass& symbolTable, treeNode* root, treeNode* node)
{
	//int terminalsMatched = 0;
	if(root->children.size() != node->children.size())
	{
		DBG(printf("size of nodes uneual, returing\n"));
		return -1;
	}
	
	for(int j =0; j < root->children.size(); j++)
	{
		treeNode* rootTerm = (root->children)[j];
		treeNode* nodeTerm = (node->children)[j];
		
		string IDENTIFIER = "IDENTIFIER";
		string identifier = "identifier";
		string INTEGER_NUMBER = "INTEGER_NUMBER";
		string integerlit = "integerLit";
		
		if( ( (rootTerm->children).size() == 0)  && ( (nodeTerm->children).size() == 0) )
		{
			DBG(printf("terminal check started\n"));
			
			
			if((rootTerm->nodeName == IDENTIFIER) && (nodeTerm->nodeName == IDENTIFIER))
			{

				if(rootTerm->lexValue == nodeTerm->lexValue)
				{
					DBG(printf("%d | matched terminal %s %s\n",
					 node->lineNum, (char*)&(rootTerm->lexValue)[0], (char*)&(nodeTerm->lexValue)[0] ));
				}
				else return -1;
			}
			
			else if( (rootTerm->nodeName == IDENTIFIER) && (nodeTerm->nodeName == INTEGER_NUMBER) )
			{
				DBG(printf("inside the unequal check\n"));
				struct attr* rootSym = symbolTable.getSymbolAttr((root->children)[j]->lexValue);
				if( (rootSym->isStaticallyDefined == 1) && (to_string(rootSym->staticValue) == nodeTerm->lexValue) )
				{
					DBG(printf("%d | matched terminal %d %s\n",
						 node->lineNum, (rootSym->staticValue), (char*)&(nodeTerm->lexValue)[0] ));
				}
				else return -1;
			}
			
			else if( (nodeTerm->nodeName == IDENTIFIER) && (rootTerm->nodeName == INTEGER_NUMBER) )
			{
				DBG(printf("inside the unequal check\n"));
				struct attr* nodeSym = symbolTable.getSymbolAttr((node->children)[j]->lexValue);
				if( (nodeSym->isStaticallyDefined == 1) && (to_string(nodeSym->staticValue) == rootTerm->lexValue) )
				{
					DBG(printf("%d | matched terminal %s %d\n",
						 node->lineNum, (char*)&(rootTerm->lexValue)[0], (nodeSym->staticValue) ));
				}
				else return -1;
			}
			
			else if(rootTerm->lexValue == nodeTerm->lexValue)
			{
				DBG(printf("%d | matched terminal %s %s\n",
					 node->lineNum, (char*)&(rootTerm->lexValue)[0], (char*)&(nodeTerm->lexValue)[0] ));
			}
			
			else return -1;
		}
		
		
		else if( ( (rootTerm->children).size() != 0)  && ( (nodeTerm->children).size() != 0) )
		{
			DBG(printf("NON-terminal check started\n"));
			
			if( rootTerm->nodeName == nodeTerm->nodeName )
			{
				DBG(printf("%d | matched NON-terminal %s %s\n", node->lineNum, (char*)&(rootTerm->nodeName)[0], (char*)&(nodeTerm->nodeName)[0] ));
			}
			
			else if( (rootTerm->nodeName == identifier && nodeTerm->nodeName == integerlit) || 
					(rootTerm->nodeName == integerlit && nodeTerm->nodeName == identifier) )
			{
				DBG(printf("%d | continue chcking %s %s\n", node->lineNum, (char*)&(rootTerm->nodeName)[0], (char*)&(nodeTerm->nodeName)[0] ));	
			}
			
			else
			{
				DBG(printf("%d | MISMATCH NON-terminal %s %s\n", node->lineNum, (char*)&(rootTerm->nodeName)[0], (char*)&(nodeTerm->nodeName)[0] ));
				return -1;
			}
		}
		
		else
		{
			DBG(printf("one node childeren size is zero, returning\n"));
			return -1;
		}
	}
	
	for(int j = 0; j < root->children.size(); j++)
	{
		if(bfs(symbolTable, (root->children)[j], (node->children)[j]) <=0)
		{
			return -1;
		}
	}
	
	
	return 1;
}

treeNode* findSubTree(SymbolTableClass& symbolTable, vector<treeNode*> &treeNodeList, treeNode* node)
{
	for(int i=0; i<treeNodeList.size(); i++)
	{
		if( (treeNodeList[i] != node)  && (treeNodeList[i]->nodeName == node->nodeName))
		{
			treeNode* root = treeNodeList[i];
			DBG(printf("%d | checking tree with line %d with root num in node list %d  having nodename %s\n", 
				node->lineNum, root->lineNum, i, (char*)&(root->nodeName)[0] ));
			if(bfs(symbolTable, root, node) > 0)
			{
				DBG(printf("%d | MATCHED tree with line %d with root num in node list %d  having nodename %s\n", 
				node->lineNum, root->lineNum, i, (char*)&(root->nodeName)[0] ));
				logCommonSubExprElimination(root->lineNum, node->lineNum);
				return root;
			}
		}
	}
	return NULL;
}

int findSubTreeFromNode(SymbolTableClass& symbolTable, treeNode* root, treeNode* node)
{
	DBG(printf("FINDING MAXIMAL EXPR TREE at line %d \n", root->lineNum));
	if(bfs(symbolTable, root, node) > 0)
	{
		DBG(printf("MAXIMAL TREE FOUND\n"));
		return 1;	
	}
	if( (node->nodeName == "expr") && (node->children.size() == 1) && (node->children[0]->nodeName == "Pexpr") )
	{
		if(bfs(symbolTable, root, node->children[0])>0)
		{
			DBG(printf("MAXIMAL TREE FOUND\n"));
			return 1;
		}
	}
	for(int i=0; i < root->children.size(); i++)
	{
		if(findSubTreeFromNode(symbolTable, (root->children)[i], node)>0)
		{
			DBG(printf("MAXIMAL TREE FOUND\n"));
			return 1;
		}
	}
	DBG(printf("MAXIMAL TREE NOT FOUND\n"));
	return -1;

}



#endif


