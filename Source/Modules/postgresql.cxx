/* -----------------------------------------------------------------------------
 * This file is part of SWIG, which is licensed as a whole under version 3
 * (or any later version) of the GNU General Public License. Some additional
 * terms also apply to certain portions of SWIG. The full details of the SWIG
 * license and copyrights can be found in the LICENSE and COPYRIGHT files
 * included with the SWIG source code as distributed by the SWIG developers
 * and at https://www.swig.org/legal.html.
 *
 * postgresql.cxx
 *
 * PostgreSQL language module for SWIG.
 * ----------------------------------------------------------------------------- */

#include "swigmod.h"
#include <ctype.h>

static const char *usage = "\
PostgreSQL Options (available with -postgresql)\n\
     -declaremodule                - Create extension that declares a module\n\
     -dynamic-load <lib>,[lib,...] - Do not link with these libraries, dynamic load them\n\
     -noinit                       - Do not emit module initialization code\n\
     -prefix <name>                - Set a prefix <name> to be prepended to all names\n\
     -extension-name    <name>     - Set the name of the PG extension: default module name\n\
     -extension-version <version>  - Set the version of the PG extension\n\
     -extension-schema  <schema>   - Set the schema to use\n\
";

static String *fieldnames_tab = 0;
static String *convert_tab = 0;
static String *convert_proto_tab = 0;
static String *struct_name = 0;
static String *mangled_struct_name = 0;

static String *prefix = 0;
static bool declaremodule = false;
static bool noinit = false;
static String *load_libraries = NULL;
static String *module = 0;
static String *extension_name = 0;
static String *extension_version = 0;
static String *extension_schema = 0;
static String *extension_schema_prefix = 0;
static const char *postgresql_path = "postgresql";
static String *init_func_def = 0;

static File *f_begin = 0;
static File *f_runtime = 0;
static File *f_header = 0;
static File *f_wrappers = 0;
static File *f_init = 0;
static File *f_pg_sql = 0;
static File *f_pg_control = 0;
static File *f_pg_make = 0;
static File *f_pg_test = 0;

// Used for garbage collection
static int exporting_destructor = 0;
static String *swigtype_ptr = 0;
static String *cls_swigtype = 0;

class POSTGRESQL:public Language {
public:

  /* ------------------------------------------------------------
   * main()
   * ------------------------------------------------------------ */

  virtual void main(int argc, char *argv[]) {

    int i;

     SWIG_library_directory(postgresql_path);

    // Look for certain command line options
    for (i = 1; i < argc; i++) {
      if (argv[i]) {
	if (strcmp(argv[i], "-help") == 0) {
	  fputs(usage, stdout);
	  Exit(EXIT_SUCCESS);
	} else if (strcmp(argv[i], "-prefix") == 0) {
	  if (argv[i + 1]) {
	    prefix = NewString(argv[i + 1]);
	    Swig_mark_arg(i);
	    Swig_mark_arg(i + 1);
	    i++;
	  } else {
	    Swig_arg_error();
	  }
  } else if (strcmp(argv[i], "-extension-name") == 0) {
    if (argv[i + 1]) {
      extension_name = NewString(argv[i + 1]);
      Swig_mark_arg(i);
      Swig_mark_arg(i + 1);
      i++;
    } else {
      Swig_arg_error();
    }
  } else if (strcmp(argv[i], "-extension-version") == 0) {
    if (argv[i + 1]) {
      extension_version = NewString(argv[i + 1]);
      Swig_mark_arg(i);
      Swig_mark_arg(i + 1);
      i++;
    } else {
      Swig_arg_error();
    }
  } else if (strcmp(argv[i], "-extension-schema") == 0) {
    if (argv[i + 1]) {
      extension_schema = NewString(argv[i + 1]);
      Swig_mark_arg(i);
      Swig_mark_arg(i + 1);
      i++;
    } else {
      Swig_arg_error();
    }
	} else if (strcmp(argv[i], "-declaremodule") == 0) {
	  declaremodule = true;
	  Swig_mark_arg(i);
	} else if (strcmp(argv[i], "-noinit") == 0) {
	  noinit = true;
	  Swig_mark_arg(i);
	}
	else if (strcmp(argv[i], "-dynamic-load") == 0) {
	  if (argv[i + 1]) {
	    Delete(load_libraries);
	    load_libraries = NewString(argv[i + 1]);
	    Swig_mark_arg(i++);
	    Swig_mark_arg(i);
	  } else {
	    Swig_arg_error();
	  }
	}
      }
    }

    if ( ! extension_name ) extension_name = module;
    if ( ! extension_version ) extension_version = NewString("0.0.1");
    extension_schema_prefix = NewStringf(extension_schema ? "\"%s\"." : "", extension_schema);

    // If a prefix has been specified make sure it ends in a '_' (not actually used!)
    if (prefix) {
      const char *px = Char(prefix);
      if (px[Len(prefix) - 1] != '_')
	Printf(prefix, "_");
    } else
      prefix = NewString("swig_");

    // Add a symbol for this module

    Preprocessor_define("SWIGPOSTGRESQL 1", 0);

    // Set name of typemaps

    SWIG_typemap_lang("postgresql");

    // Read in default typemaps */
    SWIG_config_file("postgresql.swg");
    allow_overloading();

  }

