#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>

#include "prog.h"

// Add individual opcodes or native functions here

NATIVE(myadd) {
  val_t *v1 = ARG(0);
  val_t *v2 = ARG(1);

  return val_add(v1, v2);
}

OPCODE(mymul) {
  val_t *v1 = POP;
  val_t *v2 = POP;
  PUSH(val_mul(v1, v2));
}

// PostgreSQL

#include <libpq-fe.h>
#include <catalog/pg_type_d.h>

static PGconn *conn;

struct dbresult {
    PGresult *result;
    int nrrows, currow;
};

void dbnoticeprocessor (void *arg, const char *_msg) {
	exec_t *exec = arg;
	if (strncmp(_msg, "NOTICE:  ", 9) != 0) {
		vmerror(E_WARN, exec, "Malformed msg (1): %s", _msg);
		return;
	}
	char *msg = alloca(strlen(_msg)+1);
	strcpy(msg, _msg+9);
		
	char *ptr = strchr(msg, '/');
	if (!ptr) {
		vmerror(E_WARN, exec, "Malformed msg (2): %s", _msg);
		return;
	}
	*ptr = '\0';
	ptr++;

	if (strcmp(msg, "println") == 0) {
		printf("db> %s", ptr);
	} else if (strcmp(msg, "exit") == 0) {
		exec->flags = PF_HALT;
	} else {
		vmerror(E_WARN, exec, "Unknown command: %s (%s)", msg, _msg);
	}
}

NATIVE(dbconnect) {
	val_t *v1 = ARG(0);
	int st = 0;
	if (v1->type == T_STR) {
		if (conn != NULL) {
			PQfinish(conn);
		}
		conn = PQconnectdb(v1->u.str->buf);
		if (PQstatus(conn) != CONNECTION_OK) {
        vmerror(E_ERR, exec, "Error while connecting to the database server: %s", PQerrorMessage(conn));
        PQfinish(conn);
        exit(1);
    } else {
			PQsetNoticeProcessor(conn, dbnoticeprocessor, exec);
			st = 1;
		}
	}

  return v_num_new_int(st);
}

NATIVE(dbquery) {
    val_t *v1 = ARG(0);

    int nparams = NRARGS-1;
    const char *params[nparams];
    for (int i = 0; i < nparams; i++) {
        val_t *v = ARG(i+1);
        if (v->type == T_UNDEF) {
            params[i] = NULL;
        } else {
            val_t *param = val_to_string(v);
            params[i] = strdupa(param->u.str->buf);
        }
    }

    if (conn && v1->type == T_STR) {
        PGresult *result = PQexecParams(conn, v1->u.str->buf, nparams, NULL, params, NULL, NULL, 0);
        if (!result) {
            vmerror(E_WARN, exec, "Error while sending query to the database server: %s", PQerrorMessage(conn));
        } else {
            struct dbresult *dbr = malloc(sizeof(*dbr));
            dbr->result = result;
            ExecStatusType es = PQresultStatus(result);
            switch (es) {
                case PGRES_BAD_RESPONSE:
                    vmerror(E_WARN, exec, "Bad response!");
                    break;
                case PGRES_FATAL_ERROR:
                    vmerror(E_WARN, exec, "Error while executing query: %s", PQerrorMessage(conn));
                    break;
                default:
                    dbr->nrrows = PQntuples(result);
                    dbr->currow = 0;
                    break;
            }
            return v_ref_new_ptr(dbr);
        }
    }

    return &val_undef;
}

NATIVE(dbexec) {
	return native_dbquery(exec, args);
}

NATIVE(dbnext) {
    val_t *r = ARG(0);
    struct dbresult *dbr = r->u.ref;
	if (conn && dbr->currow < dbr->nrrows) {
		int fields = PQnfields(dbr->result);
		val_t *res = v_map_create();
		for (int i = 0; i < fields; i++) {
			char *_f = PQfname(dbr->result, i);
			char *_v = PQgetvalue(dbr->result, dbr->currow, i);
			val_t *f = v_str_new_cstr(_f);
			val_t *v = v_str_new_cstr(_v);
			map_set(res->u.map, f, v);
		}
		dbr->currow++;

		return res;
	} else {
		return v_num_new_int(0);
	}
}

NATIVE(dbnextarray) {
    val_t *r = ARG(0);
    struct dbresult *dbr = r->u.ref;
	if (conn && dbr->currow < dbr->nrrows) {
		int fields = PQnfields(dbr->result);
		val_t *res = v_arr_create();
		for (int i = 0; i < fields; i++) {
			char *s = PQgetvalue(dbr->result, dbr->currow, i);
			val_t *v = v_str_new_cstr(s);
			arr_push(res->u.arr, v);
		}
		dbr->currow++;

		return res;
	} else {
		return v_num_new_int(0);
	}
}

