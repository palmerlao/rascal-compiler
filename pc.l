%{
#include <stdio.h>
#include "Tree.h"
#include "Scope.h"
#include "y.tab.hpp"

#define LEX_DBG 0

void echo(char*);
int lineno = 1;

%}

%x              COMMENT1
%x              COMMENT
                        
ident		[a-zA-Z][a-zA-Z0-9]*
number		[0-9]+
whitespace	[ \t]+

%%

"program"	{ echo("PROGRAM"); return PROGRAM; }
"var"		{ echo("VAR"); return VAR; }
"array"		{ echo("ARRAY"); return ARRAY; }
"of"		{ echo("OF"); return OF; }
"integer"	{ echo("INTEGER"); return INTEGER; }
"real"		{ echo("REAL"); return REAL; }
"function"	{ echo("FUNCTION"); return FUNCTION; }
"procedure"	{ echo("PROCEDURE"); return PROCEDURE; }
"begin"		{ echo("BBEGIN"); return BBEGIN; }
"end"		{ echo("END"); return END; }
"if"		{ echo("IF"); return IF; }
"then"		{ echo("THEN"); return THEN; }
"else"		{ echo("ELSE"); return ELSE; }
"and"           { echo("AND"); return AND; }
"while"		{ echo("WHILE"); return WHILE; }
"do"		{ echo("DO"); return DO; }
"not"		{ echo("NOT"); return NOT; }
"to"            { echo("TO"); return TO; }
"for"           { echo("FOR"); return FOR; }

".."		{ echo("DOTDOT"); return DOTDOT; }
":="		{ echo("ASSIGNOP"); return ASSIGNOP; }

"="		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = EQ;
                  return RELOP;
                }
"<>"		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = NE;
                  return RELOP;
                }
"<"		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = LT;
                  return RELOP;
                }
"<="		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = LE;
                  return RELOP;
                }
">"		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = GT;
                  return RELOP;
                }
">="		{
                  if (LEX_DBG) fprintf(stderr, "RELOP[%s]", yytext);
                  yylval.opval = GE;
                  return RELOP;
                }

"or"		{
                  if (LEX_DBG) fprintf(stderr, "ADDOP[%s]", yytext);
                  yylval.opval = OR;
                  return ADDOP;
                }
"+"		{
                  if (LEX_DBG) fprintf(stderr, "ADDOP[%s]", yytext);
                  yylval.opval = PLUS;
                  return ADDOP;
                }
"-"		{
                  if (LEX_DBG) fprintf(stderr, "ADDOP[%s]", yytext);
                  yylval.opval = MINUS;
                  return ADDOP;
                }

"and"		{
                  if (LEX_DBG) fprintf(stderr, "MULOP[%s]", yytext);
                  yylval.opval = AND;
                  return MULOP;
                }
"*"		{
                  if (LEX_DBG) fprintf(stderr, "MULOP[%s]", yytext);
                  yylval.opval = STAR;
                  return MULOP;
                }
"/"		{
                  if (LEX_DBG) fprintf(stderr, "MULOP[%s]", yytext);
                  yylval.opval = SLASH;
                  return MULOP;
                }

{number}	{
                  if (LEX_DBG) fprintf(stderr, "INUM[%d]", atoi(yytext));
                  yylval.ival = atoi(yytext);
                  return INUM;
                }
{number}"."{number}	{
                          if (LEX_DBG) fprintf(stderr, "RNUM[%f]", atof(yytext));
                          yylval.rval = atof(yytext);
                          return RNUM;
                        }
{ident}	        {
                  if (LEX_DBG)fprintf(stderr, "ID[%s]", strdup(yytext));
                  yylval.sval = strdup(yytext);
                  return ID;
                }

"//"            { BEGIN(COMMENT1); }
<COMMENT1>"\n"  { ++lineno; BEGIN(INITIAL); }
<COMMENT1>.     { ; }

"(*"            { BEGIN(COMMENT); }
<COMMENT>\n     { ++lineno; }
<COMMENT>"*)"   { BEGIN(INITIAL); } /* reset lex to normal state */
<COMMENT>.      { ; }

{whitespace}	{ ; }
\n		{
                  ++lineno;
                  if (LEX_DBG) fprintf(stderr,"%s", yytext);
                }
.		{
                  if(LEX_DBG) fprintf(stderr, "{%c}", yytext[0]);
                  return yytext[0];
                }

%%

void echo(char* message) {
  if (LEX_DBG)
    fprintf(stderr, "{%s} ", message);
}
