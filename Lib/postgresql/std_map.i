/* -----------------------------------------------------------------------------
 * std_map.i
 *
 * SWIG typemaps for std::map
 * ----------------------------------------------------------------------------- */

%include <std_common.i>

// ------------------------------------------------------------------------
// std::map
//
// The aim of all that follows would be to integrate std::map with
// MzScheme as much as possible, namely, to allow the user to pass and
// be returned Scheme association lists.
// const declarations are used to guess the intent of the function being
// exported; therefore, the following rationale is applied:
//
//   -- f(std::map<T>), f(const std::map<T>&), f(const std::map<T>*):
//      the parameter being read-only, either a Scheme alist or a
//      previously wrapped std::map<T> can be passed.
//   -- f(std::map<T>&), f(std::map<T>*):
//      the parameter must be modified; therefore, only a wrapped std::map
//      can be passed.
//   -- std::map<T> f():
//      the map is returned by copy; therefore, a Scheme alist
//      is returned which is most easily used in other Scheme functions
//   -- std::map<T>& f(), std::map<T>* f(), const std::map<T>& f(),
//      const std::map<T>* f():
//      the map is returned by reference; therefore, a wrapped std::map
//      is returned
// ------------------------------------------------------------------------

%{
#include <map>
#include <algorithm>
#include <stdexcept>
%}

// exported class

namespace std {

