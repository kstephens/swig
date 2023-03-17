/* -----------------------------------------------------------------------------
 * postgresql_run.swg
 * ----------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <assert.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/elog.h"

PG_MODULE_MAGIC;

/* Common SWIG API */

#define swig_pg_void       ((Datum) 0)      // See: PG_RETURN_VOID()
#define swig_pg_true       BoolGetDatum(1)  // TODO : Save a constant?
#define swig_pg_false      BoolGetDatum(0)

/**************************************************
 * !!! : PLACEHOLDERS
 */

// for dispatching
#define swig_PG_FUNCTION_PARAMS	fcinfo

#define swig_pg_UNIMPLEMENTED swig_pg_void
#define swig_pg_UNUSED ((void) 0)

#define SWIG_PG_NULLP(X) 0
#define swig_pg_builtin_value(X) swig_pg_UNIMPLEMENTED
#define swig_pg_add_global_symbol(...) swig_pg_UNIMPLEMENTED
#define swig_pg_add_global(...) swig_pg_UNUSED
#define swig_pg_lookup_global(...) swig_pg_UNIMPLEMENTED
#define swig_pg_subtract_finalizer(...) swig_pg_UNIMPLEMENTED
#define swig_pg_make_null(...) swig_pg_UNIMPLEMENTED
#define swig_pg_add_finalizer(...) swig_pg_UNUSED
#define swig_pg_make_prim_w_arity(...) swig_pg_UNIMPLEMENTED
#define SWIG_PG_CPTR_VAL(X) NULL
#define SWIG_PG_CPTRP(X) NULL
#define swig_pg_reload(...) swig_pg_UNIMPLEMENTED
#define swig_pg_make_cptr(...) swig_pg_UNIMPLEMENTED
#define _swig_pg_apply(...) swig_pg_UNIMPLEMENTED

#define swig_pg_intern_symbol(...) swig_pg_UNIMPLEMENTED
#define swig_pg_make_symbol(...) swig_pg_UNIMPLEMENTED

typedef struct SWIG_PG_Env {
  void *dummy;
} SWIG_PG_Env;
#define SWIG_PG_CREATE_MENV(...) ((SWIG_PG_Env *) 0)

typedef struct SWIG_PG_Type_s {
  void *dummy;
} *SWIG_PG_Type;
#define SWIG_PG_TYPE(X) ((SWIG_PG_Type) 0)
#define swig_pg_make_type(...) ((SWIG_PG_Type) 0)

#define swig_pg_make_struct_type(...)      swig_pg_UNIMPLEMENTED
#define swig_pg_make_struct_names(...)     ((Datum*) swig_pg_UNIMPLEMENTED)
#define swig_pg_make_struct_values(...)    ((Datum*) swig_pg_UNIMPLEMENTED)
#define swig_pg_make_struct_instance(...)  swig_pg_UNIMPLEMENTED

/*
struct swig_pg_runtime_data {
  void* type;
  void* dummy;
};
*/

/**************************************************
 * Error handling
 */

#define SWIG_PG_ERROR_PARAMS const char *file, int line, const char *function, const char *func_name
#define SWIG_PG_ERROR_ARGS   __FILE__, __LINE__, __FUNCTION__, FUNC_NAME

static char* _swig_format_error(char* buf, size_t buflen, const char *fmt, va_list* vap) {
  char *str = buf, *bufend = buf + buflen;
  memset(buf, 0, buflen);
  snprintf(str, bufend - str, "%s %s : ", swig_pg_extension_name_cstr, swig_pg_extension_version_cstr);
  str = strchr(str, '\0');
  vsnprintf(str, bufend - str, fmt, *vap);
  return buf;
}

static void _swig_pg_signal_error(SWIG_PG_ERROR_PARAMS, const char *fmt, ...) {
  char message[1024];
  va_list va;
  va_start(va, fmt);
  _swig_format_error(message, sizeof(message), fmt, &va);
  va_end(va);
  fprintf(stderr, "ERROR : SWIG : %s : %d : %s : %s\n", file, line, function, message);
  ErrorData* edata = CopyErrorData();
  edata->elevel = ERROR;
	edata->filename = pstrdup(file);
	edata->lineno = line;
  edata->funcname = function;
  edata->message = pstrdup(message);
  ThrowErrorData(edata);
  // ??? : does PG have exception processing?
}

static void _swig_pg_wrong_type(SWIG_PG_ERROR_PARAMS, const char *msg, int argnum) {
  char str[1024];
  snprintf(str, sizeof(str) - 1, "%s : %s : argnum %d", func_name, msg, argnum);
  _swig_pg_signal_error(file, line, function, func_name, "%s : argnum %d", msg, argnum);
}

static const char FUNC_NAME[] = "UNKNOWN-FUNC-NAME";

