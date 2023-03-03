/* -----------------------------------------------------------------------------
 * typemaps.i
 * ----------------------------------------------------------------------------- */

#define %set_output(obj)                  $result = obj
#define %set_varoutput(obj)               $result = obj
#define %argument_fail(code, type, name, argn)	swig_pg_wrong_type(FUNC_NAME, type, argn, argc, argv)
#define %as_voidptr(ptr)		(void*)(ptr)


/* The postgresql module handles all types uniformly via typemaps. Here
   are the definitions.  */

/* Pointers */

%typemap(in) SWIGTYPE * {
  $1 = ($ltype) SWIG_MustGetPtr($input, $descriptor, $argnum, 0);
}

%typemap(in) void * {
  $1 = SWIG_MustGetPtr($input, NULL, $argnum, 0);
}

%typemap(varin) SWIGTYPE * {
  $1 = ($ltype) SWIG_MustGetPtr($input, $descriptor, 1, 0);
}

%typemap(varin) SWIGTYPE & {
  $1 = *(($1_ltype)SWIG_MustGetPtr($input, $descriptor, 1, 0));
}

%typemap(varin) SWIGTYPE && {
  $1 = *(($1_ltype)SWIG_MustGetPtr($input, $descriptor, 1, 0));
}

%typemap(varin) SWIGTYPE [ANY] {
  void *temp;
  int ii;
  $1_basetype *b = 0;
  temp = SWIG_MustGetPtr($input, $1_descriptor, 1, 0);
  b = ($1_basetype *) $1;
  for (ii = 0; ii < $1_size; ii++) b[ii] = *(($1_basetype *) temp + ii);
}


%typemap(varin) void * {
  $1 = SWIG_MustGetPtr($input, NULL, 1, 0);
}

%typemap(out) SWIGTYPE * {
  $result = SWIG_NewPointerObj ($1, $descriptor, $owner);
}

%typemap(out) SWIGTYPE *DYNAMIC {
  swig_type_info *ty = SWIG_TypeDynamicCast($1_descriptor,(void **) &$1);
  $result = SWIG_NewPointerObj ($1, ty, $owner);
}

%typemap(varout) SWIGTYPE *, SWIGTYPE [] {
  $result = SWIG_NewPointerObj ($1, $descriptor, 0);
}

%typemap(varout) SWIGTYPE & {
  $result = SWIG_NewPointerObj((void *) &$1, $1_descriptor, 0);
}

%typemap(varout) SWIGTYPE && {
  $result = SWIG_NewPointerObj((void *) &$1, $1_descriptor, 0);
}

/* C++ References */

#ifdef __cplusplus

%typemap(in) SWIGTYPE & {
  $1 = ($ltype) SWIG_MustGetPtr($input, $descriptor, $argnum, 0);
  if ($1 == NULL) swig_pg_signal_error(FUNC_NAME ": swig-type-error (null reference)");
}

%typemap(in, noblock=1, fragment="<memory>") SWIGTYPE && (void *argp = 0, int res = 0, std::unique_ptr<$*1_ltype> rvrdeleter) {
  res = SWIG_ConvertPtr($input, &argp, $descriptor, SWIG_POINTER_RELEASE);
  if (!SWIG_IsOK(res)) {
    if (res == SWIG_ERROR_RELEASE_NOT_OWNED) {
      swig_pg_signal_error(FUNC_NAME ": cannot release ownership as memory is not owned for argument $argnum of type '$1_type'");
    } else {
      %argument_fail(res, "$1_type", $symname, $argnum);
    }
  }
  if (argp == NULL) swig_pg_signal_error(FUNC_NAME ": swig-type-error (null reference)");
  $1 = ($1_ltype)argp;
  rvrdeleter.reset($1);
}

%typemap(out) SWIGTYPE &, SWIGTYPE && {
  $result = SWIG_NewPointerObj ($1, $descriptor, $owner);
}

