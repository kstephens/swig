/* -----------------------------------------------------------------------------
 * std_pair.i
 *
 * SWIG typemaps for std::pair
 * ----------------------------------------------------------------------------- */

%include <std_common.i>
%include <exception.i>


// ------------------------------------------------------------------------
// std::pair
//
// See std_vector.i for the rationale of typemap application
// ------------------------------------------------------------------------

%{
#include <utility>
%}

// exported class

namespace std {

    template<class T, class U> struct pair {
        %typemap(in) pair<T,U> (std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                U* y;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                x = (T*) SWIG_MustGetPtr(first,$descriptor(T *),$argnum, 0);
                y = (U*) SWIG_MustGetPtr(second,$descriptor(U *),$argnum, 0);
                $1 = std::make_pair(*x,*y);
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const pair<T,U>& (std::pair<T,U> temp,
                                       std::pair<T,U>* m),
                     const pair<T,U>* (std::pair<T,U> temp,
                                       std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                U* y;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                x = (T*) SWIG_MustGetPtr(first,$descriptor(T *),$argnum, 0);
                y = (U*) SWIG_MustGetPtr(second,$descriptor(U *),$argnum, 0);
                temp = std::make_pair(*x,*y);
                $1 = &temp;
            } else {
                $1 = ($1_ltype)
                    SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) pair<T,U> {
            T* x = new T($1.first);
            U* y = new U($1.second);
            Datum first = SWIG_NewPointerObj(x,$descriptor(T *), 1);
            Datum second = SWIG_NewPointerObj(y,$descriptor(U *), 1);
            $result = swig_pg_make_pair(first,second);
        }
        %typecheck(SWIG_TYPECHECK_PAIR) pair<T,U> {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                U* y;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (SWIG_ConvertPtr(first,(void**) &x,
                                    $descriptor(T *), 0) != -1 &&
                    SWIG_ConvertPtr(second,(void**) &y,
                                    $descriptor(U *), 0) != -1) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_PAIR) const pair<T,U>&,
                                        const pair<T,U>* {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                U* y;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (SWIG_ConvertPtr(first,(void**) &x,
                                    $descriptor(T *), 0) != -1 &&
                    SWIG_ConvertPtr(second,(void**) &y,
                                    $descriptor(U *), 0) != -1) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }

        typedef T first_type;
        typedef U second_type;

        pair();
        pair(T first, U second);
        pair(const pair& other);

        template <class U1, class U2> pair(const pair<U1, U2> &other);

        T first;
        U second;
    };

    // specializations for built-ins

    %define specialize_std_pair_on_first(T,CHECK,CONVERT_FROM,CONVERT_TO)
    template<class U> struct pair<T,U> {
        %typemap(in) pair<T,U> (std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                U* y;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                if (!CHECK(first))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                y = (U*) SWIG_MustGetPtr(second,$descriptor(U *),$argnum, 0);
                $1 = std::make_pair(CONVERT_FROM(first),*y);
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const pair<T,U>& (std::pair<T,U> temp,
                                       std::pair<T,U>* m),
                     const pair<T,U>* (std::pair<T,U> temp,
                                       std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                U* y;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                if (!CHECK(first))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                y = (U*) SWIG_MustGetPtr(second,$descriptor(U *),$argnum, 0);
                temp = std::make_pair(CONVERT_FROM(first),*y);
                $1 = &temp;
            } else {
                $1 = ($1_ltype)
                    SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) pair<T,U> {
            U* y = new U($1.second);
            Datum second = SWIG_NewPointerObj(y,$descriptor(U *), 1);
            $result = swig_pg_make_pair(CONVERT_TO($1.first),second);
        }
        %typecheck(SWIG_TYPECHECK_PAIR) pair<T,U> {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                U* y;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (CHECK(first) &&
                    SWIG_ConvertPtr(second,(void**) &y,
                                    $descriptor(U *), 0) != -1) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_PAIR) const pair<T,U>&,
                                        const pair<T,U>* {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                U* y;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (CHECK(first) &&
                    SWIG_ConvertPtr(second,(void**) &y,
                                    $descriptor(U *), 0) != -1) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        pair();
        pair(T first, U second);
        pair(const pair& other);

        template <class U1, class U2> pair(const pair<U1, U2> &other);

        T first;
        U second;
    };
    %enddef

    %define specialize_std_pair_on_second(U,CHECK,CONVERT_FROM,CONVERT_TO)
    template<class T> struct pair<T,U> {
        %typemap(in) pair<T,U> (std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                x = (T*) SWIG_MustGetPtr(first,$descriptor(T *),$argnum, 0);
                if (!CHECK(second))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                $1 = std::make_pair(*x,CONVERT_FROM(second));
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const pair<T,U>& (std::pair<T,U> temp,
                                       std::pair<T,U>* m),
                     const pair<T,U>* (std::pair<T,U> temp,
                                       std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                x = (T*) SWIG_MustGetPtr(first,$descriptor(T *),$argnum, 0);
                if (!CHECK(second))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                temp = std::make_pair(*x,CONVERT_FROM(second));
                $1 = &temp;
            } else {
                $1 = ($1_ltype)
                    SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) pair<T,U> {
            T* x = new T($1.first);
            Datum first = SWIG_NewPointerObj(x,$descriptor(T *), 1);
            $result = swig_pg_make_pair(first,CONVERT_TO($1.second));
        }
        %typecheck(SWIG_TYPECHECK_PAIR) pair<T,U> {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (SWIG_ConvertPtr(first,(void**) &x,
                                    $descriptor(T *), 0) != -1 &&
                    CHECK(second)) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_PAIR) const pair<T,U>&,
                                        const pair<T,U>* {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                T* x;
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (SWIG_ConvertPtr(first,(void**) &x,
                                    $descriptor(T *), 0) != -1 &&
                    CHECK(second)) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        pair();
        pair(T first, U second);
        pair(const pair& other);

        template <class U1, class U2> pair(const pair<U1, U2> &other);

        T first;
        U second;
    };
    %enddef

    %define specialize_std_pair_on_both(T,CHECK_T,CONVERT_T_FROM,CONVERT_T_TO,
                                        U,CHECK_U,CONVERT_U_FROM,CONVERT_U_TO)
    template<> struct pair<T,U> {
        %typemap(in) pair<T,U> (std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                Datum first, *second;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                if (!CHECK_T(first) || !CHECK_U(second))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                $1 = make_pair(CONVERT_T_FROM(first),
                               CONVERT_U_FROM(second));
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const pair<T,U>& (std::pair<T,U> temp,
                                       std::pair<T,U>* m),
                     const pair<T,U>* (std::pair<T,U> temp,
                                       std::pair<T,U>* m) {
            if (SWIG_PG_PAIRP($input)) {
                Datum first, *second;
            T *x;
                first = swig_pg_car($input);
                second = swig_pg_cdr($input);
                x = (T*) SWIG_MustGetPtr(first,$descriptor(T *),$argnum, 0);
                if (!CHECK_T(first) || !CHECK_U(second))
                    SWIG_exception(SWIG_TypeError,
                                   "pair<" #T "," #U "> expected");
                temp = make_pair(CONVERT_T_FROM(first),
                               CONVERT_U_FROM(second));
                $1 = &temp;
            } else {
                $1 = ($1_ltype)
                    SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) pair<T,U> {
            $result = swig_pg_make_pair(CONVERT_T_TO($1.first),
                                       CONVERT_U_TO($1.second));
        }
        %typecheck(SWIG_TYPECHECK_PAIR) pair<T,U> {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (CHECK_T(first) && CHECK_U(second)) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_PAIR) const pair<T,U>&,
                                        const pair<T,U>* {
            /* native pair? */
            if (SWIG_PG_PAIRP($input)) {
                Datum first = swig_pg_car($input);
                Datum second = swig_pg_cdr($input);
                if (CHECK_T(first) && CHECK_U(second)) {
                        $1 = 1;
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped pair? */
                std::pair<T,U >* p;
                if (SWIG_ConvertPtr($input,(void **) &p,
                                    $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        pair();
        pair(T first, U second);
        pair(const pair& other);

        template <class U1, class U2> pair(const pair<U1, U2> &other);

        T first;
        U second;
    };
    %enddef


    specialize_std_pair_on_first(bool,SWIG_PG_BOOLP,
                              SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_first(int,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(short,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(long,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(unsigned int,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(unsigned short,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(unsigned long,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_first(double,SWIG_PG_REALP,
                              swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_first(float,SWIG_PG_REALP,
                              swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_first(std::string,SWIG_PG_STRINGP,
                              swig_scm_to_string,swig_make_string);

    specialize_std_pair_on_second(bool,SWIG_PG_BOOLP,
                                SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_second(int,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(short,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(long,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(unsigned int,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(unsigned short,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(unsigned long,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_second(double,SWIG_PG_REALP,
                                swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_second(float,SWIG_PG_REALP,
                                swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_second(std::string,SWIG_PG_STRINGP,
                                swig_scm_to_string,swig_make_string);

    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_pair_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
}
