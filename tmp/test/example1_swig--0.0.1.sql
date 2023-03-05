CREATE FUNCTION EXAMPLE1_VERSION (  )
  RETURNS text
  AS '$libdir/example1_swig', 'example1_swig_EXAMPLE1_VERSION'
  LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly (
    x_ float8,
    c0_ float8,
    c1_ float8,
    c2_ float8,
    c3_ float8
  )
  RETURNS float8
  AS '$libdir/example1_swig', 'example1_swig_cubic_poly'
  LANGUAGE C STRICT;

