%{
#include <cstdio>
#include <iostream>
#include <string>
//#include <sstream>
#include <stack>
#include <cstdlib>
#include "nodeblock.cpp"
#include "asmgen.cpp"
using namespace std;
//TAC initial implementation.
int count =0;
stack<int> temp;
int swap_temp;
NodeBlock nodeblock; //create nodeblock << need to fixed !!

//Binary Tree initial implmentation
struct node{
   int data;
   struct node *right, *left;
};


typedef struct node node;
node *subtree;

//stack for tree
stack<NodeBlock*> stack_node;

void print_inorder(node *tree)
{
    if (tree)
    {
      //print_inorder(tree->left);
      printf("%d\n",tree->data);
      //print_inorder(tree->right);
    }
}

void deltree(node * tree)
{
    if (tree)
    {
      deltree(tree->left);
      deltree(tree->right);
      free(tree);
    }
}

string asmShow(){
	return "mov $show,%edi \nmov %eax,%esi \npush %rax\ncall printf\npop %rax\nret\n";
}

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;

void convert_to_asm(int opr1,int opr2);
void yyerror(const char *s);
%}

%token CONST
%token LEFT RIGHT
%token ENDLN
%token ASSIGN EQ IF ENDIF LOOP END SHOW SHOWX COLON
%token VAR

%left PLUS MINUS 
%left TIMES DIVIDE MOD
%left NEG

%start Input

%%

Input:
     | Input Line 
;

Line:
  ENDLN 
  | Ifstm
  | Loopstm
  | Stms 
  | Display
  | Condition
  | error { yyerror("oops\n"); } 
;


Oprn:
  VAR 
  {
  	Variable *node_var = new Variable($1);
 	cout << " var = " << $1 << endl;
 	stack_node.push(node_var);
	cout << "var assign @ = " << node_var->getValue() << endl;
  }

  | CONST
  {
  	Constant *node_const = new Constant(); //create constant object 
   node_const->setValue($1);  //add value to constant node
   //test aassign
   cout << "const assign : " << node_const->getValue() << endl;
   stack_node.push(node_const);
  }
;

Condition:
  Oprn EQ Oprn 
  { 
  	NodeBlock *node1 = stack_node.top();
  	stack_node.pop();
  	NodeBlock *node2 = stack_node.top();
  	stack_node.pop();

  	Equal *node_equal = new Equal(node2,node1); //condition object 
  	stack_node.push(node_equal);
  	node_equal->print();
  }
;


Ifstm:
  IF Condition ENDLN Stm ENDIF ENDLN  // change Stms to Stm for first version support only one statement
  {
  	NodeBlock *node_equal = stack_node.top();
  	stack_node.pop();
	NodeBlock *node_stm = stack_node.top();  //statements do after pass condition
	stack_node.pop();
  	IfStatement *node_if = new IfStatement(node_equal,node_stm);
	node_if->print();
  }
;

Stm:
  VAR ASSIGN Exp ENDLN{
  	NodeBlock *node_exp = stack_node.top();
  	
  	Variable *node_var = new Variable($1);
 	cout << " var = " << $1 << endl;
 	stack_node.push(node_exp);
	cout << "var assign @ = " << node_var->getValue() << endl;

//---
	cout<<"+++++++++++++++++"<<endl;
	cout<<xassign(node_exp->getAsm(),node_var->getValue());
	cout<<"-----------------"<<endl;
  }
;

Stms:
  Stm ENDLN{ cout << "statement " << endl; }
  | Stm ENDLN Stms { }
;

