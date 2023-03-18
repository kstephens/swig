/* -----------------------------------------------------------------------------
 * typemaps.i
 * ----------------------------------------------------------------------------- */

#define %set_output(obj)                  $result = obj
#define %set_varoutput(obj)               $result = obj
#define %argument_fail(code, type, name, argn)	swig_pg_wrong_type(FUNC_NAME, type, argn)
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
  if (!swig_pg_is_integer($input))
      swig_pg_wrong_type("INTEGER", $argnum - 1);
  $1 = ($1_type) SWIG_convert_int($input);
}

%typemap(varin) enum SWIGTYPE {
  if (!swig_pg_is_integer($input))
      swig_pg_wrong_type("INTEGER", 0);
  $1 = ($1_type) SWIG_convert_int($input);
}

%typemap(out)     enum SWIGTYPE "$result = Int32GetDatum($1);"
%typemap(varout)  enum SWIGTYPE "$result = Int32GetDatum($1);"


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

/*
https://www.postgresql.org/docs/current/datatype-numeric.html#DATATYPE-INT

Name	   | Storage Size |	Description                | Range
smallint | 2 bytes	    | small-range integer        | -32768 to +32767
integer  | 4 bytes	    | typical choice for integer | -2147483648 to +2147483647
bigint	 | 8 bytes	    | large-range integer	       | -9223372036854775808 to +9223372036854775807
decimal	 | variable	    | user-specified precision   | exact up to 131072 digits before the decimal point; up to 16383 digits after the decimal point
numeric	 | variable	    | user-specified precision   | exactup to 131072 digits before the decimal point; up to 16383 digits after the decimal point
real	   | 4 bytes	    | variable-precision         | inexact	6 decimal digits precision
double precision | 8 bytes | variable-precision      | inexact	15 decimal digits precision

Note: unsigned types are not supported by PostgreSQL.
Use a potentially larger signed type and add a CHECK constraint to enforce non-negative values.
We use the TEXT type to represent strings.
*/


%define SIMPLE_MAP(C_NAME, PG_TO_C, C_TO_PG, PG_NAME)
%typemap("pg_type")       C_NAME   PG_NAME;
%typemap("pg_type") const C_NAME & PG_NAME;
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
    Datum  s;
    s = C_TO_PG(*$1);
    SWIG_APPEND_VALUE(s);
}
%typemap(in) C_NAME *BOTH = C_NAME *INPUT;
%typemap(argout) C_NAME *BOTH = C_NAME *OUTPUT;
%typemap(in) C_NAME *INOUT = C_NAME *INPUT;
%typemap(argout) C_NAME *INOUT = C_NAME *OUTPUT;

%typemap(in) const C_NAME & (C_NAME temp) {
   temp = PG_TO_C($input);
   $1 = &temp;
}
%typemap(out) const C_NAME & {
  $result = C_TO_PG(*$1);
}
%enddef


SIMPLE_MAP(void,
     swig_pg_datum_to_void, swig_pg_void_to_datum,
     "VOID");
SIMPLE_MAP(bool,
     DatumGetBool, BoolGetDatum,
     "BOOLEAN");
// ??? Handle with DatumGetVarCharP, CStringGetDatum
SIMPLE_MAP(char,
     swig_pg_datum_to_char, swig_pg_char_to_datum,
     "CHAR(1)");
SIMPLE_MAP(unsigned char,
     swig_pg_datum_to_uchar, swig_pg_uchar_to_datum,
     "CHAR(1)");
SIMPLE_MAP(short,
     DatumGetInt16, Int16GetDatum,
     "SMALLINT");
SIMPLE_MAP(unsigned short,
     DatumGetUInt16, UInt32GetDatum,
     "INTEGER");
SIMPLE_MAP(int,
     DatumGetInt32, Int32GetDatum,
     "INTEGER");
SIMPLE_MAP(unsigned int,
     DatumGetUInt32, UInt32GetDatum,
     "BIGINT");
SIMPLE_MAP(long,
     DatumGetInt64, Int64GetDatum,
     "BIGINT");
SIMPLE_MAP(ptrdiff_t,
     DatumGetInt64, Int64GetDatum,
     "BIGINT");
SIMPLE_MAP(unsigned long,
     DatumGetUInt64, UInt64GetDatum,
     "BIGINT");
SIMPLE_MAP(size_t,
     DatumGetUInt64, UInt64GetDatum,
     "BIGINT");
SIMPLE_MAP(float,
     DatumGetFloat4, Float4GetDatum,
     "FLOAT4");
SIMPLE_MAP(double,
     DatumGetFloat8, Float8GetDatum,
     "FLOAT8");


// ??? memory mgmt?
// Does DatumGetCString work with pg TEXT type?
SIMPLE_MAP(char *,
     swig_pg_datum_to_cstring, swig_pg_cstring_to_datum,
     "TEXT");
SIMPLE_MAP(const char *,
     swig_pg_datum_to_cstring, swig_pg_cstring_to_datum,
     "TEXT");

%typemap(throws) char * {
  swig_pg_signal_error("%s: %s", FUNC_NAME, $1);
}

/* Void */

%typemap(out) void "$result = swig_pg_void;"

/* Pass through Datum   */

%typemap (in) Datum   "$1=$input;"
%typemap (out) Datum   "$result=$1;"
%typecheck(SWIG_TYPECHECK_POINTER) Datum  "$1=1;";


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
  $1 = swig_pg_is_integer($input);
}

%typecheck(SWIG_TYPECHECK_BOOL) bool, bool &, const bool &
{
  $1 = swig_pg_is_bool($input);
}

%typecheck(SWIG_TYPECHECK_DOUBLE)
	float, double,
	const float &, const double &
{
  $1 = swig_pg_is_float($input);
}

%typecheck(SWIG_TYPECHECK_STRING) char {
  $1 = swig_pg_is_string($input);
}

%typecheck(SWIG_TYPECHECK_STRING) char * {
  $1 = swig_pg_is_string($input);
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
