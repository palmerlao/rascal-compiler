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

string Tree::opint2str(int opint) {
  switch (opint) {
  case STAR:
    return "*";
  case SLASH:
    return "/";
  case EQ:
    return "=";
  case NE:
    return "<>";
  case LT:
    return "<";
  case LE:
    return "<=";
  case GT:
    return ">";
  case GE:
    return ">=";
  case OR:
    return "or";
  case PLUS:
    return "+";
  case MINUS:
    return "-";
  case AND:
    return "and";
  }
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
    out << "RELOP:" << opint2str(this->attr.opval);
    break;
  case MULOP:
    out << "MULOP:" << opint2str(this->attr.opval);
    break;
  case ADDOP:
    out << "ADDOP:" << opint2str(this->attr.opval);
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

void Tree::chained_relop_fixer() {
  if (this == NULL) return;
  if (this->type == 0) return;
  if (this->type == RELOP && this->lr[0]->type == RELOP) {
    // found RELOP chain.
    Tree *r = new Tree(this->lr[0]->lr[1],
                       this->attr.opval,
                       this->lr[1],
                       this->type);
    this->lr[0]->chained_relop_fixer();
    this->type = MULOP;
    this->attr.opval = AND;
    this->lr[1] = r;
  }
  this->lr[0]->chained_relop_fixer();
  this->lr[1]->chained_relop_fixer();
}
