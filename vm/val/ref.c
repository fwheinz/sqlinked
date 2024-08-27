#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "prog.h"
#include "val.h"
#include "str.h"


val_t *v_ref_new_ptr (void *p) {
  val_t *v = val_new(T_REF);
  v->u.ref = p;

  return v;
}


val_t *v_ref_create (void) {
  val_t *v = val_new(T_REF);
  v->u.ref = 0;

  return v;
}

val_t *v_ref_dup (val_t *v) {
  val_t *v2 = val_new(T_REF);
  v2->u.ref = v->u.ref;

  return v;
}

int v_ref_cmp (val_t *v1, val_t *v2) {
  return v1->u.ref == v2->u.ref;
}

val_t *v_ref_to_string (val_t *ref) {
  int l = snprintf(NULL, 0, "%p", ref->u.ref);
  char buf[l+1];
  snprintf(buf, sizeof(buf), "%p", ref->u.ref);
  return v_str_new_cstr(buf);
}

int v_ref_to_bool (val_t *v) {
  return v->u.ref != 0;
}

void v_ref_serialize (FILE *f, val_t *v) {
    printf("Cannot serialize reference!\n");
    abort();
}

val_t *v_ref_deserialize (FILE *f) {
    printf("Cannot deserialize reference!\n");
    abort();
    return &val_undef;
}

void val_register_ref (void) {
  val_ops[T_REF] = (struct val_ops) {
    .create = v_ref_create,
    .free   = NULL,
    .len    = NULL,
    .dup    = v_ref_dup,
    .cmp    = v_ref_cmp,
    .to_bool= v_ref_to_bool,
    .index  = NULL,
    .index_assign = NULL,
    .to_string = v_ref_to_string,
    .conv   = NULL,
    .serialize = v_ref_serialize,
    .deserialize = v_ref_deserialize,
  };
}

