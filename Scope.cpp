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
    case ANY:
      ss << "ANY ";
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
  check_index_args(code_tree);

  compute_expr_types(code_tree);
  check_loop_if_conds(code_tree);

  if (this->parent != NULL) {
    TypeSignature ts = this->parent->search(scope_name, scope_name);
    if (ts[0] == FUNCTION) {
      if (!(check_function_returns(code_tree)))
        cerr << "ERROR in " << scope_name << ": Function did not return a value." << endl;
    }
    else { // we have to check a procedure.
      if (!(check_proc_returns(code_tree)))
        cerr << "ERROR in " << scope_name << ": Procedure contains a return statement." << endl;
    }
  }
  
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
    // assume it's correct for now. be sure to run function call checker before this one
    ts = search(*(t->lr[0]->attr.sval), scope_name);
    // I believe this handles the case 'a := b(x)' when b is a proc.
    return (ts[0] == FUNCTION) ? ts[ts.size()-1] : PROCEDURE;
  case INUM:
    return INTEGER;
  case RNUM:
    return REAL;
  case RELOP:
  case ADDOP:
  case MULOP:
    if (lt == rt && (lt==INTEGER || lt==REAL))
      return (t->type == RELOP) ? BOOL : lt;
    else {
      cerr << "ERROR in " << scope_name << ": Pairwise operation done on disparate types. Syntax tree:" << endl;
      t->display(cerr,1);
      //      exit(1); might segfault without?
    }
    break;
  case ID:
    ts = search(*(t->attr.sval), scope_name);
    if (*(t->attr.sval) == scope_name) // if the id is the same as the function name
      return ts[ts.size()-1]; // return what the function should return.
    // undef. behav. if the function name appears on right side of :=. pls don't
    else
      return ts[0];
    break;
  case NOT:
    if (lt == BOOL)
      return BOOL;
    else {
      cerr << "ERROR in " << scope_name << ": Not operator applied to non-boolean type. Syntax tree:" << endl;
      t->display(cerr,1);
    }
    break;
  case ASSIGNOP:
    if ( compute_expr_types(t->lr[0]) != compute_expr_types(t->lr[1]) ) {
      cerr << "ERROR in " << scope_name << ": Tried to use assignment on disparate types. Syntax tree:" << endl;
      t->display(cerr,1);
    }
    return 0;
  }
}

void Scope::check_loop_if_conds(Tree* t) {
  if (t == NULL) return;
  switch (t->type) {

  case FOR:
    int looper_t, lower_t, upper_t;
    looper_t = compute_expr_types(t->lr[0]->lr[0]);
    lower_t = compute_expr_types(t->lr[0]->lr[1]->lr[0]);
    upper_t = compute_expr_types(t->lr[0]->lr[1]->lr[1]);
    if (! ((lower_t == upper_t) && (looper_t == lower_t)) ) {
      cerr << "ERROR in " << scope_name << ": For loop variable and bound types don't match. Syntax tree:" << endl;
      t->display(cerr,1);
    }
    break;

  case IF:
  case WHILE:
    if (compute_expr_types(t->lr[0]) != BOOL) {
      cerr << "ERROR in " << scope_name << ": If or while condition is not a boolean. Syntax tree:" << endl;
      t->lr[0]->display(cerr,1);
    }
    break;
  }
  check_loop_if_conds(t->lr[0]);
  check_loop_if_conds(t->lr[1]);
}

void Scope::check_index_args(Tree* t) {
  if (t == NULL) return;
  switch (t->type) {
  case ARRAY_ACCESS:
    if (compute_expr_types(t->lr[1]) != INTEGER) {
      cerr << "ERROR in " << scope_name << ": Array indices must be integer type. Syntax tree:" << endl;
      t->display(cerr,1);
    }
  }
  check_index_args(t->lr[0]);
  check_index_args(t->lr[1]);
}

bool Scope::check_function_returns(Tree* t) {
  if (t == NULL) // we made it to a leaf without seeing a ret. stmt.
    return false;
  if (t->type == ASSIGNOP &&
      t->lr[0]->type == ID &&
      scope_name == *(t->lr[0]->attr.sval) ) {
    TypeSignature ts = search(scope_name, scope_name);
    if (compute_expr_types(t->lr[1]) == ts[ts.size()-1]) // we found the return statement and the types matched.
      return true;
    else { // the types didn't match!
      cerr << "ERROR in " << scope_name << ": Return value type and function type signature did not match. Syntax tree:" << endl;
      t->display(cerr,1);
      return false;
    }
  } else
    return (check_function_returns(t->lr[0]) || check_function_returns(t->lr[1]));
}

bool Scope::check_proc_returns(Tree* t) {
  if (t == NULL)
    return true;
  if (t->type == ASSIGNOP &&
      t->lr[0]->type == ID &&
      scope_name == *(t->lr[0]->attr.sval)) // we found a return stmt.
    return false;
  else
    return (check_proc_returns(t->lr[0]) && check_proc_returns(t->lr[1]));
}