%typemap(out) SWIGTYPE &DYNAMIC {
  swig_type_info *ty = SWIG_TypeDynamicCast($1_descriptor,(void **) &$1);
  $result = SWIG_NewPointerObj ($1, ty, $owner);
}

#endif

/* Arrays */

%typemap(in) SWIGTYPE[] {
  $1 = ($ltype) SWIG_MustGetPtr($input, $descriptor, $argnum, 0);
}

%typemap(out) SWIGTYPE[] {
  $result = SWIG_NewPointerObj ($1, $descriptor, $owner);
}

/* Enums */
%typemap(in) enum SWIGTYPE {
  if (!SWIG_is_integer($input))
      swig_pg_wrong_type(FUNC_NAME, "integer", $argnum - 1, argc, argv);
  $1 = ($1_type) SWIG_convert_int($input);
}

%typemap(varin) enum SWIGTYPE {
  if (!SWIG_is_integer($input))
      swig_pg_wrong_type(FUNC_NAME, "integer", 0, argc, argv);
  $1 = ($1_type) SWIG_convert_int($input);
}

%typemap(out) enum SWIGTYPE "$result = postgresql_make_integer_value($1);"
%typemap(varout) enum SWIGTYPE "$result = postgresql_make_integer_value($1);"


/* Pass-by-value */

%typemap(in) SWIGTYPE($&1_ltype argp) {
  argp = ($&1_ltype) SWIG_MustGetPtr($input, $&1_descriptor, $argnum, 0);
  $1 = *argp;
}

%typemap(varin) SWIGTYPE {
  $&1_ltype argp;
  argp = ($&1_ltype) SWIG_MustGetPtr($input, $&1_descriptor, 1, 0);
  $1 = *argp;
}


%typemap(out) SWIGTYPE
#ifdef __cplusplus
{
  $&1_ltype resultptr;
  resultptr = new $1_ltype($1);
  $result =  SWIG_NewPointerObj (resultptr, $&1_descriptor, 1);
}
#else
{
  $&1_ltype resultptr;
  resultptr = ($&1_ltype) swig_pg_malloc(sizeof($1_type));
  memmove(resultptr, &$1, sizeof($1_type));
  $result = SWIG_NewPointerObj(resultptr, $&1_descriptor, 1);
}
#endif

%typemap(varout) SWIGTYPE
#ifdef __cplusplus
{
  $&1_ltype resultptr;
  resultptr = new $1_ltype($1);
  $result =  SWIG_NewPointerObj(resultptr, $&1_descriptor, 0);
}
#else
{
  $&1_ltype resultptr;
  resultptr = ($&1_ltype) swig_pg_malloc(sizeof($1_type));
  memmove(resultptr, &$1, sizeof($1_type));
  $result = SWIG_NewPointerObj(resultptr, $&1_descriptor, 0);
}
#endif

/* The SIMPLE_MAP macro below defines the whole set of typemaps needed
   for simple types. */

%define SIMPLE_MAP(C_NAME, PG_PREDICATE, PG_TO_C, C_TO_PG, PG_NAME)
%typemap(in) C_NAME {
    $1 = PG_TO_C($input);
}
%typemap(varin) C_NAME {
    $1 = PG_TO_C($input);
}
%typemap(out) C_NAME {
    $result = C_TO_PG($1);
}
%typemap(varout) C_NAME {
    $result = C_TO_PG($1);
}
%typemap(in) C_NAME *INPUT (C_NAME temp) {
    temp = (C_NAME) PG_TO_C($input);
    $1 = &temp;
}
%typemap(in,numinputs=0) C_NAME *OUTPUT (C_NAME temp) {
    $1 = &temp;
}
%typemap(argout) C_NAME *OUTPUT {
    swig_pg_value  s;
    s = C_TO_PG(*$1);
    SWIG_APPEND_VALUE(s);
}
%typemap(in) C_NAME *BOTH = C_NAME *INPUT;
%typemap(argout) C_NAME *BOTH = C_NAME *OUTPUT;
%typemap(in) C_NAME *INOUT = C_NAME *INPUT;
%typemap(argout) C_NAME *INOUT = C_NAME *OUTPUT;
%enddef

