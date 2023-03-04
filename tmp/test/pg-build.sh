#!/bin/bash

# RUN THIS AS tmp/test/pg-build.sh
# build-swig
#

set -xe
swig_root=$(pwd)
swig=$swig_root/swig
example_dir="$swig_root/tmp/test"

PG_VERSION=14.7
PG_MAJOR_VERSION=${PG_VERSION%.*}
PG_ROOT="/opt/homebrew/Cellar/postgresql@$PG_MAJOR_VERSION/$PG_VERSION"
PG_INCL="$PG_ROOT/include/postgresql@$PG_MAJOR_VERSION"
CC="clang -g -I$(pg_config --includedir-server) -I. -Isrc"

EXTENSION_NAME=example1
EXTENSION_VERSION=0.0.1
set +xe
export CFLAGS='-g'

cmd-configure-swig() {
  set -xe
  cd "$swig_root"
./autogen.sh
./configure
}

cmd-build-swig() {
  set -xe
  cd "$swig_root"
  make
}

# brew services start postgresql@${PG_MAJOR_VERSION}
# createdb

cmd-run-swig() {
  set -ex
  cd "$example_dir" || exit $?

  args=''
  # args+=' -debug-top 1,2,3,4'
  args+="-postgresql -module-version $EXTENSION_VERSION -I$swig_root/Lib -I$swig_root/Lib/postgresql -o ${EXTENSION_NAME}.c src/${EXTENSION_NAME}.i"

  echo "$swig $args"
  rm -f ${EXTENSION_NAME}.c
  $swig $args ||
  [[ -f ${EXTENSION_NAME}.c ]] ||
  lldb $swig -o run -- $args </dev/null

  cat src/${EXTENSION_NAME}.c >> ${EXTENSION_NAME}.c

set +x

# TODO: make this part of swig!
cat <<EOF | tee ${EXTENSION_NAME}.control
########################################################
# ${EXTENSION_NAME}.control:

comment           = '${EXTENSION_NAME} extension'
default_version   = '${EXTENSION_VERSION}'
relocatable       = true

########################################################

EOF

# TODO: make this part of swig!
cat <<EOF | tee ${EXTENSION_NAME}.make
########################################################
# ${EXTENSION_NAME}.make:

EXTENSION = ${EXTENSION_NAME}        # the extensions name
DATA = ${EXTENSION_NAME}--${EXTENSION_VERSION}.sql  # script files to install
# REGRESS = ${EXTENSION_NAME}_test     # our test script file (without extension)
MODULES = ${EXTENSION_NAME}
PG_CFLAGS+=-Isrc

# postgres build stuff
PG_CONFIG = pg_config
PGXS := \$(shell \$(PG_CONFIG) --pgxs)
include \$(PGXS)

########################################################

EOF

# TODO: make this part of swig!
directory='$libdir/'"${EXTENSION_NAME}"
cat <<EOF | tee ${EXTENSION_NAME}--${EXTENSION_VERSION}.sql
-- ----------------------------------------------------
-- ${EXTENSION_NAME}--${EXTENSION_VERSION}.sql

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION $EXTENSION_NAME" to load this file. \quit

CREATE FUNCTION EXAMPLE1_VERSION() RETURNS text
    AS '$directory', '${EXTENSION_NAME}_swig_EXAMPLE1_VERSION'
    LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly(
  x   float8,
  c0  float8,
  c1  float8,
  c2  float8,
  c3  float8
) RETURNS float8
    AS '$directory', '${EXTENSION_NAME}_swig_cubic_poly'
    LANGUAGE C STRICT;

-- ----------------------------------------------------

EOF

}

cmd-compile-code() {
  set -e
  cd "$example_dir" || exit $?
rm -f *.o *.so
set -x
$CC -c -Wall -o src/${EXTENSION_NAME}.o src/${EXTENSION_NAME}.c
set +x

# https://www.postgresql.org/docs/current/xfunc-c.html#DFUNC
if false
then
$CC -c -o ${EXTENSION_NAME}.o ${EXTENSION_NAME}.c
$CC -bundle -flat_namespace -undefined suppress -o ${EXTENSION_NAME}.so ${EXTENSION_NAME}.o src/${EXTENSION_NAME}.o
file ${EXTENSION_NAME}.so
fi

set -x
make -f ${EXTENSION_NAME}.make install
# make -f ${EXTENSION_NAME}.make installcheck
}

cmd-run-example() {
  cd "$example_dir" || exit $?
cat <<EOF | tee $EXTENSION_NAME-test.sql
-- ----------------------------------------------------
-- $EXTENSION_NAME-test.sql:

DROP EXTENSION $EXTENSION_NAME;
CREATE EXTENSION $EXTENSION_NAME;

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

EOF

echo "RESULT:"
psql --echo-all < $EXTENSION_NAME-test.sql | tee $EXTENSION_NAME-test.sql.output
}

########################


for cmd in "$@"
do
  echo "  #######################################################"
  echo "  # $cmd"
  echo ""
  "cmd-$cmd"
  set +xe
  echo ""
  echo "  # $cmd : DONE"
  echo "  #######################################################"
  echo ""
done
