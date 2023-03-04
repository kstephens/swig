########################################################
# example1.make:

EXTENSION = example1        # the extensions name
DATA = example1--0.0.1.sql  # script files to install
# REGRESS = example1_test     # our test script file (without extension)
MODULES = example1
PG_CFLAGS+=-Isrc

# postgres build stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

########################################################