SIMPLE_MAP(bool, SWIG_PG_BOOLP,
     DatumGetBool, BoolGetDatum, boolean);
// ??? Handle with DatumGetVarCharP, CStringGetDatum
SIMPLE_MAP(char, SWIG_PG_CHARP,
     DatumGetInt32, Int32GetDatum, character);
SIMPLE_MAP(unsigned char, SWIG_PG_CHARP,
     DatumGetUInt32, UInt32GetDatum, character);
SIMPLE_MAP(int, SWIG_is_integer,
     DatumGetInt32, Int32GetDatum, integer);
SIMPLE_MAP(short, SWIG_is_integer,
     DatumGetInt32, Int32GetDatum, integer);
SIMPLE_MAP(long, SWIG_is_integer,
     DatumGetInt64, Int64GetDatum, integer);
SIMPLE_MAP(ptrdiff_t, SWIG_is_integer, DatumGetInt64,
	   DatumGetInt32, integer);
SIMPLE_MAP(unsigned int, SWIG_is_unsigned_integer,
     DatumGetUInt32, UInt32GetDatum, integer);
SIMPLE_MAP(unsigned short, SWIG_is_unsigned_integer,
     DatumGetUInt32, UInt32GetDatum, integer);
SIMPLE_MAP(unsigned long, SWIG_is_unsigned_integer,
     DatumGetUInt64, UInt64GetDatum, integer);
SIMPLE_MAP(size_t, SWIG_is_unsigned_integer,
     DatumGetUInt64, DatumGetUInt64, integer);
SIMPLE_MAP(float, SWIG_PG_REALP,
     DatumGetFloat4, Float4GetDatum, real);
SIMPLE_MAP(double, SWIG_PG_REALP,
     DatumGetFloat8, Float8GetDatum, real);

// ??? memory mgmt?
SIMPLE_MAP(char *, SWIG_PG_STRINGP,
     DatumGetVarCharP, CStringGetDatum, string);
SIMPLE_MAP(const char *, SWIG_PG_STRINGP,
     DatumGetVarCharP, CStringGetDatum, string);

/* For MzScheme 30x:  Use these typemaps if you are not going to use
   UTF8 encodings in your C code.
 SIMPLE_MAP(char *,SWIG_PG_BYTE_STRINGP, SWIG_PG_BYTE_STR_VAL,
 	   swig_pg_make_byte_string_without_copying,bytestring);
 SIMPLE_MAP(const char *,SWIG_PG_BYTE_STRINGP, SWIG_PG_BYTE_STR_VAL,
 	   swig_pg_make_byte_string_without_copying,bytestring);
*/

/* Const primitive references.  Passed by value */

