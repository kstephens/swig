/* -----------------------------------------------------------------------------
 * std_vector.i
 *
 * SWIG typemaps for std::vector
 * ----------------------------------------------------------------------------- */

%include <std_common.i>

%{
#include <vector>
#include <algorithm>
#include <stdexcept>
%}

// exported class

namespace std {

    template<class T> class vector {
        %typemap(in) vector<T> {
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                $1 = std::vector<T >(size);
                for (size_t i=0; i<size; i++) {
                    (($1_type &)$1)[i] =
                        *((T*) SWIG_MustGetPtr(swig_pg_sequence_get($input, i),
                                               $descriptor(T *),
                                               $argnum, 0));
                }
            } else if (swig_pg_is_null($input)) {
                $1 = std::vector<T >();
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const vector<T>& (std::vector<T> temp),
                     const vector<T>* (std::vector<T> temp) {
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                temp = std::vector<T >(size);
                $1 = &temp;
                for (size_t i=0; i<size; i++) {
                    temp[i] = *((T*) SWIG_MustGetPtr(swig_pg_sequence_get($input, i),
                                                     $descriptor(T *),
                                                     $argnum, 0));
                }
            } else if (swig_pg_is_null($input)) {
                temp = std::vector<T >();
                $1 = &temp;
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) vector<T> {
            $result = swig_pg_make_vector($1.size(),swig_pg_undefined);
            for (size_t i = 0; i < $1.size(); i ++) {
                T* x = new T((($1_type &)$1)[i]);
                swig_pg_sequence_set($result, i, SWIG_NewPointerObj(x,$descriptor(T *), 1));
            }
        }
        %typecheck(SWIG_TYPECHECK_VECTOR) vector<T> {
            /* native sequence? */
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                if (size == 0) {
                    /* an empty sequence can be of any type */
                    $1 = 1;
                } else {
                    /* check the first element only */
                    T* x;
                    if (SWIG_ConvertPtr(swig_pg_sequence_get($input, 0),(void**) &x,
                                    $descriptor(T *), 0) != -1)
                        $1 = 1;
                    else
                        $1 = 0;
                }
            } else if (swig_pg_is_null($input)) {
                /* again, an empty sequence can be of any type */
                $1 = 1;
            } else {
                /* wrapped vector? */
                std::vector<T >* v;
                if (SWIG_ConvertPtr($input,(void **) &v,
                                $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_VECTOR) const vector<T>&,
                                          const vector<T>* {
            /* native sequence? */
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                if (size == 0) {
                    /* an empty sequence can be of any type */
                    $1 = 1;
                } else {
                    /* check the first element only */
                    T* x;
                    if (SWIG_ConvertPtr(swig_pg_sequence_get($input, 0),(void**) &x,
                                    $descriptor(T *), 0) != -1)
                        $1 = 1;
                    else
                        $1 = 0;
                }
            } else if (swig_pg_is_null($input)) {
                /* again, an empty sequence can be of any type */
                $1 = 1;
            } else {
                /* wrapped vector? */
                std::vector<T >* v;
                if (SWIG_ConvertPtr($input,(void **) &v,
                                $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
      public:
        typedef unsigned int size_type;
        typedef ptrdiff_t difference_type;
        typedef T value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        vector(unsigned int size = 0);
        vector(unsigned int size, const T& value);
        vector(const vector& other);

        %rename(length) size;
        unsigned int size() const;
        %rename("emptyQ") empty;
        bool empty() const;
        %rename("clearE") clear;
        void clear();
        %rename("setE") set;
        %rename("popE") pop;
        %rename("pushE") push_back;
        void push_back(const T& x);
        %extend {
            T pop() throw (std::out_of_range) {
                if (self->size() == 0)
                    throw std::out_of_range("pop from empty vector");
                T x = self->back();
                self->pop_back();
                return x;
            }
            T& ref(unsigned int i) throw (std::out_of_range) {
                size_t size = size_t(self->size());
                if (i>=0 && i<size)
                    return (*self)[i];
                else
                    throw std::out_of_range("vector index out of range");
            }
            void set(unsigned int i, const T& x) throw (std::out_of_range) {
                size_t size = size_t(self->size());
                if (i>=0 && i<size)
                    (*self)[i] = x;
                else
                    throw std::out_of_range("vector index out of range");
            }
        }
    };


    // specializations for built-ins

    %define specialize_std_vector(T,CHECK,CONVERT_FROM,CONVERT_TO)
    template<> class vector<T> {
        %typemap(in) vector<T> {
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                $1 = std::vector<T >(size);
                for (size_t i=0; i<size; i++) {
                    Datum o = swig_pg_sequence_get($input, i);
                    if (CHECK(o))
                        (($1_type &)$1)[i] = (T)(CONVERT_FROM(o));
                    else
                        swig_pg_wrong_type("vector<" #T ">", $argnum - 1);
                }
            } else if (swig_pg_is_null($input)) {
                $1 = std::vector<T >();
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const vector<T>& (std::vector<T> temp),
                     const vector<T>* (std::vector<T> temp) {
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                temp = std::vector<T >(size);
                $1 = &temp;
                for (size_t i=0; i<size; i++) {
                    Datum o = swig_pg_sequence_get($input, i);
                    if (CHECK(o))
                        temp[i] = (T)(CONVERT_FROM(o));
                    else
                        swig_pg_wrong_type("vector<" #T ">", $argnum - 1);
                }
            } else if (swig_pg_is_null($input)) {
                temp = std::vector<T >();
                $1 = &temp;
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum - 1, 0);
            }
        }
        %typemap(out) vector<T> {
            $result = swig_pg_make_vector($1.size(),swig_pg_undefined);
            for (size_t i=0; i<$1.size(); i++)
                swig_pg_sequence_set($result, i, CONVERT_TO((($1_type &)$1)[i]));
        }
        %typecheck(SWIG_TYPECHECK_VECTOR) vector<T> {
            /* native sequence? */
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                if (size == 0) {
                    /* an empty sequence can be of any type */
                    $1 = 1;
                } else {
                    /* check the first element only */
                    T* x;
                    $1 = CHECK(swig_pg_sequence_get($input, 0)) ? 1 : 0;
                }
            } else if (swig_pg_is_null($input)) {
                /* again, an empty sequence can be of any type */
                $1 = 1;
            } else {
                /* wrapped vector? */
                std::vector<T >* v;
                $1 = (SWIG_ConvertPtr($input,(void **) &v,
                                  $&1_descriptor, 0) != -1) ? 1 : 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_VECTOR) const vector<T>&,
                                          const vector<T>* {
            /* native sequence? */
            if (swig_pg_is_sequence($input)) {
                size_t size = swig_pg_sequence_size($input);
                if (size == 0) {
                    /* an empty sequence can be of any type */
                    $1 = 1;
                } else {
                    /* check the first element only */
                    T* x;
                    $1 = CHECK(swig_pg_sequence_get($input, 0)) ? 1 : 0;
                }
            } else if (swig_pg_is_null($input)) {
                /* again, an empty sequence can be of any type */
                $1 = 1;
            } else {
                /* wrapped vector? */
                std::vector<T >* v;
                $1 = (SWIG_ConvertPtr($input,(void **) &v,
                                  $1_descriptor, 0) != -1) ? 1 : 0;
            }
        }
      public:
        typedef unsigned int size_type;
        typedef ptrdiff_t difference_type;
        typedef T value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        vector(unsigned int size = 0);
        vector(unsigned int size, const T& value);
        vector(const vector& other);

        %rename(length) size;
        unsigned int size() const;
        %rename("emptyQ") empty;
        bool empty() const;
        %rename("clearE") clear;
        void clear();
        %rename("setE") set;
        %rename("popE") pop;
        %rename("pushE") push_back;
        void push_back(T x);
        %extend {
            T pop() throw (std::out_of_range) {
                if (self->size() == 0)
                    throw std::out_of_range("pop from empty vector");
                T x = self->back();
                self->pop_back();
                return x;
            }
            T ref(int i) throw (std::out_of_range) {
                int size = int(self->size());
                if (i>=0 && i<size)
                    return (*self)[i];
                else
                    throw std::out_of_range("vector index out of range");
            }
            void set(int i, T x) throw (std::out_of_range) {
                int size = int(self->size());
                if (i>=0 && i<size)
                    (*self)[i] = x;
                else
                    throw std::out_of_range("vector index out of range");
            }
        }
    };
    %enddef

    // See typemaps.i
    specialize_std_vector(bool,swig_pg_is_bool,DatumGetBool,\
                          swig_make_boolean);
    specialize_std_vector(char,swig_pg_is_integer,swig_pg_datum_to_char,\
                          swig_pg_make_integer_value);
    specialize_std_vector(int,swig_pg_is_integer,DatumGetInt32,\
                          swig_pg_make_integer_value);
    specialize_std_vector(short,swig_pg_is_integer,DatumGetInt16,\
                          swig_pg_make_integer_value);
    specialize_std_vector(long,swig_pg_is_integer,DatumGetInt64,\
                          swig_pg_make_integer_value);
    specialize_std_vector(unsigned char,swig_pg_is_integer,swig_pg_datum_to_char,\
                          swig_pg_make_integer_value);
    specialize_std_vector(unsigned int,swig_pg_is_integer,DatumGetUInt32,\
                          swig_pg_make_integer_value);
    specialize_std_vector(unsigned short,swig_pg_is_integer,DatumGetUInt16,\
                          swig_pg_make_integer_value);
    specialize_std_vector(unsigned long,swig_pg_is_integer,DatumGetUInt64,\
                          swig_pg_make_integer_value);
    specialize_std_vector(float,swig_pg_is_float,DatumGetFloat8,\
                          Float8GetDatum);
    specialize_std_vector(double,swig_pg_is_float,DatumGetFloat8,\
                          Float8GetDatum);
    specialize_std_vector(std::string,SWIG_PG_STRINGP,swig_scm_to_string,\
                          swig_make_string);

}

