%{
#include <iostream>
using std::cerr;
using std::endl;
#include <string>
using std::string;
#include <vector>
using std::vector;

#include <stdio.h>

#include "Tree.h"
#include "Scope.h"

#define YYDEBUG 1
#define SCOPE_DBG 1
#define TREE_DBG 0

int yylex();
int yyparse();
void yyerror(char*);

extern int lineno;
extern Scope* prog_scope;
extern Scope* current;
%}

%union {
    /* scanner attributes */
    int ival;
    float rval;
    char *sval;
    int opval;

    /* for passing around the trees */
    Tree *tval;
    /* dirty thing to get around some strange typing error */
    void *vp;
}

%token  <ival>          INUM
%token  <rval>          RNUM
%token  <sval>          ID

%token  <opval>         ASSIGNOP
%token  <opval>         RELOP
%token  <opval>         ADDOP
%token  <opval>         MULOP
%token  <opval>         NOT

%token  <opval>         LT LE GT GE EQ NE
%token  <opval>         OR PLUS MINUS
%token  <opval>         AND STAR SLASH

%token                  PROGRAM
%token                  VAR
%token                  ARRAY OF DOTDOT
%token                  INTEGER REAL
%token                  FUNCTION PROCEDURE
%token                  BBEGIN END
%token                  IF THEN ELSE
%token                  WHILE DO FOR TO

%token                  FUNCTION_CALL
%token                  ARRAY_ACCESS
%token                  COMMA
%token                  SEMICOLON
%token                  ARGUMENT

%type   <sval>          subprogram_head

%type   <tval>          compound_statement
%type   <tval>          optional_statements
%type   <tval>          procedure_statement
%type   <tval>          statement_list
%type   <tval>          statement

%type   <tval>          variable
%type   <tval>          expression_list
%type   <tval>          expression
%type   <tval>          simple_expression
%type   <tval>          term
%type   <tval>          factor

%type   <vp>            identifier_list // a vector of ids (represented as strings)
%type   <vp>            type // a vector of types (represented as integers)
%type   <vp>            subprogram_declarations // a vector of scopes (which will have the same parent)
%type   <vp>            declarations // a pointer to a vector<Decls>
%type   <vp>            arguments // a pointer to a vector<Decls>
%type   <vp>            parameter_list
%type   <vp>            subprogram_declaration
%type   <ival>          standard_type
                        
%%

program:
	PROGRAM ID '(' identifier_list ')' ';' 
	declarations
	subprogram_declarations
	compound_statement
	'.'
                {
                    if (TREE_DBG) {
                        cerr << "line "<< lineno <<": PROGRAM " << $2 << ": " << endl;
                        $9->display(cerr, 0);
                        cerr << endl;
                    }
                
                   prog_scope = new Scope(string($2),
                                           (vector<Decls>*) $7,
                                           (vector<Scope*>*) $8,
                                           $9);
                    current = prog_scope;
                }
	;

identifier_list
	: ID
                {
                    vector<string> *tmp = new vector<string>;
                    tmp->push_back(string($1));
                    $$ = tmp;
                }
	| identifier_list ',' ID
                {
                    vector<string> *tmp = (vector<string>*) $1;
                    tmp->push_back(string($3));
                    $$ = tmp;
                }
	;

declarations
	: declarations VAR identifier_list ':' type ';'
                {
                    vector<Decls> *tmp = (vector<Decls>*) $1;
                    vector<string> *ids = (vector<string>*) $3;
                    TypeSignature *types = (TypeSignature*) $5;
                    tmp->push_back( make_pair(ids, types) );
                    $$ = tmp;
                }
	| /* empty */
                {
                    $$ = new vector<Decls>;
                }
	;

type
	: standard_type
                {
                    TypeSignature *tmp = new TypeSignature;
                    tmp->push_back($1);
                    $$ = tmp;
                }
	| ARRAY '[' INUM DOTDOT INUM ']' OF standard_type
                {
                    TypeSignature *tmp = new TypeSignature;
                    tmp->push_back(ARRAY);
                    tmp->push_back($3);
                    tmp->push_back($5);
                    tmp->push_back($8);
                    $$ = tmp;
                }
	;

standard_type
	: INTEGER
                { $$ = INTEGER; }
	| REAL
                { $$ = REAL; }
	;

subprogram_declarations
	: subprogram_declarations subprogram_declaration ';'
                {
                    vector<Scope*> *tmp = (vector<Scope*>*) $1;
                    tmp->push_back((Scope*) $2);
                    $$ = tmp;
                }
	| /* empty */
                {
                    $$ = new vector<Scope*>;
                }
	;

