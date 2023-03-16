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
        if ( ! swig_pg_is_string($input) )
            swig_pg_wrong_type("expected string : %s : arg %d", $symname, $argnum);
        $1.assign(DatumGetCString($input));
    }

    %typemap(in) const string & ($*1_ltype temp) {
        if ( ! swig_pg_is_string($input) )
            swig_pg_wrong_type("expected string : %s : arg %d", $symname, $argnum);
        temp.assign(DatumGetCString($input));
        $1 = &temp;
    }

    %typemap(out) string {
        $result = swig_CStringGetDatum($1.c_str());
    }

    %typemap(out) const string & {
        $result = swig_CStringGetDatum($1->c_str());
    }

    %typemap(throws) string {
      swig_pg_signal_error("%s: %s", FUNC_NAME, $1.c_str());
    }

    %typemap(throws) const string & {
      swig_pg_signal_error("%s: %s", FUNC_NAME, $1.c_str());
    }
}


