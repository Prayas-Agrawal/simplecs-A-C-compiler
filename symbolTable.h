#include <cassert>

using namespace std;
#ifndef HEADER_SYMBOLTABLE
#define HEADER_SYMBOLTABLE
    struct attr
    {
    	int offset;
    	int order;
    	int lineNum;
    	int isDeclared;
    	int isDefined; // {-1: uinit, 0:false, 1:true}
    	int staticValue;
    	int isStaticallyDefined;
    };
    
class SymbolTableClass {
    public:
    vector <map<string, attr>> ST;
    int offset = 0;
    
    int order = 0;

    SymbolTableClass () {
        incrementScope();
    }

    void incrementScope () {
        ST.push_back({});
    }

    int put (string var, int lineNum) {
        int l = ST.size() - 1;
        if (ST[l].find(var) != ST[l].end()) 
        {
            cout << "Symbol Table Error: Multiple declarations of <" << var << "> in the same scope" << endl;

        }
        //offset++;
        order++;
        ST[l][var] = {-1, order, lineNum, 1, -1, -1, -1};
            
        return 1;
    }
    
    int setDefinedFlagAndAllocStack(const string& var)
    {
        for (int i = ST.size() - 1; i >=0; i--) 
        {
            if (ST[i].find(var) != ST[i].end()) 
            {
            	offset++;
            	ST[i][var].offset = offset;
                ST[i][var].isDefined = 1;
                return 4*offset;
            }
        }
        cout << "////Symbol Table Error: use of undeclared variable in set<" << var << ">" << endl;
        return -1;
    
    }

    void putArray (string var, int siz, int lineNum) {
        for (int i = 0; i <siz; i++) {
            put(var + "eesdj[" +  to_string(i) +  "]", lineNum);
        }
        put (var, lineNum);
    }

    int get (string var) {
        for (int i = ST.size() - 1; i >=0; i--) {
            if (ST[i].find(var) != ST[i].end()) {
                return 4*ST[i][var].offset;
            }
        }
        cout << "////Symbol Table Error: use of undeclared variable in get <" << var << ">" << endl;
        return -1;
    }
    
    struct attr* getSymbolAttr (string var) {
        for (int i = ST.size() - 1; i >=0; i--) {
            if (ST[i].find(var) != ST[i].end()) {
         	return &ST[i][var];
            }
        }
        cout << "////Symbol Table Error: use of undeclared variable in getSynbolAttr<" << var << ">" << endl;
        return NULL;
    }

    void decrementScope () {
        int l = ST.size() - 1;
        offset -= ST[l].size();
        ST.pop_back();  
    }

};

#endif
