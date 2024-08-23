%{
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <errno.h>
#include "vm/vm.h"
#include "vm/val/str.h"

#define METHOD1 1

#define MAXCHILDREN 5

extern int yylineno;
extern FILE *yyin;
int yylex(void);
void yyerror (const char *msg);

typedef struct astnode astnode_t;
struct astnode {
  int type;
  union {
    int num;
		double real;
    char *id;
    char *str;
  } v;
	int dt, sdt;
  struct astnode *child[MAXCHILDREN];
} *globalroot;
astnode_t *node (int type);

int compile_ast(astnode_t *root);

static int ignoredblocks = 0;

%}

%define parse.error detailed

%union {
  int num;
	double real;
  char *id;
  char *str;
  struct astnode *ast;
}

%type <ast> STMTS STMT NUM APARAMS APARAM ID STR ARR ARRAYVALS ARRAYVAL FPARAMS FPARAM ELSE REAL

%token stmts funcall func aparams arrayvals fparams defun _if _else _while _return arr block dblock
%token hello repeat
       <num> num
       <id>  id
       <str> str
			 <real> real

%right _return
%right '='
%left neq eq
%left '<'
%left '+' '-'
%left '*'

%start START

%%
START: STMTS { globalroot = $1; compile_ast($1); }

STMTS: STMTS STMT ';' { $$ = node(stmts); $$->child[0] = $1; $$->child[1] = $2; }
     | %empty { $$ = NULL; }

STMT: repeat '(' NUM ')' '{' STMTS '}'  { $$ = node(repeat); $$->child[0] = $3; $$->child[1] = $6; }
    | hello { $$ = node(hello); }
    | STMT '+' STMT { $$ = node('+'); $$->child[0] = $1; $$->child[1] = $3; }
    | STMT '*' STMT { $$ = node('*'); $$->child[0] = $1; $$->child[1] = $3; }
    | STMT '-' STMT { $$ = node('-'); $$->child[0] = $1; $$->child[1] = $3; }
    | STMT '<' STMT { $$ = node('<'); $$->child[0] = $1; $$->child[1] = $3; }
    | STMT eq  STMT { $$ = node(eq); $$->child[0] = $1; $$->child[1] = $3; }
    | STMT neq STMT { $$ = node(neq); $$->child[0] = $1; $$->child[1] = $3; }
    | ID '(' APARAMS ')' { $$ = node(funcall); $$->child[0] = $1; $$->child[1] = $3; }
    | defun ID '(' FPARAMS ')' '{' STMTS '}'  { $$ = node(func); $$->child[0] = $2; $$->child[1] = $4; $$->child[2] = $7; }
    | ID '=' STMT { $$ = node('='); $$->child[0] = $1; $$->child[1] = $3; }
		| ID '[' STMT ']' '=' STMT { $$ = node('['); $$->child[0] = $1; $$->child[1] = $3; $$->child[2] = $6; }
		| ID '[' STMT ']' { $$ = node(']'); $$->child[0] = $1; $$->child[1] = $3; }
    | NUM | ID | STR | ARR | REAL
    | _while '(' STMT ')' '{' STMTS '}' { $$ = node(_while); $$->child[0] = $3; $$->child[1] = $6; }
    | _if '(' STMT ')' '{' STMTS '}' ELSE { $$ = node(_if); $$->child[0] = $3; $$->child[1] = $6; $$->child[2] = $8; }
    | _return STMT { $$ = node(_return); $$->child[0] = $2; }
		|     '{' STMTS '}' { $$ = node(block);  $$->child[0] = $2; }
		| '$' '{' STMTS '}' { $$ = node(ignoredblocks ? block : dblock); $$->child[0] = $3; }

ELSE: _else '{' STMTS '}' { $$ = $3;   }
    | %empty             { $$ = NULL; }

APARAMS: APARAM | %empty { $$ = NULL; }
APARAM: APARAM ',' STMT { $$ = node(aparams); $$->child[0] = $1; $$->child[1] = $3; }
       | STMT             { $$ = node(aparams); $$->child[0] = NULL; $$->child[1] = $1; }

