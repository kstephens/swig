########################################################
# example1_swig.make:

EXTENSION   = example1_swig
DATA        = example1_swig--0.0.1.sql
# REGRESS   = example1_swig_test
MODULES     = example1_swig
PG_CFLAGS  += -Isrc
PG_CONFIG   = pg_config
PGXS       := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

########################################################

