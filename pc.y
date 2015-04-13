%{
#include <iostream>
using std::cout;
#include <stdio.h>
#include "Tree.h"
#include "Scope.h"

extern void yyerror(char*);
extern int yylex();
extern int yyparse();
%}

%union {
    /* scanner attributes */
    int ival;
    float rval;
    char *sval;
    int opval;

    /* for passing around the trees */
    Tree *tval;
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
%token                  WHILE DO

%token                  FUNCTION_CALL
%token                  ARRAY_ACCESS
%token                  COMMA
%token                  SEMICOLON

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

                        
%%

program:
	PROGRAM ID '(' identifier_list ')' ';' 
	declarations
	subprogram_declarations
	compound_statement
	'.'
                {
                    cout << "PROGRAM " << $2 << ": " << endl;
                    $9->display(cout, 0);
                    cout << endl;
                }
	;

identifier_list
	: ID
	| identifier_list ',' ID
	;

declarations
	: declarations VAR identifier_list ':' type ';'
	| /* empty */
	;

type
	: standard_type
	| ARRAY '[' INUM DOTDOT INUM ']' OF standard_type
	;

standard_type
	: INTEGER
	| REAL
	;

subprogram_declarations
	: subprogram_declarations subprogram_declaration ';'
	| /* empty */
	;

subprogram_declaration
	: subprogram_head declarations subprogram_declarations compound_statement
                {
                    cout << $1 << ":" << endl;
                    $4->display(cout, 0);
                    cout << endl;
                }
	;

subprogram_head
	: FUNCTION ID arguments ':' standard_type ';'
                { $$ = $2; }
	| PROCEDURE ID arguments ';'
                { $$ = $2; }
	;

arguments
	: '(' parameter_list ')'
	;

parameter_list
	: identifier_list ':' type
	| parameter_list ';' identifier_list ':' type
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
	| WHILE expression DO statement
                {
                    $$ = new Tree($2, WHILE, $4);
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
    fprintf(stderr, "Error: %s\n", message);
    exit(1);
}
main() {
    cout << endl;
    yyparse();
}
