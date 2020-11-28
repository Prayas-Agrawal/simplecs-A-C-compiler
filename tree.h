
#include <string>
#include <vector>
#include <cassert>
#include <iostream>

using namespace std;

#ifndef HEADER_TREE
#define HEADER_TREE

class treeNode {
public:
    vector<treeNode*> children;   // children
    string nodeName;              // name of the node
    string lexValue;              // lexical value, name of identifier etc.
    int level;                    // for printing
    int val = 0;
    int timesExprFolded = 0;
    
    static vector<treeNode*> treeNodeList;


    string code = "";
    int lineNum = -1; // -1 is unknown
    
    int isLitOrStaticDefined = -1;  // {-1: uinit, 0: false, 1: true} 
    int staticValue = -1;

    void addIns (const std::string& ins) {
        code += ("\t" + ins + "\n");

    }
    
    void append (treeNode *t) {
        code += t->code;
        std::string().swap(t->code); //Deletes this string and reclaims memory 

    }

    void append (const std::string& s) {
        code += s;
    }


    void makeIns (const std::string& com, const std::string& op1, const std::string& op2) {
        addIns(com + "\t" + op1 +  ", " + op2) ;
    }
    void makeIns (const std::string& com, const std::string& op1) {
        addIns( com + "\t" + op1 );
    }
    void makeIns (const std::string& ins) {
        addIns(ins);
    }
    void putLabel (const std::string& L) {
        code += (L + ":" + "\n");
    }


    treeNode(const std::string& nodeName, vector<treeNode*> children) {  // for non-terminals, assume valid pointers are passed
        this->nodeName = nodeName;
        this->children = children;
        treeNodeList.push_back(this);
        // cout << nodeName << endl;
    }
    
    treeNode(const std::string& nodeName) {     // for epsilon and terminals, no need to call compute
        this->nodeName = nodeName;
        this->lexValue = nodeName;
        children.assign(0, NULL);
        treeNodeList.push_back(this);

        // cout << nodeName << endl;
    }
    
    treeNode(const std::string& nodeName, int lineNum)
    {
    	this->nodeName = nodeName;
        children.assign(0, NULL);
    	this->lineNum = lineNum;
    	treeNodeList.push_back(this);
    }
    
    void debug() {
        cout << nodeName << endl;
        for(auto& child : children) {
            if(child) {
                cout << child->nodeName << ' ';
            }
        }
        cout << endl;
        cout.flush();
    }
};

#endif