  String* name_wrapper(String* name) {
    String* result = NewStringf("%s_%s", module, name);
    return result;
  }

  /* ------------------------------------------------------------
   * top()
   * ------------------------------------------------------------ */

  virtual int top(Node *n) {

    /* Initialize all of the output files */
    String *outfile = Getattr(n, "outfile");

    f_begin = NewFile(outfile, "w", SWIG_output_files());
    if (!f_begin) {
      FileErrorDisplay(outfile);
      Exit(EXIT_FAILURE);
    }
    f_runtime = NewString("");
    f_init = NewString("");
    f_header = NewString("");
    f_wrappers = NewString("");

    /* Register file targets with the SWIG file handler */
    Swig_register_filebyname("header", f_header);
    Swig_register_filebyname("wrapper", f_wrappers);
    Swig_register_filebyname("begin", f_begin);
    Swig_register_filebyname("runtime", f_runtime);

    init_func_def = NewString("");
    Swig_register_filebyname("init", init_func_def);

    Swig_banner(f_begin);

    Swig_obligatory_macros(f_runtime, "POSTGRESQL");

    module = Getattr(n, "name");
    if ( ! extension_name )     extension_name = module;
    if ( ! extension_version )  extension_version = NewString("0.0.1");

    String *outfile_pg_sql      = outputFileForSuffix(".", "");
    Printv(outfile_pg_sql,      "--", extension_version, ".sql", NIL);
    String *outfile_pg_control  = outputFileForSuffix(".", ".control");
    String *outfile_pg_make     = outputFileForSuffix(".", ".make");
    String *outfile_pg_test     = outputFileForSuffix("sql", "");
    Printv(outfile_pg_test,     "_test.sql", NIL);

    f_pg_sql      = NewFile(outfile_pg_sql,     "w", SWIG_output_files());
    f_pg_control  = NewFile(outfile_pg_control, "w", SWIG_output_files());
    f_pg_make     = NewFile(outfile_pg_make,    "w", SWIG_output_files());
    f_pg_test     = NewFile(outfile_pg_test,    "w", SWIG_output_files());

    begin_pg_sql(n);

    Printf(f_runtime, "\n");
    Printf(f_runtime, "static const char * swig_pg_extension_name_cstr    = \"%s\";\n", extension_name);
    Printf(f_runtime, "static const char * swig_pg_extension_version_cstr = \"%s\";\n", extension_version);
    Printf(f_runtime, "\n");

    Language::top(n);

    SwigType_emit_type_table(f_runtime, f_wrappers);

    if (!noinit) {
      if (declaremodule) {
	Printf(f_init, "#define SWIG_POSTGRESQL_CREATE_MENV(env) swig_pg_primitive_module(swig_pg_intern_symbol(\"%s\"), env)\n", module);
      } else {
	Printf(f_init, "#define SWIG_POSTGRESQL_CREATE_MENV(env) (env)\n");
      }
      Printf(f_init, "%s\n", Char(init_func_def));
      if (declaremodule) {
	Printf(f_init, "\tswig_pg_finish_primitive_module(menv);\n");
      }
      Printf(f_init, "\treturn swig_pg_void;\n}\n");
      Printf(f_init, "static Datum swig_pg_initialize(SWIG_PG_Env *env) {\n");

      if (load_libraries) {
	Printf(f_init, "swig_pg_set_dlopen_libraries(\"%s\");\n", load_libraries);
      }

      Printf(f_init, "\treturn swig_pg_reload(env);\n");
      Printf(f_init, "}\n");

      Printf(f_init, "static Datum swig_pg_module_name(void) {\n");
      if (declaremodule) {
	Printf(f_init, "   return swig_pg_intern_symbol((char*)\"%s\");\n", module);
      } else {
	Printf(f_init, "   return swig_pg_make_symbol((char*)\"%s\");\n", module);
      }
      Printf(f_init, "}\n");
    }

    create_pg_control(n);
    create_pg_make(n);
    create_pg_test(n);
    end_pg_sql(n);

    /* Close all of the files */
    Dump(f_runtime, f_begin);
    Dump(f_header, f_begin);
    Dump(f_wrappers, f_begin);
    Wrapper_pretty_print(f_init, f_begin);

    Delete(f_header);
    Delete(f_wrappers);
    Delete(f_init);
    Delete(f_runtime);
    Delete(f_begin);
    Delete(f_pg_sql);
    Delete(f_pg_control);
    Delete(f_pg_make);
    Delete(f_pg_test);
    return SWIG_OK;
  }

