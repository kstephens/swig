#!/usr/bin/env bash

# RUN THIS AS tmp/test/pg-build.sh
# swig-configure swig-clean swig-build run-swig compile-code run-example
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
EXTENSION_MODULE=${EXTENSION_NAME}_swig

set +xe
export CFLAGS='-g'
export CXXFLAGS='-g'

cmd-swig-configure() {
  set -xe
  cd "$swig_root"
./autogen.sh
./configure
}

cmd-swig-clean() {
  set -xe
  cd "$swig_root"
  rm -f ./Source/Modules/postgresql.o
  rm -f ./swig
}

cmd-swig-build() {
  set -xe
  cd "$swig_root"
  make CFLAGS='-g'
}

# brew services start postgresql@${PG_MAJOR_VERSION}
# createdb

cmd-run-swig() {
  set -ex
  cd "$example_dir" || exit $?

  args=''
  args+=' -debug-top 4'
  args+=' -debug-typemap'
  args+=' -debug-tags'
  args+=' -debug-symtabs'
  args+=" -postgresql -extension-version $EXTENSION_VERSION -I$swig_root/Lib -I$swig_root/Lib/postgresql -o ${EXTENSION_MODULE}.c src/${EXTENSION_NAME}.i"

  echo "$swig $args"
  rm -f ${EXTENSION_MODULE}.c ${EXTENSION_MODULE}--${EXTENSION_VERSION}.sql ${EXTENSION_MODULE}.make ${EXTENSION_MODULE}.control
  (
    $swig $args ||
    [[ -f ${EXTENSION_MODULE}.c ]] ||
    lldb $swig -o run -- $args

    cat src/${EXTENSION_NAME}.c >> ${EXTENSION_MODULE}.c
  ) </dev/null |& tee ${EXTENSION_MODULE}.log

  wc -l *.c *.sql *.make *.control
}

cmd-make-control-files() {
  set +x
  cd "$example_dir" || exit $?

# TODO: make this part of swig!
cat <<EOF | tee ${EXTENSION_MODULE}.control
########################################################
# ${EXTENSION_MODULE}.control:

comment          = '${EXTENSION_MODULE} extension'
default_version  = '${EXTENSION_VERSION}'
relocatable      = true

########################################################

EOF

# TODO: make this part of swig!
cat <<EOF | tee ${EXTENSION_MODULE}.make
########################################################
# ${EXTENSION_MODULE}.make:

EXTENSION = ${EXTENSION_MODULE}           # the extensions name
DATA      = ${EXTENSION_MODULE}--${EXTENSION_VERSION}.sql  # script files to install
# REGRESS = ${EXTENSION_MODULE}_test      # our test script file (without extension)
MODULES   = ${EXTENSION_MODULE}
PG_CFLAGS+=-Isrc

# postgres build stuff
PG_CONFIG = pg_config
PGXS := \$(shell \$(PG_CONFIG) --pgxs)
include \$(PGXS)

########################################################

EOF

# TODO: make this part of swig!
directory='$libdir/'"${EXTENSION_MODULE}"
cat <<EOF | tee ${EXTENSION_MODULE}--${EXTENSION_VERSION}.sql
-- ----------------------------------------------------
-- ${EXTENSION_MODULE}--${EXTENSION_VERSION}.sql

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION $EXTENSION_MODULE" to load this file. \quit

CREATE FUNCTION EXAMPLE1_VERSION() RETURNS text
    AS '$directory', '${EXTENSION_MODULE}_swig_EXAMPLE1_VERSION'
    LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly(
  x   float8,
  c0  float8,
  c1  float8,
  c2  float8,
  c3  float8
) RETURNS float8
    AS '$directory', '${EXTENSION_MODULE}_cubic_poly'
    LANGUAGE C STRICT;

-- ----------------------------------------------------

EOF

}

cmd-compile-code() {
  set -e
  cd "$example_dir" || exit $?
rm -f *.o *.so
set -x
$CC -c -Wall -o src/${EXTENSION_MODULE}.o src/${EXTENSION_MODULE}.c
make -f ${EXTENSION_MODULE}.make install
# make -f ${EXTENSION_NAME}.make installcheck
}

cmd-run-example() {
  cd "$example_dir" || exit $?
cat <<EOF | tee $EXTENSION_NAME-test.sql
-- ----------------------------------------------------
-- $EXTENSION_NAME-test.sql:

DROP EXTENSION $EXTENSION_MODULE;
CREATE EXTENSION $EXTENSION_MODULE;

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
  "cmd-$cmd" || exit $?
  set +xe
  echo ""
  echo "  # $cmd : DONE"
  echo "  #######################################################"
  echo ""
done