FPARAMS: FPARAM | %empty { $$ = NULL; }
FPARAM: FPARAM ',' ID   { $$ = node(fparams); $$->child[0] = $1; $$->child[1] = $3; }
       | ID             { $$ = node(fparams); $$->child[0] = NULL; $$->child[1] = $1; }

NUM: num { $$ = node(num); $$->v.num = $1; }

REAL: real { $$ = node(real); $$->v.real = $1; }

ID: id { $$ = node(id); $$->v.id = $1; }

STR: str { $$ = node(str); $$->v.str = $1; }

ARR: '[' ARRAYVALS ']' { $$ = node(arr); $$->child[0] = $2; }
ARRAYVALS: ARRAYVAL | %empty { $$ = NULL; }
ARRAYVAL: ARRAYVAL ',' STMT { $$ = node(arrayvals); $$->child[0] = $1; $$->child[1] = $3; }
       | STMT               { $$ = node(arrayvals); $$->child[0] = NULL; $$->child[1] = $1; }

%%

prog_t *p;

void dblock_parse(astnode_t *root);

void typeerror(int dt1, int dt2) {
	printf("Type mismatch: expected %d, got %d\n", dt1, dt2);
	assert(0);
}

void typeverify(int dt1, int dt2) {
	if (dt1 != dt2)
		typeerror(dt1, dt2);
}

void _typecheck (astnode_t *o1, astnode_t *o2, int assign) {
	if (o1->dt != o2->dt ||
			o1->sdt != o2->sdt) {
		if (o1->dt == T_UNDEF) {
			o1->dt = o2->dt;
			o1->sdt = o2->sdt;
		} else if (!assign && o2->dt == T_UNDEF){
			o2->dt = o1->dt;
			o2->sdt = o1->sdt;
		} else if (o2->dt != T_UNDEF) {
			typeerror(o1->dt, o2->dt);
		}
	}
}

void typecheck(astnode_t *root, int o1, int o2, int assign) {
	_typecheck (root->child[o1], root->child[o2], assign);
}

astnode_t *find_func (astnode_t *root, char *name) {
	if (!root)
		return NULL;
	if (root->type == func && strcmp(root->child[0]->v.id, name) == 0)
		return root;
	for (int i = 0; i < MAXCHILDREN; i++) {
		astnode_t *f = find_func(root->child[i], name);
		if (f)
			return f;
	}
	return NULL;
}

