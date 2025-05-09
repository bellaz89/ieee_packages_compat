#!/usr/bin/bash

rm -f ieee_test-obj93.cf

set -e

ghdl -a -v --work=ieee_test --std=93c fixed_float_types.vhdl
ghdl -a -v --work=ieee_test --std=93c fixed_generic_pkg.vhdl
ghdl -a -v --work=ieee_test --std=93c fixed_generic_pkg-body.vhdl