  String *outputFileForSuffix(const char* dir, const char *suffix) {
    return NewStringf("%s%s/%s%s", SWIG_output_directory(), dir, extension_name, suffix);
  }

  /* ------------------------------------------------------------
   * Generate control and make files for the module:
   */

  void generate_file(Node *n, String *f, const char *str) {
    String* tmpl = NewString(str);
    Replaceall(tmpl, "${extension_name}"   , extension_name);
    Replaceall(tmpl, "${extension_version}", extension_version);
    if ( extension_schema ) {
      Replaceall(tmpl, "${extension_schema}", extension_schema);
      Replaceall(tmpl, "${extension_schema_prefix}", extension_schema_prefix);
    }
    Printv(f, tmpl, NIL);
    Delete(tmpl);
  }

  void begin_pg_sql(Node *n) {
    generate_file(n, f_pg_sql,
      "-- -----------------------------------------------------\n"
      "-- ${extension_name}--${extension_version}.sql:\n\n");
    if ( extension_schema ) {
      Printf(f_pg_sql, "CREATE SCHEMA IF NOT EXISTS \"%s\";\n\n", extension_schema);
    }
  }

  void end_pg_sql(Node *n) {
    generate_file(n, f_pg_sql,
      "-- -----------------------------------------------------\n");
  }

  void create_pg_control(Node *n) {
    generate_file(n, f_pg_control,
      "########################################################\n"
      "# ${extension_name}.control:\n"
      "\n"
      "comment           = '${extension_name} extension'\n"
      "default_version   = '${extension_version}'\n"
      "relocatable       = true\n"
      "\n"
      "########################################################\n");
  }

  void create_pg_make(Node *n) {
    generate_file(n, f_pg_make,
      "########################################################\n"
      "# ${extension_name}.make:\n"
      "\n"
      "EXTENSION   = ${extension_name}\n"
      "DATA        = ${extension_name}--${extension_version}.sql\n"
      "# REGRESS     = ${extension_name}_test\n"
      "MODULES     = ${extension_name}\n"
      "PG_CFLAGS  += -Isrc\n"
      "PG_CONFIG   = pg_config\n"
      "PGXS       := $(shell $(PG_CONFIG) --pgxs)\n"
      "include $(PGXS)\n"
      "\n"
      "########################################################\n");
  }

  void create_pg_test(Node *n) {
    generate_file(n, f_pg_test,
      "-- -----------------------------------------------------\n"
      "-- ${extension_name}_test.sql:\n"
      "\n"
      "DROP EXTENSION IF EXISTS ${extension_name};\n"
      "CREATE EXTENSION ${extension_name};\n"
      "\n"
      "-- -----------------------------------------------------\n");
  }

  /* ------------------------------------------------------------
   * functionWrapper()
   * Create a function declaration and register it with the interpreter.
   * ------------------------------------------------------------ */

  void throw_unhandled_postgresql_type_error(SwigType *d) {
    Swig_warning(WARN_TYPEMAP_UNDEF, input_file, line_number, "Unable to handle type %s.\n", SwigType_str(d, 0));
  }

  /* Return true iff T is a pointer type */

  int
   is_a_pointer(SwigType *t) {
    return SwigType_ispointer(SwigType_typedef_resolve_all(t));
  }


  /* ------------------------------------------------------------
   * Postgres: CREATE FUNCTION declaration.
   * ------------------------------------------------------------ */

