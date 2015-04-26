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

#include "Tree.h"


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

 private:
  string scope_name;
  SymbolTable syms;
  Scope *parent;
  vector<Scope*> children;
  Tree *code_tree;

  string display_type_sig(TypeSignature ts);

  // check that the tree refers to accessible vars
  void check_vars_valid(Tree*);
  // computes types but exits if something is inconsistent.
  int compute_expr_types(Tree*);
  
};

#endif
