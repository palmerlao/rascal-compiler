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
  Scope(string, vector<Decls>*, vector<Scope*>*, Tree*); // default initializer
  void insert(vector<string>, TypeSignature); // put new variables of the same type in.
  void search(string); // search for a variable.
  void scope_link(Scope*); // attach a child scope to this one.
  void scope_link(vector<Scope*>); // attach many scopes to this one.
  ostream& display(ostream&, int);
 private:
  string scope_name;
  SymbolTable syms;
  Scope *parent;
  vector<Scope*> children;
  Tree *code_tree;
};

#endif
