#include <stdlib.h>
#include <string.h>

#include "prog.h"

static struct varalloc varalloc;

struct var *_var_lookup (char *id, struct var **list, int len, int block) {
  for (int i = len-1; i >= 0; i--) {
    if (strcmp(list[i]->id, id) == 0)
      return list[i];
    if (list[i]->nr == VAR_BLOCKBORDER && block)
      return NULL;
  }

  return NULL;
}

struct var *_var_add (char *id, struct var ***list, int *len, int global) {
  if (id && _var_lookup(id, *list, *len, 1))
    return NULL;

  *list = realloc(*list, (*len+1) * sizeof(**list));
	(*list)[*len] = malloc(sizeof(struct var));
  if (id) {
    (*list)[*len]->id = strdup(id);
    (*list)[*len]->nr = *len;
  } else {
    (*list)[*len]->id = strdup("BLOCKBORDER");
    (*list)[*len]->nr = VAR_BLOCKBORDER;
  }
  (*list)[*len]->type = -1;
  (*list)[*len]->global = global;
	(*list)[*len]->flags = 0;
	(*list)[*len]->dt = T_UNDEF;
	(*list)[*len]->sdt = T_UNDEF;
  (*len)++;

  return (*list)[*len-1];
}

struct var *var_add_global (char *id) {
  return _var_add(id, &varalloc.globals, &varalloc.nrglobals, 1);
}

struct var *var_add_local (char *id) {
  return _var_add(id, &varalloc.locals, &varalloc.nrlocals, 0);
}

struct var *var_get_or_addlocal (char *id) {
  struct var *ret = _var_lookup(id, varalloc.locals, varalloc.nrlocals, 0);
  if (!ret)
    ret = _var_lookup(id, varalloc.globals, varalloc.nrglobals, 0);
  if (!ret)
    ret = _var_add(id, &varalloc.locals, &varalloc.nrlocals, 0);

  return ret;
}

struct var *var_get (char *id) {
  struct var *ret = _var_lookup(id, varalloc.locals, varalloc.nrlocals, 0);
  if (!ret)
    ret = _var_lookup(id, varalloc.globals, varalloc.nrglobals, 0);

  return ret;
}

void var_enter_block (void) {
  var_add_local(NULL);
}

void var_leave_block (void) {
  for (int i = varalloc.nrlocals-1; i >= 0; i--) {
		int nr = varalloc.locals[i]->nr;
		free(varalloc.locals[i]);
    if (nr == VAR_BLOCKBORDER) {
      varalloc.nrlocals = i;
      break;
    }
  }
}

void var_reset (void) {
  for (int i = varalloc.nrlocals-1; i >= 0; i--)
		free(varalloc.locals[i]);
  varalloc.nrlocals = 0;
}

void var_reset_all (void) {
  for (int i = varalloc.nrlocals-1; i >= 0; i--)
		free(varalloc.locals[i]);
  varalloc.nrlocals = 0;
  for (int i = varalloc.nrlocals-1; i >= 0; i--)
		free(varalloc.globals[i]);
  varalloc.nrglobals = 0;
}