    template<class K, class T, class C = std::less<K> > class map {
        %typemap(in) map< K, T, C > (std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                $1 = std::map< K, T, C >();
            } else if (SWIG_PG_PAIRP($input)) {
                $1 = std::map< K, T, C >();
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    K* k;
                    T* x;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    k = (K*) SWIG_MustGetPtr(key,$descriptor(K *),$argnum, 0);
                    if (SWIG_ConvertPtr(val,(void**) &x,
                                    $descriptor(T *), 0) == -1) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        x = (T*) SWIG_MustGetPtr(val,$descriptor(T *),$argnum, 0);
                    }
                    (($1_type &)$1)[*k] = *x;
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const map< K, T, C >& (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m),
                     const map< K, T, C >* (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
            } else if (SWIG_PG_PAIRP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    K* k;
                    T* x;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    k = (K*) SWIG_MustGetPtr(key,$descriptor(K *),$argnum, 0);
                    if (SWIG_ConvertPtr(val,(void**) &x,
                                    $descriptor(T *), 0) == -1) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        x = (T*) SWIG_MustGetPtr(val,$descriptor(T *),$argnum, 0);
                    }
                    temp[*k] = *x;
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) map< K, T, C > {
            swig_pg_value alist = swig_pg_null;
            for (std::map< K, T, C >::reverse_iterator i=$1.rbegin();
                                                  i!=$1.rend(); ++i) {
                K* key = new K(i->first);
                T* val = new T(i->second);
                swig_pg_value k = SWIG_NewPointerObj(key,$descriptor(K *), 1);
                swig_pg_value x = SWIG_NewPointerObj(val,$descriptor(T *), 1);
                swig_pg_value entry = swig_pg_make_pair(k,x);
                alist = swig_pg_make_pair(entry,alist);
            }
            $result = alist;
        }
        %typecheck(SWIG_TYPECHECK_MAP) map< K, T, C > {
            /* native sequence? */
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                /* check the first element only */
                K* k;
                T* x;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (SWIG_ConvertPtr(key,(void**) &k,
                                    $descriptor(K *), 0) == -1) {
                        $1 = 0;
                    } else {
                        if (SWIG_ConvertPtr(val,(void**) &x,
                                        $descriptor(T *), 0) != -1) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (SWIG_ConvertPtr(val,(void**) &x,
                                            $descriptor(T *), 0) != -1)
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped map? */
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_MAP) const map< K, T, C >&,
                                       const map< K, T, C >* {
            /* native sequence? */
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                /* check the first element only */
                K* k;
                T* x;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (SWIG_ConvertPtr(key,(void**) &k,
                                    $descriptor(K *), 0) == -1) {
                        $1 = 0;
                    } else {
                        if (SWIG_ConvertPtr(val,(void**) &x,
                                        $descriptor(T *), 0) != -1) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (SWIG_ConvertPtr(val,(void**) &x,
                                            $descriptor(T *), 0) != -1)
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                /* wrapped map? */
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %rename("length") size;
        %rename("null?") empty;
        %rename("clear!") clear;
        %rename("ref") __getitem__;
        %rename("set!") __setitem__;
        %rename("delete!") __delitem__;
        %rename("has-key?") has_key;
      public:
        typedef size_t size_type;
        typedef ptrdiff_t difference_type;
        typedef K key_type;
        typedef T mapped_type;
        typedef std::pair< const K, T > value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        map();
        map(const map& other);

        unsigned int size() const;
        bool empty() const;
        void clear();
        %extend {
            T& __getitem__(const K& key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    return i->second;
                else
                    throw std::out_of_range("key not found");
            }
            void __setitem__(const K& key, const T& x) {
                (*self)[key] = x;
            }
            void __delitem__(const K& key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    self->erase(i);
                else
                    throw std::out_of_range("key not found");
            }
            bool has_key(const K& key) {
                std::map< K, T, C >::iterator i = self->find(key);
                return i != self->end();
            }
            swig_pg_value keys() {
                swig_pg_value result = swig_pg_null;
                for (std::map< K, T, C >::reverse_iterator i=self->rbegin();
                                                      i!=self->rend(); ++i) {
                    K* key = new K(i->first);
                    swig_pg_value k = SWIG_NewPointerObj(key,$descriptor(K *), 1);
                    result = swig_pg_make_pair(k,result);
                }
                return result;
            }
        }
    };


    // specializations for built-ins

    %define specialize_std_map_on_key(K,CHECK,CONVERT_FROM,CONVERT_TO)

    template<class T> class map< K, T, C > {
        %typemap(in) map< K, T, C > (std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                $1 = std::map< K, T, C >();
            } else if (SWIG_PG_PAIRP($input)) {
                $1 = std::map< K, T, C >();
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    T* x;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    if (!CHECK(key))
                        SWIG_exception(SWIG_TypeError,
                                       "map<" #K "," #T "," #C "> expected");
                    if (SWIG_ConvertPtr(val,(void**) &x,
                                    $descriptor(T *), 0) == -1) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        x = (T*) SWIG_MustGetPtr(val,$descriptor(T *),$argnum, 0);
                    }
                    (($1_type &)$1)[CONVERT_FROM(key)] = *x;
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const map< K, T, C >& (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m),
                     const map< K, T, C >* (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
            } else if (SWIG_PG_PAIRP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    T* x;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    if (!CHECK(key))
                        SWIG_exception(SWIG_TypeError,
                                       "map<" #K "," #T "," #C "> expected");
                    if (SWIG_ConvertPtr(val,(void**) &x,
                                    $descriptor(T *), 0) == -1) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        x = (T*) SWIG_MustGetPtr(val,$descriptor(T *),$argnum, 0);
                    }
                    temp[CONVERT_FROM(key)] = *x;
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) map< K, T, C > {
            swig_pg_value alist = swig_pg_null;
            for (std::map< K, T, C >::reverse_iterator i=$1.rbegin();
                                                  i!=$1.rend(); ++i) {
                T* val = new T(i->second);
                swig_pg_value k = CONVERT_TO(i->first);
                swig_pg_value x = SWIG_NewPointerObj(val,$descriptor(T *), 1);
                swig_pg_value entry = swig_pg_make_pair(k,x);
                alist = swig_pg_make_pair(entry,alist);
            }
            $result = alist;
        }
        %typecheck(SWIG_TYPECHECK_MAP) map< K, T, C > {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                T* x;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (!CHECK(key)) {
                        $1 = 0;
                    } else {
                        if (SWIG_ConvertPtr(val,(void**) &x,
                                        $descriptor(T *), 0) != -1) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (SWIG_ConvertPtr(val,(void**) &x,
                                            $descriptor(T *), 0) != -1)
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_MAP) const map< K, T, C >&,
                                       const map< K, T, C >* {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                T* x;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (!CHECK(key)) {
                        $1 = 0;
                    } else {
                        if (SWIG_ConvertPtr(val,(void**) &x,
                                        $descriptor(T *), 0) != -1) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (SWIG_ConvertPtr(val,(void**) &x,
                                            $descriptor(T *), 0) != -1)
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %rename("length") size;
        %rename("null?") empty;
        %rename("clear!") clear;
        %rename("ref") __getitem__;
        %rename("set!") __setitem__;
        %rename("delete!") __delitem__;
        %rename("has-key?") has_key;
      public:
        typedef size_t size_type;
        typedef ptrdiff_t difference_type;
        typedef K key_type;
        typedef T mapped_type;
        typedef std::pair< const K, T > value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        map();
        map(const map& other);

        unsigned int size() const;
        bool empty() const;
        void clear();
        %extend {
            T& __getitem__(K key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    return i->second;
                else
                    throw std::out_of_range("key not found");
            }
            void __setitem__(K key, const T& x) {
                (*self)[key] = x;
            }
            void __delitem__(K key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    self->erase(i);
                else
                    throw std::out_of_range("key not found");
            }
            bool has_key(K key) {
                std::map< K, T, C >::iterator i = self->find(key);
                return i != self->end();
            }
            swig_pg_value keys() {
                swig_pg_value result = swig_pg_null;
                for (std::map< K, T, C >::reverse_iterator i=self->rbegin();
                                                      i!=self->rend(); ++i) {
                    swig_pg_value k = CONVERT_TO(i->first);
                    result = swig_pg_make_pair(k,result);
                }
                return result;
            }
        }
    };
    %enddef

    %define specialize_std_map_on_value(T,CHECK,CONVERT_FROM,CONVERT_TO)
    template<class K> class map< K, T, C > {
        %typemap(in) map< K, T, C > (std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                $1 = std::map< K, T, C >();
            } else if (SWIG_PG_PAIRP($input)) {
                $1 = std::map< K, T, C >();
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    K* k;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    k = (K*) SWIG_MustGetPtr(key,$descriptor(K *),$argnum, 0);
                    if (!CHECK(val)) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        if (!CHECK(val))
                            SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    }
                    (($1_type &)$1)[*k] = CONVERT_FROM(val);
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const map< K, T, C >& (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m),
                     const map< K, T, C >* (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
            } else if (SWIG_PG_PAIRP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    K* k;
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    k = (K*) SWIG_MustGetPtr(key,$descriptor(K *),$argnum, 0);
                    if (!CHECK(val)) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        if (!CHECK(val))
                            SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    }
                    temp[*k] = CONVERT_FROM(val);
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) map< K, T, C > {
            swig_pg_value alist = swig_pg_null;
            for (std::map< K, T, C >::reverse_iterator i=$1.rbegin();
                                                  i!=$1.rend(); ++i) {
                K* key = new K(i->first);
                swig_pg_value k = SWIG_NewPointerObj(key,$descriptor(K *), 1);
                swig_pg_value x = CONVERT_TO(i->second);
                swig_pg_value entry = swig_pg_make_pair(k,x);
                alist = swig_pg_make_pair(entry,alist);
            }
            $result = alist;
        }
        %typecheck(SWIG_TYPECHECK_MAP) map< K, T, C > {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                K* k;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (SWIG_ConvertPtr(val,(void **) &k,
                                    $descriptor(K *), 0) == -1) {
                        $1 = 0;
                    } else {
                        if (CHECK(val)) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (CHECK(val))
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_MAP) const map< K, T, C >&,
                                       const map< K, T, C >* {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                K* k;
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (SWIG_ConvertPtr(val,(void **) &k,
                                    $descriptor(K *), 0) == -1) {
                        $1 = 0;
                    } else {
                        if (CHECK(val)) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (CHECK(val))
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %rename("length") size;
        %rename("null?") empty;
        %rename("clear!") clear;
        %rename("ref") __getitem__;
        %rename("set!") __setitem__;
        %rename("delete!") __delitem__;
        %rename("has-key?") has_key;
      public:
        typedef size_t size_type;
        typedef ptrdiff_t difference_type;
        typedef K key_type;
        typedef T mapped_type;
        typedef std::pair< const K, T > value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        map();
        map(const map& other);

        unsigned int size() const;
        bool empty() const;
        void clear();
        %extend {
            T __getitem__(const K& key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    return i->second;
                else
                    throw std::out_of_range("key not found");
            }
            void __setitem__(const K& key, T x) {
                (*self)[key] = x;
            }
            void __delitem__(const K& key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    self->erase(i);
                else
                    throw std::out_of_range("key not found");
            }
            bool has_key(const K& key) {
                std::map< K, T, C >::iterator i = self->find(key);
                return i != self->end();
            }
            swig_pg_value keys() {
                swig_pg_value result = swig_pg_null;
                for (std::map< K, T, C >::reverse_iterator i=self->rbegin();
                                                      i!=self->rend(); ++i) {
                    K* key = new K(i->first);
                    swig_pg_value k = SWIG_NewPointerObj(key,$descriptor(K *), 1);
                    result = swig_pg_make_pair(k,result);
                }
                return result;
            }
        }
    };
    %enddef

    %define specialize_std_map_on_both(K,CHECK_K,CONVERT_K_FROM,CONVERT_K_TO,
                                       T,CHECK_T,CONVERT_T_FROM,CONVERT_T_TO)
    template<> class map< K, T, C > {
        %typemap(in) map< K, T, C > (std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                $1 = std::map< K, T, C >();
            } else if (SWIG_PG_PAIRP($input)) {
                $1 = std::map< K, T, C >();
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    if (!CHECK_K(key))
                        SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    if (!CHECK_T(val)) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        if (!CHECK_T(val))
                            SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    }
                    (($1_type &)$1)[CONVERT_K_FROM(key)] =
                                               CONVERT_T_FROM(val);
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = *(($&1_type)
                       SWIG_MustGetPtr($input,$&1_descriptor,$argnum, 0));
            }
        }
        %typemap(in) const map< K, T, C >& (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m),
                     const map< K, T, C >* (std::map< K, T, C > temp,
                                      std::map< K, T, C >* m) {
            if (SWIG_PG_NULLP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
            } else if (SWIG_PG_PAIRP($input)) {
                temp = std::map< K, T, C >();
                $1 = &temp;
                swig_pg_value alist = $input;
                while (!SWIG_PG_NULLP(alist)) {
                    swig_pg_value entry, *key, *val;
                    entry = swig_pg_car(alist);
                    if (!SWIG_PG_PAIRP(entry))
                        SWIG_exception(SWIG_TypeError,"alist expected");
                    key = swig_pg_car(entry);
                    val = swig_pg_cdr(entry);
                    if (!CHECK_K(key))
                        SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    if (!CHECK_T(val)) {
                        if (!SWIG_PG_PAIRP(val))
                            SWIG_exception(SWIG_TypeError,"alist expected");
                        val = swig_pg_car(val);
                        if (!CHECK_T(val))
                            SWIG_exception(SWIG_TypeError,
                                           "map<" #K "," #T "," #C "> expected");
                    }
                    temp[CONVERT_K_FROM(key)] = CONVERT_T_FROM(val);
                    alist = swig_pg_cdr(alist);
                }
            } else {
                $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum, 0);
            }
        }
        %typemap(out) map< K, T, C > {
            swig_pg_value alist = swig_pg_null;
            for (std::map< K, T, C >::reverse_iterator i=$1.rbegin();
                                                  i!=$1.rend(); ++i) {
                swig_pg_value k = CONVERT_K_TO(i->first);
                swig_pg_value x = CONVERT_T_TO(i->second);
                swig_pg_value entry = swig_pg_make_pair(k,x);
                alist = swig_pg_make_pair(entry,alist);
            }
            $result = alist;
        }
        %typecheck(SWIG_TYPECHECK_MAP) map< K, T, C > {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (!CHECK_K(key)) {
                        $1 = 0;
                    } else {
                        if (CHECK_T(val)) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (CHECK_T(val))
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $&1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %typecheck(SWIG_TYPECHECK_MAP) const map< K, T, C >&,
                                       const map< K, T, C >* {
            // native sequence?
            if (SWIG_PG_NULLP($input)) {
                /* an empty sequence can be of any type */
                $1 = 1;
            } else if (SWIG_PG_PAIRP($input)) {
                // check the first element only
                swig_pg_value head = swig_pg_car($input);
                if (SWIG_PG_PAIRP(head)) {
                    swig_pg_value key = swig_pg_car(head);
                    swig_pg_value val = swig_pg_cdr(head);
                    if (!CHECK_K(key)) {
                        $1 = 0;
                    } else {
                        if (CHECK_T(val)) {
                            $1 = 1;
                        } else if (SWIG_PG_PAIRP(val)) {
                            val = swig_pg_car(val);
                            if (CHECK_T(val))
                                $1 = 1;
                            else
                                $1 = 0;
                        } else {
                            $1 = 0;
                        }
                    }
                } else {
                    $1 = 0;
                }
            } else {
                // wrapped map?
                std::map< K, T, C >* m;
                if (SWIG_ConvertPtr($input,(void **) &m,
                                $1_descriptor, 0) != -1)
                    $1 = 1;
                else
                    $1 = 0;
            }
        }
        %rename("length") size;
        %rename("null?") empty;
        %rename("clear!") clear;
        %rename("ref") __getitem__;
        %rename("set!") __setitem__;
        %rename("delete!") __delitem__;
        %rename("has-key?") has_key;
      public:
        typedef size_t size_type;
        typedef ptrdiff_t difference_type;
        typedef K key_type;
        typedef T mapped_type;
        typedef std::pair< const K, T > value_type;
        typedef value_type* pointer;
        typedef const value_type* const_pointer;
        typedef value_type& reference;
        typedef const value_type& const_reference;

        map();
        map(const map& other);

        unsigned int size() const;
        bool empty() const;
        void clear();
        %extend {
            T __getitem__(K key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    return i->second;
                else
                    throw std::out_of_range("key not found");
            }
            void __setitem__(K key, T x) {
                (*self)[key] = x;
            }
            void __delitem__(K key) throw (std::out_of_range) {
                std::map< K, T, C >::iterator i = self->find(key);
                if (i != self->end())
                    self->erase(i);
                else
                    throw std::out_of_range("key not found");
            }
            bool has_key(K key) {
                std::map< K, T, C >::iterator i = self->find(key);
                return i != self->end();
            }
            swig_pg_value keys() {
                swig_pg_value result = swig_pg_null;
                for (std::map< K, T, C >::reverse_iterator i=self->rbegin();
                                                      i!=self->rend(); ++i) {
                    swig_pg_value k = CONVERT_K_TO(i->first);
                    result = swig_pg_make_pair(k,result);
                }
                return result;
            }
        }
    };
    %enddef


    specialize_std_map_on_key(bool,SWIG_PG_BOOLP,
                              SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_key(int,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(short,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(long,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(unsigned int,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(unsigned short,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(unsigned long,SWIG_PG_INTP,
                              SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_key(double,SWIG_PG_REALP,
                              swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_key(float,SWIG_PG_REALP,
                              swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_key(std::string,SWIG_PG_STRINGP,
                              swig_scm_to_string,swig_make_string);

    specialize_std_map_on_value(bool,SWIG_PG_BOOLP,
                                SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_value(int,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(short,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(long,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(unsigned int,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(unsigned short,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(unsigned long,SWIG_PG_INTP,
                                SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_value(double,SWIG_PG_REALP,
                                swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_value(float,SWIG_PG_REALP,
                                swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_value(std::string,SWIG_PG_STRINGP,
                                swig_scm_to_string,swig_make_string);

    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               bool,SWIG_PG_BOOLP,
                               SWIG_PG_TRUEP,swig_make_boolean);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned int,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned short,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               unsigned long,SWIG_PG_INTP,
                               SWIG_PG_INT_VAL,swig_pg_make_integer_value);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               double,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               float,SWIG_PG_REALP,
                               swig_pg_real_to_double,swig_pg_make_double);
    specialize_std_map_on_both(std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string,
                               std::string,SWIG_PG_STRINGP,
                               swig_scm_to_string,swig_make_string);
}
