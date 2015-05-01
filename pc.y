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
#define SCOPE_DBG 0
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

/* for dangling else.
   Source: http://epaperpress.com/lexandyacc/if.html */
%nonassoc IFX
%nonassoc ELSE

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
%token                  INTEGER REAL BOOL
%token                  FUNCTION PROCEDURE
%token                  BBEGIN END
%token                  IF THEN ELSE
%token                  WHILE DO FOR TO

%token                  FUNCTION_CALL
%token                  ARRAY_ACCESS
%token                  COMMA
%token                  SEMICOLON
%token                  ARGUMENT
%token                  ANY // for read/write functions.

//                       %type   <sval>          subprogram_head

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
                    TypeSignature ts;
                    ts.push_back(PROCEDURE);
                    ts.push_back(ANY);
                    vector<string> ids;
                    ids.push_back("read");
                    ids.push_back("write");
                    prog_scope->insert(ids,ts);
                    if (SCOPE_DBG)
                        prog_scope->display(cerr,0);
                    prog_scope->semantic_check();
/*                    ofstream o;
                    o.open("a.s");
                    prog_scope->top_prologue(o);
                    prog_scope->gencode(o); */
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
       // 1        2  3         4   5             6   7            8                       9
        : FUNCTION ID arguments ':' standard_type ';' declarations subprogram_declarations compound_statement
                {
                    if (TREE_DBG) {
                        cerr << "line " << lineno << ": " << $2 << ":" << endl;
                        $9->display(cerr, 0);
                        cerr << endl;
                    }
                    string id = string($2);
                    vector<Decls>* args = (vector<Decls>*) $3;
                    vector<Decls>* decls = (vector<Decls>*) $7;
                    // construct the function entry. We'll push it up the scope tree later.
                    Decls tmp;
                    TypeSignature *fcn_type = new TypeSignature;
                    fcn_type->push_back(FUNCTION);
                    for (int i=0; i<args->size(); i++) {
                        tmp = (*args)[i];
                        for (int j=0; j<(tmp.first)->size(); j++) // for each arg of this type
                            for (int k=0; k<((tmp.second)->size())-1; k++) // push back the type, except the trailing ARGUMENT.
                                fcn_type->push_back( (*(tmp.second))[k] );
                    }
                    fcn_type->push_back($5); // the return type.
                    vector<Decls>* total = new vector<Decls>; // (id,fcn_type) + args + decls

                    // the function bit
                    vector<string> *fcn_id = new vector<string>;
                    fcn_id->push_back(id);
                    total->push_back( make_pair(fcn_id, fcn_type) );
                    // args
                    for (int i=0; i<args->size(); i++)
                        total->push_back( (*args)[i] );
                    // decls
                    for (int i=0; i<decls->size(); i++)
                        total->push_back( (*decls)[i] );
                    $$ = new Scope(id, total, (vector<Scope*>*) $8, $9);
                }
        | PROCEDURE ID arguments ';' declarations subprogram_declarations compound_statement 
                { //yolo copy pasta swag i am so bad at this
                    if (TREE_DBG) {
                        cerr << "line " << lineno << ": " << $2 << ":" << endl;
                        $7->display(cerr, 0);
                        cerr << endl;
                    }
                    string id = string($2);
                    vector<Decls>* args = (vector<Decls>*) $3;
                    vector<Decls>* decls = (vector<Decls>*) $5;
                    // construct the function entry. We'll push it up the scope tree later.
                    Decls tmp;
                    TypeSignature *fcn_type = new TypeSignature;
                    fcn_type->push_back(PROCEDURE);
                    for (int i=0; i<args->size(); i++) {
                        tmp = (*args)[i];
                        for (int j=0; j<(tmp.first)->size(); j++) // for each arg of this type
                            for (int k=0; k<((tmp.second)->size())-1; k++) // push back the type, except the trailing ARGUMENT.
                                fcn_type->push_back( (*(tmp.second))[k] );
                    }
                    vector<Decls>* total = new vector<Decls>; // (id,fcn_type) + args + decls
                    // the function bit
                    vector<string> *fcn_id = new vector<string>;
                    fcn_id->push_back(id);
                    total->push_back( make_pair(fcn_id, fcn_type) );
                    // args
                    for (int i=0; i<args->size(); i++)
                        total->push_back( (*args)[i] );
                    // decls
                    for (int i=0; i<decls->size(); i++)
                        total->push_back( (*decls)[i] );
                    $$ = new Scope(id, total, (vector<Scope*>*) $6, $7);
                }
        ;

arguments
	: '(' parameter_list ')'
                {
                    $$ = $2;
                }
        | /* empty */
                {
                    $$ = new vector<Decls>;
                }
        ;

parameter_list
	: identifier_list ':' type
                {
                    vector<Decls>* ret = new vector<Decls>;
                    vector<string> *t1 = (vector<string>*) $1;
                    TypeSignature *t2 = (TypeSignature*) $3;
                    t2->push_back(ARGUMENT);
                    ret->push_back( make_pair(t1, t2) );
                    $$ = ret;
                }
	| parameter_list ';' identifier_list ':' type
                {
                    vector<Decls>* ret = (vector<Decls>*) $1;
                    vector<string> *t1 = (vector<string>*) $3;
                    TypeSignature *t2 = (TypeSignature*) $5;
                    t2->push_back(ARGUMENT);
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
                {
                    $$ = new Tree();
                }
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
        // Note that IF x THEN y is the same as If x THEN y ELSE do-nothing
        | IF expression THEN statement %prec IFX 
                {
                    $$ = new Tree($2, IF,
                                  new Tree($4, ELSE, new Tree()));
                }
	| IF expression THEN statement ELSE statement
                {
                    $$ = new Tree( $2, IF, new Tree($4, ELSE, $6));
                }
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
	| expression RELOP simple_expression
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