  int functionSql(Node *n, ParmList *l) {
    char *iname = GetChar(n, "sym:name");
    SwigType *d = Getattr(n, "type");

    String *rtn_pg_type   = Swig_typemap_lookup("pg_type",   n, Swig_cresult_name(), 0);
    String *rtn_pg_return = Swig_typemap_lookup("pg_return", n, Swig_cresult_name(), 0);
    String *pg_func = Getattr(n, "wrap:pg_func");
    String *pg_name = Getattr(n, "wrap:pg_name");
    String *extension_dir = NewString("");
    Printv(extension_dir, "$libdir/", module, NIL);

    Printf(f_pg_sql, "CREATE FUNCTION %s%s (", extension_schema_prefix, pg_name, NIL);
    if ( l )  {
      Parm *p;
      int i = 0;

      Swig_typemap_attach_parms("pg_type", l, 0);
      for ( p = l; p; i++) {
        String   *pname    = Getattr(p, "name");
        SwigType *pt       = Getattr(p, "type");
        String   *pg_type  = Getattr(p, "tmap:pg_type");
        if ( i > 0 )
          Printf(f_pg_sql, ",");
        Printf(f_pg_sql, "\n    \"%s\" %s", pname, pg_type);
      	p = Getattr(p, "tmap:in:next");
      }
      Printf(f_pg_sql, "\n");
    }
    Printf(f_pg_sql, "  )\n");
    Printf(f_pg_sql, "  RETURNS %s\n", rtn_pg_type, NIL);
    Printf(f_pg_sql, "  AS '%s', '%s'\n", extension_dir, pg_func, NIL);
    Printf(f_pg_sql, "  LANGUAGE C STRICT;\n\n", NIL);

    return 0;
  }

