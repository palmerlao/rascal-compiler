#include <cassert>
#include "Scope.h"
#include "y.tab.hpp"

Scope::Scope(string name, vector<Decls>* var_decls, vector<Scope*>* c, Tree* code) {
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
    err_msg = "ID " + ids[i] + " in " + scope_name + " has already been declared. ";
    assert( err_msg.c_str() && syms.count(ids[i]) == 0); // check that the current id hasn't been inserted before.
    syms[ids[i]] = type;
  }
}

void Scope::search(string name) {
  ;
}

void Scope::scope_link(Scope* child) {
  children.push_back(child);
  child->parent = this;
}

void Scope::scope_link(vector<Scope*> chitlins) {
  for (int i=0; i<chitlins.size(); i++) {
    this->scope_link(chitlins[i]);
  }
}

ostream& Scope::display(ostream& out, int spaces) {
  
  return out;
}
