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

/*
#include "server/c.h"
#include "server/utils/palloc.h"
#include "server/fmgr.h"
*/

// See: http://big-elephants.com/2015-10/writing-postgres-extensions-part-i/
#include "postgres.h"
#include "c.h"
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
  fprintf(stderr, "ERROR : SWIG : %s : ", swig_pg_module_name_cstr);
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

#if defined(_WIN32) || defined(__WIN32__)
#define __OS_WIN32
#endif

#ifdef __OS_WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

  static char **pg_dlopen_libraries=NULL;
  static void **pg_libraries=NULL;
  static char **pg_dynload_libpaths=NULL;

  static void pg_set_dlopen_libraries(const char *_libs)
  {
    int   i,k,n;
    int   pg_dynload_debug=(1==0);
    char *extra_paths[1000];
    char *EP;

    {
      char *dbg=getenv("MZ_DYNLOAD_DEBUG");
      if (dbg!=NULL) {
	pg_dynload_debug=atoi(dbg);
      }
    }

    {
      char *ep=getenv("MZ_DYNLOAD_LIBPATH");
      int   i,k,j;
      k=0;
      if (ep!=NULL) {
	EP=strdup(ep);
	for(i=0,j=0;EP[i]!='\0';i++) {
	  if (EP[i]==':') {
	    EP[i]='\0';
	    extra_paths[k++]=&EP[j];
	    j=i+1;
	  }
	}
	if (j!=i) {
	  extra_paths[k++]=&EP[j];
	}
      }
      else {
	EP=strdup("");
      }
      extra_paths[k]=NULL;
      k+=1;

      if (pg_dynload_debug) {
	fprintf(stderr,"SWIG:pg:MZ_DYNLOAD_LIBPATH=%s\n",(ep==NULL) ? "(null)" : ep);
	fprintf(stderr,"SWIG:pg:extra_paths[%d]\n",k-1);
	for(i=0;i<k-1;i++) {
	  fprintf(stderr,"SWIG:pg:extra_paths[%d]=%s\n",i,extra_paths[i]);
	}
      }

      pg_dynload_libpaths=(char **) malloc(sizeof(char *)*k);
      for(i=0;i<k;i++) {
	if (extra_paths[i]!=NULL) {
	  pg_dynload_libpaths[i]=strdup(extra_paths[i]);
	}
	else {
	  pg_dynload_libpaths[i]=NULL;
	}
      }

      if (pg_dynload_debug) {
	int i;
	for(i=0;extra_paths[i]!=NULL;i++) {
	  fprintf(stderr,"SWIG:postgresql:%s\n",extra_paths[i]);
	}
      }
    }

    {
#ifdef MZ_DYNLOAD_LIBS
      char *libs=(char *) malloc((strlen(MZ_DYNLOAD_LIBS)+1)*sizeof(char));
      strcpy(libs,MZ_DYNLOAD_LIBS);
#else
      char *libs=(char *) malloc((strlen(_libs)+1)*sizeof(char));
      strcpy(libs,_libs);
#endif

      for(i=0,n=strlen(libs),k=0;i<n;i++) {
	if (libs[i]==',') { k+=1; }
      }
      k+=1;
      pg_dlopen_libraries=(char **) malloc(sizeof(char *)*(k+1));
      pg_dlopen_libraries[0]=libs;
      for(i=0,k=1,n=strlen(libs);i<n;i++) {
	if (libs[i]==',') {
	  libs[i]='\0';
	  pg_dlopen_libraries[k++]=&libs[i+1];
	  i+=1;
	}
      }

      if (pg_dynload_debug) {
	fprintf(stderr,"k=%d\n",k);
      }
      pg_dlopen_libraries[k]=NULL;

      free(EP);
    }
  }

  static void *pg_load_function(char *function)
  {
    int pg_dynload_debug=(1==0);

    {
      char *dbg=getenv("MZ_DYNLOAD_DEBUG");
      if (dbg!=NULL) {
	pg_dynload_debug=atoi(dbg);
      }
    }

    if (pg_dlopen_libraries==NULL) {
      return NULL;
    }
    else {
      if (pg_libraries==NULL) {
        int i,n;
        for(n=0;pg_dlopen_libraries[n]!=NULL;n++);
	if (pg_dynload_debug) {
	  fprintf(stderr,"SWIG:postgresql:n=%d\n",n);
	}
        pg_libraries=(void **) malloc(sizeof(void*)*n);
        for(i=0;i<n;i++) {
	  if (pg_dynload_debug) {
	   fprintf(stderr,"SWIG:postgresql:loading %s\n",pg_dlopen_libraries[i]);
	  }
#ifdef __OS_WIN32
	  pg_libraries[i]=(void *) LoadLibrary(pg_dlopen_libraries[i]);
#else
	  pg_libraries[i]=(void *) dlopen(pg_dlopen_libraries[i],RTLD_LAZY);
#endif
	  if (pg_libraries[i]==NULL) {
	    int k;
	    char *libp;
	    for(k=0;pg_dynload_libpaths[k]!=NULL && pg_libraries[i]==NULL;k++) {
	      int L=strlen(pg_dynload_libpaths[k])+strlen("\\")+strlen(pg_dlopen_libraries[i])+1;
	      libp=(char *) malloc(L*sizeof(char));
#ifdef __OS_WIN32
	      sprintf(libp,"%s\\%s",pg_dynload_libpaths[k],pg_dlopen_libraries[i]);
	      pg_libraries[i]=(void *) LoadLibrary(libp);
#else
	      sprintf(libp,"%s/%s",pg_dynload_libpaths[k],pg_dlopen_libraries[i]);
	      pg_libraries[i]=(void *) dlopen(libp,RTLD_LAZY);
#endif
	      if (pg_dynload_debug) {
		fprintf(stderr,"SWIG:postgresql:trying %s --> %p\n",libp,pg_libraries[i]);
	      }
	      free(libp);
	    }
	  }
        }
      }
      {
        int i;
        void *func=NULL;

        for(i=0;pg_dlopen_libraries[i]!=NULL && func==NULL;i++) {
          if (pg_libraries[i]!=NULL) {
#ifdef __OS_WIN32
            func=GetProcAddress(pg_libraries[i],function);
#else
            func=dlsym(pg_libraries[i],function);
#endif
          }
	  if (pg_dynload_debug) {
	    fprintf(stderr,
		    "SWIG:postgresql:library:%s;dlopen=%p,function=%s,func=%p\n",
		    pg_dlopen_libraries[i],pg_libraries[i],function,func
		    );
	  }
        }

        return func;
      }
    }
  }