Exp: 
   
   CONST {
   //TAC Syntax
   /*cout << "T" << count << " = " << $1 <<endl; 
   temp.push(count); 
   $$ = count; count++;
	*/
   //TREE Syntax --Keep in stack
   Constant *node_const = new Constant(); //create constant object 
   node_const->setValue($1);  //add value to constant node
   //test aassign
   cout << "const assign : " << node_const->getValue() << endl;

   //insert(&constant_node, $1);
   stack_node.push(node_const);
	cout<<"+++++++++++++++++"<<endl;
	cout<<xconstant(node_const->getValue());
	cout<<"-----------------"<<endl;
   } 
  | VAR {
  	// add var to tree it's looklike constant but keep on address form fp(frame pointer)
 	Variable *node_var = new Variable($1);
 	cout << " var = " << $1 << endl;
 	stack_node.push(node_var);
	cout << "var assign @ = " << node_var->getValue() << endl;

  }
  | Exp PLUS Exp {
      //TAC Syntax
      /*swap_temp = temp.top();
      temp.pop(); 
      cout<<"T"<< count << " = " << "T" << temp.top();
      temp.pop();   
      cout << " + T" << swap_temp << endl; 
      temp.push(count);count++;
	  */

      //TREE Syntax
      NodeBlock *node_left;
      NodeBlock *node_right; 
      node_right = stack_node.top();
      stack_node.pop();
      node_left = stack_node.top();
      stack_node.pop();

      AddSyntax* addsyn = new AddSyntax(node_left,node_right);
      stack_node.push(addsyn);

      // FOR TESTING VALUE 
      
      NodeBlock* node_test = stack_node.top();
      cout << "test print from stack" << endl;  
      node_test->print();
 	cout<<xadd(node_right->getAsm(),node_left->getAsm(),""); // TODO : where dest?
	  

    }
  | Exp MINUS Exp {

      //TAC Syntax
      /*swap_temp = temp.top();
      temp.pop(); 
      cout<<"T"<< count << " = " << "T" << temp.top();
      temp.pop();   
      cout << " - T" << swap_temp << endl; 
      temp.push(count);count++;
		*/

      //TREE Syntax
      NodeBlock *node_left;
      NodeBlock *node_right; 
      node_right = stack_node.top();
	  stack_node.pop();
      node_left = stack_node.top();
      stack_node.pop();

      MinusSyntax* minsyn = new MinusSyntax(node_left,node_right);
      stack_node.push(minsyn);
      minsyn->print();
      // FOR TESTING VALUE 
      /*
      NodeBlock* node_test = stack_node.top();
      cout << "test print from stack" << endl;  
      node_test->print();
	  */
      
    }
  | Exp TIMES Exp {
      //TAC Syntax
     /* swap_temp = temp.top();
      temp.pop();
      cout << "T" << count << " = " << "T" << temp.top();
      temp.pop();
      cout << " * T" << swap_temp << endl;
      temp.push(count);count++;
	 */
      //TREE Syntax
      NodeBlock *node_left;
      NodeBlock *node_right;
      node_right = stack_node.top();
      stack_node.pop();
      node_left = stack_node.top();
      stack_node.pop();

      TimesSyntax* timessyn = new TimesSyntax(node_left,node_right);
      stack_node.push(timessyn);

      NodeBlock* node_test = stack_node.top();
      node_test->print();

    }         
  | Exp DIVIDE Exp {
      //TAC Syntax
      /*swap_temp = temp.top();
      temp.pop();
      cout << "T" << count << " = " << "T" << temp.top();
      temp.pop();
      cout << " / T" << swap_temp << endl;
      temp.push(count);count++;
	 */
      //TREE Syntax
      NodeBlock *node_left;
      NodeBlock *node_right;
      node_right = stack_node.top();
      stack_node.pop();
      node_left = stack_node.top();
      stack_node.pop();

      DivideSyntax* dividesyn = new DivideSyntax(node_left,node_right);
      stack_node.push(dividesyn);

      NodeBlock* node_test = stack_node.top();
      node_test->print();

    } 
  | Exp MOD Exp {
      //TAC Syntax
  	  /*
      swap_temp = temp.top();
      temp.pop(); 
      cout << "T" << count << " = " << "T" << temp.top();
      temp.pop();
      cout << " % T" << swap_temp << endl;
      temp.push(count);count++;
	  */

      //TREE Syntax
      NodeBlock *node_left;
      NodeBlock *node_right;
      node_right = stack_node.top();
      stack_node.pop();
      node_left = stack_node.top();
      stack_node.pop();

      ModSyntax* modsyn = new ModSyntax(node_left,node_right);
      stack_node.push(modsyn);

      NodeBlock* node_test = stack_node.top();
      node_test->print();

    }
  | LEFT Exp RIGHT { }
  | MINUS Exp %prec NEG {
      //TAC Syntax
      cout << "T" << temp.top() << " =  -" << "T" << temp.top() << endl;

      //TREE Syntax
      NodeBlock *node;
      node = stack_node.top();
      cout << "OLD: " << node->getValue() << endl;
      stack_node.pop();
      int temp_neg = 0-(node->getValue());
      node->setValue(temp_neg);
      cout << "NEW: " << node->getValue() << endl;
      stack_node.push(node);
    }
;

Loopstm:
  LOOP CONST COLON CONST ENDLN Stms END ENDLN { printf("LOOP\n");}
;

Display:
  SHOW VAR { printf("SHOW\n");}
  | SHOWX VAR { printf("SHOWX\n");}
;
%%

void printStack(){
	
}

void yyerror(const char *s) {
  cout << "EEK, parse error!  Message: " << s << endl;
  // might as well halt now:
  exit(-1);
}

void convert_to_asm(int opr1, int opr2)
{

}




int main() {
  while(yyparse());
/*
  // open a file handle to a particular file:
  FILE *myfile = fopen("a.snazzle.file", "r");
  // make sure it is valid:
  if (!myfile) {
    cout << "I can't open a.snazzle.file!" << endl;
    return -1;
  }
  // set flex to read from it instead of defaulting to STDIN:
  yyin = myfile;
  
  // parse through the input until there is no more:
  do {
    yyparse();
  } while (!feof(yyin));
*/
return 0;
}
