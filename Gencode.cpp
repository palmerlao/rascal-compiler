#include <cstdlib>
#include <iostream>
using std::cerr;
using std::endl;

#include "Tree.h"
#include "Scope.h"
#include "y.tab.hpp"

const int nregs = 3;

void Scope::gencode(ofstream& out) {
    int stk_sz = compute_act_rec_sz();
    out << scope_name <<":" << endl;
    out << "\t" << "pushl\t" << "%ebp" << endl;
    out << "\t" << "movl\t" << "%esp, %ebp" <<endl;
    out << "\t" << "subl\t" << "$" << (stk_sz+1)*4 << ", %esp" << endl;
    genasm(out, code_tree);
    out << "\tleave" << endl;
    out << "\tret" << endl;
}

int Scope::compute_ershov_num(Tree* t) {
    if ((t == NULL) || (t->type == 0))
        return 0;
    int ln = compute_ershov_num(t->lr[0]);
    int rn = compute_ershov_num(t->lr[1]);
    if (ln==rn)
        return (ln+1);
    else
        return (((ln > rn) ? ln : rn)+1);
}

int Scope::compute_act_rec_sz() {
    int ntemps = compute_ershov_num(code_tree)-nregs;
    ntemps = (ntemps > 0) ? ntemps : 0;
    // we can compute this in one go because the
    // symbol table of a scope contains the arguments
    //as well as the variables. 
    int nargsvars = 0;
    int tmp_t;
    int addr_mult = 1;
    for (SymbolTable::iterator it = syms.begin();
         it != syms.end();
         it++) {
        tmp_t = (it->second)[0];
        if (tmp_t == INTEGER || tmp_t == REAL) {
            addr_tab[it->first] = addr_mult++;
            nargsvars++; // no array support currently.
        }
    }
    return nargsvars+ntemps;
}

void Scope::top_prologue(ofstream& out) {
    // this should only be called from the top-most scope.
    if (scope_name == "main") {
        cerr << "Please name your top-level program something other than 'main'." << endl;
        exit(1);
    }
    out << "\t" << ".globl main" << endl
        << "main:" << endl
        << "\t" << "pushl\t%ebp" << endl
        << "\t" << "movl\t%esp, %ebp" << endl
        << "\t" << "andl\t$-16, %esp" << endl
        << "\t" << "call\t" << scope_name << endl
        << "\t" << "movl\t$0, %eax" << endl
        << "\tleave" << endl << "\tret" << endl;

    out << ".LC0:" << endl
        << "\t.string\t" << "\"%d\\n\"" << endl;

    out << ".LC1:" << endl
        << "\t.string\t" << "\"%d\"" << endl;

    return;
}

void Scope::genasm(ofstream& out, Tree* t) {
    if (t == NULL)
        return;
    switch(t->type) {
    case FUNCTION_CALL: // handle read/write special case first.
        if (*(t->lr[0]->attr.sval) == "read") {
            // assume the arg is an id for now.
            out << "\t" << "leal\t"
                << -4*addr_tab[*(t->lr[1]->attr.sval)]
                << "(%ebp), %eax" << endl;
            out << "\t" << "movl\t%eax, 4(%esp)" << endl;
            out << "\t" << "movl\t$.LC1, (%esp)" << endl;
            out << "\t" << "call\tscanf" << endl;
        } else if (*(t->lr[0]->attr.sval) == "write") {
            // assume arg an id.
            out << "\t" << "movl\t"
                << -4*addr_tab[*(t->lr[1]->attr.sval)]
                << "(%ebp), %eax" << endl;
            out << "\t" << "movl\t"
                << "%eax, 4(%esp)" << endl;
            out << "\t" << "movl\t" << "$.LC0, (%esp)" << endl;
            out << "\t" << "call\tprintf" << endl;
        }
        break;
    case 0:
        return;
    }
    genasm(out, t->lr[0]);
    genasm(out, t->lr[1]);
}

void Scope::swap_rs() {
  if ((rstack.size() == 0) || (rstack.size() == 1))
    return;
  string t = *(rstack.end());
  *(rstack.end()) = *(rstack.end()-1);
  *(rstack.end()-1) = t;
}

string Scope::pop_rs() {
  string res = *(rstack.end());
  rstack.pop_back();
  return res;
}

void Scope::push_rs(string id) { rstack.push_back(id); }
string Scope::top_rs() { return *(rstack.end()); }

string Scope::op2asm(int op) {
  switch(op) {
  case PLUS:
    return "addl";
  case MINUS:
    return "subl";
  case STAR:
    return "imull";
  }
}

void Scope::gen_expr(ofstream& out, Tree* t) {
  if (t == NULL)
    return;

  // case 0
  switch(t->type) {
  case ID:
    out << "\t" << "leal\t"
        << -4*addr_tab[*(t->lr[0]->attr.sval)]
        << "(%ebp), %eax" << endl;
    out << "\t" << "movl\t" << "%eax, "
        << top_rs() << endl;
    break;
  case INUM:
    out << "\t" << "movl\t"
        << "$" << (t->attr.ival) << ", "
        << top_rs() << endl;
    break;
  }

  int n1 = compute_ershov_num(t->lr[0]);
  int n2 = compute_ershov_num(t->lr[1]);

  // case 1
  /*  if (n2 == 0) {
    out << "\t" << op2asm(t->attr.opval) << "\t";
    gen_expr(out, t->lr[1]);
    out << pop_rs() << ", ";
    gen_expr(out, t->lr[0]);
    out << pop_rs() << endl;
    } */
}
