/*
 * =====================================================================================
 *
 *       Filename:  helper.h
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  25/09/20 06:32:01 PM IST
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Prayas Agrawal
 *
 * =====================================================================================
 */

#define DEBUG(x)
#ifndef DEBUG
#define DEBUG(x) x
#endif



#ifndef HELPER
#define HELPER
#define MINHEIGHT 1

#include <stdlib.h>
#include <stdarg.h>
#include "sym.h"



struct node 
{
	char* name;
	int height;
	int numChild;
	struct node* child[];
};

struct node*
makeNode(char* name, int numChild, ...)
{
	struct node* p = malloc(sizeof(*p) + numChild*(sizeof(struct node*)));
	p->numChild = numChild;
	p->name = name;
	va_list args;
	va_start(args, numChild);
	for(int i=0; i< numChild; i++){
		p->child[i] = va_arg(args, struct node*);
		DEBUG(printf("%s CHILD ADDED %d / %d\n",p->name, i+1, p->numChild););
	}  
	va_end(args);
	if(numChild == 0) DEBUG(printf("%s LEAF ADDED\n",p->name););
	return p;
}

struct node*
mkL(char* id)
{
	
	return makeNode(id, 0);
}

struct node* 
mkEmp()
{
	return makeNode("NULL", 0);
}

#define SIZE 1<<12
struct list 
{
	int numChild;
	struct node* trees[SIZE];
} *ifTrees, *whileTrees, *switchTrees;

void 
a2t(struct list* p, struct node* item)
{
	p->trees[p->numChild] = item;
	p->numChild += 1;
}

void
heightMap(struct node* p)
{
	p->height = MINHEIGHT;
	int numChild = p->numChild;
	
	if(!numChild) p->height = MINHEIGHT;
	
	for(int i=0; i<numChild; i++)
	{	
		heightMap(p->child[i]);
		
		if(p->height < (p->child[i]->height + 1))
			p->height = p->child[i]->height + 1;
	}
}

void 
restoreMap(struct node*p)
{
	p->height = MINHEIGHT;
	int numChild = p->numChild;
	
	for(int i=0; i<numChild; i++)
	{	
		restoreMap(p->child[i]);
	}

}

int
test(struct node* p)
{

	heightMap(p);
	int max = 0, mid = 0;
	
	for(int i=0; i< p->numChild; i++)
	{
		int temp = p->child[i]->height;
		
		if(temp + 1 > max)
		{
			mid = max ;
			max = temp + 1 ;
		}
		else if(temp + 1> mid)
		{
			mid = temp + 1;
		}
	
	}
	restoreMap(p);
	
	return mid+max-1;

}

void
longestPath(struct node* p, int * longest)
{
	int max = test(p);
	if(max > *longest) *longest = max;
	for(int i=0; i<p->numChild; i++)
	{
		longestPath(p->child[i], longest);
	}

}

int
longestPathList(struct list * p)
{
	int maxTree = 0;
	for (int i =0; i< p->numChild ; i++)
	{
		int treeH = 0;
		longestPath(p->trees[i], &treeH);
		
		//printf("----> candidate max path: %d\n", treeH);
		if(maxTree < treeH) maxTree = treeH;
	}
	
	return maxTree;

}

void 
initTrees()
{
	ifTrees = malloc(sizeof(struct list));
	whileTrees = malloc(sizeof(struct list));
	switchTrees = malloc(sizeof(struct list));
	ifTrees->numChild = 0;
	whileTrees->numChild = 0;
	switchTrees->numChild = 0;
}


#define RED "\033[1;31m"
#define GREEN "\033[1;32m"
#define RESET "\033[0m"

void
printTree(struct node* p )
{

	printf( GREEN "%s" RESET, p->name);
	printf("[");
	for(int i=0; i< p->numChild; i++)
	{
		printf("--%s--", p->child[i]->name);
	}
	printf("]");
	printf("\n");
	
	if(p->numChild)
	{
		for(int i=0; i< p->numChild; i++)
		{
			printTree(p->child[i]);
		}
		printf("\n");
	}
	
}


#endif




















