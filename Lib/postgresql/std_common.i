/* -----------------------------------------------------------------------------
 * std_common.i
 *
 * SWIG typemaps for STL - common utilities
 * ----------------------------------------------------------------------------- */

%include <std/std_except.i>

%apply size_t { std::size_t };

%{
#include <string>

SWIGINTERNINLINE
std::string swig_pg_datum_to_string(Datum x) {
#if 1
    // See text_to_cstring_buffer in postgresql/src/backend/utils/adt/varchar.c
    text       *src = DatumGetTextPP(x);
	text	   *srcunpacked = pg_detoast_datum_packed(src);
	size_t	   src_len = VARSIZE_ANY_EXHDR(srcunpacked);
    std::string str(VARDATA_ANY(srcunpacked), src_len);
	if (srcunpacked != src)
		pfree(srcunpacked);
#else
    char *cstr = swig_pg_datum_to_cstring(x);
    std::string str(cstr);
    pfree(cstr);
#endif
    return str;
}

SWIGINTERNINLINE
Datum swig_pg_string_to_datum(const std::string &s) {
    return swig_pg_cstring_len_to_datum(s.c_str(), s.size());
}
%}
