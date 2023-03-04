#include <stdio.h>
#include "example1.h"

int main(int argc, char **argv) {
  printf("EXAMPLE1_VERSION = %s\n", EXAMPLE1_VERSION);
  printf("%5.1f\n", cubic_poly(2.0, 3.0, 5.0, 7.0, 11.0));
  return 0;
}
