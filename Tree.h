#ifndef TREE_H
#define TREE_H

#include <iostream>
using std::endl;
#include <fstream>
using std::ostream;
#include <string>
using std::string;

class Tree {
 public:
  Tree() { type = 0; lr[0] = lr[1] = NULL; }
  Tree(char*);
  Tree(int);
  Tree(float);
  Tree(Tree*, int, Tree*);
  Tree(Tree*, int, Tree*, int);
  ostream& display(ostream&, int);
  int type;

  Tree *lr[2];
  union attr {
    int ival;
    float rval;
    string *sval;
    int opval;
  } attr;

};

#endif
