-- ----------------------------------------------------
-- example1--0.0.1.sql

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION example1" to load this file. \quit

CREATE FUNCTION EXAMPLE1_VERSION() RETURNS text
    AS '$libdir/example1', 'example1_swig_EXAMPLE1_VERSION'
    LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly(
  x   float8,
  c0  float8,
  c1  float8,
  c2  float8,
  c3  float8
) RETURNS float8
    AS '$libdir/example1', 'example1_swig_cubic_poly'
    LANGUAGE C STRICT;

-- ----------------------------------------------------

