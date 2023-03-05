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

PG_MODULE_MAGIC;

/* !!! : PLACEHOLDERS */
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

#define swig_pg_make_struct_names(...) ((swig_pg_value*) 0)
#define swig_pg_make_struct_type(...) 0
#define swig_pg_make_struct_values(...) ((swig_pg_value*) 0)

/*
struct swig_pg_runtime_data {
  void* type;
  void* dummy;
};
*/

/* Common SWIG API */

#define swig_pg_void       ((Datum) 0)
#define swig_pg_true       BoolGetDatum(1)
#define swig_pg_false      BoolGetDatum(0)
#define swig_pg_malloc(X)  palloc(X)
#define swig_pg_free(X)    pfree(X)
#define swig_pg_value      Datum

// !!! : Hack
// https://cpp.hotexamples.com/examples/-/-/PG_RETURN_CSTRING/cpp-pg_return_cstring-function-examples.html
static swig_pg_value CStringGetDatum_dup(const char *str) {
  return CStringGetTextDatum(pstrdup(str));
}

static void _swig_pg_signal_error(const char *fmt, ...) {
  va_list va;
  va_start(va, fmt);
  fprintf(stderr, "ERROR : SWIG : %s %s : ", swig_pg_extension_name_cstr, swig_pg_extension_version_cstr);
  vfprintf(stderr, fmt, va);
  fprintf(stderr, "\n\n");
  fflush(stderr);
  va_end(va);
  // ??? : does PG have exception processing?
}

static void _swig_pg_wrong_type(const char* func_name, const char *msg, int argnum, int argc, swig_pg_value* argv) {
  char str[1024];
  snprintf(str, sizeof(str) - 1, "%s : %s : argnum %d", func_name, msg, argnum);
  _swig_pg_signal_error("%s", str);
}

#if 0
#define swig_pg_signal_error(FMT, ...) \
({ _swig_pg_signal_error(FMT, ## __VA_ARGS__); PG_RETURN_NULL(); })
#define swig_pg_wrong_type(FMT, ...) \
({ _swig_pg_wrong_type(FMT, ## __VA_ARGS__); PG_RETURN_NULL(); })
#else
#define swig_pg_signal_error(FMT, ...) \
_swig_pg_signal_error(FMT, ## __VA_ARGS__)
#define swig_pg_wrong_type(FMT, ...) \
_swig_pg_wrong_type(FMT, ## __VA_ARGS__)
#endif

#define SWIG_ConvertPtr(s, result, type, flags) \
  SWIG_PG_ConvertPtr(s, result, type, flags)
#define SWIG_NewPointerObj(ptr, type, owner) \
  SWIG_PG_NewPointerObj((void *)ptr, type, owner)
#define SWIG_MustGetPtr(s, type, argnum, flags) \
  SWIG_PG_MustGetPtr(s, type, argnum, flags, FUNC_NAME, argc, argv)

#define SWIG_contract_assert(expr,msg) \
  do { \
    if (!(expr)) { \
      char *m=(char *) swig_pg_malloc(strlen(msg)+1000); \
      sprintf(m,"SWIG contract, assertion failed: function=%s, message=%s", \
              (char *) FUNC_NAME,(char *) msg); \
      swig_pg_signal_error(m); \
    } \
  } while (0)

/* Runtime API */
#define SWIG_GetModule(clientdata) SWIG_PG_GetModule((SWIG_PG_Env *)(clientdata))
#define SWIG_SetModule(clientdata, pointer) SWIG_PG_SetModule((SWIG_PG_Env *) (clientdata), pointer)
#define SWIG_MODULE_CLIENTDATA_TYPE SWIG_PG_Env *

/* PostgreSQL-specific SWIG API */

#define SWIG_malloc(size) swig_pg_malloc_(size, FUNC_NAME)
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
  if (SWIG_PG_NULLP((swig_pg_value )p) || SWIG_PG_TYPE((swig_pg_value )p) != swig_type)
    return;
  if (proxy->type) {
    if (proxy->type->clientdata && proxy->own) {
#if 0 // !!! FIXME
      ((SWIG_PG_Prim *)proxy->type->clientdata)(1, (swig_pg_value *)&proxy);
#endif
    }
  }
}

static swig_pg_value
SWIG_PG_NewPointerObj(void *ptr, swig_type_info *type, int owner) {
  if (ptr) {
    struct swig_pg_proxy *new_proxy;
    new_proxy = (struct swig_pg_proxy *) swig_pg_malloc(sizeof(struct swig_pg_proxy));
    new_proxy->pgtype = swig_type;
    new_proxy->type = type;
    new_proxy->object = ptr;
    new_proxy->own = owner & SWIG_POINTER_OWN;
    if (new_proxy->own) {
      swig_pg_add_finalizer(new_proxy, pg_free_swig, NULL);
    }
    return (swig_pg_value ) new_proxy;
  } else {
    return swig_pg_make_null();
  }
}

static int
SWIG_PG_ConvertPtr(swig_pg_value s, void **result, swig_type_info *type, int flags) {
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
SWIG_PG_MustGetPtr(swig_pg_value s, swig_type_info *type,
                         int argnum, int flags, const char *func_name,
                         int argc, swig_pg_value *argv) {
  void *result;
  if (SWIG_PG_ConvertPtr(s, &result, type, flags)) {
    swig_pg_wrong_type(func_name, type->str ? type->str : "void *", argnum - 1, argc, argv);
  }
  return result;
}

static SWIGINLINE void *
swig_pg_malloc_(size_t size, const char *func_name) {
  void *p = swig_pg_malloc(size);
  if (p == NULL)
    _swig_pg_signal_error("SWIG : memory error : %s", func_name);
  return p;
}

#ifndef swig_pg_make_inspector
#define swig_pg_make_inspector(x,y) \
        _swig_pg_apply(swig_pg_builtin_value("make-inspector"), x, y)
#endif

/* Function to create a new struct. */
static swig_pg_value
SWIG_PG_new_swig_pg_struct (SWIG_PG_Env* env, const char* basename,
				 int num_fields, char** field_names)
{
    swig_pg_value new_type;
    int count_out = 0, i = 0;
    swig_pg_value *struct_names;
    swig_pg_value *vals;
    swig_pg_value *a = (swig_pg_value *) \
        swig_pg_malloc(num_fields*sizeof(swig_pg_value ));

    for (i=0; i<num_fields; ++i) {
        a[i] = (swig_pg_value ) swig_pg_intern_symbol(field_names[i]);
    }

    new_type = swig_pg_make_struct_type(swig_pg_intern_symbol(basename),
                                       NULL /*super_type*/,
                                       swig_pg_make_inspector(0, NULL),
                                       num_fields,
                                       0 /* auto_fields */,
                                       NULL /* auto_val */,
                                       NULL /* properties */
#ifdef MZSCHEME30X
				       ,NULL /* Guard */
#endif
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

