#include <cassert>
#include <cstdlib>
#include <iostream>
using std::cerr;
using std::endl;
#include <sstream>
using std::ostringstream;
#include "Scope.h"
#include "y.tab.hpp"

string display_type_sig(TypeSignature);

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
    if (syms.count(ids[i]) != 0) {
      cerr << endl << "ERROR: ID " << ids[i] << " in " << scope_name << " has already been declared. " << endl;
      exit(1);
    }
    syms[ids[i]] = type;
  }
}

void Scope::search(string name) {
  ;
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
  string dspc = " "+spacer;
  out << spacer << "SCOPE " << scope_name << ":" << endl;
  for (SymbolTable::iterator it = syms.begin();
       it != syms.end();
       it++) {
    out << dspc << it->first << ":: ";
    out << display_type_sig(it->second);
    out << endl;
  }
  for (int i=0; i<children.size(); i++)
    children[i]->display(out, spaces+1);
  return out;
}

string display_type_sig(TypeSignature ts) {
  string result;
  for (int i=0; i<ts.size(); i++) {
    switch (ts[i]) {
    case INTEGER:
      result += "INTEGER ";
      break;
    case REAL:
      result += "REAL ";
      break;
    case FUNCTION:
      result += "FUNCTION ";
      break;
    case PROCEDURE:
      result += "PROCEDURE ";
      break;
    case ARRAY:
      result += "ARRAY ";
      break;
    case ARGUMENT:
      result += "ARGUMENT ";
      break;
    default:
      ostringstream ss; ss << ts[i] << " ";
      result += ss.str();
      ss.str("");
      ss.clear();
      break;
    }
  }
  return result;
}
