-- ----------------------------------------------------
-- example1-test.sql:

DROP EXTENSION example1_swig;
CREATE EXTENSION example1_swig;

SELECT EXAMPLE1_VERSION();

DROP TABLE IF EXISTS cubics;
CREATE TABLE cubics (
  cubics_id int,
  c0 float8,
  c1 float8,
  c2 float8,
  c3 float8
);
INSERT INTO cubics VALUES
  (1, 2.0, 3.0, 5.0, 7.0),
  (2, 2.3, 5.7, 11.13, 17.23),
  (3, -5.2, 1.2, -99.0, 12.34);

DROP TABLE IF EXISTS cubic_parameters;
CREATE TABLE cubic_parameters (
  x float8
);
INSERT INTO cubic_parameters VALUES
  (2),
  (-3.7),
  (3.1415926);

SELECT *, cubic_poly(x, c0, c1, c2, c3)
FROM cubics, cubic_parameters;

-- ----------------------------------------------------