subprogram_declaration
	: subprogram_head declarations subprogram_declarations compound_statement
                {
                    if (TREE_DBG) {
                        cerr << "line " << lineno << ": " << $1 << ":" << endl;
                        $4->display(cerr, 0);
                        cerr << endl;
                    }
                    string id = string($1);
                    $$ = new Scope(id, (vector<Decls>*) $2, (vector<Scope*>*) $3, $4);
                }
	;

subprogram_head
	: FUNCTION ID arguments ':' standard_type ';'
                {
                    $$ = $2;
                }
	| PROCEDURE ID arguments ';'
                { $$ = $2; }
	;

arguments
	: '(' parameter_list ')'
                {
                    $$ = $2;
                }
	;

parameter_list
	: identifier_list ':' standard_type
                {
                    vector<Decls>* ret = new vector<Decls>;
                    vector<string> *t1 = (vector<string>*) $1;
                    TypeSignature *t2 = (TypeSignature*) $3;
                    ret->push_back( make_pair(t1, t2) );
                    $$ = ret;
                }
	| parameter_list ';' identifier_list ':' standard_type
                {
                    vector<Decls>* ret = (vector<Decls>*) $1;
                    vector<string> *t1 = (vector<string>*) $3;
                    TypeSignature *t2 = (TypeSignature*) $5;
                    ret->push_back( make_pair(t1, t2) );
                    $$ = ret;
                }
	;


/* statement */

compound_statement
	: BBEGIN optional_statements END
                { $$ = $2; }
	;

optional_statements
	: statement_list
                { $$ = $1; }
	| /* empty */
                { $$ = NULL; }
	;

statement_list
	: statement
                { $$ = $1; }
	| statement_list ';' statement
                {
                    $$ = new Tree( $1, SEMICOLON, $3);
                }
	;

statement
	: variable ASSIGNOP expression
                {
                    $$ = new Tree($1, ASSIGNOP, $3);
                }
	| procedure_statement
                { $$ = $1; }
	| compound_statement
                { $$ = $1; }
	| IF expression THEN statement ELSE statement
                {
                    $$ = new Tree( $2, IF, new Tree($4, ELSE, $6));
                }
/*              	| IF expression THEN statement
                {
                    $$ = new Tree( $2, IF, $4);
                } */
                
	| WHILE expression DO statement
                {
                    $$ = new Tree($2, WHILE, $4);
                }
        | FOR variable ASSIGNOP expression TO expression DO statement
                {
                    $$ = new Tree(new Tree($2,
                                           ASSIGNOP,
                                           new Tree($4, TO, $6)),
                                  FOR,
                                  $8);
                }
	;

variable
	: ID
                { $$ = new Tree($1); }
	| ID '[' expression ']'
                {
                    $$ = new Tree(new Tree($1), ARRAY_ACCESS, $3);
                }
	;

procedure_statement
	: ID
                { $$ = new Tree($1); }
	| ID '(' expression_list ')'
                {
                    $$ = new Tree(new Tree($1), FUNCTION_CALL, $3);
                }
	;


/* expression */

expression_list
	: expression
                { $$ = $1; }
	| expression_list ',' expression
                {
                    $$ = new Tree($1, COMMA, $3);
                }
	;

expression
	: simple_expression
                { $$ = $1; }
	| simple_expression RELOP simple_expression
                {
                    $$ = new Tree( $1, $2, $3, RELOP);
                }
	;

simple_expression
	: term
                { $$ = $1; }
	| simple_expression ADDOP term
                {
                    $$ = new Tree($1, $2, $3, ADDOP);
                }
	;

term
	: factor
                { $$ = $1; }
	| term MULOP factor
                {
                    $$ = new Tree($1, $2, $3, MULOP);
                }
	;

factor
	: ID
                { $$ = new Tree($1); }
	| ID '[' expression ']'
                {
                    $$ = new Tree(new Tree($1), ARRAY_ACCESS, $3);
                }
	| ID '(' expression_list ')'
                {
                    $$ = new Tree(new Tree($1), FUNCTION_CALL, $3);
                }
	| INUM
                { $$ = new Tree($1); }
	| RNUM
                { $$ = new Tree($1); }
	| '(' expression ')'
                { $$ = $2; }
	| NOT factor
                {
                    $$ = new Tree($2, NOT, NULL);
                }
	;


%%

void yyerror(char* message) {
    fprintf(stderr, "line %d, error: %s\n", lineno, message);
    exit(1);
}

Scope *prog_scope, *current;

main() {
    cerr << endl;
    yyparse();
}