  virtual int functionWrapper(Node *n) {
    char *iname = GetChar(n, "sym:name");
    SwigType *d = Getattr(n, "type");
    ParmList *l = Getattr(n, "parms");
    Parm *p;

    Wrapper *f = NewWrapper();
    String *proc_name = NewString("");
    String *target = NewString("");
    String *arg = NewString("");
    String *cleanup = NewString("");
    String *outarg = NewString("");
    String *build = NewString("");
    String *tm;
    String *pg_return = 0;
    int i = 0;
    int numargs;
    int numreq;
    String *overname = 0;

    if (load_libraries) {
      ParmList *parms = Getattr(n, "parms");
      SwigType *type = Getattr(n, "type");
      String *name = NewString("caller");
      Setattr(n, "wrap:action", Swig_cresult(type, Swig_cresult_name(), Swig_cfunction_call(name, parms)));
    }

    // Make a wrapper name for this
    String *wname = name_wrapper(iname);
    if (Getattr(n, "sym:overloaded")) {
      overname = Getattr(n, "sym:overname");
    } else {
      if (!addSymbol(iname, n)) {
        DelWrapper(f);
	return SWIG_ERROR;
      }
    }
    if (overname) {
      Append(wname, overname);
    }
    Setattr(n, "wrap:name", wname);
    Setattr(n, "wrap:pg_name", iname);
    Setattr(n, "wrap:pg_func", wname);

    // Build the name of the function:
    Printv(proc_name, iname, NIL);

    // writing the function wrapper function
    Printv(f->def, "PG_FUNCTION_INFO_V1(", wname, ");\n", NIL);
    Printv(f->def, "Datum ", wname, "(PG_FUNCTION_ARGS) {\n", NIL);

    Printv(f->def, "#define FUNC_NAME \"", proc_name, "\"", NIL);

    Wrapper_add_local(f, "swig_pg_result", "Datum swig_pg_result = swig_pg_void");

    Printv(f->code, "  	PG_TRY();\n{\n", NIL);

    // Emit all of the local variables for holding arguments.
    emit_parameter_variables(l, f);

    /* Attach the standard typemaps */
    emit_attach_parmmaps(l, f);
    Setattr(n, "wrap:parms", l);

    argc_template_string = NewString("PG_NARGS()");
    argv_template_string = NewString("PG_GETARG_DATUM(%d)");

    numargs = emit_num_arguments(l);
    numreq = emit_num_required(l);

    /* Add the holder for the pointer to the function to be opened */
    if (load_libraries) {
      Wrapper_add_local(f, "_function_loaded", "static int _function_loaded=(1==0)");
      Wrapper_add_local(f, "_the_function", "static void *_the_function=NULL");
      {
	String *parms = ParmList_protostr(l);
	String *func = NewStringf("(*caller)(%s)", parms);
	Wrapper_add_local(f, "caller", SwigType_lstr(d, func));	/*"(*caller)()")); */
      }
    }

    if (load_libraries) {
      Printf(f->code, "if (!_function_loaded) { _the_function=postgresql_load_function(\"%s\");_function_loaded=(1==1); }\n", iname);
      Printf(f->code, "if (!_the_function) { swig_pg_signal_error(\"Cannot load C function '%s'\"); }\n", iname);
      Printf(f->code, "caller=_the_function;\n");
    }

    // Check number of arguments:
    Printf(f->code, "if ( PG_NARGS() < %d ) swig_pg_signal_error(\"not enough arguments : expected %%d : given %%d\", %d, PG_NARGS());\n", numreq, numreq);

    // Extract parameters:

    for (i = 0, p = l; i < numargs; i++) {
      /* Skip ignored arguments */

      while (checkAttribute(p, "tmap:in:numinputs", "0")) {
	p = Getattr(p, "tmap:in:next");
      }

      SwigType *pt = Getattr(p, "type");
      String *ln = Getattr(p, "lname");

      // ??? : TODO use PG_ARGISNULL(n) to check for nulls;
      // Produce names of source and target
      Clear(target);
      Clear(arg);
      String *source = NewStringf("PG_GETARG_DATUM(%d)", i);
      Printf(target, "%s", ln);
      Printv(arg, Getattr(p, "name"), NIL);

      // if (i >= numreq) {
	// Printf(f->code, "if (argc > %d) {\n", i);
      // }
      // Handle parameter types.
      if ((tm = Getattr(p, "tmap:in"))) {
	Replaceall(tm, "$input", source);
	Setattr(p, "emit:input", source);
	Printv(f->code, tm, "\n", NIL);
	p = Getattr(p, "tmap:in:next");
      } else {
	// no typemap found
	// check if typedef and resolve
	throw_unhandled_postgresql_type_error(pt);
	p = nextSibling(p);
      }
      if (i >= numreq) {
	Printf(f->code, "}\n");
      }
      Delete(source);
    }

    /* Insert constraint checking code */
    for (p = l; p;) {
      if ((tm = Getattr(p, "tmap:check"))) {
	Printv(f->code, tm, "\n", NIL);
	p = Getattr(p, "tmap:check:next");
      } else {
	p = nextSibling(p);
      }
    }

    // Pass output arguments back to the caller.

    for (p = l; p;) {
      if ((tm = Getattr(p, "tmap:argout"))) {
	Replaceall(tm, "$arg", Getattr(p, "emit:input"));
	Replaceall(tm, "$input", Getattr(p, "emit:input"));
	Printv(outarg, tm, "\n", NIL);
	p = Getattr(p, "tmap:argout:next");
      } else {
	p = nextSibling(p);
      }
    }

    // Free up any memory allocated for the arguments.

    /* Insert cleanup code */
    for (p = l; p;) {
      if ((tm = Getattr(p, "tmap:freearg"))) {
	Printv(cleanup, tm, "\n", NIL);
	p = Getattr(p, "tmap:freearg:next");
      } else {
	p = nextSibling(p);
      }
    }

    // Now write code to make the function call

    String *actioncode = emit_action(n);

    // Now have return value, figure out what to do with it.
    pg_return     = Swig_typemap_lookup    ("pg_return", n, Swig_cresult_name(), 0);
    tm            = Swig_typemap_lookup_out("out",       n, Swig_cresult_name(), f, actioncode);
    String *rtn = 0;

    if ( pg_return ) {
      rtn = NewString(pg_return);
      Replaceall(rtn, "$result", "result");
      Replaceall(tm, "$result", "result");
    } else if ( tm ) {
      rtn = NewString("return swig_pg_result");
      Replaceall(tm, "$result", "swig_pg_result");
      Replaceall(tm, "$owner", GetFlag(n, "feature:new") ? "1" : "0");
      Printv(f->code, tm, "\n", NIL);
    } else {
      throw_unhandled_postgresql_type_error(d);
    }
    emit_return_variable(n, d, f);

    // Dump the argument output code
    Printv(f->code, Char(outarg), NIL);

    // Dump the argument cleanup code
    Printv(f->code, Char(cleanup), NIL);

    // Look for any remaining cleanup
    if ( GetFlag(n, "feature:new") && (tm = Swig_typemap_lookup("newfree", n, Swig_cresult_name(), 0)) ) {
	Printv(f->code, tm, "\n", NIL);
    }

    // Free any memory allocated by the function being wrapped..
    if ((tm = Swig_typemap_lookup("ret", n, Swig_cresult_name(), 0))) {
      Printv(f->code, tm, "\n", NIL);
    }

    Printv(f->code, "  }\n  PG_CATCH();\n  {\n", NIL);

    // TODO: do something with the error message?
    Printv(f->code, "    ", "swig_pg_signal_error(\"Error in C function\");\n");
    Printv(f->code, "  }\n  PG_END_TRY();\n", NIL);

    Printv(f->code, "  ", rtn, ";\n", NIL);

    Printv(f->code, "#undef FUNC_NAME\n", NIL);
    Printv(f->code, "}\n", NIL);

    /* Substitute the function name */
    Replaceall(f->code, "$symname", iname);

    Wrapper_print(f, f_wrappers);

    if (!Getattr(n, "sym:overloaded")) {

      // Now register the function
      char temp[256];
      sprintf(temp, "%d", numargs);
      if (exporting_destructor) {
	Printf(init_func_def, "SWIG_TypeClientData(SWIGTYPE%s, (void *) %s);\n", swigtype_ptr, wname);
      }
      Printf(init_func_def, "swig_pg_add_global(\"%s\", swig_pg_make_prim_w_arity(%s,\"%s\",%d,%d),menv);\n", proc_name, wname, proc_name, numreq, numargs);
    } else {
      if (!Getattr(n, "sym:nextSibling")) {
	/* Emit overloading dispatch function */

	int maxargs;
  // ??? : FIXME
	String *dispatch = Swig_overload_dispatch(n, "return %s(swig_PG_FUNCTION_PARAMS);", &maxargs);

	/* Generate a dispatch wrapper for all overloaded functions */

	Wrapper *df = NewWrapper();
	String *dname = name_wrapper(iname);

  Printv(f->def, "PG_FUNCTION_INFO_V1(", dname, ");\n", NIL);
	Printv(df->def, "Datum\n", dname, "(PG_FUNCTION_ARGS) {", NIL);
	Printv(df->code, dispatch, "\n", NIL);
	Printf(df->code, "swig_pg_signal_error(\"No matching function for overloaded '%s'\");\n", iname);
	Printf(df->code, "return swig_pg_void;\n");
	Printv(df->code, "}\n", NIL);
	Wrapper_print(df, f_wrappers);
	Printf(init_func_def, "swig_pg_add_global(\"%s\", swig_pg_make_prim_w_arity(%s,\"%s\",%d,%d),menv);\n", proc_name, dname, proc_name, 0, maxargs);
	DelWrapper(df);
	Delete(dispatch);
	Delete(dname);
      }
    }

    functionSql(n, l);

    Delete(proc_name);
    Delete(target);
    Delete(arg);
    Delete(outarg);
    Delete(cleanup);
    Delete(build);
    Delete(pg_return);
    DelWrapper(f);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * variableWrapper()
   *
   * Create a link to a C variable.
   * This creates a single function _wrap_swig_var_varname().
   * This function takes a single optional argument.   If supplied, it means
   * we are setting this variable to some value.  If omitted, it means we are
   * simply evaluating this variable.  Either way, we return the variables
   * value.
   * ------------------------------------------------------------ */


  virtual int variableWrapper(Node *n) {
    char *name = GetChar(n, "name");
    char *iname = GetChar(n, "sym:name");
    SwigType *t = Getattr(n, "type");

    String *proc_name = NewString("");
    String *tm;
    String *tm2 = NewString("");
    String *argnum = NewString("0");
    String *arg = NewString("PG_GETARG_DATUM(0)");
    Wrapper *f;

    if (!addSymbol(iname, n))
      return SWIG_ERROR;

    f = NewWrapper();

    // evaluation function names
    String *var_name = name_wrapper(iname);

    Printv(proc_name, iname, NIL);
    Setattr(n, "wrap:name", proc_name);
    Setattr(n, "wrap:pg_name", iname);
    Setattr(n, "wrap:pg_func", var_name);

    if ((SwigType_type(t) != T_USER) || (is_a_pointer(t))) {
      Printf(f->def, "PG_FUNCTION_INFO_V1(%s);\n", var_name);
      Printf(f->def, "Datum %s(PG_FUNCTION_ARGS) {\n", var_name);
      Printv(f->def, "#define FUNC_NAME \"", proc_name, "\"", NIL);

      Wrapper_add_local(f, "swig_pg_result", "Datum swig_pg_result = swig_pg_void");

      if (!GetFlag(n, "feature:immutable")) {
      	/* Check for a setting of the variable value */
	Printf(f->code, "if (PG_NARGS()) {\n");
	if ((tm = Swig_typemap_lookup("varin", n, name, 0))) {
	  Replaceall(tm, "$input", "PG_GETARG_DATUM(0)");
	  Replaceall(tm, "$argnum", "1");
	  emit_action_code(n, f->code, tm);
	} else {
	  throw_unhandled_postgresql_type_error(t);
	}
	Printf(f->code, "}\n");
      }
      // Now return the value of the variable (regardless
      // of evaluating or setting)

      if ((tm = Swig_typemap_lookup("varout", n, name, 0))) {
	Replaceall(tm, "$result", "swig_pg_result");
	/* Printf (f->code, "%s\n", tm); */
	emit_action_code(n, f->code, tm);
      } else {
	throw_unhandled_postgresql_type_error(t);
      }
      Printf(f->code, "\nreturn swig_pg_result;\n");
      Printf(f->code, "#undef FUNC_NAME\n");
      Printf(f->code, "}\n");

      Wrapper_print(f, f_wrappers);
    } else {
      Swig_warning(WARN_TYPEMAP_VAR_UNDEF, input_file, line_number, "Unsupported variable type %s (ignored).\n", SwigType_str(t, 0));
    }

    functionSql(n, 0);

    Delete(var_name);
    Delete(proc_name);
    Delete(argnum);
    Delete(arg);
    Delete(tm2);
    DelWrapper(f);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * constantWrapper()
   * ------------------------------------------------------------ */

  virtual int constantWrapper(Node *n) {
    char *name = GetChar(n, "name");
    char *iname = GetChar(n, "sym:name");
    SwigType *type = Getattr(n, "type");
    String *value = Getattr(n, "value");

    String *var_name = NewString("");
    String *proc_name = NewString("");
    String *rvalue = NewString("");
    String *temp = NewString("");
    String *tm;

    // Make a static variable;

    Printf(var_name, "_wrap_const_%s", Swig_name_mangle_string(Getattr(n, "sym:name")));

    Printv(proc_name, iname, NIL);

    if ((SwigType_type(type) == T_USER) && (!is_a_pointer(type))) {
      Swig_warning(WARN_TYPEMAP_CONST_UNDEF, input_file, line_number, "Unsupported constant value.\n");
      return SWIG_NOWRAP;
    }
    // See if there's a typemap

    Printv(rvalue, value, NIL);
    if ((SwigType_type(type) == T_CHAR) && (is_a_pointer(type) == 1)) {
      temp = Copy(rvalue);
      Clear(rvalue);
      Printv(rvalue, "\"", temp, "\"", NIL);
    }
    if ((SwigType_type(type) == T_CHAR) && (is_a_pointer(type) == 0)) {
      Delete(temp);
      temp = Copy(rvalue);
      Clear(rvalue);
      Printv(rvalue, "'", temp, "'", NIL);
    }
    if ((tm = Swig_typemap_lookup("constant", n, name, 0))) {
      Replaceall(tm, "$value", rvalue);
      Printf(f_init, "%s\n", tm);
    } else {
      // Create variable and assign it a value

      Printf(f_header, "static %s = ", SwigType_lstr(type, var_name));
      bool is_enum_item = (Cmp(nodeType(n), "enumitem") == 0);
      if ((SwigType_type(type) == T_STRING)) {
	Printf(f_header, "\"%s\";\n", value);
      } else if (SwigType_type(type) == T_CHAR && !is_enum_item) {
	Printf(f_header, "\'%s\';\n", value);
      } else {
	Printf(f_header, "%s;\n", value);
      }

      // Now create a variable declaration

      {
	/* Hack alert: will cleanup later -- Dave */
	Node *nn = NewHash();
	Setfile(nn, Getfile(n));
	Setline(nn, Getline(n));
	Setattr(nn, "name", var_name);
	Setattr(nn, "sym:name", iname);
	Setattr(nn, "type", type);
	SetFlag(nn, "feature:immutable");
	variableWrapper(nn);
	Delete(nn);
      }
    }
    Delete(proc_name);
    Delete(rvalue);
    Delete(temp);
    return SWIG_OK;
  }

  virtual int destructorHandler(Node *n) {
    exporting_destructor = true;
    Language::destructorHandler(n);
    exporting_destructor = false;
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * classHandler()
   * ------------------------------------------------------------ */
  virtual int classHandler(Node *n) {
    String *scm_structname = NewString("");
    SwigType *ctype_ptr = NewStringf("p.%s", getClassType());

    SwigType *t = NewStringf("p.%s", Getattr(n, "name"));
    swigtype_ptr = SwigType_manglestr(t);
    Delete(t);

    cls_swigtype = SwigType_manglestr(Getattr(n, "name"));


    fieldnames_tab = NewString("");
    convert_tab = NewString("");
    convert_proto_tab = NewString("");

    struct_name = Getattr(n, "sym:name");
    mangled_struct_name = Swig_name_mangle_string(Getattr(n, "sym:name"));

    Printv(scm_structname, struct_name, NIL);
    Replaceall(scm_structname, "_", "-");

    Printv(fieldnames_tab, "static const char *_swig_struct_", cls_swigtype, "_field_names[] = { \n", NIL);

    Printv(convert_proto_tab, "static Datum_swig_convert_struct_", cls_swigtype, "(", SwigType_str(ctype_ptr, "ptr"), ");\n", NIL);

    Printv(convert_tab, "static Datum_swig_convert_struct_", cls_swigtype, "(", SwigType_str(ctype_ptr, "ptr"), ")\n {\n", NIL);

    Printv(convert_tab,
	   tab4, "Datum obj;\n", tab4, "Datum fields[_swig_struct_", cls_swigtype, "_field_names_cnt];\n", tab4, "int i = 0;\n\n", NIL);

    /* Generate normal wrappers */
    Language::classHandler(n);

    Printv(convert_tab, tab4, "obj = swig_pg_make_struct_instance(", "_swig_struct_type_", cls_swigtype, ", i, fields);\n", NIL);
    Printv(convert_tab, tab4, "return obj;\n}\n\n", NIL);

    Printv(fieldnames_tab, "};\n", NIL);

    Printv(f_header, "static Datum_swig_struct_type_", cls_swigtype, ";\n", NIL);

    Printv(f_header, fieldnames_tab, NIL);
    Printv(f_header, "#define  _swig_struct_", cls_swigtype, "_field_names_cnt (sizeof(_swig_struct_", cls_swigtype, "_field_names)/sizeof(char*))\n", NIL);

    Printv(f_header, convert_proto_tab, NIL);
    Printv(f_wrappers, convert_tab, NIL);

    Printv(init_func_def, "_swig_struct_type_", cls_swigtype,
	   " = SWIG_POSTGRESQL_new_swig_pg_struct(menv, \"", scm_structname, "\", ",
	   "_swig_struct_", cls_swigtype, "_field_names_cnt,", "(char**) _swig_struct_", cls_swigtype, "_field_names);\n", NIL);

    Delete(swigtype_ptr);
    swigtype_ptr = 0;
    Delete(fieldnames_tab);
    Delete(convert_tab);
    Delete(ctype_ptr);
    Delete(convert_proto_tab);
    struct_name = 0;
    mangled_struct_name = 0;
    Delete(cls_swigtype);
    cls_swigtype = 0;

    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * membervariableHandler()
   * ------------------------------------------------------------ */

  virtual int membervariableHandler(Node *n) {
    Language::membervariableHandler(n);

    if (!is_smart_pointer()) {
      String *symname = Getattr(n, "sym:name");
      String *name = Getattr(n, "name");
      SwigType *type = Getattr(n, "type");
      String *swigtype = SwigType_manglestr(Getattr(n, "type"));
      String *tm = 0;
      String *access_mem = NewString("");
      SwigType *ctype_ptr = NewStringf("p.%s", Getattr(n, "type"));

      Printv(fieldnames_tab, tab4, "\"", symname, "\",\n", NIL);
      Printv(access_mem, "(ptr)->", name, NIL);
      if ((SwigType_type(type) == T_USER) && (!is_a_pointer(type))) {
	Printv(convert_tab, tab4, "fields[i++] = ", NIL);
	Printv(convert_tab, "_swig_convert_struct_", swigtype, "((", SwigType_str(ctype_ptr, 0), ")&((ptr)->", name, "));\n", NIL);
      } else if ((tm = Swig_typemap_lookup("varout", n, access_mem, 0))) {
	Replaceall(tm, "$result", "fields[i++]");
	Printv(convert_tab, tm, "\n", NIL);
      } else
	Swig_warning(WARN_TYPEMAP_VAR_UNDEF, input_file, line_number, "Unsupported member variable type %s (ignored).\n", SwigType_str(type, 0));

      Delete(access_mem);
    }
    return SWIG_OK;
  }


  String *runtimeCode() {
    String *s = Swig_include_sys("postgresql_run.swg");
    if (!s) {
      Printf(stderr, "*** Unable to open 'postgresql_run.swg'\n");
      s = NewString("");
    }
    return s;
  }

  String *defaultExternalRuntimeFilename() {
    return NewString("swig_posgresql_run.h");
  }
};

/* -----------------------------------------------------------------------------
 * swig_postgresql()    - Instantiate module
 * ----------------------------------------------------------------------------- */

static Language *new_swig_postgresql() {
  return new POSTGRESQL();
}
extern "C" Language *swig_postgresql(void) {
  return new_swig_postgresql();
}
