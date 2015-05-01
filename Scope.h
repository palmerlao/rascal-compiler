#ifndef SCOPE_H
#define SCOPE_H

#include <map>
using std::map;
#include <utility>
using std::pair;
using std::make_pair;
#include <vector>
using std::vector;
#include <fstream>
using std::ostream;
using std::ofstream;

#include "Tree.h"
/*
  GOD OBJECT STATUS
 */

typedef vector<int> TypeSignature;
/*
  For inum, rnum: just one integer.
  for arrays: ARRAY <lower_bound> <upper> <standard_type>
  for functions/procedures: <FUNCTION|PROCEDURE> <type> .. <type> <inum|rnum> (last one: return type)
  something is an argument when the last entry is ARGUMENT.
 */
typedef map<string, TypeSignature> SymbolTable;
typedef pair<vector<string>*,TypeSignature*> Decls;

class Scope {
 public:
  /* initializer: a name, a vector of variables/types,
     a vector of children scopes, a tree for the code */
  Scope(string, vector<Decls>*, vector<Scope*>*, Tree*);
  // put new variables, all of the same type in.
  void insert(vector<string>, TypeSignature);
  // search for a variable.
  TypeSignature search(string, string);
  // attach a child scope to this one.
  void scope_link(Scope*);
  // attach many scopes to this one.
  void scope_link(vector<Scope*>);
  ostream& display(ostream&, int);

  void semantic_check();
  // ----------------------- CODE GENERATION -----------------------
  void gencode(ofstream&); // stream for output s file.
  void top_prologue(ofstream&);

 private:
  string scope_name;
  SymbolTable syms;
  Scope *parent;
  vector<Scope*> children;
  Tree *code_tree;
  map<string,int> addr_tab;
  vector<string> rstack;

  // ----------------------- SEMANTIC CHECKING -----------------------
  string display_type_sig(TypeSignature ts);

  // check that the tree refers to accessible vars
  void check_vars_valid(Tree*);
  // computes types and makes sure they're consistent.
  // assumes function/array ind are correct. 
  int compute_expr_types(Tree*);
  // check that while condition is bool.
  // check that for bound types are consistent.
  void check_loop_if_conds(Tree*);
  void check_index_args(Tree*);
  bool check_function_returns(Tree*);
  bool check_proc_returns(Tree*);
  void check_subprog_calls(Tree*);
  void check_proc_call(TypeSignature, Tree*);
  bool is_local(string); // check if id is local.
  void check_fcn_mutation(Tree*);

  // ----------------------- CODE GENERATION -----------------------
  void genasm(ofstream&, Tree*);
  int compute_ershov_num(Tree*);
  int compute_act_rec_sz();
  void gen_expr(ofstream&, Tree*);
  void swap_rs();
  string pop_rs();
  void push_rs(string);
  string top_rs();
  string op2asm(int);
};

#endif
