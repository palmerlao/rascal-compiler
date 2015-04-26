#include "Tree.h"
#include "y.tab.hpp"

Tree::Tree(char* cstr) {
  lr[0] = lr[1] = NULL;
  attr.sval = new string(cstr);
  type = ID;
}

Tree::Tree(int a) {
  lr[0] = lr[1] = NULL;
  attr.ival = a;
  type = INUM;
}

Tree::Tree(float rv) {
  lr[0] = lr[1] = NULL;
  attr.rval = rv;
  type = RNUM;
}

Tree::Tree(Tree* l, int op, Tree* r, int op_t) {
  lr[0] = l; lr[1] = r;
  attr.opval = op;
  type = op_t;
}

Tree::Tree(Tree* l, int op, Tree* r) {
  lr[0] = l; lr[1] = r;
  attr.opval = op;
  type = op;
}


ostream& Tree::display(ostream& out, int level) {
  string spacer = string(level, '\t');
  out << spacer;
  switch (this->type) {
  case 0:
    out << "LEAF";
    break;
  case ID:
    out << *(this->attr.sval);
    break;
  case INUM:
    out << this->attr.ival;
    break;
  case RNUM:
    out << this->attr.rval;
    break;
  case FUNCTION_CALL:
    out << "FUNCTION_CALL";
    break;
  case ARRAY_ACCESS:
    out << "ARRAY_ACCESS";
    break;
  case ASSIGNOP:
    out << ":=";
    break;
  case RELOP:
    out << "RELOP:" << this->attr.opval;
    break;
  case MULOP:
    out << "MULOP:" << this->attr.opval;
    break;
  case ADDOP:
    out << "ADDOP:" << this->attr.opval;
    break;
  case NOT:
    out << "NOT";
    break;
  case COMMA:
    out << ",";
    break;
  case WHILE:
    out << "WHILE";
    break;
  case FOR:
    out << "FOR";
    break;
  case TO:
    out << "TO";
    break;
  case IF:
    out << "IF";
    break;
  case ELSE:
    out << "ELSE";
    break;
  case SEMICOLON:
    out << ";";
    break;
  default:
    out << "reached default case.";
  }
  out << endl;
  if (this->lr[0] != NULL) {
    this->lr[0]->display(out, level+1);
  }
  if (this->lr[1] != NULL) {
    this->lr[1]->display(out, level+1);
  }
  return out;
}