%define REF_MAP(C_NAME, PG_PREDICATE, PG_TO_C, C_TO_PG, PG_NAME)
  %typemap(in) const C_NAME & (C_NAME temp) {
     if (!PG_PREDICATE($input))
        swig_pg_wrong_type(FUNC_NAME, #PG_NAME, $argnum - 1, argc, argv);
     temp = PG_TO_C($input);
     $1 = &temp;
  }
  %typemap(out) const C_NAME & {
    $result = C_TO_PG(*$1);
  }
%enddef

REF_MAP(bool, SWIG_PG_BOOLP, SWIG_PG_TRUEP,
	   swig_make_boolean, boolean);
REF_MAP(char, SWIG_PG_CHARP, SWIG_PG_CHAR_VAL,
	   swig_pg_make_character, character);
REF_MAP(unsigned char, SWIG_PG_CHARP, SWIG_PG_CHAR_VAL,
	   swig_pg_make_character, character);
REF_MAP(int, SWIG_is_integer, SWIG_convert_int,
	   swig_pg_make_integer_value, integer);
REF_MAP(short, SWIG_is_integer, SWIG_convert_short,
	   swig_pg_make_integer_value, integer);
REF_MAP(long, SWIG_is_integer, SWIG_convert_long,
	   swig_pg_make_integer_value, integer);
REF_MAP(unsigned int, SWIG_is_unsigned_integer, SWIG_convert_unsigned_int,
	   swig_pg_make_integer_value_from_unsigned, integer);
REF_MAP(unsigned short, SWIG_is_unsigned_integer, SWIG_convert_unsigned_short,
	   swig_pg_make_integer_value_from_unsigned, integer);
REF_MAP(unsigned long, SWIG_is_unsigned_integer, SWIG_convert_unsigned_long,
	   swig_pg_make_integer_value_from_unsigned, integer);
REF_MAP(float, SWIG_PG_REALP, swig_pg_real_to_double,
	   swig_pg_make_double, real);
REF_MAP(double, SWIG_PG_REALP, swig_pg_real_to_double,
	   swig_pg_make_double, real);

%typemap(throws) char * {
  swig_pg_signal_error("%s: %s", FUNC_NAME, $1);
}

/* Void */

%typemap(out) void "$result = swig_pg_void;"

/* Pass through swig_pg_value   */

%typemap (in) swig_pg_value   "$1=$input;"
%typemap (out) swig_pg_value   "$result=$1;"
%typecheck(SWIG_TYPECHECK_POINTER) swig_pg_value  "$1=1;";


/* ------------------------------------------------------------
 * String & length
 * ------------------------------------------------------------ */

//%typemap(in) (char *STRING, int LENGTH) {
//    int temp;
//    $1 = ($1_ltype) SWIG_Guile_scm2newstr($input, &temp);
//    $2 = ($2_ltype) temp;
//}

/* ------------------------------------------------------------
 * Typechecking rules
 * ------------------------------------------------------------ */

%typecheck(SWIG_TYPECHECK_INTEGER)
	 int, short, long,
 	 unsigned int, unsigned short, unsigned long,
	 signed char, unsigned char,
	 long long, unsigned long long,
	 const int &, const short &, const long &,
 	 const unsigned int &, const unsigned short &, const unsigned long &,
	 const long long &, const unsigned long long &,
	 enum SWIGTYPE
{
  $1 = (SWIG_is_integer($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_BOOL) bool, bool &, const bool &
{
  $1 = (SWIG_PG_BOOLP($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_DOUBLE)
	float, double,
	const float &, const double &
{
  $1 = (SWIG_PG_REALP($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_STRING) char {
  $1 = (SWIG_PG_STRINGP($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_STRING) char * {
  $1 = (SWIG_PG_STRINGP($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_POINTER) SWIGTYPE *, SWIGTYPE [] {
  void *ptr;
  if (SWIG_ConvertPtr($input, (void **) &ptr, $1_descriptor, 0)) {
    $1 = 0;
  } else {
    $1 = 1;
  }
}

%typecheck(SWIG_TYPECHECK_POINTER) SWIGTYPE &, SWIGTYPE && {
  void *ptr;
  if (SWIG_ConvertPtr($input, (void **) &ptr, $1_descriptor, SWIG_POINTER_NO_NULL)) {
    $1 = 0;
  } else {
    $1 = 1;
  }
}

%typecheck(SWIG_TYPECHECK_POINTER) SWIGTYPE {
  void *ptr;
  if (SWIG_ConvertPtr($input, (void **) &ptr, $&1_descriptor, SWIG_POINTER_NO_NULL)) {
    $1 = 0;
  } else {
    $1 = 1;
  }
}

%typecheck(SWIG_TYPECHECK_VOIDPTR) void * {
  void *ptr;
  if (SWIG_ConvertPtr($input, (void **) &ptr, 0, 0)) {
    $1 = 0;
  } else {
    $1 = 1;
  }
}


/* Array reference typemaps */
%apply SWIGTYPE & { SWIGTYPE ((&)[ANY]) }
%apply SWIGTYPE && { SWIGTYPE ((&&)[ANY]) }

/* const pointers */
%apply SWIGTYPE * { SWIGTYPE *const }


