#!/bin/bash
set -xe

# RUN THIS AS
tmp/test/pg-build.sh

if false
then
./autogen.sh
# aclocal
# autoconf
# autoheader
# automake --add-missing
./configure
fi
make

SWIG_DIR=$(pwd)
swig=$SWIG_DIR/swig

PG_VERSION=14.7
PG_MAJOR_VERSION=${PG_VERSION%.*}
PG_ROOT="/opt/homebrew/Cellar/postgresql@$PG_MAJOR_VERSION/$PG_VERSION"
PG_INCL="$PG_ROOT/include/postgresql@$PG_MAJOR_VERSION"

# brew services start postgresql@${PG_MAJOR_VERSION}
setup-database() {
  psql postgres <<EOF
CREATE ROLE swig WITH LOGIN PASSWORD 'swig';
ALTER ROLE swig CREATEDB;
EOF
}
cd tmp/test

NAME=example1
args="-debug-top 1,2,3,4 -postgresql -I$SWIG_DIR/Lib -I$SWIG_DIR/Lib/postgresql -o ${NAME}.c src/${NAME}.i"
$swig $args || lldb $swig -o run -- $args
cat src/${NAME}.c >> ${NAME}.c

CC="clang -g -I$PG_INCL/server -I."

rm -f *.o *.so
$CC -c -Wall -o src/${NAME}.o src/${NAME}.c
# https://www.postgresql.org/docs/current/xfunc-c.html#DFUNC
if false
then
$CC -c -o ${NAME}.o ${NAME}.c
$CC -bundle -flat_namespace -undefined suppress -o ${NAME}.so ${NAME}.o src/${NAME}.o
file ${NAME}.so
fi

directory='$libdir/'"$NAME"

VERSION=0.0.1
cat <<EOF > ${NAME}.control
# ${NAME} extension
comment = '${NAME} extension'
default_version = '${VERSION}'
relocatable = true
EOF

cat <<EOF > ${NAME}--${VERSION}.sql
-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION $NAME" to load this file. \quit

CREATE FUNCTION EXAMPLE1_VERSION() RETURNS varchar
    AS '$directory', '${NAME}_swig_EXAMPLE1_VERSION'
    LANGUAGE C STRICT;

CREATE FUNCTION cubic_poly(
  x   double precision,
  c0  double precision,
  c1  double precision,
  c2  double precision,
  c3  double precision
) RETURNS double precision
    AS '$directory', '${NAME}_swig_cubic_poly'
    LANGUAGE C STRICT;
EOF

cat <<EOF > Makefile
EXTENSION = ${NAME}        # the extensions name
DATA = ${NAME}--${VERSION}.sql  # script files to install
# REGRESS = ${NAME}_test     # our test script file (without extension)
MODULES = ${NAME}
PG_CFLAGS+=-Isrc

# postgres build stuff
PG_CONFIG = pg_config
PGXS := \$(shell \$(PG_CONFIG) --pgxs)
include \$(PGXS)
EOF

make install
make installcheck
