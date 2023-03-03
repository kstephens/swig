/* -----------------------------------------------------------------------------
 * std_string.i
 *
 * SWIG typemaps for std::string types
 * ----------------------------------------------------------------------------- */

// ------------------------------------------------------------------------
// std::string is typemapped by value
// This can prevent exporting methods which return a string
// in order for the user to modify it.
// However, I think I'll wait until someone asks for it...
// ------------------------------------------------------------------------

%include <exception.i>

%{
#include <string>
%}

namespace std {

    %naturalvar string;

    class string;

    /* Overloading check */

    %typemap(typecheck) string = char *;
    %typemap(typecheck) const string & = char *;

    %typemap(in) string {
        if (SWIG_PG_STRINGP($input))
            $1.assign(SWIG_PG_STR_VAL($input));
        else
            SWIG_exception(SWIG_TypeError, "string expected");
    }

    %typemap(in) const string & ($*1_ltype temp) {
        if (SWIG_PG_STRINGP($input)) {
            temp.assign(SWIG_PG_STR_VAL($input));
            $1 = &temp;
        } else {
            SWIG_exception(SWIG_TypeError, "string expected");
        }
    }

    %typemap(out) string {
        $result = swig_pg_make_string($1.c_str());
    }

    %typemap(out) const string & {
        $result = swig_pg_make_string($1->c_str());
    }

    %typemap(throws) string {
      swig_pg_signal_error("%s: %s", FUNC_NAME, $1.c_str());
    }

    %typemap(throws) const string & {
      swig_pg_signal_error("%s: %s", FUNC_NAME, $1.c_str());
    }
}


