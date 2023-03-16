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
std::string swig_pg_to_string(Datum x) {
    return std::string(DatumGetCString(x));
}

SWIGINTERNINLINE
Datum swig_make_string(const std::string &s) {
    return swig_CStringGetDatum(s.c_str());
}
%}