int compile_ast(astnode_t *root) {
  int c, nrparams, jmp, pc, jt;
  int loopstart, jumpend, dstelse, dstend;
  struct var *v;
	static astnode_t * curfunc = NULL;

  if (root == NULL)
    return 0;

  switch (root->type) {
    case stmts:
      compile_ast(root->child[0]);
      compile_ast(root->child[1]);
      prog_add_op(p, DISCARD);
      break;

    case hello:
      c = prog_new_constant(p, v_str_new_cstr("Hello World!"));
      prog_add_num(p, c);
      prog_add_op(p, CONSTANT);
      prog_add_op(p, PRINT);
      break;

    case num:
			root->dt = T_NUM;
      prog_add_num(p, root->v.num);
      break;

    case real:
			root->dt = T_REAL;
      c = prog_new_constant(p, v_real_new_double(root->v.real));
      prog_add_num(p, c);
      prog_add_op(p, CONSTANT);
      break;

    case id:
      v = var_get_or_addlocal(root->v.id);
			root->dt = v->dt;
			root->sdt = v->sdt;
      prog_add_num(p, v->nr);
      prog_add_op(p, GETVAR);
      break;

    case '<':
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = T_NUM;
      prog_add_op(p, LESS);
      break;

    case neq:
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = T_NUM;
      prog_add_op(p, NOTEQUAL);
      break;

    case eq:
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = T_NUM;
      prog_add_op(p, EQUAL);
      break;

    case '=':
      compile_ast(root->child[1]);
      v = var_get_or_addlocal(root->child[0]->v.id);
			if (v->dt == T_UNDEF) {
				v->dt = root->child[1]->dt;
				v->sdt = root->child[1]->sdt;
			} else if (root->child[1]->dt != T_UNDEF && (v->dt != root->child[1]->dt || v->sdt != root->child[1]->sdt)) {
				typeerror(v->dt, root->child[1]->dt);
			}
      prog_add_num(p, v->nr);
      prog_add_op(p, SETVAR);
      prog_add_num(p, v->nr);
      prog_add_op(p, GETVAR);
      break;

    case '+':
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
      prog_add_op(p, ADD);
      break;

    case '*':
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
      prog_add_op(p, MUL);
      break;

    case '-':
      compile_ast(root->child[1]);
      compile_ast(root->child[0]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
      prog_add_op(p, SUB);
      break;

    case str:
      c = prog_new_constant(p, v_str_new_cstr(root->v.str));
      prog_add_num(p, c);
      prog_add_op(p, CONSTANT);
			root->dt = T_STR;
      break;

		case '[':
			compile_ast(root->child[2]); // Value to assign
			compile_ast(root->child[1]); // Index
			compile_ast(root->child[0]); // Array
			typeverify(root->child[0]->dt, T_ARR);
			if (root->child[0]->sdt == T_UNDEF || root->child[0]->sdt == root->child[2]->dt)
				root->child[0]->sdt = root->child[2]->dt;
			else
				typeerror(root->child[2]->dt, root->child[0]->sdt);
			prog_add_op(p, INDEXAS);
			break;

		case ']':
			compile_ast(root->child[1]);
			compile_ast(root->child[0]);
			root->dt = root->child[0]->sdt;
			prog_add_op(p, INDEX1);
			break;

    case repeat:
      prog_add_num(p, root->child[0]->v.num);
      pc = prog_add_op(p, DUP);
      jt = prog_add_num(p, 0);
      prog_add_op(p, JUMPF);
      prog_add_num(p, 1);
      prog_add_op(p, SUB);
      prog_add_num(p, 0);
      prog_add_op(p, SUB);
      compile_ast(root->child[1]);
      prog_add_num(p, pc);
      prog_add_op(p, JUMP);
      prog_set_num(p, jt, prog_next_pc(p)); 
      prog_add_op(p, DISCARD);
      break;

    case _if:
#ifdef METHOD1
      compile_ast(root->child[0]);
      dstelse = prog_add_num(p, 0);
      prog_add_op(p, JUMPF);
      compile_ast(root->child[1]);
      dstend = prog_add_num(p, 0);
      prog_add_op(p, JUMP);
      prog_set_num(p, dstelse, prog_next_pc(p));
      compile_ast(root->child[2]);
      prog_set_num(p, dstend, prog_next_pc(p));
      prog_add_num(p, 0);
#else
      compile_ast(root->child[0]);
      prog_add_op(p, CONDBEGIN);
      compile_ast(root->child[1]);
      prog_add_op(p, CONDELSE);
      compile_ast(root->child[2]);
      prog_add_op(p, CONDEND);
      prog_add_num(p, 0);
#endif
      break;

    case _while:
#ifdef METHOD1
      loopstart = prog_next_pc(p);
      compile_ast(root->child[0]);
      jumpend = prog_add_num(p, 0);
      prog_add_op(p, JUMPF);
      compile_ast(root->child[1]);
      prog_add_num(p, loopstart);
      prog_add_op(p, JUMP);
      prog_set_num(p, jumpend, prog_next_pc(p));
      prog_add_num(p, 0);
#else
      prog_add_op(p, LOOPBEGIN);
      compile_ast(root->child[0]);
      prog_add_op(p, LOOPBODY);
      compile_ast(root->child[1]);
      prog_add_op(p, LOOPEND);
      prog_add_num(p, 0);
#endif
      break;

    case funcall:
      nrparams = 0;
      if (root->child[1] != NULL)
        nrparams = compile_ast(root->child[1])+1;
      prog_add_num(p, nrparams);
			astnode_t *f = find_func(globalroot, root->child[0]->v.id);
			if (!f) {
				printf("Warning: Undeclared function: %s\n", root->child[0]->v.id);
			} else {
				root->dt = f->dt;
				root->sdt = f->sdt;
			}
      c = prog_new_constant(p, v_str_new_cstr(root->child[0]->v.id));
      prog_add_num(p, c);
      prog_add_op(p, CONSTANT);
      prog_add_op(p, CALL);
      break;

    case arr:
			root->dt = T_ARR;
      nrparams = 0;
      if (root->child[0] != NULL) {
        nrparams = compile_ast(root->child[0])+1;
				root->sdt = root->child[0]->dt;
			} else {
				root->sdt = T_UNDEF;
			}
      prog_add_num(p, nrparams);
      prog_add_op(p, MKARRAY);
      break;

    case arrayvals:
      compile_ast(root->child[1]);
			root->dt = root->child[1]->dt;
      if (root->child[0] != NULL) {
        c = compile_ast(root->child[0]) + 1;
				typecheck(root, 0, 1, false);
			} else
        c = 0;
      return c;
      break;

    case func:
      jmp = prog_add_num(p, 0);
      prog_add_op(p, JUMP);
      var_reset();
      compile_ast(root->child[1]);
			curfunc = root;
      prog_register_function(p, root->child[0]->v.id, prog_next_pc(p));
      compile_ast(root->child[2]);
      prog_add_num(p, 0);
      prog_add_op(p, RET);
      prog_set_num(p, jmp, prog_next_pc(p));
      prog_add_num(p, 0);
      break;

    case _return:
      compile_ast(root->child[0]);
			_typecheck(curfunc, root->child[0], true);
      prog_add_op(p, RET);
      break;

    case fparams:
      compile_ast(root->child[0]);
      var_add_local(root->child[1]->v.str);
      break;

    case aparams:
      compile_ast(root->child[1]);
      if (root->child[0] != NULL) {
        c = compile_ast(root->child[0]) + 1;
			} else
        c = 0;
      return c;
      break;

		case block:
			compile_ast(root->child[0]);
			prog_add_num(p, 0);
			break;

		case dblock:
			dblock_parse(root->child[0]);
			prog_add_num(p, 0);
			break;

    default:
      printf("Unhandled AST node %d\n", root->type);
      assert(0);
      break;
  }

  return 0;
}

static struct var **extvars, **intvars;
static int nrextvars = 0, nrintvars = 0;
static int dblockid = 1000;

void addextvar (struct var *v) {
	for (int i = 0; i < nrextvars; i++) {
		if (strcmp(extvars[i]->id, v->id) == 0)
			return;
	}
	extvars = realloc(extvars, (nrextvars+1)*sizeof(struct var *));
	extvars[nrextvars++] = v;
}

void addintvar (struct var *v) {
	assert(v != NULL);
	for (int i = 0; i < nrintvars; i++) {
		if (strcmp(intvars[i]->id, v->id) == 0)
			return;
	}
	intvars = realloc(intvars, (nrintvars+1)*sizeof(struct var *));
	intvars[nrintvars++] = v;
}

void dblock_identify_ext_variables (astnode_t *root) {
	if (!root)
		return; 

	if (root->type == id) {
		struct var *v = var_get(root->v.id);
		if (v) {
			addextvar(v);
		}
	}

	for (int i = 0; i < MAXCHILDREN; i++) {
		dblock_identify_ext_variables(root->child[i]);
	}
}

void dblock_identify_int_variables (astnode_t *root) {
	if (!root)
		return; 

	if (root->type == id) {
		int found = 0;
		struct var *v = var_get(root->v.id);
		for (int i = 0; v && i < nrextvars && !found; i++) {
			if (strcmp(extvars[i]->id, v->id) == 0)
				found = 1;
		}
		if (!found && v) {
			addintvar(v);
		}
	}

	for (int i = 0; i < MAXCHILDREN; i++) {
		dblock_identify_int_variables(root->child[i]);
	}
}

#define T_CURS 1000
#define T_REC 1001
// First create the block parts, then do the typecheck, finally combine these
str_t *dblock_create_plpgsql(astnode_t *root) {
	struct var *v;
	str_t *s, *s1, *s2, *s3;
	char buf[100];

	if (!root)
		return str_new_cstr("");
	switch (root->type) {
    case stmts:
			s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			str_add_cstr(s, "  ");
			str_add_str(s, s2); str_free(s2);
			str_add_cstr(s, ";\n");
			return s;
      break;

		case id:
			s = str_new_cstr(root->v.id);
			v = var_get_or_addlocal(root->v.id);
			root->dt = v->dt;
			root->sdt = v->sdt;
			return s;
			break;

		case num:
			root->dt = T_NUM;
			snprintf(buf, sizeof(buf), "%d", root->v.num);
			s = str_new_cstr(buf);
			return s;
			break;

		case str:
			root->dt = T_STR;
			s = str_new_cstr("'");
			str_add_cstr(s, root->v.str);
			str_add_cstr(s, "'");
			return s;

		case real:
			root->dt = T_REAL;
			snprintf(buf, sizeof(buf), "%f", root->v.real);
			s = str_new_cstr(buf);
			return s;
			break;

		case aparams:
			s = str_new_cstr("");
			if (!root->child[1]) return s;
			s2 = dblock_create_plpgsql(root->child[0]);
			str_add_str(s, s2); str_free(s2);
			s2 = dblock_create_plpgsql(root->child[1]);
			str_add_str(s, s2); str_free(s2);
			s = str_add_cstr(s, ", ");
			return s;
			break;

		case funcall:
			if (strcmp(root->child[0]->v.id, "println") == 0) {
				s2 = dblock_create_plpgsql(root->child[1]->child[1]);
				s = str_new_cstr("RAISE NOTICE 'println/%', ");
				str_add_str(s, s2); str_free(s2);
			} else if (strcmp(root->child[0]->v.id, "dbquery") == 0) {
				root->dt = T_CURS;
				s = str_new_cstr("EXECUTE ");
				astnode_t *tmp = root->child[1], *save;
				while (tmp && tmp->child[0])
					tmp = tmp->child[0];
				s2 = dblock_create_plpgsql(tmp->child[1]);
				save = tmp->child[1];
				tmp->child[1] = NULL;
				str_add_str(s, s2); str_free(s2);
				astnode_t *params = root->child[1];
				if (params) {
					str_t *using = str_new_cstr(" USING ");
					s2 = dblock_create_plpgsql(params->child[0]);
					str_add_str(using, s2); str_free(s2);
					s2 = dblock_create_plpgsql(params->child[1]);
					str_add_str(using, s2); str_free(s2);
					str_add_str(s, using); str_free(using);
				}
				tmp->child[1] = save;
			} else if (strcmp(root->child[0]->v.id, "exit") == 0) {
				s = str_new_cstr("RAISE NOTICE 'exit/';\nRETURN");
			} else if (strcmp(root->child[0]->v.id, "dbnext") == 0) {
				s = dblock_create_plpgsql(root->child[1]->child[1]);
				root->dt = T_REC;
			} else {
				printf("Unsupported function: %s\n", root->child[0]->v.id);
				abort();
			}
			return s;
			break;

		case '+':
			s2 = dblock_create_plpgsql(root->child[0]);
			s3 = dblock_create_plpgsql(root->child[1]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
			root->sdt = root->child[0]->sdt;
			switch (root->dt) {
				case T_NUM:
				case T_REAL:
					str_add_cstr(s2, " + ");
					str_add_str(s2, s3); str_free(s3);
					s = s2;
					break;
				case T_STR:
					s = str_new_cstr("");
					str_add_str(s,s2); str_free(s2);
					str_add_cstr(s, " || ");
					str_add_str(s,s3); str_free(s3);
					str_add_cstr(s, "");
					break;
				default:
					printf("Invalid type: %d\n", root->dt);
					abort();
					break;
			}
			return s;
			break;

		case '-':
      s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
			root->sdt = root->child[0]->sdt;
			str_add_cstr(s, " - ");
			str_add_str(s, s2); str_free(s2);
			return s;
			break;

		case '<':
      s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			typecheck(root, 0, 1, false);
			root->dt = root->child[0]->dt;
			root->sdt = root->child[0]->sdt;
			str_add_cstr(s, " < ");
			str_add_str(s, s2); str_free(s2);
			return s;
			break;

		case eq:
      s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			root->dt = root->child[0]->dt;
			root->sdt = root->child[0]->sdt;
			str_add_cstr(s, " = ");
			str_add_str(s, s2); str_free(s2);
			return s;
			break;

		case '=':
      s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			typecheck(root, 0, 1, true);
			root->dt = root->child[0]->dt;
			root->sdt = root->child[0]->sdt;
      v = var_get_or_addlocal(root->child[0]->v.id);
			if (v->dt == T_UNDEF) {
				v->dt = root->child[1]->dt;
				v->sdt = root->child[1]->sdt;
			} else if (root->child[1]->dt != T_UNDEF && (v->dt != root->child[1]->dt || v->sdt != root->child[1]->sdt)) {
				typeerror(v->dt, root->child[1]->dt);
			}
			if (root->dt == T_CURS) {
				str_t *ret = str_new_cstr("");
#if 0
				str_add_cstr(ret, "BEGIN CLOSE ");
				str_add_str(ret, s);
				str_add_cstr(ret, "; EXCEPTION WHEN null_value_not_allowed THEN null; END;\n");
#else
				if (v->flags & F_CURSOROPEN) {
					str_add_cstr(ret, "CLOSE ");
					str_add_str(ret, s);
					str_add_cstr(ret, ";\n");
				}
#endif
				str_add_cstr(ret, "OPEN ");
				str_add_str(ret, s); str_free(s); s = ret;
				str_add_cstr(s, " FOR ");
				str_add_str(s, s2);
				v->flags |= F_CURSOROPEN;
			} else if (root->dt == T_REC) {
				str_t *ret = str_new_cstr("FETCH ");
				str_add_str(ret, s2); str_free(s2);
				str_add_cstr(ret, " INTO ");
				str_add_str(ret, s); str_free(s); s = ret;
			} else {
				str_add_cstr(s, " = ");
				str_add_str(s, s2); str_free(s2);
			}
			return s;
			break;

		case ']':
      s = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
			if (root->child[0]->dt == T_REC && root->child[1]->dt == T_STR) {
				str_add_cstr(s, ".");
				str_add_cstr(s, root->child[1]->v.str); str_free(s2);
			} else {
				printf("Unsupported index operation: %d.%d\n", root->child[0]->dt, root->child[1]->dt);
				abort();
			}
			return s;
			break;

		case _if:
      s1 = dblock_create_plpgsql(root->child[0]);
      s2 = dblock_create_plpgsql(root->child[1]);
      s3 = dblock_create_plpgsql(root->child[2]);
			s = str_new_cstr("IF ");
			str_add_str(s, s1); str_free(s1);
			if (root->child[0]->dt == T_REC) {
				str_add_cstr(s, " IS NOT NULL");
			}
			str_add_cstr(s, " THEN\n");
			str_add_str(s, s2); str_free(s2);
			if (root->child[2]) {
				str_add_cstr(s, "ELSE\n");
				str_add_str(s, s3); str_free(s3);
			}
			str_add_cstr(s, "END IF");
			return s;
			break;

		case _while:
			s1 = dblock_create_plpgsql(root->child[0]);
			s2 = dblock_create_plpgsql(root->child[1]);
			if (root->child[0]->dt == T_REC) {
				s = str_new_cstr(
						"  LOOP\n  ");
				str_add_str(s, s1); str_free(s1);
				str_add_cstr(s, ";\n  EXIT WHEN NOT FOUND;\n");
				str_add_str(s, s2); str_free(s2);
				str_add_cstr(s, "END LOOP");
			} else {
				s = str_new_cstr(
						"  LOOP\n"
						"    EXIT WHEN NOT (");
				str_add_str(s, s1); str_free(s1);
				str_add_cstr(s, ");\n");
				str_add_str(s, s2); str_free(s2);
				str_add_cstr(s, "END LOOP");
			}
			return s;
			break;

		default:
			printf("Unhandled in plpgsql: %d\n", root->type);
			exit(1);
			break;
	}
}

void dblock_parse(astnode_t *root) {
	dblockid++;
	nrextvars = 0;
	nrintvars = 0;
	dblock_identify_ext_variables (root);
	for (int i = nrextvars-1; i >= 0; i--) {
		prog_add_num(p, extvars[i]->nr);
		prog_add_op(p, extvars[i]->global ? GETGLOBAL : GETVAR);
		int c = prog_new_constant(p, v_str_new_cstr(extvars[i]->id));
		prog_add_num(p, c);
		prog_add_op(p, CONSTANT);
	}
	prog_add_num(p, nrextvars);
	prog_add_num(p, dblockid);

	printf("Compiling PL/PGSQL block...\n");
	str_t *fbody = dblock_create_plpgsql(root);

	dblock_identify_int_variables (root);
	str_t *s = str_new_cstr("DECLARE\n");
	for (int i = 0; i < nrintvars; i++) {
		char buf[1000];
		char *type;
		switch (intvars[i]->dt) {
			case T_NUM:
				type = "int";
				break;
			case T_STR:
				type = "text";
				break;
			case T_REAL:
				type = "real";
				break;
			case T_CURS:
				type = "refcursor";
				break;
			case T_REC:
				type = "record := row(NULL)";
				break;
			default:
				printf("Unsupported type: %d\n", intvars[i]->dt);
				abort();
		}

		snprintf(buf, sizeof(buf), "  %s %s;\n", intvars[i]->id, type);
		str_add_cstr(s, buf);

	}
	str_add_cstr(s, "BEGIN\n");
	str_add_str(s, fbody); str_free(fbody);
	str_add_cstr(s, "END;");

	printf("Result: %s\n", s->buf);

	int c = prog_new_constant(p, v_str_new_cstr(s->buf));
	str_free(s);
	prog_add_num(p, c);
	prog_add_op(p, CONSTANT);
	prog_add_op(p, DBLOCK);
	for (int i = 0; i < nrextvars; i++) {
		prog_add_num(p, extvars[i]->nr);
		prog_add_op(p, extvars[i]->global ? SETGLOBAL : SETVAR);
	}
}

astnode_t *node (int type) {
  astnode_t *n = calloc(1, sizeof *n);
  n->type = type;
	n->dt = n->sdt = T_UNDEF;
  return n;
}

void yyerror (const char *msg) {
  fprintf(stderr, "Line %d: %s\n", yylineno, msg);
}

void usage (void) {
  fprintf(stderr, "prolang [-v] [-d] <file>\n"
      "        -v  Increase verbosity\n"
      "        -d  Dump file (no execution)\n"
      "        -c  (Re-)create stored procedures\n"
      "        -i  Ignore database blocks\n"
      "    <file>  Bytecode filename\n"
      "\n"
      );

  exit(EXIT_FAILURE);
}

int main (int argc, char **argv) {
  int verbose = 0, dump = 0, opt, createsp = 0;

  while ((opt = getopt(argc, argv, "vdci")) != -1) {
    switch (opt) {
      case 'v':
        verbose++;
        break;
      case 'd':
        dump++;
        break;
      case 'c':
        createsp++;
        break;
      case 'i':
        ignoredblocks++;
        break;
      default:
        usage();
    }
  }

  if (optind >= argc) {
    usage();
    exit(EXIT_FAILURE);
  }

  p = prog_new();
  yyin = fopen(argv[optind], "r");
  if (yyin == NULL) {
    printf("Could not open file %s: %s\n", argv[optind], strerror(errno));
    usage();
  }

  int st = yyparse();
  if (verbose >= 1)
  prog_dump(p);
  if (st) {
    printf("Parsing failed!\n");
    exit(EXIT_FAILURE);
  }

  char bytecodefile[100];
  snprintf(bytecodefile, sizeof(bytecodefile), "%s.vm3", argv[optind]);
  prog_write(p, bytecodefile);
  exec_t *e = exec_new(p);
  if (createsp)
    e->flags |= PF_CREATESP;
  exec_set_debuglvl(e, verbose);
  exec_run(e);

  return st;
}

