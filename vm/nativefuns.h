// WARNING: File is autogenerated, changes are overwritten!
val_t *native_myadd (exec_t *exec, val_t *args);
val_t *native_dbconnect (exec_t *exec, val_t *args);
val_t *native_dbquery (exec_t *exec, val_t *args);
val_t *native_dbexec (exec_t *exec, val_t *args);
val_t *native_dbnext (exec_t *exec, val_t *args);
val_t *native_dbnextarray (exec_t *exec, val_t *args);
val_t *native_exit (exec_t *exec, val_t *args);
val_t *native_getint (exec_t *exec, val_t *args);
val_t *native_random (exec_t *exec, val_t *args);
val_t *native_getstring (exec_t *exec, val_t *args);
val_t *native_print (exec_t *exec, val_t *args);
val_t *native_println (exec_t *exec, val_t *args);
val_t *call_native (exec_t *exec, char *id, val_t *args) {
 if (0) {
  } else if (strcmp(id, "myadd") == 0) {
     return native_myadd(exec, args);
  } else if (strcmp(id, "dbconnect") == 0) {
     return native_dbconnect(exec, args);
  } else if (strcmp(id, "dbquery") == 0) {
     return native_dbquery(exec, args);
  } else if (strcmp(id, "dbexec") == 0) {
     return native_dbexec(exec, args);
  } else if (strcmp(id, "dbnext") == 0) {
     return native_dbnext(exec, args);
  } else if (strcmp(id, "dbnextarray") == 0) {
     return native_dbnextarray(exec, args);
  } else if (strcmp(id, "exit") == 0) {
     return native_exit(exec, args);
  } else if (strcmp(id, "getint") == 0) {
     return native_getint(exec, args);
  } else if (strcmp(id, "random") == 0) {
     return native_random(exec, args);
  } else if (strcmp(id, "getstring") == 0) {
     return native_getstring(exec, args);
  } else if (strcmp(id, "print") == 0) {
     return native_print(exec, args);
  } else if (strcmp(id, "println") == 0) {
     return native_println(exec, args);
 } else { return NULL; }
}
int native_exists (char *id) {
 if (0) {
  } else if (strcmp(id, "myadd") == 0) {
     return 1;
  } else if (strcmp(id, "dbconnect") == 0) {
     return 1;
  } else if (strcmp(id, "dbquery") == 0) {
     return 1;
  } else if (strcmp(id, "dbexec") == 0) {
     return 1;
  } else if (strcmp(id, "dbnext") == 0) {
     return 1;
  } else if (strcmp(id, "dbnextarray") == 0) {
     return 1;
  } else if (strcmp(id, "exit") == 0) {
     return 1;
  } else if (strcmp(id, "getint") == 0) {
     return 1;
  } else if (strcmp(id, "random") == 0) {
     return 1;
  } else if (strcmp(id, "getstring") == 0) {
     return 1;
  } else if (strcmp(id, "print") == 0) {
     return 1;
  } else if (strcmp(id, "println") == 0) {
     return 1;
 } else { return 0; }
}
