%{
#include "sqlinked.tab.h"
%}

%option noinput nounput noyywrap yylineno

NEQ    "!="
EQ     "=="
HELLO  "hello"
REPEAT "repeat"
DEFUN  "defun"
IF     "if"
ELSE   "else"
WHILE  "while"
RETURN "return"
NUM    [0-9]+
REAL   [0-9]+\.[0-9]+
ID     [a-z_]+
STR    \"[^\"]*\"

%%

{HELLO}  { return hello;  }
{DEFUN}  { return defun;  }
{NEQ}    { return neq;    }
{EQ}     { return eq;     }
{IF}     { return _if;    }
{ELSE}   { return _else;  }
{WHILE}  { return _while; }
{REPEAT} { return repeat; }
{RETURN} { return _return; }
{NUM}    { yylval.num =   atoi(yytext); return num; }
{REAL}   { yylval.real =   atof(yytext); return real; }
{ID}     { yylval.id  = strdup(yytext); return id;  }
{STR}    { yylval.str = strdup(yytext+1); yylval.str[strlen(yylval.str)-1] = 0; return str; }
"//".*
(\ |\n|\t)
.        { return yytext[0]; }

%%

