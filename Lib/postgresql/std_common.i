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
std::string swig_scm_to_string(Datum x) {
    return std::string(POSTGRESQL_STR_VAL(x));
}

SWIGINTERNINLINE
postgresql_value swig_make_string(const std::string &s) {
    return postgresql_make_string(s.c_str());
}
%}