/* Stack:
TOP: Stored Procedure Creation String
     DBLOCKID
		 NRVARS
		 VAR_1
		 VAR_2
		 VAR_...
		 VAR_n
*/
OPCODE(dblock) {
	val_t *fbody = POP;
	val_t *_dblockname = POP;
    char *dblockname = _dblockname->u.str->buf;
	val_t *_nrvars = POP;	
	int nrvars = _nrvars->u.num;

	val_t *vars[nrvars], *varnames[nrvars];
	for (int i = 0; i < nrvars; i++) {
		varnames[i] = POP;
		vars[i] = POP;
	}

	char func[10000];

	char sig[10000] = "(";
	for (int i = 0; i < nrvars; i++) {
		char *type;
		switch (vars[i]->type) {
			case T_NUM:
				type = "int";
				break;
			case T_REAL:
				type = "real";
				break;
			default:
				type = "text";
				break;
		}
		snprintf(sig+strlen(sig), sizeof(sig)-strlen(sig), "INOUT %s %s%s", varnames[i]->u.str->buf, type, i < nrvars-1 ? ", " : "");
	}
	snprintf(sig+strlen(sig), sizeof(sig)-strlen(sig), ")");
	if (nrvars == 0) {
		snprintf(sig+strlen(sig), sizeof(sig)-strlen(sig), " RETURNS VOID");
	}
	PGresult *r;

  if (exec->flags & PF_CREATESP) {
	snprintf(func, sizeof(func), "DROP FUNCTION IF EXISTS %s %s", dblockname, sig);
	r = PQexec(conn, func);
	PQclear(r);
    vmerror(E_INFO, exec, "Executing query: %s", func);
    snprintf(func, sizeof(func),
        "CREATE OR REPLACE FUNCTION %s %s LANGUAGE plpgsql AS $$\n"
        "%s\n"
        "$$\n"
        , dblockname, sig, fbody->u.str->buf);

    vmerror(E_WARN, exec, "CREATESP: %s\n", func);
    r = PQexec(conn, func);
    ExecStatusType es = PQresultStatus(r);
    switch (es) {
      case PGRES_BAD_RESPONSE:
        vmerror(E_ERR, exec, "Bad response!\n");
        exit(1);
        break;
      case PGRES_FATAL_ERROR:
        vmerror(E_ERR, exec, "Error while executing query: %s\n", PQerrorMessage(conn));
        exit(1);
        break;
      default:
        break;
    }
    PQclear(r);
  }

  char funcall[1000];
  snprintf(funcall, sizeof(funcall), "SELECT * FROM %s(%s",dblockname, nrvars > 0 ? "$1":"");
  vmerror(E_INFO, exec, "Executing query: %s", funcall);
  for (int i = 1; i < nrvars; i++) {
    char buf[20];
    snprintf(buf, sizeof(buf), ",$%d", i+1);
    strncat(funcall, buf, sizeof(funcall)-1);
	}
  strncat(funcall, ")", sizeof(funcall)-1);

	const char * pqvals[nrvars];
	for (int i = 0; i < nrvars; i++) {
		val_t *v = vars[i];
    char *buf;
		switch (v->type) {
			case T_NUM:
				buf = alloca(100);
				snprintf(buf, 100, "%d", v->u.num);
				pqvals[i] = buf;
				break;
			case T_REAL:
				buf = alloca(100);
				snprintf(buf, 100, "%f", v->u.real);
				pqvals[i] = buf;
				break;
			case T_STR:
				pqvals[i] = v->u.str->buf;
				break;
			default:
				vmerror(E_ERR, exec, "Unsupported data type %d", v->type);
				abort();
				pqvals[i] = "0";
				break;
		}
	}

	r = PQexecParams(conn, funcall, nrvars, NULL, pqvals, NULL, NULL, 0);
	ExecStatusType es = PQresultStatus(r);
	switch (es) {
		case PGRES_BAD_RESPONSE:
			vmerror(E_ERR, exec, "Bad response!");
			break;
		case PGRES_FATAL_ERROR:
			vmerror(E_ERR, exec, "Error while executing query: %s", PQerrorMessage(conn));
			exit(1);
			break;
		default:
			break;
	}
	int n = PQnfields(r);

	for (int i = n-1; i >= 0; i--) {
		char *s = PQgetvalue(r, 0, i);
		switch (PQftype(r, i)) {
			case INT2OID:
			case INT4OID:
			case INT8OID:
				PUSH(v_num_new_int(atoi(s)));
				break;
			default:
				PUSH(v_str_new_cstr(s));
				break;
		}
	}
	PQclear(r);

	// Cleanup
//	snprintf(func, sizeof(func), "DROP FUNCTION IF EXISTS dblock_%d %s", dblockid->u.num, sig);
//	r = PQexec(conn, func);
//	PQclear(r);
//	r = PQexec(conn, "COMMIT");
//	PQclear(r);
}


