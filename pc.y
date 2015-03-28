%{
#include <stdio.h>

void yyerror(char*);
extern "C" { /* because lex creates c, and we want yacc to make cpp */
  int yylex();
}
int yyparse();

%}

%union {
	/* scanner attributes */
	int ival;
	float rval;
	char *sval;
	int opval;
}

%token <ival>	INUM
%token <rval>	RNUM
%token <sval>	ID

%token	ASSIGNOP
%token <opval>	RELOP
%token <opval>	ADDOP
%token <opval>	MULOP
%token	NOT

%token	LT LE GT GE EQ NE
%token	OR PLUS MINUS
%token	AND STAR SLASH

%token	PROGRAM
%token	VAR
%token	ARRAY OF DOTDOT
%token	INTEGER REAL
%token	FUNCTION PROCEDURE
%token	BBEGIN END
%token	IF THEN ELSE
%token	WHILE DO

%token	FUNCTION_CALL
%token	ARRAY_ACCESS
%token	COMMA

%%

program:
	PROGRAM ID '(' identifier_list ')' ';' 
	declarations
	subprogram_declarations
	compound_statement
	'.'
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
	;

subprogram_head
	: FUNCTION ID arguments ':' standard_type ';'
	| PROCEDURE ID arguments ';'
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
	;

optional_statements
	: statement_list
	| /* empty */
	;

statement_list
	: statement
	| statement_list ';' statement
	;

statement
	: variable ASSIGNOP expression
	| procedure_statement
	| compound_statement
	| IF expression THEN statement ELSE statement
	| WHILE expression DO statement 
	;

variable
	: ID
	| ID '[' expression ']'
	;

procedure_statement
	: ID
	| ID '(' expression_list ')'
	;


/* expression */

expression_list
	: expression
	| expression_list ',' expression
	;

expression
	: simple_expression
	| simple_expression RELOP simple_expression
	;

simple_expression
	: term
	| simple_expression ADDOP term
	;

term
	: factor
	| term MULOP factor
	;

factor
	: ID
	| ID '[' expression ']'
	| ID '(' expression_list ')'
	| INUM
	| RNUM
	| '(' expression ')'
	| NOT factor
	;


%%

void yyerror(char* message)
{
  fprintf(stderr, "Error: %s\n", message);
  exit(1);
}
main()
{
  yyparse();
}
