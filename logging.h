#include<stdio.h>
#include<stdlib.h>
#include <map>
#include <cassert>
#include <vector>


using namespace std;
extern SymbolTableClass symbolTable;
extern int findSubTreeFromNode(SymbolTableClass&, treeNode*, treeNode*);

#ifndef HEADER_LOGGING
#define HEADER_LOGGING

#define _UNUSEDVAR		"unused-vars"
#define _STRENGTHREDUCTION	"strength-reduction"
#define _CONSTANTFOLDING	"constant-folding"
#define _CSE			"cse"
#define _IFELSESIMPLIFICATION	"if-simpl"
#define _CONSTANTPROPOGATION	"constant-propagation"

FILE *file;

std::map<int, string> unusedVars;
std::map<int, int> strengthRed;
std::vector<treeNode*> constFoldingCandidates;
std::map<int, int> constFolding;
std::vector<int>  ifsimpl;
map<int , vector<pair<string, int>>> constPropMap;
map<int, vector<int>> cse;

void logAll()
{
	fprintf(file, "%s\n", _UNUSEDVAR);
	if(unusedVars.size())
	{
		for(auto iter = unusedVars.begin(); iter != unusedVars.end(); iter++)
		{
			fprintf(file, "%s\n", (char*)&(iter->second)[0]);
		}
	}
	fprintf(file, "\n");
	
	
	fprintf(file, "%s\n", _IFELSESIMPLIFICATION);
	if(ifsimpl.size())
	{
		fprintf(file, "%d\n", ifsimpl[0]);
	}
	fprintf(file, "\n");
	
	
	fprintf(file, "%s\n", _STRENGTHREDUCTION);
	if(strengthRed.size())
	{
		for(auto iter = strengthRed.begin(); iter != strengthRed.end(); iter++)
		{
			fprintf(file, "%d %d\n", iter->first, iter->second);
		}
	}
	fprintf(file, "\n");
	
	fprintf(file, "%s\n", _CONSTANTFOLDING);
	if(constFoldingCandidates.size())
	{
		for(int i = 0; i < constFoldingCandidates.size(); i++)
		{
			//printf("constPropCanditate[%d] is %d\n", i, constFoldingCandidates[i]->val);
			if(constFolding[constFoldingCandidates[i]->lineNum] < constFoldingCandidates[i]->val)
			{
				constFolding[constFoldingCandidates[i]->lineNum] = constFoldingCandidates[i]->val;
			}
		}
		
		for(auto iter = constFolding.begin(); iter != constFolding.end(); iter++)
		{
			fprintf(file, "%d %d\n", iter->first, iter->second);
		}
		
	}
	fprintf(file, "\n");
	
	fprintf(file, "%s\n", _CONSTANTPROPOGATION);
	if(constPropMap.size())
	{
		for(auto iter = constPropMap.begin(); iter != constPropMap.end(); iter++)
		{
			fprintf(file, "%d", iter->first);
			for(auto item = (iter->second).begin(); item != (iter->second).end(); item++)
			{
				fprintf(file, " %s %d", (char*)&(item->first)[0], item->second);
			}
			fprintf(file, "\n");


		}
	}
	fprintf(file, "\n");
	
	fprintf(file, "%s\n", _CSE);
	if(cse.size())
	{
		//sort(cse.begin(), cse.end());
		for(auto iter = cse.begin(); iter != cse.end(); iter++)
		{
			fprintf(file, "%d", iter->first);
			for(int j=0; j < iter->second.size(); j++)
			{
				fprintf(file, " %d", (iter->second)[j]);
			}
			fprintf(file, "\n");
		}
	}

}

void saveLog()
{
	fclose(file);
}

void initLog(const char* filename)
{
	file = fopen(filename, "w");
}

void logUnusedVar(const std::string& var, int order) // printf in order of decl
{
	unusedVars[order] = var;
	//printf("logged\n");
}

void logStrengthReduction(int lineNum, int exp) // make a max map
{
	if(strengthRed.find(lineNum) == strengthRed.end())
	{
		strengthRed[lineNum] = exp;
	}
	else
	{
		if(strengthRed[lineNum] < exp)
		{
			strengthRed[lineNum] = exp;
		}
	}

}

void logConstantFolding(treeNode* exprRoot) //make max map
{

	vector<int> toRemove;
	
	for (int i=0; i<constFoldingCandidates.size(); i++)
	{
		if (findSubTreeFromNode(symbolTable, exprRoot, constFoldingCandidates[i]) > 0)
		{
			
			//toRemove.push_back(i);
			constFoldingCandidates.erase(constFoldingCandidates.begin() + i);
			i--;
		}
	}
	
	//for(int i=0; i<toRemove.size(); i++)
	//{
		//printf("---------->erased %d\n", constFoldingCandidates[toRemove[i]]->val);
	//	constFoldingCandidates.erase(constFoldingCandidates.begin() + toRemove[i]);
	//}
	//printf("----------->added %d\n", exprRoot->val);
	constFoldingCandidates.push_back(exprRoot);
}

void logIfSimpl(int flag, int lineNum)
{
	ifsimpl.push_back(flag);
}

void logConstProp(int lineNum, string var, int val)
{
	pair<string, int> temp;
	temp = make_pair(var, val);
	constPropMap[lineNum].push_back(temp);


}

void logCommonSubExprElimination(int rootNum, int nodeNum)
{
	//cse[rootNum].push_back
	cse[rootNum].push_back(nodeNum);
}






#endif