/* The interpreter will store a pointer to this structure in a global
   variable called swig-runtime-data-type-pointer.  The instance of this
   struct is only used if no other module has yet been loaded */
struct swig_pg_runtime_data {
  swig_module_info *module_head;
  SWIG_PG_Type type;
};
static struct swig_pg_runtime_data swig_pg_runtime_data;


static swig_module_info *
SWIG_PG_GetModule(SWIG_PG_Env *env) {
  swig_pg_value pointer, symbol;
  struct swig_pg_runtime_data *data;

  /* first check if pointer already created */
  symbol = swig_pg_intern_symbol("swig-runtime-data-type-pointer" SWIG_RUNTIME_VERSION SWIG_TYPE_TABLE_NAME);
  pointer = swig_pg_lookup_global(symbol, env);
  if (pointer && SWIG_PG_CPTRP(pointer)) {
      data = (struct swig_pg_runtime_data *) SWIG_PG_CPTR_VAL(pointer);
      swig_type = data->type;
      return data->module_head;
  } else {
      return NULL;
  }
}

static void
SWIG_PG_SetModule(SWIG_PG_Env *env, swig_module_info *module) {
  swig_pg_value pointer, symbol;
  struct swig_pg_runtime_data *data;

  /* first check if pointer already created */
  symbol = swig_pg_intern_symbol("swig-runtime-data-type-pointer" SWIG_RUNTIME_VERSION SWIG_TYPE_TABLE_NAME);
  pointer = swig_pg_lookup_global(symbol, env);
  if (pointer && SWIG_PG_CPTRP(pointer)) {
    data = (struct swig_pg_runtime_data *) SWIG_PG_CPTR_VAL(pointer);
    swig_type = data->type;
    data->module_head = module;
  } else {
    /* create a new type for wrapped pointer values */
    swig_type = swig_pg_make_type((char *)"swig");
    swig_pg_runtime_data.module_head = module;
    swig_pg_runtime_data.type = swig_type;

    /* create a new pointer */
#ifndef MZSCHEME30X
    pointer = swig_pg_make_cptr((void *) &swig_pg_runtime_data, "swig_pg_runtime_data");
#else
    pointer = swig_pg_make_cptr((void *) &swig_pg_runtime_data,
			       swig_pg_make_byte_string("swig_pg_runtime_data"));
#endif
    swig_pg_add_global_symbol(symbol, pointer, env);
  }
}

#ifdef __cplusplus
}
#endif

