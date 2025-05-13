#!/usr/bin/bash

rm -f ./*.cf
rm -f ./*.o

set -e

ghdl -a -v --work=ieee_compat --std=93c std_logic_1164.vhdl
ghdl -a -v --work=ieee_compat --std=93c std_logic_1164-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c std_logic_textio.vhdl
ghdl -a -v --work=ieee_compat --std=93c math_real.vhdl
ghdl -a -v --work=ieee_compat --std=93c math_real-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c math_complex.vhdl
ghdl -a -v --work=ieee_compat --std=93c math_complex-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_std.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_std-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_bit.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_bit-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_bit_unsigned.vhdl
ghdl -a -v --work=ieee_compat --std=93c numeric_bit_unsigned-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c fixed_float_types.vhdl
ghdl -a -v --work=ieee_compat --std=93c fixed_pkg_conf.vhdl
ghdl -a -v --work=ieee_compat --std=93c fixed_pkg.vhdl
ghdl -a -v --work=ieee_compat --std=93c fixed_pkg-body.vhdl
ghdl -a -v --work=ieee_compat --std=93c float_pkg_conf.vhdl
ghdl -a -v --work=ieee_compat --std=93c float_pkg.vhdl
ghdl -a -v --work=ieee_compat --std=93c float_pkg-body.vhdl