#define swig_pg_signal_error(FMT, ...) \
_swig_pg_signal_error(SWIG_PG_ERROR_ARGS, FMT, ## __VA_ARGS__)
#define swig_pg_wrong_type(FMT, ...) \
_swig_pg_wrong_type(SWIG_PG_ERROR_ARGS, FMT, ## __VA_ARGS__)

/****************************************************/

static SWIGINLINE void *
swig_pg_malloc_(SWIG_PG_ERROR_PARAMS, size_t size) {
  void *p = palloc(size);
  if (p == NULL)
    _swig_pg_signal_error(file, line, function, func_name, "memory error : cannot allocate %lu", (unsigned long) size);
  return p;
}
#define swig_pg_malloc(size) swig_pg_malloc_(SWIG_PG_ERROR_ARGS, size)
#define swig_pg_free(X)      pfree(X)

/****************************************************/
/* Type helpers */

// https://cpp.hotexamples.com/examples/-/-/PG_RETURN_CSTRING/cpp-pg_return_cstring-function-examples.html
static Datum swig_CStringGetDatum(const char *str) {
  return CStringGetTextDatum(pstrdup(str));
}
static Datum swig_CharGetDatum(int c) {
  swig_pg_signal_error("unimplemented");
  PG_RETURN_VOID();
}
static int swig_DatumGetChar(Datum d) {
  const char *str = DatumGetCString(d);
  if ( *str ) {
    return str[0];
  } else {
    swig_pg_signal_error("cannot cast empty string to C char");
    PG_RETURN_VOID();
  }
}
// !!! PLACEHOLDERS : generated .sql defines strict - probably dont need these checks.
static int swig_pg_is_null(Datum d) {
  return 0;
}
static int swig_pg_is_bool(Datum d) {
  // TODO:
  return 1;
}
static int swig_pg_is_integer(Datum d) {
  // TODO:
  return 1;
}
static int swig_pg_is_float(Datum d) {
  // TODO:
  return 1;
}
static int swig_pg_is_string(Datum d) {
  // TODO:
  return 1;
}
static int swig_pg_is_sequence(Datum d) {
  // TODO:
  return 0;
}
static size_t swig_pg_sequence_size(Datum d) {
  // TODO:
  return 0;
}
static Datum swig_pg_sequence_get(Datum d, size_t i) {
  // TODO:
  return swig_pg_void;
}
static Datum swig_pg_sequence_set(Datum d, size_t i, Datum v) {
  // TODO:
  return swig_pg_void;
}

#define swig_DatumGetUChar swig_DatumGetChar
#define swig_DatumGetVoid(...) ((void) __VA_ARGS__)
#define swig_VoidGetDatum(...) swig_pg_void

/****************************************************/

static long
SWIG_convert_integer(Datum o,
		     long lower_bound, long upper_bound,
		     const char *func_name, int argnum)
{
  // ??? does this work for all integral PG types?
  // ??? do we need a typecheck?
  long value = DatumGetInt64(o);
  if (value < lower_bound || value > upper_bound)
    swig_pg_wrong_type("integer", argnum);
  return value;
}

/****************************************************/

#define SWIG_ConvertPtr(s, result, type, flags) \
  SWIG_PG_ConvertPtr(s, result, type, flags)
#define SWIG_NewPointerObj(ptr, type, owner) \
  SWIG_PG_NewPointerObj((void *)ptr, type, owner)
#define SWIG_MustGetPtr(s, type, argnum, flags) \
  SWIG_PG_MustGetPtr(s, type, argnum, flags, FUNC_NAME)

#define SWIG_contract_assert(expr,msg) \
  do { \
    if (!(expr)) { \
      swig_pg_signal_error("SWIG contract, assertion failed : %s", msg); \
    } \
  } while (0)

/* Runtime API */
#define SWIG_GetModule(clientdata) SWIG_PG_GetModule((SWIG_PG_Env *)(clientdata))
#define SWIG_SetModule(clientdata, pointer) SWIG_PG_SetModule((SWIG_PG_Env *) (clientdata), pointer)
#define SWIG_MODULE_CLIENTDATA_TYPE SWIG_PG_Env *

/* PostgreSQL-specific SWIG API */

#define SWIG_malloc(size) swig_pg_malloc(size)
#define SWIG_free(mem) swig_pg_free(mem)
#define SWIG_NewStructFromPtr(ptr,type) \
        _swig_convert_struct_##type##(ptr)

#define swig_make_boolean(b) (b ? swig_pg_true : swig_pg_false)

struct swig_pg_proxy {
  SWIG_PG_Type pgtype;
  swig_type_info *type;
  void *object;
  int own;
};

static SWIG_PG_Type swig_type;

static void
pg_free_swig(void *p, void *data) {
  struct swig_pg_proxy *proxy = (struct swig_pg_proxy *) p;
  if (SWIG_PG_NULLP((Datum )p) || SWIG_PG_TYPE((Datum )p) != swig_type)
    return;
  if (proxy->type) {
    if (proxy->type->clientdata && proxy->own) {
#if 0 // !!! FIXME
      ((SWIG_PG_Prim *)proxy->type->clientdata)(1, (Datum *)&proxy);
#endif
    }
  }
}

static Datum
SWIG_PG_NewPointerObj(void *ptr, swig_type_info *type, int owner) {
  if (ptr) {
    struct swig_pg_proxy *new_proxy;
    new_proxy = (struct swig_pg_proxy *) swig_pg_malloc(sizeof(*new_proxy));
    new_proxy->pgtype = swig_type;
    new_proxy->type = type;
    new_proxy->object = ptr;
    new_proxy->own = owner & SWIG_POINTER_OWN;
    if (new_proxy->own) {
      swig_pg_add_finalizer(new_proxy, pg_free_swig, NULL);
    }
    return (Datum ) new_proxy;
  } else {
    return swig_pg_make_null();
  }
}

static int
SWIG_PG_ConvertPtr(Datum s, void **result, swig_type_info *type, int flags) {
  swig_cast_info *cast;
  int ret = SWIG_ERROR;

  if (SWIG_PG_NULLP(s)) {
    *result = NULL;
    return (flags & SWIG_POINTER_NO_NULL) ? SWIG_NullReferenceError : SWIG_OK;
  } else if (SWIG_PG_TYPE(s) == swig_type) {
    struct swig_pg_proxy *proxy = (struct swig_pg_proxy *) s;

    if ((flags & SWIG_POINTER_RELEASE) == SWIG_POINTER_RELEASE && !proxy->own) {
      return SWIG_ERROR_RELEASE_NOT_OWNED;
    }

    if (type) {
      cast = SWIG_TypeCheckStruct(proxy->type, type);
      if (cast) {
        int newmemory = 0;
        *result = SWIG_TypeCast(cast, proxy->object, &newmemory);
        assert(!newmemory); /* newmemory handling not yet implemented */
        ret = SWIG_OK;
      } else {
        return SWIG_ERROR;
      }
    } else {
      *result = proxy->object;
      ret = SWIG_OK;
    }

    if (flags & SWIG_POINTER_DISOWN) {
      swig_pg_subtract_finalizer(proxy, pg_free_swig, NULL);
      proxy->own = 0;
    }
    if (flags & SWIG_POINTER_CLEAR) {
      proxy->object = 0;
    }
  }
  return ret;
}

static SWIGINLINE void *
SWIG_PG_MustGetPtr(Datum s, swig_type_info *type,
                         int argnum, int flags, const char *func_name) {
  void *result;
  if (SWIG_PG_ConvertPtr(s, &result, type, flags)) {
    _swig_pg_wrong_type(__FILE__, __LINE__, __FUNCTION__, func_name, type->str ? type->str : "void *", argnum - 1);
  }
  return result;
}

#ifndef swig_pg_make_inspector
#define swig_pg_make_inspector(x,y) \
        _swig_pg_apply(swig_pg_builtin_value("make-inspector"), x, y)
#endif

/* Function to create a new struct. */
static Datum
SWIG_PG_new_swig_pg_struct (SWIG_PG_Env* env, const char* basename,
				 int num_fields, char** field_names)
{
    Datum new_type;
    int count_out = 0, i = 0;
    Datum *struct_names;
    Datum *vals;
    Datum *a = (Datum *) \
        swig_pg_malloc(num_fields * sizeof(a[0]));

    for (i=0; i<num_fields; ++i) {
        a[i] = (Datum) swig_pg_intern_symbol(field_names[i]);
    }

    new_type = swig_pg_make_struct_type(swig_pg_intern_symbol(basename),
                                       NULL /*super_type*/,
                                       swig_pg_make_inspector(0, NULL),
                                       num_fields,
                                       0 /* auto_fields */,
                                       NULL /* auto_val */,
                                       NULL /* properties */
				       );
    struct_names = swig_pg_make_struct_names(swig_pg_intern_symbol(basename),
                                            swig_pg_build_list(num_fields,a),
                                            0 /*flags*/, &count_out);
    vals = swig_pg_make_struct_values(new_type, struct_names, count_out, 0);

    for (i = 0; i < count_out; i++)
        swig_pg_add_global_symbol(struct_names[i], vals[i],env);

    return new_type;
}

/////////////////////////////////////////
// ??? : unnecessary?

static swig_module_info *
SWIG_PG_GetModule(SWIG_PG_Env *env) {
  return (swig_module_info *) 0;
}

static void
SWIG_PG_SetModule(SWIG_PG_Env *env, swig_module_info *module) {
}

#ifdef __cplusplus
}
#endif

