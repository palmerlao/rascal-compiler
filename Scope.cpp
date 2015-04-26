#include <cassert>
#include <cstdlib>
#include <iostream>
using std::cerr;
using std::endl;
#include <sstream>
using std::ostringstream;
#include "Scope.h"
#include "y.tab.hpp"

#define SEARCH_DBG 0

string display_type_sig(TypeSignature);

Scope::Scope(string name, vector<Decls>* var_decls,
             vector<Scope*>* c, Tree* code) {
    scope_name = name;
    code_tree = code;
    parent = NULL;
    this->scope_link(*c);

    vector<Decls> decs = *var_decls;
    for (int i=0; i<decs.size(); i++)
      this->insert( *(decs[i].first), *(decs[i].second) );
}

void Scope::insert(vector<string> ids, TypeSignature type) {
  string err_msg;
  for (int i=0; i<ids.size(); i++) {
    if (syms.count(ids[i]) != 0) {
      cerr << endl << "ERROR: ID " << ids[i]
           << " in " << scope_name << " has already been declared. "
           << endl;
      //      exit(1);
    }
    syms[ids[i]] = type;
  }
}

TypeSignature Scope::search(string name, string originator) {
  // originator is the scope that started the search
  if (syms.count(name) == 0) { // this name isn't in this scope.
    if (this->parent == NULL) { // this is the top-most scope. Error!
      cerr << "ERROR: ID " << name << " in "
           << originator << " was never declared. " << endl;
      exit(1);
    } else { // otherwise, check the next scope up.
      return this->parent->search(name, originator);
    }
  } else { // it's here.
    if (SEARCH_DBG)
      cerr << "Found ID " << name << ". Used in " << originator
           << ", found in " << scope_name << "." << endl;
    return syms[name];
  }
}

void Scope::scope_link(Scope* child) {
  children.push_back(child);
  child->parent = this;

  // push up function/proc vars
  vector<string> ids;
  ids.push_back(child->scope_name);
  TypeSignature ts = child->syms[ids[0]];
  this->insert(ids, ts);
  child->syms.erase(ids[0]);
}

void Scope::scope_link(vector<Scope*> chitlins) {
  for (int i=0; i<chitlins.size(); i++) {
    this->scope_link(chitlins[i]);
  }
}

ostream& Scope::display(ostream& out, int spaces) {
  string spacer = string(spaces, '\t');
  string dspc = spacer+" ";
  out << spacer << "SCOPE " << scope_name;
  if (parent != NULL)
    out << "(parent: " << parent->scope_name <<")";
  out << ":" << endl;
  for (SymbolTable::iterator it = syms.begin();
       it != syms.end();
       it++) {
    out << dspc << it->first << " :: ";
    out << display_type_sig(it->second);
    out << endl;
  }
  for (int i=0; i<children.size(); i++)
    children[i]->display(out, spaces+1);
  return out;
}

string Scope::display_type_sig(TypeSignature ts) {
  string result;
  ostringstream ss;
  for (int i=0; i<ts.size(); i++) {
    switch (ts[i]) {
    case INTEGER:
      ss << "INTEGER ";
      break;
    case REAL:
      ss << "REAL ";
      break;
    case FUNCTION:
      ss << "FUNCTION ";
      break;
    case PROCEDURE:
      ss << "PROCEDURE ";
      break;
    case ARRAY:
      ss << "ARRAY ";
      break;
    case ARGUMENT:
      ss << "ARGUMENT ";
      break;
    default:
      ss << ts[i] << " ";
      break;
    }
  }
  result = ss.str();
  return result;
}

void Scope::semantic_check() {
  check_vars_valid(code_tree);
  // array/fcn args checker here pls
  compute_expr_types(code_tree);
  
  for (int i=0; i<children.size(); i++)
    children[i]->semantic_check();
}

void Scope::check_vars_valid(Tree* t) {
  if (t != NULL) {
    // if you can't find this node's id you won't even
    // get to check the rest of the tree, you'll exit.
    if (t->type == ID)
      search( *((t->attr).sval), scope_name );
    check_vars_valid(t->lr[0]);
    check_vars_valid(t->lr[1]);
  }
}

int Scope::compute_expr_types(Tree* t) {
  if (t == NULL)
    return 0;

  int lt = compute_expr_types(t->lr[0]);
  int rt = compute_expr_types(t->lr[1]);
  TypeSignature ts;

  switch (t->type) {
  case ARRAY_ACCESS:
    // also assume index is integer typed. be sure to run array access checker before this one.
    ts = search(*(t->lr[0]->attr.sval), scope_name);
    return ts[3];
  case FUNCTION_CALL:
    // assume it's correct for now. be sure to run function call checker before this one to make sure.
    ts = search(*(t->lr[0]->attr.sval), scope_name);
    return ts[ts.size()-1];
  case INUM:
    return INTEGER;
  case RNUM:
    return REAL;
  case RELOP:
  case ADDOP:
  case MULOP:
    if (lt == rt && (lt==INTEGER || lt==REAL))
      return lt;
    else {
      cerr << "ERROR: Pairwise operation done on disparate types. Syntax tree:" << endl;
      t->display(cerr,1);
      //      exit(1); might segfault without.
    }
    break;
  case ID:
    ts = search(*(t->attr.sval), scope_name);
    return ts[0];
    break;
  }
}
