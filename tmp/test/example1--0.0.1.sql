-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION example1" to load this file. \quit

CREATE FUNCTION EXAMPLE1_VERSION() RETURNS varchar
    AS '$libdir/example1', 'example1_swig_EXAMPLE1_VERSION'
    LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly(
  x   double precision,
  c0  double precision,
  c1  double precision,
  c2  double precision,
  c3  double precision
) RETURNS double precision
    AS '$libdir/example1', 'example1_swig_cubic_poly'
    LANGUAGE C STRICT;
