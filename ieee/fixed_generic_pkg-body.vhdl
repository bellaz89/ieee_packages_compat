-- -----------------------------------------------------------------
--
-- Copyright 2019 IEEE P1076 WG Authors
--
-- See the LICENSE file distributed with this work for copyright and
-- licensing information and the AUTHORS file.
--
-- This file to you under the Apache License, Version 2.0 (the "License").
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
-- implied.  See the License for the specific language governing
-- permissions and limitations under the License.
--
--   Title     :  Fixed-point package (Generic package body)
--             :
--   Library   :  This package shall be compiled into a library
--             :  symbolically named IEEE.
--             :
--   Developers:  Accellera VHDL-TC and IEEE P1076 Working Group
--             :
--   Purpose   :  This packages defines basic binary fixed point arithmetic
--             :  arithmetic functions
--             :
--   Note      :  This package may be modified to include additional data
--             :  required by tools, but it must in no way change the
--             :  external interfaces or simulation behavior of the
--             :  description. It is permissible to add comments and/or
--             :  attributes to the package declarations, but not to change
--             :  or delete any original lines of the package declaration.
--             :  The package body may be changed only in accordance with
--             :  the terms of Clause 16 of this standard.
--             :
-- --------------------------------------------------------------------
-- $Revision: 1220 $
-- $Date: 2008-04-10 17:16:09 +0930 (Thu, 10 Apr 2008) $
-- --------------------------------------------------------------------

-- vsg_off length_002

library ieee;
use ieee.math_real.all;

package body fixed_generic_pkg is

  -- Author David Bishop (dbishop@vhdl.org)
  -- Other contributers: Jim Lewis, Yannick Grugni, Ryan W. Hilton
  -- null array constants
  constant NAUF : unresolved_ufixed (0 downto 1) := (others => '0');
  constant NASF : unresolved_sfixed (0 downto 1) := (others => '0');
  constant NSLV : std_ulogic_vector (0 downto 1) := (others => '0');

  -- This differed constant will tell you if the package body is synthesizable
  -- or implemented as real numbers, set to "true" if synthesizable.
  constant FIXEDSYNTH_OR_REAL : boolean := true;

  type stdlogic_1d is array (std_ulogic) of std_ulogic;
  type private_stdlogic_table is array(std_ulogic, std_ulogic) of std_ulogic;

  constant match_logic_table : private_stdlogic_table := (
    -----------------------------------------------------
    -- U    X    0    1    Z    W    L    H    -         |   |  
    -----------------------------------------------------
    ('U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', '1'),  -- | U |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '1'),  -- | X |
    ('U', 'X', '1', '0', 'X', 'X', '1', '0', '1'),  -- | 0 |
    ('U', 'X', '0', '1', 'X', 'X', '0', '1', '1'),  -- | 1 |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '1'),  -- | Z |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '1'),  -- | W |
    ('U', 'X', '1', '0', 'X', 'X', '1', '0', '1'),  -- | L |
    ('U', 'X', '0', '1', 'X', 'X', '0', '1', '1'),  -- | H |
    ('1', '1', '1', '1', '1', '1', '1', '1', '1')   -- | - |
    );

  constant no_match_logic_table : private_stdlogic_table := (
    -----------------------------------------------------
    -- U    X    0    1    Z    W    L    H    -         |   |  
    -----------------------------------------------------
    ('U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', '0'),  -- | U |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '0'),  -- | X |
    ('U', 'X', '0', '1', 'X', 'X', '0', '1', '0'),  -- | 0 |
    ('U', 'X', '1', '0', 'X', 'X', '1', '0', '0'),  -- | 1 |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '0'),  -- | Z |
    ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', '0'),  -- | W |
    ('U', 'X', '0', '1', 'X', 'X', '0', '1', '0'),  -- | L |
    ('U', 'X', '1', '0', 'X', 'X', '1', '0', '0'),  -- | H |
    ('0', '0', '0', '0', '0', '0', '0', '0', '0')   -- | - |
    );

  -------------------------------------------------------------------
  -- string conversion and write operations
  -------------------------------------------------------------------

  function to_ostring (value : std_ulogic_vector) return string is
    constant result_length : NATURAL := (value'length+2)/3;
    variable pad           : std_ulogic_vector(1 to result_length*3 - value'length);
    variable padded_value  : std_ulogic_vector(1 to result_length*3);
    variable result        : string(1 to result_length);
    variable tri           : std_ulogic_vector(1 to 3);
  begin
    if value (value'left) = 'Z' then
      pad := (others => 'Z');
    else
      pad := (others => '0');
    end if;
    padded_value := pad & value;
    for i in 1 to result_length loop
      tri := To_X01Z(padded_value(3*i-2 to 3*i));
      case tri is
        when o"0"   => result(i) := '0';
        when o"1"   => result(i) := '1';
        when o"2"   => result(i) := '2';
        when o"3"   => result(i) := '3';
        when o"4"   => result(i) := '4';
        when o"5"   => result(i) := '5';
        when o"6"   => result(i) := '6';
        when o"7"   => result(i) := '7';
        when "ZZZ"  => result(i) := 'Z';
        when others => result(i) := 'X';
      end case;
    end loop;
    return result;
  end function to_ostring;

  function to_hstring (value : std_ulogic_vector) return string is
    constant result_length : NATURAL := (value'length+3)/4;
    variable pad           : std_ulogic_vector(1 to result_length*4 - value'length);
    variable padded_value  : std_ulogic_vector(1 to result_length*4);
    variable result        : string(1 to result_length);
    variable quad          : std_ulogic_vector(1 to 4);
  begin
    if value (value'left) = 'Z' then
      pad := (others => 'Z');
    else
      pad := (others => '0');
    end if;
    padded_value := pad & value;
    for i in 1 to result_length loop
      quad := To_X01Z(padded_value(4*i-3 to 4*i));
      case quad is
        when x"0"   => result(i) := '0';
        when x"1"   => result(i) := '1';
        when x"2"   => result(i) := '2';
        when x"3"   => result(i) := '3';
        when x"4"   => result(i) := '4';
        when x"5"   => result(i) := '5';
        when x"6"   => result(i) := '6';
        when x"7"   => result(i) := '7';
        when x"8"   => result(i) := '8';
        when x"9"   => result(i) := '9';
        when x"A"   => result(i) := 'A';
        when x"B"   => result(i) := 'B';
        when x"C"   => result(i) := 'C';
        when x"D"   => result(i) := 'D';
        when x"E"   => result(i) := 'E';
        when x"F"   => result(i) := 'F';
        when "ZZZZ" => result(i) := 'Z';
        when others => result(i) := 'X';
      end case;
    end loop;
    return result;
  end function to_hstring;

  function \?=\ (l, r : std_ulogic) return std_ulogic is
  begin
    return match_logic_table (l, r);
  end function \?=\;

  function \?/=\ (l, r : std_ulogic) return std_ulogic is
  begin
    return no_match_logic_table (l, r);
  end function \?/=\;

  function private_sra (ARG : unsigned; COUNT : integer)
    return unsigned is
  begin
    if (COUNT >= 0) then
      return SHIFT_RIGHT(ARG, COUNT);
    else
      return SHIFT_LEFT(ARG, -COUNT);
    end if;
  end function private_sra;

  function private_sra (ARG : signed; COUNT : integer)
    return signed is
  begin
    if (COUNT >= 0) then
      return SHIFT_RIGHT(ARG, COUNT);
    else
      return SHIFT_LEFT(ARG, -COUNT);
    end if;
  end function private_sra;

  function private_minimum (
    l,
    r: integer
  )
  return integer is
  begin

    if (l < r) then
      return l;
    else
      return r;
    end if;

  end function private_minimum;

  function private_minimum (
    l,
    r: signed
  )
  return signed is
  begin

    if (l < r) then
      return l;
    else
      return r;
    end if;

  end function private_minimum;

  function private_minimum (
    l,
    r: unsigned
  )
  return unsigned is
  begin

    if (l < r) then
      return l;
    else
      return r;
    end if;

  end function private_minimum;

  function private_maximum (
    l,
    r: integer
  )
  return integer is
  begin

    if (l > r) then
      return l;
    else
      return r;
    end if;

  end function private_maximum;

  function private_maximum (
    l,
    r: signed
  )
  return signed is
  begin

    if (l > r) then
      return l;
    else
      return r;
    end if;

  end function private_maximum;

  function private_maximum (
    l,
    r: unsigned
  )
  return unsigned is
  begin

    if (l > r) then
      return l;
    else
      return r;
    end if;

  end function private_maximum;

  function IS_X (S : unsigned) return boolean is
  begin
    return IS_X(std_ulogic_vector(S));
  end function IS_X;

  -- Id: T.10
  function IS_X (S : signed) return boolean is
  begin
    return IS_X(std_ulogic_vector(S));
  end function IS_X;
  
  function \?>\ (L, R : unsigned) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?>\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?>\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?>\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L > R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?>\;

  function \?>\ (L, R : signed) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?>\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?>\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?>\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L > R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?>\;

  function \?>\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?>\(TO_UNSIGNED(L, R'length), R);
  end function \?>\;

  function \?>\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?>\(to_signed(L, R'length), R);
  end function \?>\;

  function \?>\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?>\(L, TO_UNSIGNED(R, L'length));
  end function \?>\;

  function \?>\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?>\(L, to_signed(R, L'length));
  end function \?>\;

  -- ============================================================================

  function \?<\ (L, R : unsigned) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?<\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?<\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?<\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L < R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?<\;

  function \?<\ (L, R : signed) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?<\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?<\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?<\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L < R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?<\;

  function \?<\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?<\(TO_UNSIGNED(L, R'length), R);
  end function \?<\;

  function \?<\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?<\(to_signed(L, R'length), R);
  end function \?<\;

  function \?<\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?<\(L, TO_UNSIGNED(R, L'length));
  end function \?<\;

  function \?<\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?<\(L, to_signed(R, L'length));
  end function \?<\;

  -- ============================================================================

  function \?<=\ (L, R : unsigned) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?<=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?<=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?<=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L <= R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?<=\;

  function \?<=\ (L, R : signed) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?<=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?<=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?<=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L <= R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?<=\;

  function \?<=\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?<=\(TO_UNSIGNED(L, R'length), R);
  end function \?<=\;

  function \?<=\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?<=\(to_signed(L, R'length), R);
  end function \?<=\;

  function \?<=\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?<=\(L, TO_UNSIGNED(R, L'length));
  end function \?<=\;

  function \?<=\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?<=\(L, to_signed(R, L'length));
  end function \?<=\;

  -- ============================================================================

  function \?>=\ (L, R : unsigned) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?>=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?>=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?>=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L >= R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?>=\;

  function \?>=\ (L, R : signed) return std_ulogic is
  begin
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?>=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      for i in L'range loop
        if L(i) = '-' then
          report "NUMERIC_STD.""\?>=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      for i in R'range loop
        if R(i) = '-' then
          report "NUMERIC_STD.""\?>=\"": '-' found in compare string"
            severity error;
          return 'X';
        end if;
      end loop;
      if IS_X(L) or IS_X(R) then
        return 'X';
      elsif L >= R then
        return '1';
      else
        return '0';
      end if;
    end if;
  end function \?>=\;

  function \?>=\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?>=\(TO_UNSIGNED(L, R'length), R);
  end function \?>=\;

  function \?>=\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?>=\(to_signed(L, R'length), R);
  end function \?>=\;

  function \?>=\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?>=\(L, TO_UNSIGNED(R, L'length));
  end function \?>=\;

  function \?>=\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?>=\(L, to_signed(R, L'length));
  end function \?>=\;

  -- ============================================================================

  function \?=\ (L, R : unsigned) return std_ulogic is
    constant L_LEFT          : integer := L'length-1;
    constant R_LEFT          : integer := R'length-1;
    alias XL                 : unsigned(L_LEFT downto 0) is L;
    alias XR                 : unsigned(R_LEFT downto 0) is R;
    constant SIZE            : NATURAL := private_MAXIMUM(L'length, R'length);
    variable LX              : unsigned(SIZE-1 downto 0);
    variable RX              : unsigned(SIZE-1 downto 0);
    variable result, result1 : std_ulogic;  -- result
  begin
    -- Logically identical to an "=" operator.
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      LX     := resize(XL, SIZE);
      RX     := resize(XR, SIZE);
      result := '1';
      for i in LX'low to LX'high loop
        result1 := \?=\(LX(i), RX(i));
        if result1 = 'U' then
          return 'U';
        elsif result1 = 'X' or result = 'X' then
          result := 'X';
        else
          result := result and result1;
        end if;
      end loop;
      return result;
    end if;
  end function \?=\;

  function \?=\ (L, R : signed) return std_ulogic is
    constant L_LEFT          : integer := L'length-1;
    constant R_LEFT          : integer := R'length-1;
    alias XL                 : signed(L_LEFT downto 0) is L;
    alias XR                 : signed(R_LEFT downto 0) is R;
    constant SIZE            : NATURAL := private_MAXIMUM(L'length, R'length);
    variable LX              : signed(SIZE-1 downto 0);
    variable RX              : signed(SIZE-1 downto 0);
    variable result, result1 : std_ulogic;  -- result
  begin  -- ?=
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      LX     := resize(XL, SIZE);
      RX     := resize(XR, SIZE);
      result := '1';
      for i in LX'low to LX'high loop
        result1 := \?=\(LX(i), RX(i));
        if result1 = 'U' then
          return 'U';
        elsif result1 = 'X' or result = 'X' then
          result := 'X';
        else
          result := result and result1;
        end if;
      end loop;
      return result;
    end if;
  end function \?=\;

  function \?=\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?=\(TO_UNSIGNED(L, R'length), R);
  end function \?=\;

  function \?=\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?=\(to_signed(L, R'length), R);
  end function \?=\;

  function \?=\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?=\(L, TO_UNSIGNED(R, L'length));
  end function \?=\;

  function \?=\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?=\(L, to_signed(R, L'length));
  end function \?=\;

  -- ============================================================================

  function \?/=\ (L, R : unsigned) return std_ulogic is
    constant L_LEFT          : integer := L'length-1;
    constant R_LEFT          : integer := R'length-1;
    alias XL                 : unsigned(L_LEFT downto 0) is L;
    alias XR                 : unsigned(R_LEFT downto 0) is R;
    constant SIZE            : NATURAL := private_MAXIMUM(L'length, R'length);
    variable LX              : unsigned(SIZE-1 downto 0);
    variable RX              : unsigned(SIZE-1 downto 0);
    variable result, result1 : std_ulogic;  -- result
  begin  -- ?=
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?/=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      LX     := resize(XL, SIZE);
      RX     := resize(XR, SIZE);
      result := '0';
      for i in LX'low to LX'high loop
        result1 := \?/=\(LX(i), RX(i));
        if result1 = 'U' then
          return 'U';
        elsif result1 = 'X' or result = 'X' then
          result := 'X';
        else
          result := result or result1;
        end if;
      end loop;
      return result;
    end if;
  end function \?/=\;

  function \?/=\ (L, R : signed) return std_ulogic is
    constant L_LEFT          : integer := L'length-1;
    constant R_LEFT          : integer := R'length-1;
    alias XL                 : signed(L_LEFT downto 0) is L;
    alias XR                 : signed(R_LEFT downto 0) is R;
    constant SIZE            : NATURAL := private_MAXIMUM(L'length, R'length);
    variable LX              : signed(SIZE-1 downto 0);
    variable RX              : signed(SIZE-1 downto 0);
    variable result, result1 : std_ulogic;  -- result
  begin  -- ?=
    if ((L'length < 1) or (R'length < 1)) then
      assert NO_WARNING
        report "NUMERIC_STD.""\?/=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      LX     := resize(XL, SIZE);
      RX     := resize(XR, SIZE);
      result := '0';
      for i in LX'low to LX'high loop
        result1 := \?/=\(LX(i), RX(i));
        if result1 = 'U' then
          return 'U';
        elsif result1 = 'X' or result = 'X' then
          result := 'X';
        else
          result := result or result1;
        end if;
      end loop;
      return result;
    end if;
  end function \?/=\;

  function \?/=\ (L : NATURAL; R : unsigned) return std_ulogic is
  begin
    return \?/=\(TO_UNSIGNED(L, R'length), R);
  end function \?/=\;

  function \?/=\ (L : integer; R : signed) return std_ulogic is
  begin
    return \?/=\(to_signed(L, R'length), R);
  end function \?/=\;

  function \?/=\ (L : unsigned; R : NATURAL) return std_ulogic is
  begin
    return \?/=\(L, TO_UNSIGNED(R, L'length));
  end function \?/=\;

  function \?/=\ (L : signed; R : integer) return std_ulogic is
  begin
    return \?/=\(L, to_signed(R, L'length));
  end function \?/=\;

  -- truth table for "and" function
  constant private_and_table : private_stdlogic_table := (
    --      ----------------------------------------------------
    --      |  U    X    0    1    Z    W    L    H    -         |   |
    --      ----------------------------------------------------
             ('U', 'U', '0', 'U', 'U', 'U', '0', 'U', 'U'),  -- | U |
             ('U', 'X', '0', 'X', 'X', 'X', '0', 'X', 'X'),  -- | X |
             ('0', '0', '0', '0', '0', '0', '0', '0', '0'),  -- | 0 |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | 1 |
             ('U', 'X', '0', 'X', 'X', 'X', '0', 'X', 'X'),  -- | Z |
             ('U', 'X', '0', 'X', 'X', 'X', '0', 'X', 'X'),  -- | W |
             ('0', '0', '0', '0', '0', '0', '0', '0', '0'),  -- | L |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | H |
             ('U', 'X', '0', 'X', 'X', 'X', '0', 'X', 'X')   -- | - |
             );

  -- truth table for "or" function
  constant private_or_table : private_stdlogic_table := (
    --      ----------------------------------------------------
    --      |  U    X    0    1    Z    W    L    H    -         |   |
    --      ----------------------------------------------------
             ('U', 'U', 'U', '1', 'U', 'U', 'U', '1', 'U'),  -- | U |
             ('U', 'X', 'X', '1', 'X', 'X', 'X', '1', 'X'),  -- | X |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | 0 |
             ('1', '1', '1', '1', '1', '1', '1', '1', '1'),  -- | 1 |
             ('U', 'X', 'X', '1', 'X', 'X', 'X', '1', 'X'),  -- | Z |
             ('U', 'X', 'X', '1', 'X', 'X', 'X', '1', 'X'),  -- | W |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | L |
             ('1', '1', '1', '1', '1', '1', '1', '1', '1'),  -- | H |
             ('U', 'X', 'X', '1', 'X', 'X', 'X', '1', 'X')   -- | - |
             );

  -- truth table for "xor" function
  constant private_xor_table : private_stdlogic_table := (
    --      ----------------------------------------------------
    --      |  U    X    0    1    Z    W    L    H    -         |   |
    --      ----------------------------------------------------
             ('U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U'),  -- | U |
             ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X'),  -- | X |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | 0 |
             ('U', 'X', '1', '0', 'X', 'X', '1', '0', 'X'),  -- | 1 |
             ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X'),  -- | Z |
             ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X'),  -- | W |
             ('U', 'X', '0', '1', 'X', 'X', '0', '1', 'X'),  -- | L |
             ('U', 'X', '1', '0', 'X', 'X', '1', '0', 'X'),  -- | H |
             ('U', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X')   -- | - |
             );

  -- truth table for "not" function
  constant private_not_table : stdlogic_1d :=
    --  -------------------------------------------------
    --  |   U    X    0    1    Z    W    L    H    -   |
    --  -------------------------------------------------
          ('U', 'X', '1', '0', 'X', 'X', '1', '0', 'X');


  -- reduction operations

  -------------------------------------------------------------------
  -- and
  -------------------------------------------------------------------
  function private_and_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '1';
  begin
    for i in l'reverse_range loop
      result := private_and_table (l(i), result);
    end loop;
    return result;
  end function private_and_reduce;

  -------------------------------------------------------------------
  -- nand
  -------------------------------------------------------------------
  function private_nand_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '1';
  begin
    for i in l'reverse_range loop
      result := private_and_table (l(i), result);
    end loop;
    return private_not_table(result);
  end function private_nand_reduce;

  -------------------------------------------------------------------
  -- or
  -------------------------------------------------------------------
  function private_or_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '0';
  begin
    for i in l'reverse_range loop
      result := private_or_table (l(i), result);
    end loop;
    return result;
  end function private_or_reduce;

  -------------------------------------------------------------------
  -- nor
  -------------------------------------------------------------------
  function private_nor_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '0';
  begin
    for i in l'reverse_range loop
      result := private_or_table (l(i), result);
    end loop;
    return private_not_table(result);
  end function private_nor_reduce;

  -------------------------------------------------------------------
  -- xor
  -------------------------------------------------------------------
  function private_xor_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '0';
  begin
    for i in l'reverse_range loop
      result := private_xor_table (l(i), result);
    end loop;
    return result;
  end function private_xor_reduce;

  -------------------------------------------------------------------
  -- xnor
  -------------------------------------------------------------------
  function private_xnor_reduce (l : std_ulogic_vector) return std_ulogic is
    variable result : std_ulogic := '0';
  begin
    for i in l'reverse_range loop
      result := private_xor_table (l(i), result);
    end loop;
    return private_not_table(result);
  end function private_xnor_reduce;



  -- Special version of "minimum" to do some boundary checking without errors
  function mins (
    l,
    r : integer
  )
    return integer is
  begin  -- function mins

    if (l = integer'low or r = integer'low) then
      return 0;                         -- error condition, silent
    end if;

    return private_minimum (l, r);

  end function mins;

  -- Special version of "minimum" to do some boundary checking with errors
  function mine (
    l,
    r : integer
  )
    return integer is
  begin  -- function mine

    if (l = integer'low or r = integer'low) then
      report fixed_generic_pkg'instance_name
             & " Unbounded number passed, was a literal used?"
        severity error;
      return 0;
    end if;

    return private_minimum (l, r);

  end function mine;

  -- The following functions are used only internally.  Every function
  -- calls "cleanvec" either directly or indirectly.
  -- purpose: Fixes "downto" problem and resolves meta states
  function cleanvec (
    arg : unresolved_sfixed
  )            -- input
    return unresolved_sfixed
  is
  begin  -- function cleanvec

    assert not (arg'ascending and (arg'low /= integer'low))
      report fixed_generic_pkg'instance_name
             & " Vector passed using a ""to"" range, expected is ""downto"""
      severity error;
    return arg;

  end function cleanvec;

  -- purpose: Fixes "downto" problem and resolves meta states
  function cleanvec (
    arg : unresolved_ufixed
  )            -- input
    return unresolved_ufixed
  is
  begin  -- function cleanvec

    assert not (arg'ascending and (arg'low /= integer'low))
      report fixed_generic_pkg'instance_name
             & " Vector passed using a ""to"" range, expected is ""downto"""
      severity error;
    return arg;

  end function cleanvec;

  -- Type convert a "unsigned" into a "ufixed", used internally
  function to_fixed (
    arg                  : unsigned;  -- shifted vector
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (left_index downto right_index);

  begin  -- function to_fixed

    result := unresolved_ufixed(arg);
    return result;

  end function to_fixed;

  -- Type convert a "signed" into an "sfixed", used internally
  function to_fixed (
    arg                  : signed;  -- shifted vector
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (left_index downto right_index);

  begin  -- function to_fixed

    result := unresolved_sfixed(arg);
    return result;

  end function to_fixed;

  -- Type convert a "ufixed" into an "unsigned", used internally
  function to_uns (
    arg : unresolved_ufixed
  )            -- fp vector
    return unsigned
  is

    subtype t is unsigned(arg'high - arg'low downto 0);

    variable slv : t;

  begin  -- function to_uns

    slv := t(arg);
    return slv;

  end function to_uns;

  -- Type convert an "sfixed" into a "signed", used internally
  function to_s (
    arg : unresolved_sfixed
  )            -- fp vector
    return signed
  is

    subtype t is signed(arg'high - arg'low downto 0);

    variable slv : t;

  begin  -- function to_s

    slv := t(arg);
    return slv;

  end function to_s;

  -- adds 1 to the LSB of the number
  procedure round_up (
    arg       : in  unresolved_ufixed;
    result    : out unresolved_ufixed;
    overflowx : out boolean
  ) is

    variable arguns, resuns : unsigned (arg'high-arg'low+1 downto 0)
 := (others => '0');

  begin  -- round_up

    arguns (arguns'high - 1 downto 0) := to_uns (arg);
    resuns                            := arguns + 1;
    result                            := to_fixed(resuns(arg'high-arg'low
                                                         downto 0), arg'high, arg'low);
    overflowx                         := (resuns(resuns'high) = '1');

  end procedure round_up;

  -- adds 1 to the LSB of the number
  procedure round_up (
    arg       : in  unresolved_sfixed;
    result    : out unresolved_sfixed;
    overflowx : out boolean
  ) is

    variable args, ress : signed (arg'high-arg'low+1 downto 0);

  begin  -- round_up

    args (args'high - 1 downto 0) := to_s (arg);
    args(args'high)               := arg(arg'high);  -- sign extend
    ress                          := args + 1;
    result                        := to_fixed(ress (ress'high-1
                                                    downto 0), arg'high, arg'low);
    overflowx                     :=
    ((arg(arg'high) /= ress(ress'high-1))
      and (private_or_reduce (std_ulogic_vector(ress)) /= '0')
    );

  end procedure round_up;

  -- Rounding - Performs a "round_nearest" (IEEE 754) which rounds up
  -- when the remainder is > 0.5.  If the remainder IS 0.5 then if the
  -- bottom bit is a "1" it is rounded, otherwise it remains the same.
  function round_fixed (
    arg            : unresolved_ufixed;
    remainder      : unresolved_ufixed;
    overflow_style : fixed_overflow_style_type := fixed_overflow_style
  )
    return unresolved_ufixed
  is

    variable rounds         : boolean;
    variable round_overflow : boolean;
    variable result         : unresolved_ufixed (arg'range);

  begin

    rounds := false;

    if (remainder'length > 1) then
      if (remainder (remainder'high) = '1') then
        rounds := (arg(arg'low) = '1')
                  or (private_or_reduce (to_sulv(remainder(remainder'high-1 downto
                                           remainder'low))) = '1');
      end if;
    else
      rounds := (arg(arg'low) = '1') and (remainder (remainder'high) = '1');
    end if;

    if (rounds) then
      round_up(arg       => arg,
               result    => result,
               overflowx => round_overflow);
    else
      result := arg;
    end if;

    if ((overflow_style = fixed_saturate) and round_overflow) then
      result := saturate (result'high, result'low);
    end if;

    return result;

  end function round_fixed;

  -- Rounding case statement
  function round_fixed (
    arg            : unresolved_sfixed;
    remainder      : unresolved_sfixed;
    overflow_style : fixed_overflow_style_type := fixed_overflow_style
  )
    return unresolved_sfixed
  is

    variable rounds         : boolean;
    variable round_overflow : boolean;
    variable result         : unresolved_sfixed (arg'range);

  begin

    rounds := false;

    if (remainder'length > 1) then
      if (remainder (remainder'high) = '1') then
        rounds := (arg(arg'low) = '1')
                  or (private_or_reduce (to_sulv(remainder(remainder'high-1 downto
                                           remainder'low))) = '1');
      end if;
    else
      rounds := (arg(arg'low) = '1') and (remainder (remainder'high) = '1');
    end if;

    if (rounds) then
      round_up(arg       => arg,
               result    => result,
               overflowx => round_overflow);
    else
      result := arg;
    end if;

    if (round_overflow) then
      if (overflow_style = fixed_saturate) then
        if (arg(arg'high) = '0') then
          result := saturate (result'high, result'low);
        else
          result := not saturate (result'high, result'low);
        end if;
      -- Sign bit not fixed when wrapping
      end if;
    end if;

    return result;

  end function round_fixed;

  -- converts an sfixed into a ufixed.  The output is the same length as the
  -- input, because abs("1000") = "1000" = 8.
  function to_ufixed (
    arg : unresolved_sfixed
  )
    return unresolved_ufixed
  is

    constant LEFT_INDEX  : integer := arg'high;
    constant RIGHT_INDEX : integer := mine(arg'low, arg'low);
    variable xarg        : unresolved_sfixed(LEFT_INDEX + 1 downto RIGHT_INDEX);
    variable result      : unresolved_ufixed(LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (arg'length < 1) then
      return NAUF;
    end if;

    xarg   := abs(arg);
    result := unresolved_ufixed (xarg (LEFT_INDEX downto RIGHT_INDEX));
    return result;

  end function to_ufixed;

  -----------------------------------------------------------------------------
  -- Visible functions
  -----------------------------------------------------------------------------
  -- Conversion functions.  These are needed for synthesis where typically
  -- the only input and output type is a std_logic_vector.
  function to_sulv (
    arg : unresolved_ufixed
  )            -- fixed point vector
    return std_ulogic_vector
  is

    variable intermediate_result : unresolved_ufixed(arg'length-1 downto 0);

  begin

    if (arg'length < 1) then
      return NSLV;
    end if;

    intermediate_result := arg;
    return std_ulogic_vector (intermediate_result);

  end function to_sulv;

  function to_sulv (
    arg : unresolved_sfixed
  )            -- fixed point vector
    return std_ulogic_vector
  is

    variable intermediate_result : unresolved_sfixed(arg'length-1 downto 0);

  begin

    if (arg'length < 1) then
      return NSLV;
    end if;

    intermediate_result := arg;
    return std_ulogic_vector (intermediate_result);

  end function to_sulv;

  function to_slv (
    arg : unresolved_ufixed
  )            -- fixed point vector
    return std_logic_vector is
  begin

    return std_logic_vector(to_sulv(arg));

  end function to_slv;

  function to_slv (
    arg : unresolved_sfixed
  )            -- fixed point vector
    return std_logic_vector is
  begin

    return std_logic_vector(to_sulv(arg));

  end function to_slv;

  function to_ufixed (
    arg                  : std_ulogic_vector;  -- shifted vector
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (left_index downto right_index);

  begin

    if (arg'length < 1 or right_index > left_index) then
      return NAUF;
    end if;

    if (arg'length /= result'length) then
      report fixed_generic_pkg'instance_name & "TO_UFIXED(SLV) "
             & "Vector lengths do not match.  Input length is "
             & integer'image(arg'length) & " and output will be "
             & integer'image(result'length) & " wide."
        severity error;
      return NAUF;
    else
      result := to_fixed (arg         => unsigned(arg),
                          left_index  => left_index,
                          right_index => right_index);
      return result;
    end if;

  end function to_ufixed;

  function to_sfixed (
    arg                  : std_ulogic_vector;  -- shifted vector
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (left_index downto right_index);

  begin

    if (arg'length < 1 or right_index > left_index) then
      return NASF;
    end if;

    if (arg'length /= result'length) then
      report fixed_generic_pkg'instance_name & "TO_SFIXED(SLV) "
             & "Vector lengths do not match.  Input length is "
             & integer'image(arg'length) & " and output will be "
             & integer'image(result'length) & " wide."
        severity error;
      return NASF;
    else
      result := to_fixed (arg         => signed(arg),
                          left_index  => left_index,
                          right_index => right_index);
      return result;
    end if;

  end function to_sfixed;

  -- Two's complement number, Grows the vector by 1 bit.
  -- because "abs (1000.000) = 01000.000" or abs(-16) = 16.
  function "abs" (
    arg : unresolved_sfixed
  )            -- fixed point input
    return unresolved_sfixed
  is

    constant LEFT_INDEX  : integer := arg'high;
    constant RIGHT_INDEX : integer := mine(arg'low, arg'low);
    variable ressns      : signed (arg'length downto 0);
    variable result      : unresolved_sfixed (LEFT_INDEX + 1 downto RIGHT_INDEX);

  begin

    if (arg'length < 1 or result'length < 1) then
      return NASF;
    end if;

    ressns (arg'length - 1 downto 0) := to_s (cleanvec (arg));
    ressns (arg'length)              := ressns (arg'length-1);  -- expand sign bit
    result                           := to_fixed (abs(ressns), LEFT_INDEX + 1, RIGHT_INDEX);
    return result;

  end function "abs";

  -- also grows the vector by 1 bit.
  function "-" (
    arg : unresolved_sfixed
  )            -- fixed point input
    return unresolved_sfixed
  is

    constant LEFT_INDEX  : integer := arg'high+1;
    constant RIGHT_INDEX : integer := mine(arg'low, arg'low);
    variable ressns      : signed (arg'length downto 0);
    variable result      : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (arg'length < 1 or result'length < 1) then
      return NASF;
    end if;

    ressns (arg'length - 1 downto 0) := to_s (cleanvec(arg));
    ressns (arg'length)              := ressns (arg'length-1);  -- expand sign bit
    result                           := to_fixed (-ressns, LEFT_INDEX, RIGHT_INDEX);
    return result;

  end function "-";

  -- Addition
  function "+" (
    l,
    r : unresolved_ufixed
  )    -- ufixed(a downto b) + ufixed(c downto d) =
    return unresolved_ufixed     -- ufixed(max(a,c)+1 downto min(b,d))
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mine(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable result           : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);
    variable result_slv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);

  begin

    if (l'length < 1 or r'length < 1 or result'length < 1) then
      return NAUF;
    end if;

    lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv       := to_uns (lresize);
    rslv       := to_uns (rresize);
    result_slv := lslv + rslv;
    result     := to_fixed(result_slv, LEFT_INDEX, RIGHT_INDEX);
    return result;

  end function "+";

  function "+" (
    l,
    r : unresolved_sfixed
  )    -- sfixed(a downto b) + sfixed(c downto d) =
    return unresolved_sfixed     -- sfixed(max(a,c)+1 downto min(b,d))
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mine(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable result           : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (LEFT_INDEX - RIGHT_INDEX downto 0);
    variable result_slv       : signed (LEFT_INDEX - RIGHT_INDEX downto 0);

  begin

    if (l'length < 1 or r'length < 1 or result'length < 1) then
      return NASF;
    end if;

    lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv       := to_s (lresize);
    rslv       := to_s (rresize);
    result_slv := lslv + rslv;
    result     := to_fixed(result_slv, LEFT_INDEX, RIGHT_INDEX);
    return result;

  end function "+";

  -- Subtraction
  function "-" (
    l,
    r : unresolved_ufixed
  )    -- ufixed(a downto b) - ufixed(c downto d) =
    return unresolved_ufixed     -- ufixed(max(a,c)+1 downto min(b,d))
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mine(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable result           : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);
    variable result_slv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);

  begin

    if (l'length < 1 or r'length < 1 or result'length < 1) then
      return NAUF;
    end if;

    lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv       := to_uns (lresize);
    rslv       := to_uns (rresize);
    result_slv := lslv - rslv;
    result     := to_fixed(result_slv, LEFT_INDEX, RIGHT_INDEX);
    return result;

  end function "-";

  function "-" (
    l,
    r : unresolved_sfixed
  )    -- sfixed(a downto b) - sfixed(c downto d) =
    return unresolved_sfixed     -- sfixed(max(a,c)+1 downto min(b,d))
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mine(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable result           : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (LEFT_INDEX - RIGHT_INDEX downto 0);
    variable result_slv       : signed (LEFT_INDEX - RIGHT_INDEX downto 0);

  begin

    if (l'length < 1 or r'length < 1 or result'length < 1) then
      return NASF;
    end if;

    lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv       := to_s (lresize);
    rslv       := to_s (rresize);
    result_slv := lslv - rslv;
    result     := to_fixed(result_slv, LEFT_INDEX, RIGHT_INDEX);
    return result;

  end function "-";

  function "*" (
    l,
    r : unresolved_ufixed
  )    -- ufixed(a downto b) * ufixed(c downto d) =
    return unresolved_ufixed     -- ufixed(a+c+1 downto b+d)
  is

    variable lslv       : unsigned (l'length-1 downto 0);
    variable rslv       : unsigned (r'length-1 downto 0);
    variable result_slv : unsigned (r'length+l'length-1 downto 0);
    variable result     : unresolved_ufixed (l'high + r'high+1 downto
                                              mine(l'low, l'low) + mine(r'low, r'low));

  begin

    if (l'length < 1 or r'length < 1 or
        result'length /= result_slv'length) then
      return NAUF;
    end if;

    lslv       := to_uns (cleanvec(l));
    rslv       := to_uns (cleanvec(r));
    result_slv := lslv * rslv;
    result     := to_fixed (result_slv, result'high, result'low);
    return result;

  end function "*";

  function "*" (
    l,
    r : unresolved_sfixed
  )    -- sfixed(a downto b) * sfixed(c downto d) =
    return unresolved_sfixed     -- sfixed(a+c+1 downto b+d)
  is

    variable lslv       : signed (l'length-1 downto 0);
    variable rslv       : signed (r'length-1 downto 0);
    variable result_slv : signed (r'length+l'length-1 downto 0);
    variable result     : unresolved_sfixed (l'high + r'high+1 downto
                                              mine(l'low, l'low) + mine(r'low, r'low));

  begin

    if (l'length < 1 or r'length < 1 or
        result'length /= result_slv'length) then
      return NASF;
    end if;

    lslv       := to_s (cleanvec(l));
    rslv       := to_s (cleanvec(r));
    result_slv := lslv * rslv;
    result     := to_fixed (result_slv, result'high, result'low);
    return result;

  end function "*";

  function "/" (
    l,
    r : unresolved_ufixed
  )    -- ufixed(a downto b) / ufixed(c downto d) =
    return unresolved_ufixed is         --  ufixed(a-d downto b-c-1)
  begin

    return divide (l, r);

  end function "/";

  function "/" (
    l,
    r : unresolved_sfixed
  )    -- sfixed(a downto b) / sfixed(c downto d) =
    return unresolved_sfixed is         -- sfixed(a-d+1 downto b-c)
  begin

    return divide (l, r);

  end function "/";

  -- This version of divide gives the user more control
  -- ufixed(a downto b) / ufixed(c downto d) = ufixed(a-d downto b-c-1)
  function divide (
    l,
    r                 : unresolved_ufixed;
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_ufixed
  is

    variable result     : unresolved_ufixed (l'high - mine(r'low, r'low) downto
                                              mine (l'low, l'low) - r'high -1);
    variable dresult    : unresolved_ufixed (result'high downto result'low -guard_bits);
    variable lresize    : unresolved_ufixed (l'high downto l'high - dresult'length+1);
    variable lslv       : unsigned (lresize'length-1 downto 0);
    variable rslv       : unsigned (r'length-1 downto 0);
    variable result_slv : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1 or
        mins(r'low, r'low) /= r'low or mins(l'low, l'low) /= l'low) then
      return NAUF;
    end if;

    lresize := resize (arg            => l,
                       left_index     => lresize'high,
                       right_index    => lresize'low,
                       overflow_style => fixed_wrap,   -- vector only grows
                       round_style    => fixed_truncate);
    lslv    := to_uns (cleanvec (lresize));
    rslv    := to_uns (cleanvec (r));

    if (rslv = 0) then
      report fixed_generic_pkg'instance_name
             & "DIVIDE(ufixed) Division by zero"
        severity error;
      result := saturate (result'high, result'low);    -- saturate
    else
      result_slv := lslv / rslv;
      dresult    := to_fixed (result_slv, dresult'high, dresult'low);
      result     := resize (arg            => dresult,
                            left_index     => result'high,
                            right_index    => result'low,
                            overflow_style => fixed_wrap,  -- overflow impossible
                            round_style    => round_style);
    end if;

    return result;

  end function divide;

  -- sfixed(a downto b) / sfixed(c downto d) = sfixed(a-d+1 downto b-c)
  function divide (
    l,
    r                 : unresolved_sfixed;
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_sfixed
  is

    variable result     : unresolved_sfixed (l'high - mine(r'low, r'low) + 1 downto
                                              mine (l'low, l'low) - r'high);
    variable dresult    : unresolved_sfixed (result'high downto result'low-guard_bits);
    variable lresize    : unresolved_sfixed (l'high+1 downto l'high+1 - dresult'length+1);
    variable lslv       : signed (lresize'length-1 downto 0);
    variable rslv       : signed (r'length-1 downto 0);
    variable result_slv : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1 or
        mins(r'low, r'low) /= r'low or mins(l'low, l'low) /= l'low) then
      return NASF;
    end if;

    lresize := resize (arg            => l,
                       left_index     => lresize'high,
                       right_index    => lresize'low,
                       overflow_style => fixed_wrap,   -- vector only grows
                       round_style    => fixed_truncate);
    lslv    := to_s (cleanvec (lresize));
    rslv    := to_s (cleanvec (r));

    if (rslv = 0) then
      report fixed_generic_pkg'instance_name
             & "DIVIDE(sfixed) Division by zero"
        severity error;
      result := saturate (result'high, result'low);
    else
      result_slv := lslv / rslv;
      dresult    := to_fixed (result_slv, dresult'high, dresult'low);
      result     := resize (arg            => dresult,
                            left_index     => result'high,
                            right_index    => result'low,
                            overflow_style => fixed_wrap,  -- overflow impossible
                            round_style    => round_style);
    end if;

    return result;

  end function divide;

  -- 1 / ufixed(a downto b) = ufixed(-b downto -a-1)
  function reciprocal (
    arg                  : unresolved_ufixed;  -- fixed point input
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_ufixed
  is

    constant ONE : unresolved_ufixed (0 downto 0) := "1";

  begin

    return divide (l           => ONE,
                   r           => arg,
                   round_style => round_style,
                   guard_bits  => guard_bits);

  end function reciprocal;

  -- 1 / sfixed(a downto b) = sfixed(-b+1 downto -a)
  function reciprocal (
    arg                  : unresolved_sfixed;              -- fixed point input
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_sfixed
  is

    constant ONE     : unresolved_sfixed (1 downto 0) := "01";  -- extra bit.
    variable resultx : unresolved_sfixed (-mine(arg'low, arg'low) + 2 downto -arg'high);

  begin

    if (arg'length < 1 or resultx'length < 1) then
      return NASF;
    else
      resultx := divide (l           => ONE,
                         r           => arg,
                         round_style => round_style,
                         guard_bits  => guard_bits);
      return resultx (resultx'high-1 downto resultx'low);  -- remove extra bit
    end if;

  end function reciprocal;

  -- ufixed (a downto b) rem ufixed (c downto d)
  --        = ufixed (min(a,c) downto min(b,d))
  function "rem" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return unresolved_ufixed is
  begin

    return remainder (l, r);

  end function "rem";

  -- remainder
  -- sfixed (a downto b) rem sfixed (c downto d)
  --        = sfixed (min(a,c) downto min(b,d))
  function "rem" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return unresolved_sfixed is
  begin

    return remainder (l, r);

  end function "rem";

  -- ufixed (a downto b) rem ufixed (c downto d)
  --        = ufixed (min(a,c) downto min(b,d))
  function remainder (
    l,
    r                 : unresolved_ufixed;            -- fixed point input
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_ufixed
  is

    variable result     : unresolved_ufixed (private_minimum(l'high, r'high) downto
                                              mine(l'low, r'low));
    variable lresize    : unresolved_ufixed (private_maximum(l'high, r'low) downto
                                              mins(r'low, r'low) - guard_bits);
    variable rresize    : unresolved_ufixed (r'high downto r'low-guard_bits);
    variable dresult    : unresolved_ufixed (rresize'range);
    variable lslv       : unsigned (lresize'length-1 downto 0);
    variable rslv       : unsigned (rresize'length-1 downto 0);
    variable result_slv : unsigned (rslv'range);

  begin

    if (l'length < 1 or r'length < 1 or
        mins(r'low, r'low) /= r'low or mins(l'low, l'low) /= l'low) then
      return NAUF;
    end if;

    lresize := resize (arg            => l,
                       left_index     => lresize'high,
                       right_index    => lresize'low,
                       overflow_style => fixed_wrap,     -- vector only grows
                       round_style    => fixed_truncate);
    lslv    := to_uns (lresize);
    rresize := resize (arg            => r,
                       left_index     => rresize'high,
                       right_index    => rresize'low,
                       overflow_style => fixed_wrap,     -- vector only grows
                       round_style    => fixed_truncate);
    rslv    := to_uns (rresize);

    if (rslv = 0) then
      report fixed_generic_pkg'instance_name
             & "remainder(ufixed) Division by zero"
        severity error;
      result := saturate (result'high, result'low);      -- saturate
    else
      if (r'low <= l'high) then
        result_slv := lslv rem rslv;
        dresult    := to_fixed (result_slv, dresult'high, dresult'low);
        result     := resize (arg            => dresult,
                              left_index     => result'high,
                              right_index    => result'low,
                              overflow_style => fixed_wrap,  -- can't overflow
                              round_style    => round_style);
      end if;
      if (l'low < r'low) then
        result(mins(r'low - 1, l'high) downto l'low) := cleanvec(l(mins(r'low-1, l'high) downto l'low));
      end if;
    end if;

    return result;

  end function remainder;

  -- remainder
  -- sfixed (a downto b) rem sfixed (c downto d)
  --        = sfixed (min(a,c) downto min(b,d))
  function remainder (
    l,
    r                 : unresolved_sfixed;  -- fixed point input
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_sfixed
  is

    variable l_abs      : unresolved_ufixed (l'range);
    variable r_abs      : unresolved_ufixed (r'range);
    variable result     : unresolved_sfixed (private_minimum(r'high, l'high) downto
                                              mine(r'low, l'low));
    variable neg_result : unresolved_sfixed (private_minimum(r'high, l'high) + 1 downto
                                              mins(r'low, l'low));

  begin

    if (l'length < 1 or r'length < 1 or
        mins(r'low, r'low) /= r'low or mins(l'low, l'low) /= l'low) then
      return NASF;
    end if;

    l_abs      := to_ufixed (l);
    r_abs      := to_ufixed (r);
    result     := unresolved_sfixed (remainder (
                                                l           => l_abs,
                                                r           => r_abs,
                                                round_style => round_style));
    neg_result := -result;

    if (l(l'high) = '1') then
      result := neg_result(result'range);
    end if;

    return result;

  end function remainder;

  -- modulo
  -- ufixed (a downto b) mod ufixed (c downto d)
  --        = ufixed (min(a,c) downto min(b, d))
  function "mod" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return unresolved_ufixed is
  begin

    return modulo (l, r);

  end function "mod";

  -- sfixed (a downto b) mod sfixed (c downto d)
  --        = sfixed (c downto min(b, d))
  function "mod" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return unresolved_sfixed is
  begin

    return modulo(l, r);

  end function "mod";

  -- modulo
  -- ufixed (a downto b) mod ufixed (c downto d)
  --        = ufixed (min(a,c) downto min(b, d))
  function modulo (
    l,
    r                 : unresolved_ufixed;  -- fixed point input
    constant round_style : fixed_round_style_type := fixed_round_style;
    constant guard_bits  : NATURAL                := fixed_guard_bits
  )
    return unresolved_ufixed is
  begin

    return remainder(l           => l,
                     r           => r,
                     round_style => round_style,
                     guard_bits  => guard_bits);

  end function modulo;

  -- sfixed (a downto b) mod sfixed (c downto d)
  --        = sfixed (c downto min(b, d))
  function modulo (
    l,
    r                    : unresolved_sfixed;  -- fixed point input
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style;
    constant guard_bits     : NATURAL                   := fixed_guard_bits
  )
    return unresolved_sfixed
  is

    variable l_abs            : unresolved_ufixed (l'range);
    variable r_abs            : unresolved_ufixed (r'range);
    variable result           : unresolved_sfixed (r'high downto
                                                    mine(r'low, l'low));
    variable dresult          : unresolved_sfixed (private_minimum(r'high, l'high) + 1 downto
                                                    mins(r'low, l'low));
    variable dresult_not_zero : boolean;

  begin

    if (l'length < 1 or r'length < 1 or
        mins(r'low, r'low) /= r'low or mins(l'low, l'low) /= l'low) then
      return NASF;
    end if;

    l_abs   := to_ufixed (l);
    r_abs   := to_ufixed (r);
    dresult := "0" & unresolved_sfixed(remainder (l           => l_abs,
                                                  r           => r_abs,
                                                  round_style => round_style));

    if (to_s(dresult) = 0) then
      dresult_not_zero := false;
    else
      dresult_not_zero := true;
    end if;

    if (to_x01(l(l'high)) = '1' and to_x01(r(r'high)) = '0'
        and dresult_not_zero) then
      result := resize (arg            => r - dresult,
                        left_index     => result'high,
                        right_index    => result'low,
                        overflow_style => overflow_style,
                        round_style    => round_style);
    elsif (to_x01(l(l'high)) = '1' and to_x01(r(r'high)) = '1') then
      result := resize (arg            => -dresult,
                        left_index     => result'high,
                        right_index    => result'low,
                        overflow_style => overflow_style,
                        round_style    => round_style);
    elsif (to_x01(l(l'high)) = '0' and to_x01(r(r'high)) = '1'
           and dresult_not_zero) then
      result := resize (arg            => dresult + r,
                        left_index     => result'high,
                        right_index    => result'low,
                        overflow_style => overflow_style,
                        round_style    => round_style);
    else
      result := resize (arg            => dresult,
                        left_index     => result'high,
                        right_index    => result'low,
                        overflow_style => overflow_style,
                        round_style    => round_style);
    end if;

    return result;

  end function modulo;

  -- Procedure for those who need an "accumulator" function
  procedure add_carry (
    l,
    r      : in  unresolved_ufixed;
    c_in   : in  std_ulogic;
    result : out unresolved_ufixed;
    c_out  : out std_ulogic
  ) is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);
    variable result_slv       : unsigned (LEFT_INDEX - RIGHT_INDEX
                                           downto 0);
    variable cx               : unsigned (0 downto 0);  -- Carry in

  begin

    if (l'length < 1 or r'length < 1) then
      result := NAUF;
      c_out  := '0';
    else
      cx (0)     := c_in;
      lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv       := to_uns (lresize);
      rslv       := to_uns (rresize);
      result_slv := lslv + rslv + cx;
      c_out      := result_slv(LEFT_INDEX - RIGHT_INDEX);
      result     := to_fixed(result_slv (LEFT_INDEX - RIGHT_INDEX - 1 downto 0),
                             LEFT_INDEX - 1, RIGHT_INDEX);
    end if;

  end procedure add_carry;

  procedure add_carry (
    l,
    r      : in  unresolved_sfixed;
    c_in   : in  std_ulogic;
    result : out unresolved_sfixed;
    c_out  : out std_ulogic
  ) is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high) + 1;
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (LEFT_INDEX - RIGHT_INDEX
                                         downto 0);
    variable result_slv       : signed (LEFT_INDEX - RIGHT_INDEX
                                         downto 0);
    variable cx               : signed (1 downto 0);  -- Carry in

  begin

    if (l'length < 1 or r'length < 1) then
      result := NASF;
      c_out  := '0';
    else
      cx (1)     := '0';
      cx (0)     := c_in;
      lresize    := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize    := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv       := to_s (lresize);
      rslv       := to_s (rresize);
      result_slv := lslv + rslv + cx;
      c_out      := result_slv(LEFT_INDEX - RIGHT_INDEX);
      result     := to_fixed(result_slv (LEFT_INDEX - RIGHT_INDEX - 1 downto 0),
                             LEFT_INDEX - 1, RIGHT_INDEX);
    end if;

  end procedure add_carry;

  -- Scales the result by a power of 2.  Width of input = width of output with
  -- the decimal point moved.
  function scalb (
    y : unresolved_ufixed;
    n : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (y'high+n downto y'low+n);

  begin

    if (y'length < 1) then
      return NAUF;
    else
      result := y;
      return result;
    end if;

  end function scalb;

  function scalb (
    y : unresolved_ufixed;
    n : signed
  )
    return unresolved_ufixed is
  begin

    return scalb (y => y,
                  n => to_integer(n));

  end function scalb;

  function scalb (
    y : unresolved_sfixed;
    n : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (y'high+n downto y'low+n);

  begin

    if (y'length < 1) then
      return NASF;
    else
      result := y;
      return result;
    end if;

  end function scalb;

  function scalb (
    y : unresolved_sfixed;
    n : signed
  )
    return unresolved_sfixed is
  begin

    return scalb (y => y,
                  n => to_integer(n));

  end function scalb;

  function is_negative (
    arg : unresolved_sfixed
  ) return boolean is
  begin

    if (to_X01(arg(arg'high)) = '1') then
      return true;
    else
      return false;
    end if;

  end function is_negative;

  function find_rightmost (
    arg : unresolved_ufixed;
    y : std_ulogic
  )
    return integer is
  begin

    for_loop : for i in arg'reverse_range loop

      if \?=\(arg(i), y) = '1' then
        return i;
      end if;

    end loop;

    return arg'high+1;                  -- return out of bounds 'high

  end function find_rightmost;

  function find_leftmost (
    arg : unresolved_ufixed;
    y : std_ulogic
  )
    return integer is
  begin

    for_loop : for i in arg'range loop

      if \?=\(arg(i), y) = '1' then
        return i;
      end if;

    end loop;

    return arg'low-1;                   -- return out of bounds 'low

  end function find_leftmost;

  function find_rightmost (
    arg : unresolved_sfixed;
    y : std_ulogic
  )
    return integer is
  begin

    for_loop : for i in arg'reverse_range loop

      if \?=\(arg(i), y) = '1' then
        return i;
      end if;

    end loop;

    return arg'high+1;                  -- return out of bounds 'high

  end function find_rightmost;

  function find_leftmost (
    arg : unresolved_sfixed;
    y : std_ulogic
  )
    return integer is
  begin

    for_loop : for i in arg'range loop

      if \?=\(arg(i), y) = '1' then
        return i;
      end if;

    end loop;

    return arg'low-1;                   -- return out of bounds 'low

  end function find_leftmost;

  function "sll" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    argslv := argslv sll count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sll";

  function "srl" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    argslv := argslv srl count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "srl";

  function "rol" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    argslv := argslv rol count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "rol";

  function "ror" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    argslv := argslv ror count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "ror";

  function "sla" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    -- Arithmetic shift on an unsigned is a logical shift
    argslv := argslv sll count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sla";

  function "sra" (
    arg : unresolved_ufixed;
    count : integer
  )
    return unresolved_ufixed
  is

    variable argslv : unsigned (arg'length-1 downto 0);
    variable result : unresolved_ufixed (arg'range);

  begin

    argslv := to_uns (arg);
    -- Arithmetic shift on an unsigned is a logical shift
    argslv := argslv srl count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sra";

  function "sll" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);
    argslv := argslv sll count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sll";

  function "srl" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);
    argslv := argslv srl count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "srl";

  function "rol" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);
    argslv := argslv rol count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "rol";

  function "ror" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);
    argslv := argslv ror count;
    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "ror";

  function "sla" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);

    if (count > 0) then
      -- Arithmetic shift left on a 2's complement number is a logic shift
      argslv := argslv sll count;
    else
      argslv := private_sra(argslv, -count);
    end if;

    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sla";

  function "sra" (
    arg : unresolved_sfixed;
    count : integer
  )
    return unresolved_sfixed
  is

    variable argslv : signed (arg'length-1 downto 0);
    variable result : unresolved_sfixed (arg'range);

  begin

    argslv := to_s (arg);

    if (count > 0) then
      argslv := private_sra(argslv, count);
    else
      -- Arithmetic shift left on a 2's complement number is a logic shift
      argslv := argslv sll -count;
    end if;

    result := to_fixed (argslv, result'high, result'low);
    return result;

  end function "sra";

  -- Because some people want the older functions.
  function shift_left (
    arg : unresolved_ufixed;
    count : NATURAL
  )
    return unresolved_ufixed is
  begin

    if (arg'length < 1) then
      return NAUF;
    end if;

    return arg sla count;

  end function shift_left;

  function shift_right (
    arg : unresolved_ufixed;
    count : NATURAL
  )
    return unresolved_ufixed is
  begin

    if (arg'length < 1) then
      return NAUF;
    end if;

    return arg sra count;

  end function shift_right;

  function shift_left (
    arg : unresolved_sfixed;
    count : NATURAL
  )
    return unresolved_sfixed is
  begin

    if (arg'length < 1) then
      return NASF;
    end if;

    return arg sla count;

  end function shift_left;

  function shift_right (
    arg : unresolved_sfixed;
    count : NATURAL
  )
    return unresolved_sfixed is
  begin

    if (arg'length < 1) then
      return NASF;
    end if;

    return arg sra count;

  end function shift_right;

  ----------------------------------------------------------------------------
  -- logical functions
  ----------------------------------------------------------------------------
  function "not" (
    l : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    result := not to_sulv(l);
    return to_ufixed(result, l'high, l'low);

  end function "not";

  function "and" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) and to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """and"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "and";

  function "or" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) or to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """or"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "or";

  function "nand" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) nand to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """nand"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "nand";

  function "nor" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) nor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """nor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "nor";

  function "xor" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) xor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """xor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "xor";

  function "xnor" (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) xnor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """xnor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_ufixed(result, l'high, l'low);

  end function "xnor";

  function "not" (
    l : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    result := not to_sulv(l);
    return to_sfixed(result, l'high, l'low);

  end function "not";

  function "and" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) and to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """and"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "and";

  function "or" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) or to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """or"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "or";

  function "nand" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) nand to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """nand"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "nand";

  function "nor" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) nor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """nor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "nor";

  function "xor" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) xor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """xor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "xor";

  function "xnor" (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    variable result : std_ulogic_vector(l'length-1 downto 0);  -- force downto

  begin

    if (l'high = r'high and l'low = r'low) then
      result := to_sulv(l) xnor to_sulv(r);
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """xnor"": Range error L'RANGE /= R'RANGE"
        severity warning;
      result := (others => 'X');
    end if;

    return to_sfixed(result, l'high, l'low);

  end function "xnor";

  -- Vector and std_ulogic functions, same as functions in numeric_std
  function "and" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l and r(i);

    end loop;

    return result;

  end function "and";

  function "and" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) and r;

    end loop;

    return result;

  end function "and";

  function "or" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l or r(i);

    end loop;

    return result;

  end function "or";

  function "or" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) or r;

    end loop;

    return result;

  end function "or";

  function "nand" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l nand r(i);

    end loop;

    return result;

  end function "nand";

  function "nand" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) nand r;

    end loop;

    return result;

  end function "nand";

  function "nor" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l nor r(i);

    end loop;

    return result;

  end function "nor";

  function "nor" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) nor r;

    end loop;

    return result;

  end function "nor";

  function "xor" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l xor r(i);

    end loop;

    return result;

  end function "xor";

  function "xor" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) xor r;

    end loop;

    return result;

  end function "xor";

  function "xnor" (
    l : std_ulogic;
    r : unresolved_ufixed
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (r'range);

  begin

    for i in result'range loop

      result(i) := l xnor r(i);

    end loop;

    return result;

  end function "xnor";

  function "xnor" (
    l : unresolved_ufixed;
    r : std_ulogic
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) xnor r;

    end loop;

    return result;

  end function "xnor";

  function "and" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l and r(i);

    end loop;

    return result;

  end function "and";

  function "and" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) and r;

    end loop;

    return result;

  end function "and";

  function "or" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l or r(i);

    end loop;

    return result;

  end function "or";

  function "or" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) or r;

    end loop;

    return result;

  end function "or";

  function "nand" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l nand r(i);

    end loop;

    return result;

  end function "nand";

  function "nand" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) nand r;

    end loop;

    return result;

  end function "nand";

  function "nor" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l nor r(i);

    end loop;

    return result;

  end function "nor";

  function "nor" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) nor r;

    end loop;

    return result;

  end function "nor";

  function "xor" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l xor r(i);

    end loop;

    return result;

  end function "xor";

  function "xor" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) xor r;

    end loop;

    return result;

  end function "xor";

  function "xnor" (
    l : std_ulogic;
    r : unresolved_sfixed
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (r'range);

  begin

    for i in result'range loop

      result(i) := l xnor r(i);

    end loop;

    return result;

  end function "xnor";

  function "xnor" (
    l : unresolved_sfixed;
    r : std_ulogic
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (l'range);

  begin

    for i in result'range loop

      result(i) := l(i) xnor r;

    end loop;

    return result;

  end function "xnor";

  -- Reduction operators
  function and_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_and_reduce(to_sulv(l));

  end function and_reduce;

  function nand_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_nand_reduce(to_sulv(l));

  end function nand_reduce;

  function or_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_or_reduce(to_sulv(l));

  end function or_reduce;

  function nor_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_nor_reduce(to_sulv(l));

  end function nor_reduce;

  function xor_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_xor_reduce(to_sulv(l));

  end function xor_reduce;

  function xnor_reduce (
    l : unresolved_ufixed
  ) return std_ulogic is
  begin

    return private_xnor_reduce(to_sulv(l));

  end function xnor_reduce;

  function and_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_and_reduce(to_sulv(l));

  end function and_reduce;

  function nand_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_nand_reduce(to_sulv(l));

  end function nand_reduce;

  function or_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_or_reduce(to_sulv(l));

  end function or_reduce;

  function nor_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_nor_reduce(to_sulv(l));

  end function nor_reduce;

  function xor_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_xor_reduce(to_sulv(l));

  end function xor_reduce;

  function xnor_reduce (
    l : unresolved_sfixed
  ) return std_ulogic is
  begin

    return private_xnor_reduce(to_sulv(l));

  end function xnor_reduce;

  -- End reduction operators

  function \?=\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?=\(lslv, rslv);
    end if;

  end function \?=\;

  function \?/=\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?/=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?/=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?/=\(lslv, rslv);
    end if;

  end function \?/=\;

  function \?>\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?>

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?>\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?>\(lslv, rslv);
    end if;

  end function \?>\;

  function \?>=\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?>=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?>=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?>=\(lslv, rslv);
    end if;

  end function \?>=\;

  function \?<\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?<

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?<\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?<\(lslv, rslv);
    end if;

  end function \?<\;

  function \?<=\ (
    l,
    r : unresolved_ufixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin  -- ?<=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?<=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_uns (lresize);
      rslv    := to_uns (rresize);
      return \?<=\(lslv, rslv);
    end if;

  end function \?<=\;

  function \?=\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?=\(lslv, rslv);
    end if;

  end function \?=\;

  function \?/=\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?/=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?/=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?/=\(lslv, rslv);
    end if;

  end function \?/=\;

  function \?>\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?>

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?>\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?>\(lslv, rslv);
    end if;

  end function \?>\;

  function \?>=\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?>=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?>=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?>=\(lslv, rslv);
    end if;

  end function \?>=\;

  function \?<\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?<

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?<\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?<\(lslv, rslv);
    end if;

  end function \?<\;

  function \?<=\ (
    l,
    r : unresolved_sfixed
  ) return std_ulogic is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin  -- ?<=

    if ((l'length < 1) or (r'length < 1)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """\?<=\"": null detected, returning X"
        severity warning;
      return 'X';
    else
      lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
      rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
      lslv    := to_s (lresize);
      rslv    := to_s (rresize);
      return \?<=\(lslv, rslv);
    end if;

  end function \?<=\;

  -- Match function, similar to "std_match" from numeric_std
  function std_match (
    l,
    r : unresolved_ufixed
  ) return boolean is
  begin

    if (l'high = r'high and l'low = r'low) then
      return std_match(to_sulv(l), to_sulv(r));
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "STD_MATCH: L'RANGE /= R'RANGE, returning FALSE"
        severity warning;
      return false;
    end if;

  end function std_match;

  function std_match (
    l,
    r : unresolved_sfixed
  ) return boolean is
  begin

    if (l'high = r'high and l'low = r'low) then
      return std_match(to_sulv(l), to_sulv(r));
    else
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "STD_MATCH: L'RANGE /= R'RANGE, returning FALSE"
        severity warning;
      return false;
    end if;

  end function std_match;

  -- compare functions
  function "=" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_uns (lresize);
    rslv    := to_uns (rresize);
    return lslv = rslv;

  end function "=";

  function "=" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_s (lresize);
    rslv    := to_s (rresize);
    return lslv = rslv;

  end function "=";

  function "/=" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """/="": null argument detected, returning TRUE"
        severity warning;
      return true;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """/="": metavalue detected, returning TRUE"
        severity warning;
      return true;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_uns (lresize);
    rslv    := to_uns (rresize);
    return lslv /= rslv;

  end function "/=";

  function "/=" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """/="": null argument detected, returning TRUE"
        severity warning;
      return true;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """/="": metavalue detected, returning TRUE"
        severity warning;
      return true;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_s (lresize);
    rslv    := to_s (rresize);
    return lslv /= rslv;

  end function "/=";

  function ">" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>"": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>"": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_uns (lresize);
    rslv    := to_uns (rresize);
    return lslv > rslv;

  end function ">";

  function ">" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>"": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>"": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_s (lresize);
    rslv    := to_s (rresize);
    return lslv > rslv;

  end function ">";

  function "<" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<"": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<"": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_uns (lresize);
    rslv    := to_uns (rresize);
    return lslv < rslv;

  end function "<";

  function "<" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<"": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<"": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_s (lresize);
    rslv    := to_s (rresize);
    return lslv < rslv;

  end function "<";

  function ">=" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_uns (lresize);
    rslv    := to_uns (rresize);
    return lslv >= rslv;

  end function ">=";

  function ">=" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """>="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv    := to_s (lresize);
    rslv    := to_s (rresize);
    return lslv >= rslv;

  end function ">=";

  function "<=" (
    l,
    r : unresolved_ufixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : unsigned (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize     := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize     := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv        := to_uns (lresize);
    rslv        := to_uns (rresize);
    return lslv <= rslv;

  end function "<=";

  function "<=" (
    l,
    r : unresolved_sfixed
  )           -- fixed point input
    return boolean
  is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    variable lslv, rslv       : signed (lresize'length-1 downto 0);

  begin

    if (l'length < 1 or r'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<="": null argument detected, returning FALSE"
        severity warning;
      return false;
    elsif (is_x(l) or is_x(r)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & """<="": metavalue detected, returning FALSE"
        severity warning;
      return false;
    end if;

    lresize     := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize     := resize (r, LEFT_INDEX, RIGHT_INDEX);
    lslv        := to_s (lresize);
    rslv        := to_s (rresize);
    return lslv <= rslv;

  end function "<=";

  -- overloads of the default maximum and minimum functions
  function maximum (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (l'length < 1 or r'length < 1) then
      return NAUF;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    return to_fixed(private_maximum(to_uns(lresize), to_uns(rresize)),
                    LEFT_INDEX, RIGHT_INDEX);

  end function maximum;

  function maximum (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (l'length < 1 or r'length < 1) then
      return NASF;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    return to_fixed(private_maximum(to_s(lresize), to_s(rresize)),
                    LEFT_INDEX, RIGHT_INDEX);

  end function maximum;

  function minimum (
    l,
    r : unresolved_ufixed
  ) return unresolved_ufixed is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (l'length < 1 or r'length < 1) then
      return NAUF;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    return to_fixed(private_minimum(to_uns(lresize), to_uns(rresize)),
                    LEFT_INDEX, RIGHT_INDEX);

  end function minimum;

  function minimum (
    l,
    r : unresolved_sfixed
  ) return unresolved_sfixed is

    constant LEFT_INDEX       : integer := private_maximum(l'high, r'high);
    constant RIGHT_INDEX      : integer := mins(l'low, r'low);
    variable lresize, rresize : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (l'length < 1 or r'length < 1) then
      return NASF;
    end if;

    lresize := resize (l, LEFT_INDEX, RIGHT_INDEX);
    rresize := resize (r, LEFT_INDEX, RIGHT_INDEX);
    return to_fixed(private_minimum(to_s(lresize), to_s(rresize)),
                    LEFT_INDEX, RIGHT_INDEX);

  end function minimum;

  function to_ufixed (
    arg                     : NATURAL;  -- integer
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer                   := 0;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant FW      : integer                                 := mins (right_index, right_index);  -- catch literals
    variable result  : unresolved_ufixed (left_index downto FW);
    variable sresult : unresolved_ufixed (left_index downto 0) :=
             (others => '0');  -- integer portion
    variable argx    : natural;         -- internal version of arg

  begin

    if (result'length < 1) then
      return NAUF;
    end if;

    if (arg /= 0) then
      argx := arg;

      for i in 0 to sresult'left loop

        if ((argx mod 2) = 0) then
          sresult(I) := '0';
        else
          sresult(I) := '1';
        end if;
        argx := argx / 2;

      end loop;

      if (argx /= 0) then
        assert no_warning
          report fixed_generic_pkg'instance_name
                 & "TO_UFIXED(NATURAL): vector truncated"
          severity warning;
        if (overflow_style = fixed_saturate) then
          return saturate (left_index, right_index);
        end if;
      end if;
      result := resize (arg            => sresult,
                        left_index     => left_index,
                        right_index    => right_index,
                        round_style    => round_style,
                        overflow_style => overflow_style);
    else
      result := (others => '0');
    end if;

    return result;

  end function to_ufixed;

  function to_sfixed (
    arg                     : integer;  -- integer
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer                   := 0;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant FW      : integer                                 := mins (right_index, right_index);  -- catch literals
    variable result  : unresolved_sfixed (left_index downto FW);
    variable sresult : unresolved_sfixed (left_index downto 0) :=
             (others => '0');  -- integer portion
    variable argx    : integer;         -- internal version of arg
    variable sign    : std_ulogic;      -- sign of input

  begin

    if (result'length < 1) then         -- null range
      return NASF;
    end if;

    if (arg /= 0) then
      if (arg < 0) then
        sign := '1';
        argx := -(arg + 1);
      else
        sign := '0';
        argx := arg;
      end if;

      for i in 0 to sresult'left loop

        if ((argx mod 2) = 0) then
          sresult(I) := sign;
        else
          sresult(I) := not sign;
        end if;
        argx := argx / 2;

      end loop;

      if (argx /= 0 or left_index < 0 or sign /= sresult(sresult'left)) then
        assert no_warning
          report fixed_generic_pkg'instance_name
                 & "TO_SFIXED(integer): vector truncated"
          severity warning;
        if (overflow_style = fixed_saturate) then                -- saturate
          if (arg < 0) then
            result := not saturate (result'high, result'low);  -- underflow
          else
            result := saturate (result'high, result'low);      -- overflow
          end if;
          return result;
        end if;
      end if;
      result := resize (arg            => sresult,
                        left_index     => left_index,
                        right_index    => right_index,
                        round_style    => round_style,
                        overflow_style => overflow_style);
    else
      result := (others => '0');
    end if;

    return result;

  end function to_sfixed;

  function to_ufixed (
    arg                     : REAL;     -- real
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style;
    constant guard_bits     : NATURAL                   := fixed_guard_bits
  )  -- # of guard bits
    return unresolved_ufixed
  is

    constant FW      : integer                                  := mins (right_index, right_index);  -- catch literals
    variable result  : unresolved_ufixed (left_index downto FW) :=
             (others => '0');
    variable xresult : unresolved_ufixed (left_index downto
                                           FW - guard_bits)     :=
             (others => '0');
    variable presult : real;

  begin

    -- If negative or null range, return.
    if (left_index < FW) then
      return NAUF;
    end if;

    if (arg < 0.0) then
      report fixed_generic_pkg'instance_name
             & "TO_UFIXED: Negative argument passed "
             & REAL'image(arg)
        severity error;
      return result;
    end if;

    presult := arg;

    if (presult >= (2.0 ** (left_index + 1))) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_UFIXED(REAL): vector truncated"
        severity warning;
      if (overflow_style = fixed_wrap) then
        presult := presult mod (2.0 ** (left_index + 1));  -- wrap
      else
        return saturate (result'high, result'low);
      end if;
    end if;

    for i in xresult'range loop

      if (presult >= 2.0 ** i) then
        xresult(i) := '1';
        presult    := presult - 2.0 ** i;
      else
        xresult(i) := '0';
      end if;

    end loop;

    if (guard_bits > 0 and round_style = fixed_round) then
      result := round_fixed (arg => Xresult (left_index
                                             downto right_index),
                             remainder => Xresult (right_index - 1 downto
                                                    right_index - guard_bits),
                             overflow_style => overflow_style);
    else
      result := Xresult (result'range);
    end if;

    return result;

  end function to_ufixed;

  function to_sfixed (
    arg                     : REAL;     -- real
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style;
    constant guard_bits     : NATURAL                   := fixed_guard_bits
  )  -- # of guard bits
    return unresolved_sfixed
  is

    constant FW      : integer                                                   := mins (right_index, right_index);  -- catch literals
    variable result  : unresolved_sfixed (left_index downto FW)                  :=
             (others => '0');
    variable xresult : unresolved_sfixed (left_index + 1 downto FW - guard_bits) :=
             (others => '0');
    variable presult : real;

  begin

    if (left_index < FW) then           -- null range
      return NASF;
    end if;

    if (arg >= (2.0 ** left_index) or arg < -(2.0 ** left_index)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_SFIXED(REAL): vector truncated"
        severity warning;
      if (overflow_style = fixed_saturate) then
        if (arg < 0.0) then               -- saturate
          result := not saturate (result'high, result'low);        -- underflow
        else
          result := saturate (result'high, result'low);            -- overflow
        end if;
        return result;
      else
        presult := abs(arg) mod (2.0 ** (left_index + 1));             -- wrap
      end if;
    else
      presult := abs(arg);
    end if;

    for i in xresult'range loop

      if (presult >= 2.0 ** i) then
        xresult(i) := '1';
        presult    := presult - 2.0 ** i;
      else
        xresult(i) := '0';
      end if;

    end loop;

    if (arg < 0.0) then
      xresult := to_fixed(-to_s(xresult), xresult'high, xresult'low);
    end if;

    if (guard_bits > 0 and round_style = fixed_round) then
      result := round_fixed (arg => Xresult (left_index
                                             downto right_index),
                             remainder => Xresult (right_index - 1 downto
                                                    right_index - guard_bits),
                             overflow_style => overflow_style);
    else
      result := Xresult (result'range);
    end if;

    return result;

  end function to_sfixed;

  function to_ufixed (
    arg                     : unsigned;             -- unsigned
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer                   := 0;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant ARG_LEFT : integer := arg'length-1;
    alias    xarg     : unsigned(ARG_LEFT downto 0) is arg;
    variable result   : unresolved_ufixed (left_index downto right_index);

  begin

    if (arg'length < 1 or (left_index < right_index)) then
      return NAUF;
    end if;

    result := resize (arg            => unresolved_ufixed (xarg),
                      left_index     => left_index,
                      right_index    => right_index,
                      round_style    => round_style,
                      overflow_style => overflow_style);
    return result;

  end function to_ufixed;

  -- converted version
  function to_ufixed (
    arg : unsigned
  )          -- unsigned
    return unresolved_ufixed
  is

    constant ARG_LEFT : integer := arg'length-1;
    alias    xarg     : unsigned(ARG_LEFT downto 0) is arg;

  begin

    if (arg'length < 1) then
      return NAUF;
    end if;

    return unresolved_ufixed(xarg);

  end function to_ufixed;

  function to_sfixed (
    arg                     : signed;               -- signed
    constant left_index     : integer;  -- left index (high index)
    constant right_index    : integer                   := 0;  -- right index
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant ARG_LEFT : integer := arg'length-1;
    alias    xarg     : signed(ARG_LEFT downto 0) is arg;
    variable result   : unresolved_sfixed (left_index downto right_index);

  begin

    if (arg'length < 1 or (left_index < right_index)) then
      return NASF;
    end if;

    result := resize (arg            => unresolved_sfixed (xarg),
                      left_index     => left_index,
                      right_index    => right_index,
                      round_style    => round_style,
                      overflow_style => overflow_style);
    return result;

  end function to_sfixed;

  -- converted version
  function to_sfixed (
    arg : signed
  )            -- signed
    return unresolved_sfixed
  is

    constant ARG_LEFT : integer := arg'length-1;
    alias    xarg     : signed(ARG_LEFT downto 0) is arg;

  begin

    if (arg'length < 1) then
      return NASF;
    end if;

    return unresolved_sfixed(xarg);

  end function to_sfixed;

  function to_sfixed (
    arg : unresolved_ufixed
  ) return unresolved_sfixed is

    variable result : unresolved_sfixed (arg'high+1 downto arg'low);

  begin

    if (arg'length < 1) then
      return NASF;
    end if;

    result (arg'high downto arg'low) := unresolved_sfixed(cleanvec(arg));
    result (arg'high + 1)            := '0';
    return result;

  end function to_sfixed;

  -- Because of the fairly complicated sizing rules in the fixed point
  -- packages these functions are provided to compute the result ranges
  -- Example:
  -- signal uf1 : ufixed (3 downto -3);
  -- signal uf2 : ufixed (4 downto -2);
  -- signal uf1multuf2 : ufixed (ufixed_high (3, -3, '*', 4, -2) downto
  --                             ufixed_low (3, -3, '*', 4, -2));
  -- uf1multuf2 <= uf1 * uf2;
  -- Valid characters: '+', '-', '*', '/', 'r' or 'R' (rem), 'm' or 'M' (mod),
  -- '1' (reciprocal), 'A', 'a' (abs), 'N', 'n' (-sfixed)
  function ufixed_high (
    left_index,
    right_index   : integer;
    operation                 : CHARACTER := 'X';
    left_index2,
    right_index2 : integer   := 0
  )
    return integer is
  begin

    case operation is

      when '+'| '-' =>
        return private_maximum (left_index, left_index2) + 1;

      when '*' =>
        return left_index + left_index2 + 1;

      when '/' =>
        return left_index - right_index2;

      when '1' =>
        return -right_index;                    -- reciprocal

      when 'R'|'r' =>
        return mins (left_index, left_index2);  -- "rem"

      when 'M'|'m' =>
        return mins (left_index, left_index2);  -- "mod"

      when others =>
        return left_index;  -- For abs and default

    end case;

  end function ufixed_high;

  function ufixed_low (
    left_index,
    right_index   : integer;
    operation                 : CHARACTER := 'X';
    left_index2,
    right_index2 : integer   := 0
  )
    return integer is
  begin

    case operation is

      when '+'| '-' =>
        return mins (right_index, right_index2);

      when '*' =>
        return right_index + right_index2;

      when '/' =>
        return right_index - left_index2 - 1;

      when '1' =>
        return -left_index - 1;                   -- reciprocal

      when 'R'|'r' =>
        return mins (right_index, right_index2);  -- "rem"

      when 'M'|'m' =>
        return mins (right_index, right_index2);  -- "mod"

      when others =>
        return right_index;  -- for abs and default

    end case;

  end function ufixed_low;

  function sfixed_high (
    left_index,
    right_index   : integer;
    operation                 : CHARACTER := 'X';
    left_index2,
    right_index2 : integer   := 0
  )
    return integer is
  begin

    case operation is

      when '+'| '-' =>
        return private_maximum (left_index, left_index2) + 1;

      when '*' =>
        return left_index + left_index2 + 1;

      when '/' =>
        return left_index - right_index2 + 1;

      when '1' =>
        return -right_index + 1;                -- reciprocal

      when 'R'|'r' =>
        return mins (left_index, left_index2);  -- "rem"

      when 'M'|'m' =>
        return left_index2;                     -- "mod"

      when 'A'|'a' =>
        return left_index + 1;                  -- "abs"

      when 'N'|'n' =>
        return left_index + 1;                  -- -sfixed

      when others =>
        return left_index;

    end case;

  end function sfixed_high;

  function sfixed_low (
    left_index,
    right_index   : integer;
    operation                 : CHARACTER := 'X';
    left_index2,
    right_index2 : integer   := 0
  )
    return integer is
  begin

    case operation is

      when '+'| '-' =>
        return mins (right_index, right_index2);

      when '*' =>
        return right_index + right_index2;

      when '/' =>
        return right_index - left_index2;

      when '1' =>
        return -left_index;  -- reciprocal

      when 'R'|'r' =>
        return mins (right_index, right_index2);  -- "rem"

      when 'M'|'m' =>
        return mins (right_index, right_index2);  -- "mod"

      when others =>
        return right_index;  -- default for abs, neg and default

    end case;

  end function sfixed_low;

  -- Same as above, but using the "size_res" input only for their ranges:
  -- signal uf1multuf2 : ufixed (ufixed_high (uf1, '*', uf2) downto
  --                             ufixed_low (uf1, '*', uf2));
  -- uf1multuf2 <= uf1 * uf2;
  function ufixed_high (
    size_res  : unresolved_ufixed;
    operation : CHARACTER := 'X';
    size_res2 : unresolved_ufixed
  )
    return integer is
  begin

    return ufixed_high (left_index   => size_res'high,
                        right_index  => size_res'low,
                        operation    => operation,
                        left_index2  => size_res2'high,
                        right_index2 => size_res2'low);

  end function ufixed_high;

  function ufixed_low (
    size_res  : unresolved_ufixed;
    operation : CHARACTER := 'X';
    size_res2 : unresolved_ufixed
  )
    return integer is
  begin

    return ufixed_low (left_index   => size_res'high,
                       right_index  => size_res'low,
                       operation    => operation,
                       left_index2  => size_res2'high,
                       right_index2 => size_res2'low);

  end function ufixed_low;

  function sfixed_high (
    size_res  : unresolved_sfixed;
    operation : CHARACTER := 'X';
    size_res2 : unresolved_sfixed
  )
    return integer is
  begin

    return sfixed_high (left_index   => size_res'high,
                        right_index  => size_res'low,
                        operation    => operation,
                        left_index2  => size_res2'high,
                        right_index2 => size_res2'low);

  end function sfixed_high;

  function sfixed_low (
    size_res  : unresolved_sfixed;
    operation : CHARACTER := 'X';
    size_res2 : unresolved_sfixed
  )
    return integer is
  begin

    return sfixed_low (left_index   => size_res'high,
                       right_index  => size_res'low,
                       operation    => operation,
                       left_index2  => size_res2'high,
                       right_index2 => size_res2'low);

  end function sfixed_low;

  -- purpose: returns a saturated number
  function saturate (
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    constant SAT : unresolved_ufixed (left_index downto right_index) :=
    (
      others => '1'
    );

  begin

    return SAT;

  end function saturate;

  -- purpose: returns a saturated number
  function saturate (
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable sat : unresolved_sfixed (left_index downto right_index) :=
             (others => '1');

  begin

    -- saturate positive, to saturate negative, just do "not saturate()"
    sat (left_index) := '0';
    return sat;

  end function saturate;

  function saturate (
    size_res : unresolved_ufixed
  )       -- only the size of this is used
    return unresolved_ufixed is
  begin

    return saturate (size_res'high, size_res'low);

  end function saturate;

  function saturate (
    size_res : unresolved_sfixed
  )       -- only the size of this is used
    return unresolved_sfixed is
  begin

    return saturate (size_res'high, size_res'low);

  end function saturate;

  -- As a concession to those who use a graphical DSP environment,
  -- these functions take parameters in those tools format and create
  -- fixed point numbers.  These functions are designed to convert from
  -- a std_logic_vector to the VHDL fixed point format using the conventions
  -- of these packages.  In a pure VHDL environment you should use the
  -- "to_ufixed" and "to_sfixed" routines.
  -- Unsigned fixed point
  function to_ufix (
    arg      : std_ulogic_vector;
    width    : NATURAL;                 -- width of vector
    fraction : NATURAL
  )                 -- width of fraction
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (width - fraction - 1 downto -fraction);

  begin

    if (arg'length /= result'length) then
      report fixed_generic_pkg'instance_name
             & "TO_UFIX (std_ulogic_vector) "
             & "Vector lengths do not match.  Input length is "
             & integer'image(arg'length) & " and output will be "
             & integer'image(result'length) & " wide."
        severity error;
      return NAUF;
    else
      result := to_ufixed (arg, result'high, result'low);
      return result;
    end if;

  end function to_ufix;

  -- signed fixed point
  function to_sfix (
    arg      : std_ulogic_vector;
    width    : NATURAL;                 -- width of vector
    fraction : NATURAL
  )                 -- width of fraction
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (width - fraction - 1 downto -fraction);

  begin

    if (arg'length /= result'length) then
      report fixed_generic_pkg'instance_name
             & "TO_SFIX (std_ulogic_vector) "
             & "Vector lengths do not match.  Input length is "
             & integer'image(arg'length) & " and output will be "
             & integer'image(result'length) & " wide."
        severity error;
      return NASF;
    else
      result := to_sfixed (arg, result'high, result'low);
      return result;
    end if;

  end function to_sfix;

  -- finding the bounds of a number.  These functions can be used like this:
  -- signal xxx : ufixed (7 downto -3);
  -- -- Which is the same as "ufixed (UFix_high (11,3) downto UFix_low(11,3))"
  -- signal yyy : ufixed (UFix_high (11, 3, "+", 11, 3)
  --               downto UFix_low(11, 3, "+", 11, 3));
  -- Where "11" is the width of xxx (xxx'length),
  -- and 3 is the lower bound (abs (xxx'low))
  -- In a pure VHDL environment use "ufixed_high" and "ufixed_low"
  function ufix_high (
    width,
    fraction   : NATURAL;
    operation         : CHARACTER := 'X';
    width2,
    fraction2 : NATURAL   := 0
  )
    return integer is
  begin

    return ufixed_high (left_index   => width - 1 - fraction,
                        right_index  => -fraction,
                        operation    => operation,
                        left_index2  => width2 - 1 - fraction2,
                        right_index2 => -fraction2);

  end function ufix_high;

  function ufix_low (
    width,
    fraction   : NATURAL;
    operation         : CHARACTER := 'X';
    width2,
    fraction2 : NATURAL   := 0
  )
    return integer is
  begin

    return ufixed_low (left_index   => width - 1 - fraction,
                       right_index  => -fraction,
                       operation    => operation,
                       left_index2  => width2 - 1 - fraction2,
                       right_index2 => -fraction2);

  end function ufix_low;

  function sfix_high (
    width,
    fraction   : NATURAL;
    operation         : CHARACTER := 'X';
    width2,
    fraction2 : NATURAL   := 0
  )
    return integer is
  begin

    return sfixed_high (left_index   => width - fraction,
                        right_index  => -fraction,
                        operation    => operation,
                        left_index2  => width2 - fraction2,
                        right_index2 => -fraction2);

  end function sfix_high;

  function sfix_low (
    width,
    fraction   : NATURAL;
    operation         : CHARACTER := 'X';
    width2,
    fraction2 : NATURAL   := 0
  )
    return integer is
  begin

    return sfixed_low (left_index   => width - fraction,
                       right_index  => -fraction,
                       operation    => operation,
                       left_index2  => width2 - fraction2,
                       right_index2 => -fraction2);

  end function sfix_low;

  function to_unsigned (
    arg                     : unresolved_ufixed;  -- ufixed point input
    constant size           : NATURAL;            -- length of output
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unsigned is
  begin

    return to_uns(resize (arg            => arg,
                          left_index     => size - 1,
                          right_index    => 0,
                          round_style    => round_style,
                          overflow_style => overflow_style));

  end function to_unsigned;

  function to_unsigned (
    arg                     : unresolved_ufixed;    -- ufixed point input
    size_res                : unsigned;  -- length of output
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unsigned is
  begin

    return to_unsigned (arg            => arg,
                        size           => size_res'length,
                        round_style    => round_style,
                        overflow_style => overflow_style);

  end function to_unsigned;

  function to_signed (
    arg                     : unresolved_sfixed;  -- sfixed point input
    constant size           : NATURAL;            -- length of output
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return signed is
  begin

    return to_s(resize (arg            => arg,
                        left_index     => size - 1,
                        right_index    => 0,
                        round_style    => round_style,
                        overflow_style => overflow_style));

  end function to_signed;

  function to_signed (
    arg                     : unresolved_sfixed;  -- sfixed point input
    size_res                : signed;  -- used for length of output
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return signed is
  begin

    return to_signed (arg            => arg,
                      size           => size_res'length,
                      round_style    => round_style,
                      overflow_style => overflow_style);

  end function to_signed;

  function to_real (
    arg : unresolved_ufixed
  )            -- ufixed point input
    return REAL
  is

    constant LEFT_INDEX  : integer := arg'high;
    constant RIGHT_INDEX : integer := arg'low;
    variable result      : real;        -- result
    variable arg_int     : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);

  begin

    if (arg'length < 1) then
      return 0.0;
    end if;

    arg_int := To_X01(cleanvec(arg));

    if (is_x(arg_int)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_REAL (ufixed): metavalue detected, returning 0.0"
        severity warning;
      return 0.0;
    end if;

    result := 0.0;

    for i in arg_int'range loop

      if (arg_int(i) = '1') then
        result := result + (2.0 ** i);
      end if;

    end loop;

    return result;

  end function to_real;

  function to_real (
    arg : unresolved_sfixed
  )            -- ufixed point input
    return REAL
  is

    constant LEFT_INDEX  : integer := arg'high;
    constant RIGHT_INDEX : integer := arg'low;
    variable result      : real;        -- result
    variable arg_int     : unresolved_sfixed (LEFT_INDEX downto RIGHT_INDEX);
    -- unsigned version of argument
    variable arg_uns : unresolved_ufixed (LEFT_INDEX downto RIGHT_INDEX);
  -- absolute of argument

  begin

    if (arg'length < 1) then
      return 0.0;
    end if;

    arg_int := to_X01(cleanvec(arg));

    if (is_x(arg_int)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_REAL (sfixed): metavalue detected, returning 0.0"
        severity warning;
      return 0.0;
    end if;

    arg_uns := to_ufixed (arg_int);
    result  := to_real (arg_uns);

    if (arg_int(arg_int'high) = '1') then
      result := -result;
    end if;

    return result;

  end function to_real;

  function to_integer (
    arg                     : unresolved_ufixed;  -- fixed point input
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return NATURAL
  is

    constant LEFT_INDEX : integer := arg'high;
    variable arg_uns    : unsigned (LEFT_INDEX + 1 downto 0)
                                  := (others => '0');

  begin

    if (arg'length < 1) then
      return 0;
    end if;

    if (is_x (arg)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_integer (ufixed): metavalue detected, returning 0"
        severity warning;
      return 0;
    end if;

    if (LEFT_INDEX < -1) then
      return 0;
    end if;

    arg_uns := to_uns(resize (arg            => arg,
                              LEFT_INDEX     => arg_uns'high,
                              right_index    => 0,
                              round_style    => round_style,
                              overflow_style => overflow_style));
    return to_integer (arg_uns);

  end function to_integer;

  function to_integer (
    arg                     : unresolved_sfixed;  -- fixed point input
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return integer
  is

    constant LEFT_INDEX : integer := arg'high;
    variable arg_s      : signed (LEFT_INDEX + 1 downto 0);

  begin

    if (arg'length < 1) then
      return 0;
    end if;

    if (is_x (arg)) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_integer (sfixed): metavalue detected, returning 0"
        severity warning;
      return 0;
    end if;

    if (LEFT_INDEX < -1) then
      return 0;
    end if;

    arg_s := to_s(resize (arg            => arg,
                          LEFT_INDEX     => arg_s'high,
                          right_index    => 0,
                          round_style    => round_style,
                          overflow_style => overflow_style));
    return to_integer (arg_s);

  end function to_integer;

  function to_01 (
    s             : unresolved_ufixed;              -- ufixed point input
    constant xmap : std_ulogic := '0'
  )              -- Map x to
    return unresolved_ufixed
  is
  begin

    if (s'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_01(ufixed): null detected, returning NULL"
        severity warning;
      return NAUF;
    end if;

    return to_fixed (to_01(to_uns(s), xmap), s'high, s'low);

  end function to_01;

  function to_01 (
    s             : unresolved_sfixed;  -- sfixed point input
    constant xmap : std_ulogic := '0'
  )  -- Map x to
    return unresolved_sfixed
  is
  begin

    if (s'length < 1) then
      assert no_warning
        report fixed_generic_pkg'instance_name
               & "TO_01(sfixed): null detected, returning NULL"
        severity warning;
      return NASF;
    end if;

    return to_fixed (to_01(to_s(s), xmap), s'high, s'low);

  end function to_01;

  function is_x (
    arg : unresolved_ufixed
  )
    return boolean
  is

    variable argslv : std_ulogic_vector (arg'length-1 downto 0);  -- slv

  begin

    argslv := to_sulv(arg);
    return is_x (argslv);

  end function is_x;

  function is_x (
    arg : unresolved_sfixed
  )
    return boolean
  is

    variable argslv : std_ulogic_vector (arg'length-1 downto 0);  -- slv

  begin

    argslv := to_sulv(arg);
    return is_x (argslv);

  end function is_x;

  function to_x01 (
    arg : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return to_ufixed (To_X01(to_sulv(arg)), arg'high, arg'low);

  end function to_x01;

  function to_x01 (
    arg : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return to_sfixed (To_X01(to_sulv(arg)), arg'high, arg'low);

  end function to_x01;

  function to_x01z (
    arg : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return to_ufixed (To_X01Z(to_sulv(arg)), arg'high, arg'low);

  end function to_x01z;

  function to_x01z (
    arg : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return to_sfixed (To_X01Z(to_sulv(arg)), arg'high, arg'low);

  end function to_x01z;

  function to_ux01 (
    arg : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return to_ufixed (To_UX01(to_sulv(arg)), arg'high, arg'low);

  end function to_ux01;

  function to_ux01 (
    arg : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return to_sfixed (To_UX01(to_sulv(arg)), arg'high, arg'low);

  end function to_ux01;

  function resize (
    arg                     : unresolved_ufixed;            -- input
    constant left_index     : integer;  -- integer portion
    constant right_index    : integer;  -- size of fraction
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant ARGHIGH        : integer                                          := private_maximum (arg'high, arg'low);
    constant ARGLOW         : integer                                          := mine (arg'high, arg'low);
    variable invec          : unresolved_ufixed (ARGHIGH downto ARGLOW);
    variable result         : unresolved_ufixed(left_index downto right_index) :=
             (others => '0');
    variable needs_rounding : boolean                                          := false;

  begin  -- resize

    if ((arg'length < 1) or (result'length < 1)) then
      return NAUF;
    elsif (invec'length < 1) then
      return result;                    -- string literal value
    else
      invec := cleanvec(arg);
      if (right_index > ARGHIGH) then   -- return top zeros
        needs_rounding := (round_style = fixed_round) and
                          (right_index = ARGHIGH + 1);
      elsif (left_index < ARGLOW) then  -- return overflow
        if ((overflow_style = fixed_saturate) and
            (private_or_reduce(to_sulv(invec)) = '1')) then
          result := saturate (result'high, result'low);     -- saturate
        end if;
      elsif (ARGHIGH > left_index) then
        -- wrap or saturate?
        if (overflow_style = fixed_saturate and
            private_or_reduce(to_sulv(invec(ARGHIGH downto left_index + 1))) = '1') then
          result := saturate (result'high, result'low);     -- saturate
        else
          if (ARGLOW >= right_index) then
            result (left_index downto arglow) := invec(left_index downto ARGLOW);
          else
            result (left_index downto right_index) := invec (left_index downto right_index);
            needs_rounding                         := (round_style = fixed_round);  -- round
          end if;
        end if;
      else                              -- arghigh <= integer width
        if (ARGLOW >= right_index) then
          result (arghigh downto arglow) := invec;
        else
          result (arghigh downto right_index) := invec (ARGHIGH downto right_index);
          needs_rounding                      := (round_style = fixed_round);    -- round
        end if;
      end if;
      -- Round result
      if (needs_rounding) then
        result := round_fixed (arg            => result,
                               remainder      => invec (right_index - 1
                                                         downto ARGLOW),
                               overflow_style => overflow_style);
      end if;
      return result;
    end if;

  end function resize;

  function resize (
    arg                     : unresolved_sfixed;          -- input
    constant left_index     : integer;  -- integer portion
    constant right_index    : integer;  -- size of fraction
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant ARGHIGH        : integer                                          := private_maximum (arg'high, arg'low);
    constant ARGLOW         : integer                                          := mine (arg'high, arg'low);
    variable invec          : unresolved_sfixed (ARGHIGH downto ARGLOW);
    variable result         : unresolved_sfixed(left_index downto right_index) :=
             (others => '0');
    variable reduced        : std_ulogic;
    variable needs_rounding : boolean                                          := false;           -- rounding

  begin  -- resize

    if ((arg'length < 1) or (result'length < 1)) then
      return NASF;
    elsif (invec'length < 1) then
      return result;                    -- string literal value
    else
      invec := cleanvec(arg);
      if (right_index > ARGHIGH) then   -- return top zeros
        if (arg'low /= integer'low) then  -- check for a literal
          result := (others => arg(ARGHIGH));             -- sign extend
        end if;
        needs_rounding := (round_style = fixed_round) and
                          (right_index = ARGHIGH + 1);
      elsif (left_index < ARGLOW) then  -- return overflow
        if (overflow_style = fixed_saturate) then
          reduced := private_or_reduce (to_sulv(invec));
          if (reduced = '1') then
            if (invec(ARGHIGH) = '0') then
              -- saturate POSITIVE
              result := saturate (result'high, result'low);
            else
              -- saturate negative
              result := not saturate (result'high, result'low);
            end if;
          -- else return 0 (input was 0)
          end if;
        -- else return 0 (wrap)
        end if;
      elsif (ARGHIGH > left_index) then
        if (invec(ARGHIGH) = '0') then
          reduced := private_or_reduce(to_sulv(invec(ARGHIGH - 1 downto
                                             left_index)));
          if (overflow_style = fixed_saturate and reduced = '1') then
            -- saturate positive
            result := saturate (result'high, result'low);
          else
            if (right_index > ARGLOW) then
              result         := invec (left_index downto right_index);
              needs_rounding := (round_style = fixed_round);
            else
              result (left_index downto arglow) := invec (left_index downto ARGLOW);
            end if;
          end if;
        else
          reduced := private_and_reduce (to_sulv(invec(ARGHIGH - 1 downto
                                               left_index)));
          if (overflow_style = fixed_saturate and reduced = '0') then
            result := not saturate (result'high, result'low);
          else
            if (right_index > ARGLOW) then
              result         := invec (left_index downto right_index);
              needs_rounding := (round_style = fixed_round);
            else
              result (left_index downto arglow) := invec (left_index downto ARGLOW);
            end if;
          end if;
        end if;
      else                              -- arghigh <= integer width
        if (ARGLOW >= right_index) then
          result (arghigh downto arglow) := invec;
        else
          result (arghigh downto right_index) := invec (ARGHIGH downto right_index);
          needs_rounding                      := (round_style = fixed_round);  -- round
        end if;
        if (left_index > ARGHIGH) then  -- sign extend
          result(left_index downto arghigh + 1) := (others => invec(ARGHIGH));
        end if;
      end if;
      -- Round result
      if (needs_rounding) then
        result := round_fixed (arg            => result,
                               remainder      => invec (right_index - 1
                                                         downto ARGLOW),
                               overflow_style => overflow_style);
      end if;
      return result;
    end if;

  end function resize;

  -- size_res functions
  -- These functions compute the size from a passed variable named "size_res"
  -- The only part of this variable used it it's size, it is never passed
  -- to a lower level routine.
  function to_ufixed (
    arg      : std_ulogic_vector;       -- shifted vector
    size_res : unresolved_ufixed
  )       -- for size only
    return unresolved_ufixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_ufixed (size_res'left downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NAUF;
    else
      result := to_ufixed (arg         => arg,
                           left_index  => size_res'high,
                           right_index => size_res'low);
      return result;
    end if;

  end function to_ufixed;

  function to_sfixed (
    arg      : std_ulogic_vector;       -- shifted vector
    size_res : unresolved_sfixed
  )       -- for size only
    return unresolved_sfixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_sfixed (size_res'left downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NASF;
    else
      result := to_sfixed (arg         => arg,
                           left_index  => size_res'high,
                           right_index => size_res'low);
      return result;
    end if;

  end function to_sfixed;

  function to_ufixed (
    arg                     : NATURAL;            -- integer
    size_res                : unresolved_ufixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_ufixed (size_res'left downto FW);

  begin

    if (result'length < 1) then
      return NAUF;
    else
      result := to_ufixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_ufixed;

  function to_sfixed (
    arg                     : integer;            -- integer
    size_res                : unresolved_sfixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_sfixed (size_res'left downto FW);

  begin

    if (result'length < 1) then
      return NASF;
    else
      result := to_sfixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_sfixed;

  function to_ufixed (
    arg                     : REAL;     -- real
    size_res                : unresolved_ufixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style;
    constant guard_bits     : NATURAL                   := fixed_guard_bits
  )  -- # of guard bits
    return unresolved_ufixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_ufixed (size_res'left downto FW);

  begin

    if (result'length < 1) then
      return NAUF;
    else
      result := to_ufixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           guard_bits     => guard_bits,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_ufixed;

  function to_sfixed (
    arg                     : REAL;     -- real
    size_res                : unresolved_sfixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style;
    constant guard_bits     : NATURAL                   := fixed_guard_bits
  )  -- # of guard bits
    return unresolved_sfixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_sfixed (size_res'left downto FW);

  begin

    if (result'length < 1) then
      return NASF;
    else
      result := to_sfixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           guard_bits     => guard_bits,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_sfixed;

  function to_ufixed (
    arg                     : unsigned;  -- unsigned
    size_res                : unresolved_ufixed;    -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_ufixed (size_res'left downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NAUF;
    else
      result := to_ufixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_ufixed;

  function to_sfixed (
    arg                     : signed;  -- signed
    size_res                : unresolved_sfixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_sfixed (size_res'left downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NASF;
    else
      result := to_sfixed (arg            => arg,
                           left_index     => size_res'high,
                           right_index    => size_res'low,
                           round_style    => round_style,
                           overflow_style => overflow_style);
      return result;
    end if;

  end function to_sfixed;

  function resize (
    arg                     : unresolved_ufixed;  -- input
    size_res                : unresolved_ufixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_ufixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_ufixed (size_res'high downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NAUF;
    else
      result := resize (arg            => arg,
                        left_index     => size_res'high,
                        right_index    => size_res'low,
                        round_style    => round_style,
                        overflow_style => overflow_style);
      return result;
    end if;

  end function resize;

  function resize (
    arg                     : unresolved_sfixed;  -- input
    size_res                : unresolved_sfixed;  -- for size only
    constant overflow_style : fixed_overflow_style_type := fixed_overflow_style;
    constant round_style    : fixed_round_style_type    := fixed_round_style
  )
    return unresolved_sfixed
  is

    constant FW     : integer := mine (size_res'low, size_res'low);  -- catch literals
    variable result : unresolved_sfixed (size_res'high downto FW);

  begin

    if (result'length < 1 or arg'length < 1) then
      return NASF;
    else
      result := resize (arg            => arg,
                        left_index     => size_res'high,
                        right_index    => size_res'low,
                        round_style    => round_style,
                        overflow_style => overflow_style);
      return result;
    end if;

  end function resize;

  -- Overloaded math functions for real
  function "+" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l + to_ufixed (r, l'high, l'low));

  end function "+";

  function "+" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) + r);

  end function "+";

  function "+" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l + to_sfixed (r, l'high, l'low));

  end function "+";

  function "+" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) + r);

  end function "+";

  function "-" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l - to_ufixed (r, l'high, l'low));

  end function "-";

  function "-" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) - r);

  end function "-";

  function "-" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l - to_sfixed (r, l'high, l'low));

  end function "-";

  function "-" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) - r);

  end function "-";

  function "*" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l * to_ufixed (r, l'high, l'low));

  end function "*";

  function "*" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) * r);

  end function "*";

  function "*" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l * to_sfixed (r, l'high, l'low));

  end function "*";

  function "*" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) * r);

  end function "*";

  function "/" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l / to_ufixed (r, l'high, l'low));

  end function "/";

  function "/" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) / r);

  end function "/";

  function "/" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l / to_sfixed (r, l'high, l'low));

  end function "/";

  function "/" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) / r);

  end function "/";

  function "rem" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l rem to_ufixed (r, l'high, l'low));

  end function "rem";

  function "rem" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) rem r);

  end function "rem";

  function "rem" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l rem to_sfixed (r, l'high, l'low));

  end function "rem";

  function "rem" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) rem r);

  end function "rem";

  function "mod" (
    l : unresolved_ufixed;              -- fixed point input
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return (l mod to_ufixed (r, l'high, l'low));

  end function "mod";

  function "mod" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, r'low) mod r);

  end function "mod";

  function "mod" (
    l : unresolved_sfixed;              -- fixed point input
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return (l mod to_sfixed (r, l'high, l'low));

  end function "mod";

  function "mod" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, r'low) mod r);

  end function "mod";

  -- Overloaded math functions for integers
  function "+" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l + to_ufixed (r, l'high, 0));

  end function "+";

  function "+" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) + r);

  end function "+";

  function "+" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l + to_sfixed (r, l'high, 0));

  end function "+";

  function "+" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) + r);

  end function "+";

  -- Overloaded functions
  function "-" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l - to_ufixed (r, l'high, 0));

  end function "-";

  function "-" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) - r);

  end function "-";

  function "-" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l - to_sfixed (r, l'high, 0));

  end function "-";

  function "-" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) - r);

  end function "-";

  -- Overloaded functions
  function "*" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l * to_ufixed (r, l'high, 0));

  end function "*";

  function "*" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) * r);

  end function "*";

  function "*" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l * to_sfixed (r, l'high, 0));

  end function "*";

  function "*" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) * r);

  end function "*";

  -- Overloaded functions
  function "/" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l / to_ufixed (r, l'high, 0));

  end function "/";

  function "/" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) / r);

  end function "/";

  function "/" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l / to_sfixed (r, l'high, 0));

  end function "/";

  function "/" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) / r);

  end function "/";

  function "rem" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l rem to_ufixed (r, l'high, 0));

  end function "rem";

  function "rem" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) rem r);

  end function "rem";

  function "rem" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l rem to_sfixed (r, l'high, 0));

  end function "rem";

  function "rem" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) rem r);

  end function "rem";

  function "mod" (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return (l mod to_ufixed (r, l'high, 0));

  end function "mod";

  function "mod" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return (to_ufixed (l, r'high, 0) mod r);

  end function "mod";

  function "mod" (
    l : unresolved_sfixed;              -- fixed point input
    r : integer
  )
    return unresolved_sfixed is
  begin

    return (l mod to_sfixed (r, l'high, 0));

  end function "mod";

  function "mod" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return unresolved_sfixed is
  begin

    return (to_sfixed (l, r'high, 0) mod r);

  end function "mod";

  -- overloaded ufixed compare functions with integer
  function "=" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l = to_ufixed (r, l'high, l'low));

  end function "=";

  function "/=" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l /= to_ufixed (r, l'high, l'low));

  end function "/=";

  function ">=" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l >= to_ufixed (r, l'high, l'low));

  end function ">=";

  function "<=" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l <= to_ufixed (r, l'high, l'low));

  end function "<=";

  function ">" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l > to_ufixed (r, l'high, l'low));

  end function ">";

  function "<" (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return boolean is
  begin

    return (l < to_ufixed (r, l'high, l'low));

  end function "<";

  function \?=\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?=\(l, to_ufixed (r, l'high, l'low)));

  end function \?=\;

  function \?/=\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?/=\(l, to_ufixed (r, l'high, l'low)));

  end function \?/=\;

  function \?>=\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?>=\(l, to_ufixed (r, l'high, l'low)));

  end function \?>=\;

  function \?<=\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?<=\(l, to_ufixed (r, l'high, l'low)));

  end function \?<=\;

  function \?>\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?>\(l, to_ufixed (r, l'high, l'low)));

  end function \?>\;

  function \?<\ (
    l : unresolved_ufixed;
    r : NATURAL
  )                        -- fixed point input
    return std_ulogic is
  begin

    return (\?<\(l, to_ufixed (r, l'high, l'low)));

  end function \?<\;

  function maximum (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return maximum (l, to_ufixed (r, l'high, l'low));

  end function maximum;

  function minimum (
    l : unresolved_ufixed;              -- fixed point input
    r : NATURAL
  )
    return unresolved_ufixed is
  begin

    return minimum (l, to_ufixed (r, l'high, l'low));

  end function minimum;

  -- NATURAL to ufixed
  function "=" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) = r);

  end function "=";

  function "/=" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) /= r);

  end function "/=";

  function ">=" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) >= r);

  end function ">=";

  function "<=" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) <= r);

  end function "<=";

  function ">" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) > r);

  end function ">";

  function "<" (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) < r);

  end function "<";

  function \?=\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?=\(to_ufixed (l, r'high, r'low), r));

  end function \?=\;

  function \?/=\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?/=\(to_ufixed (l, r'high, r'low), r));

  end function \?/=\;

  function \?>=\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>=\(to_ufixed (l, r'high, r'low), r));

  end function \?>=\;

  function \?<=\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<=\(to_ufixed (l, r'high, r'low), r));

  end function \?<=\;

  function \?>\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>\(to_ufixed (l, r'high, r'low), r));

  end function \?>\;

  function \?<\ (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<\(to_ufixed (l, r'high, r'low), r));

  end function \?<\;

  function maximum (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return maximum (to_ufixed (l, r'high, r'low), r);

  end function maximum;

  function minimum (
    l : NATURAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return minimum (to_ufixed (l, r'high, r'low), r);

  end function minimum;

  -- overloaded ufixed compare functions with real
  function "=" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l = to_ufixed (r, l'high, l'low));

  end function "=";

  function "/=" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l /= to_ufixed (r, l'high, l'low));

  end function "/=";

  function ">=" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l >= to_ufixed (r, l'high, l'low));

  end function ">=";

  function "<=" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l <= to_ufixed (r, l'high, l'low));

  end function "<=";

  function ">" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l > to_ufixed (r, l'high, l'low));

  end function ">";

  function "<" (
    l : unresolved_ufixed;
    r : REAL
  )
    return boolean is
  begin

    return (l < to_ufixed (r, l'high, l'low));

  end function "<";

  function \?=\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?=\(l, to_ufixed (r, l'high, l'low)));

  end function \?=\;

  function \?/=\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?/=\(l, to_ufixed (r, l'high, l'low)));

  end function \?/=\;

  function \?>=\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?>=\(l, to_ufixed (r, l'high, l'low)));

  end function \?>=\;

  function \?<=\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?<=\(l, to_ufixed (r, l'high, l'low)));

  end function \?<=\;

  function \?>\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?>\(l, to_ufixed (r, l'high, l'low)));

  end function \?>\;

  function \?<\ (
    l : unresolved_ufixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?<\(l, to_ufixed (r, l'high, l'low)));

  end function \?<\;

  function maximum (
    l : unresolved_ufixed;
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return maximum (l, to_ufixed (r, l'high, l'low));

  end function maximum;

  function minimum (
    l : unresolved_ufixed;
    r : REAL
  )
    return unresolved_ufixed is
  begin

    return minimum (l, to_ufixed (r, l'high, l'low));

  end function minimum;

  -- real and ufixed
  function "=" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) = r);

  end function "=";

  function "/=" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) /= r);

  end function "/=";

  function ">=" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) >= r);

  end function ">=";

  function "<=" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) <= r);

  end function "<=";

  function ">" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) > r);

  end function ">";

  function "<" (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_ufixed (l, r'high, r'low) < r);

  end function "<";

  function \?=\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?=\(to_ufixed (l, r'high, r'low), r));

  end function \?=\;

  function \?/=\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?/=\(to_ufixed (l, r'high, r'low), r));

  end function \?/=\;

  function \?>=\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>=\(to_ufixed (l, r'high, r'low), r));

  end function \?>=\;

  function \?<=\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<=\(to_ufixed (l, r'high, r'low), r));

  end function \?<=\;

  function \?>\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>\(to_ufixed (l, r'high, r'low), r));

  end function \?>\;

  function \?<\ (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<\(to_ufixed (l, r'high, r'low), r));

  end function \?<\;

  function maximum (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return maximum (to_ufixed (l, r'high, r'low), r);

  end function maximum;

  function minimum (
    l : REAL;
    r : unresolved_ufixed
  )              -- fixed point input
    return unresolved_ufixed is
  begin

    return minimum (to_ufixed (l, r'high, r'low), r);

  end function minimum;

  -- overloaded sfixed compare functions with integer
  function "=" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l = to_sfixed (r, l'high, l'low));

  end function "=";

  function "/=" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l /= to_sfixed (r, l'high, l'low));

  end function "/=";

  function ">=" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l >= to_sfixed (r, l'high, l'low));

  end function ">=";

  function "<=" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l <= to_sfixed (r, l'high, l'low));

  end function "<=";

  function ">" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l > to_sfixed (r, l'high, l'low));

  end function ">";

  function "<" (
    l : unresolved_sfixed;
    r : integer
  )
    return boolean is
  begin

    return (l < to_sfixed (r, l'high, l'low));

  end function "<";

  function \?=\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?=\(l, to_sfixed (r, l'high, l'low)));

  end function \?=\;

  function \?/=\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?/=\(l, to_sfixed (r, l'high, l'low)));

  end function \?/=\;

  function \?>=\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?>=\(l, to_sfixed (r, l'high, l'low)));

  end function \?>=\;

  function \?<=\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?<=\(l, to_sfixed (r, l'high, l'low)));

  end function \?<=\;

  function \?>\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?>\(l, to_sfixed (r, l'high, l'low)));

  end function \?>\;

  function \?<\ (
    l : unresolved_sfixed;
    r : integer
  )
    return std_ulogic is
  begin

    return (\?<\(l, to_sfixed (r, l'high, l'low)));

  end function \?<\;

  function maximum (
    l : unresolved_sfixed;
    r : integer
  )
    return unresolved_sfixed is
  begin

    return maximum (l, to_sfixed (r, l'high, l'low));

  end function maximum;

  function minimum (
    l : unresolved_sfixed;
    r : integer
  )
    return unresolved_sfixed is
  begin

    return minimum (l, to_sfixed (r, l'high, l'low));

  end function minimum;

  -- integer and sfixed
  function "=" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) = r);

  end function "=";

  function "/=" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) /= r);

  end function "/=";

  function ">=" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) >= r);

  end function ">=";

  function "<=" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) <= r);

  end function "<=";

  function ">" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) > r);

  end function ">";

  function "<" (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) < r);

  end function "<";

  function \?=\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?=\(to_sfixed (l, r'high, r'low), r));

  end function \?=\;

  function \?/=\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?/=\(to_sfixed (l, r'high, r'low), r));

  end function \?/=\;

  function \?>=\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>=\(to_sfixed (l, r'high, r'low), r));

  end function \?>=\;

  function \?<=\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<=\(to_sfixed (l, r'high, r'low), r));

  end function \?<=\;

  function \?>\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>\(to_sfixed (l, r'high, r'low), r));

  end function \?>\;

  function \?<\ (
    l : integer;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<\(to_sfixed (l, r'high, r'low), r));

  end function \?<\;

  function maximum (
    l : integer;
    r : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return maximum (to_sfixed (l, r'high, r'low), r);

  end function maximum;

  function minimum (
    l : integer;
    r : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return minimum (to_sfixed (l, r'high, r'low), r);

  end function minimum;

  -- overloaded sfixed compare functions with real
  function "=" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l = to_sfixed (r, l'high, l'low));

  end function "=";

  function "/=" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l /= to_sfixed (r, l'high, l'low));

  end function "/=";

  function ">=" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l >= to_sfixed (r, l'high, l'low));

  end function ">=";

  function "<=" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l <= to_sfixed (r, l'high, l'low));

  end function "<=";

  function ">" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l > to_sfixed (r, l'high, l'low));

  end function ">";

  function "<" (
    l : unresolved_sfixed;
    r : REAL
  )
    return boolean is
  begin

    return (l < to_sfixed (r, l'high, l'low));

  end function "<";

  function \?=\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?=\(l, to_sfixed (r, l'high, l'low)));

  end function \?=\;

  function \?/=\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?/=\(l, to_sfixed (r, l'high, l'low)));

  end function \?/=\;

  function \?>=\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?>=\(l, to_sfixed (r, l'high, l'low)));

  end function \?>=\;

  function \?<=\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?<=\(l, to_sfixed (r, l'high, l'low)));

  end function \?<=\;

  function \?>\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?>\(l, to_sfixed (r, l'high, l'low)));

  end function \?>\;

  function \?<\ (
    l : unresolved_sfixed;
    r : REAL
  )
    return std_ulogic is
  begin

    return (\?<\(l, to_sfixed (r, l'high, l'low)));

  end function \?<\;

  function maximum (
    l : unresolved_sfixed;
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return maximum (l, to_sfixed (r, l'high, l'low));

  end function maximum;

  function minimum (
    l : unresolved_sfixed;
    r : REAL
  )
    return unresolved_sfixed is
  begin

    return minimum (l, to_sfixed (r, l'high, l'low));

  end function minimum;

  -- REAL and sfixed
  function "=" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) = r);

  end function "=";

  function "/=" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) /= r);

  end function "/=";

  function ">=" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) >= r);

  end function ">=";

  function "<=" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) <= r);

  end function "<=";

  function ">" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) > r);

  end function ">";

  function "<" (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return boolean is
  begin

    return (to_sfixed (l, r'high, r'low) < r);

  end function "<";

  function \?=\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?=\(to_sfixed (l, r'high, r'low), r));

  end function \?=\;

  function \?/=\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?/=\(to_sfixed (l, r'high, r'low), r));

  end function \?/=\;

  function \?>=\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>=\(to_sfixed (l, r'high, r'low), r));

  end function \?>=\;

  function \?<=\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<=\(to_sfixed (l, r'high, r'low), r));

  end function \?<=\;

  function \?>\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?>\(to_sfixed (l, r'high, r'low), r));

  end function \?>\;

  function \?<\ (
    l : REAL;
    r : unresolved_sfixed
  )              -- fixed point input
    return std_ulogic is
  begin

    return (\?<\(to_sfixed (l, r'high, r'low), r));

  end function \?<\;

  function maximum (
    l : REAL;
    r : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return maximum (to_sfixed (l, r'high, r'low), r);

  end function maximum;

  function minimum (
    l : REAL;
    r : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return minimum (to_sfixed (l, r'high, r'low), r);

  end function minimum;

  -- copied from std_logic_textio
  type mvl9plus is ('u', 'x', '0', '1', 'z', 'w', 'l', 'h', '-', error);

  type char_indexed_by_mvl9 is array (std_ulogic) of CHARACTER;

  type mvl9_indexed_by_char is array (CHARACTER) of std_ulogic;

  constant MVL9_TO_CHAR     : char_indexed_by_MVL9     := "UX01ZWLH-";
  constant CHAR_TO_MVL9     : MVL9_indexed_by_char     :=
  (
    'U'     => 'U',
    'X'     => 'X',
    '0'     => '0',
    '1'     => '1',
    'Z'     => 'Z',
    'W'     => 'W',
    'L'     => 'L',
    'H'     => 'H',
    '-'     => '-',
    others  => 'U'
  );
  
  constant NBSP             : CHARACTER                := CHARACTER'val(160);  -- space character
  constant NUS              : string(2 to 1)           := (others => ' ');

  -- purpose: Skips white space
  procedure skip_whitespace (
    l : inout line
  ) is

    variable c    : character;
    variable left : positive;

  begin

    while l /= null and L.all'length /= 0 loop

      left := L.all'left;
      c    := L.all(left);

      if (c = ' ' or c = NBSP or c = HT) then
        read (l, c);
      else
        exit;
      end if;

    end loop;

  end procedure skip_whitespace;

  -- purpose: writes fixed point into a line
  procedure write (
    l         : inout line;               -- input line
    value     : in    unresolved_ufixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is

    variable s     : string(1 to value'length +1) := (others => ' ');
    variable sindx : integer;

  begin  -- function write   Example: 0011.1100

    sindx := 1;

    for i in value'high downto value'low loop

      if (i = -1) then
        s(sindx) := '.';
        sindx    := sindx + 1;
      end if;

      s(sindx) := MVL9_to_char(std_ulogic(value(i)));
      sindx    := sindx + 1;

    end loop;

    write(l, s, justified, field);

  end procedure write;

  -- purpose: writes fixed point into a line
  procedure write (
    l         : inout line;               -- input line
    value     : in    unresolved_sfixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is

    variable s     : string(1 to value'length +1);
    variable sindx : integer;

  begin  -- function write   Example: 0011.1100

    sindx := 1;

    for i in value'high downto value'low loop

      if (i = -1) then
        s(sindx) := '.';
        sindx    := sindx + 1;
      end if;

      s(sindx) := MVL9_to_char(std_ulogic(value(i)));
      sindx    := sindx + 1;

    end loop;

    write(l, s, justified, field);

  end procedure write;

  procedure read (
    l     : inout line;
    value : out   unresolved_ufixed
  ) is

    -- Possible data:  00000.0000000
    --                 000000000000
    variable c        : character;
    variable readok   : boolean;
    variable i        : integer;          -- index variable
    variable mv       : ufixed (value'range);
    variable lastu    : boolean := false;       -- last character was an "_"
    variable founddot : boolean := false;  -- found a "."

  begin  -- read

    value := (value'range => 'U');
    skip_whitespace (l);

    if (value'length > 0) then            -- non Null input string
      read (l, c, readok);
      i := value'high;

      while i >= value'low loop

        if (readok = false) then              -- Bail out if there was a bad read
          report fixed_generic_pkg'instance_name & "read(ufixed) "
                 & "End of string encountered"
            severity error;
          return;
        elsif (c = '_') then
          if (i = value'high) then
            report fixed_generic_pkg'instance_name & "read(ufixed) "
                   & "String begins with an ""_"""
              severity error;
            return;
          elsif (lastu) then
            report fixed_generic_pkg'instance_name & "read(ufixed) "
                   & "Two underscores detected in input string ""__"""
              severity error;
            return;
          else
            lastu := true;
          end if;
        elsif (c = '.') then                -- binary point
          if (founddot) then
            report fixed_generic_pkg'instance_name & "read(ufixed) "
                   & "Two binary points found in input string"
              severity error;
            return;
          elsif (i /= -1) then                 -- Seperator in the wrong spot
            report fixed_generic_pkg'instance_name & "read(ufixed) "
                   & "Decimal point does not match number format "
              severity error;
            return;
          end if;
          founddot := true;
          lastu    := false;
        elsif (c = ' ' or c = NBSP or c = HT) then  -- reading done.
          report fixed_generic_pkg'instance_name & "read(ufixed) "
                 & "Short read, Space encounted in input string"
            severity error;
          return;
        else
          mv(i) := char_to_MVL9(c);
          i     := i - 1;
          if (i < mv'low) then
            value := mv;
            return;
          end if;
          lastu := false;
        end if;
        read(l, c, readok);

      end loop;

    end if;

  end procedure read;

  procedure read (
    l     : inout line;
    value : out   unresolved_ufixed;
    good  : out   boolean
  ) is

    -- Possible data:  00000.0000000
    --                 000000000000
    variable c        : character;
    variable readok   : boolean;
    variable mv       : ufixed (value'range);
    variable i        : integer;          -- index variable
    variable lastu    : boolean := false;       -- last character was an "_"
    variable founddot : boolean := false;  -- found a "."

  begin  -- read

    value := (value'range => 'U');
    skip_whitespace (l);

    if (value'length > 0) then
      read (l, c, readok);
      i    := value'high;
      good := false;

      while i >= value'low loop

        if (not readok) then     -- Bail out if there was a bad read
          return;
        elsif (c = '_') then
          if (i = value'high) then          -- Begins with an "_"
            return;
          elsif (lastu) then               -- "__" detected
            return;
          else
            lastu := true;
          end if;
        elsif (c = '.') then                -- binary point
          if (founddot) then
            return;
          elsif (i /= -1) then                 -- Seperator in the wrong spot
            return;
          end if;
          founddot := true;
          lastu    := false;
        else
          mv(i) := char_to_MVL9(c);
          i     := i - 1;
          if (i < mv'low) then             -- reading done
            good  := true;
            value := mv;
            return;
          end if;
          lastu := false;
        end if;
        read(l, c, readok);

      end loop;

    else
      good := true;                   -- read into a null array
    end if;

  end procedure read;

  procedure read (
    l     : inout line;
    value : out   unresolved_sfixed
  ) is

    variable c        : character;
    variable readok   : boolean;
    variable i        : integer;          -- index variable
    variable mv       : sfixed (value'range);
    variable lastu    : boolean := false;       -- last character was an "_"
    variable founddot : boolean := false;  -- found a "."

  begin  -- read

    value := (value'range => 'U');
    skip_whitespace (l);

    if (value'length > 0) then            -- non Null input string
      read (l, c, readok);
      i := value'high;

      while i >= value'low loop

        if (readok = false) then              -- Bail out if there was a bad read
          report fixed_generic_pkg'instance_name & "read(sfixed) "
                 & "End of string encountered"
            severity error;
          return;
        elsif (c = '_') then
          if (i = value'high) then
            report fixed_generic_pkg'instance_name & "read(sfixed) "
                   & "String begins with an ""_"""
              severity error;
            return;
          elsif (lastu) then
            report fixed_generic_pkg'instance_name & "read(sfixed) "
                   & "Two underscores detected in input string ""__"""
              severity error;
            return;
          else
            lastu := true;
          end if;
        elsif (c = '.') then                -- binary point
          if (founddot) then
            report fixed_generic_pkg'instance_name & "read(sfixed) "
                   & "Two binary points found in input string"
              severity error;
            return;
          elsif (i /= -1) then                 -- Seperator in the wrong spot
            report fixed_generic_pkg'instance_name & "read(sfixed) "
                   & "Decimal point does not match number format "
              severity error;
            return;
          end if;
          founddot := true;
          lastu    := false;
        elsif (c = ' ' or c = NBSP or c = HT) then  -- reading done.
          report fixed_generic_pkg'instance_name & "read(sfixed) "
                 & "Short read, Space encounted in input string"
            severity error;
          return;
        else
          mv(i) := char_to_MVL9(c);
          i     := i - 1;
          if (i < mv'low) then
            value := mv;
            return;
          end if;
          lastu := false;
        end if;
        read(l, c, readok);

      end loop;

    end if;

  end procedure read;

  procedure read (
    l     : inout line;
    value : out   unresolved_sfixed;
    good  : out   boolean
  ) is

    variable value_ufixed : unresolved_ufixed (value'range);

  begin  -- read

    read (l => l, value => value_ufixed, good => good);
    value := unresolved_sfixed (value_ufixed);

  end procedure read;

  -- octal read and write
  procedure owrite (
    l         : inout line;               -- input line
    value     : in    unresolved_ufixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is
  begin  -- Example 03.30

    write (l         => l,
           value     => to_ostring (value),
           justified => justified,
           field     => field);

  end procedure owrite;

  procedure owrite (
    l         : inout line;               -- input line
    value     : in    unresolved_sfixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is
  begin  -- Example 03.30

    write (l         => l,
           value     => to_ostring (value),
           justified => justified,
           field     => field);

  end procedure owrite;

  -- Note that for Octal and Hex read, you can not start with a ".",
  -- the read is for numbers formatted "A.BC".  These routines go to
  -- the nearest bounds, so "F.E" will fit into an sfixed (2 downto -3).
  procedure char2tribits (
    c           :     CHARACTER;
    result      : out std_ulogic_vector(2 downto 0);
    good        : out boolean;
    issue_error : in  boolean
  ) is
  begin

    case c is

      when '0' =>
        result := o"0"; good := true;

      when '1' =>
        result := o"1"; good := true;

      when '2' =>
        result := o"2"; good := true;

      when '3' =>
        result := o"3"; good := true;

      when '4' =>
        result := o"4"; good := true;

      when '5' =>
        result := o"5"; good := true;

      when '6' =>
        result := o"6"; good := true;

      when '7' =>
        result := o"7"; good := true;

      when 'Z' =>
        result := "ZZZ"; good := true;

      when 'X' =>
        result := "XXX"; good := true;

      when others =>
        assert not issue_error
          report fixed_generic_pkg'instance_name
                 & "oread Error: Read a '" & c &
                 "', expected an Octal character (0-7)."
          severity error;
        result := "UUU";
        good   := false;

    end case;

  end procedure char2tribits;

  -- purpose: Routines common to the oread routines
  procedure oread_common (
    l                : inout line;
    slv              : out   std_ulogic_vector;
    igood            : out   boolean;
    idex             : out integer;
    constant bpoint  : in integer;       -- binary point
    constant message : in    boolean;
    constant smath   : in    boolean
  ) is

    -- purpose: error message routine
    procedure errmes (
      constant mess : in string
    ) is     -- error message
    begin

      if (message) then
        if (smath) then
          report fixed_generic_pkg'instance_name
                 & "oread(sfixed) "
                 & mess
            severity error;
        else
          report fixed_generic_pkg'instance_name
                 & "oread(ufixed) "
                 & mess
            severity error;
        end if;
      end if;

    end procedure errmes;

    variable xgood    : boolean;
    variable nybble   : std_ulogic_vector (2 downto 0);        -- 3 bits
    variable c        : character;
    variable i        : integer;
    variable lastu    : boolean := false;       -- last character was an "_"
    variable founddot : boolean := false;  -- found a dot.

  begin

    skip_whitespace (l);

    if (slv'length > 0) then
      i := slv'high;
      read (l, c, xgood);

      while i > 0 loop

        if (xgood = false) then
          errmes ("Error: end of string encountered");
          exit;
        elsif (c = '_') then
          if (i = slv'length) then
            errmes ("Error: String begins with an ""_""");
            xgood := false;
            exit;
          elsif (lastu) then
            errmes ("Error: Two underscores detected in input string ""__""");
            xgood := false;
            exit;
          else
            lastu := true;
          end if;
        elsif (c = '.') then
          if (i + 1 /= bpoint) then
            errmes ("encountered ""."" at wrong index");
            xgood := false;
            exit;
          elsif (i = slv'length) then
            errmes ("encounted a ""."" at the beginning of the line");
            xgood := false;
            exit;
          elsif (founddot) then
            errmes ("Two ""."" encounted in input string");
            xgood := false;
            exit;
          end if;
          founddot := true;
          lastu    := false;
        else
          Char2TriBits(c, nybble, xgood, message);
          if (not xgood) then
            exit;
          end if;
          slv (i downto i - 2) := nybble;
          i                    := i - 3;
          lastu                := false;
        end if;
        if (i > 0) then
          read (l, c, xgood);
        end if;

      end loop;

      idex  := i;
      igood := xgood;
    else
      igood := true;                  -- read into a null array
      idex  := -1;
    end if;

  end procedure oread_common;

  -- Note that for Octal and Hex read, you can not start with a ".",
  -- the read is for numbers formatted "A.BC".  These routines go to
  -- the nearest bounds, so "F.E" will fit into an sfixed (2 downto -3).
  procedure oread (
    l     : inout line;
    value : out   unresolved_ufixed
  ) is

    constant HBV    : integer := (((private_maximum(3, (value'high+1)) + 2) / 3) * 3) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 2) / 3) * 3;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_ufixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    oread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => true,
                  smath   => false);

    if (igood) then                       -- We did not get another error
      if (not ((i = -1) and               -- We read everything, and high bits 0
               (private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0'))) then
        report fixed_generic_pkg'instance_name
               & "oread(ufixed): Vector truncated."
          severity error;
      else
        if (private_or_reduce(slv(value'low-LBV - 1 downto 0)) = '1') then
          assert no_warning
            report fixed_generic_pkg'instance_name
                   & "oread(ufixed): Vector truncated"
            severity warning;
        end if;
        valuex := to_ufixed (slv, HBV, LBV);
        value  := valuex (value'range);
      end if;
    end if;

  end procedure oread;

  procedure oread (
    l     : inout line;
    value : out   unresolved_ufixed;
    good  : out   boolean
  ) is

    constant HBV    : integer := (((private_maximum(3, (value'high+1)) + 2) / 3) * 3) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 2) / 3) * 3;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_ufixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    oread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => false,
                  smath   => false);

    if (igood and                   -- We did not get another error
        (i = -1) and                -- We read everything, and high bits 0
        (private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0')) then
      valuex := to_ufixed (slv, HBV, LBV);
      value  := valuex (value'range);
      good   := true;
    else
      good := false;
    end if;

  end procedure oread;

  procedure oread (
    l     : inout line;
    value : out   unresolved_sfixed
  ) is

    constant HBV    : integer := (((private_maximum(3, (value'high+1)) + 2) / 3) * 3) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 2) / 3) * 3;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_sfixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    oread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => true,
                  smath   => true);

    if (igood) then                       -- We did not get another error
      if (not ((i = -1) and               -- We read everything
               ((slv(value'high-LBV) = '0' and      -- sign bits = extra bits
                  private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0') or
                 (slv(value'high-LBV) = '1' and
                   private_and_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '1')))) then
        report fixed_generic_pkg'instance_name
               & "oread(sfixed): Vector truncated."
          severity error;
      else
        if (private_or_reduce(slv(value'low-LBV - 1 downto 0)) = '1') then
          assert no_warning
            report fixed_generic_pkg'instance_name
                   & "oread(sfixed): Vector truncated"
            severity warning;
        end if;
        valuex := to_sfixed (slv, HBV, LBV);
        value  := valuex (value'range);
      end if;
    end if;

  end procedure oread;

  procedure oread (
    l     : inout line;
    value : out   unresolved_sfixed;
    good  : out   boolean
  ) is

    constant HBV    : integer := (((private_maximum(3, (value'high+1)) + 2) / 3) * 3) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 2) / 3) * 3;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_sfixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    oread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => false,
                  smath   => true);

    if (igood                       -- We did not get another error
        and (i = -1)                -- We read everything
        and ((slv(value'high-LBV) = '0' and  -- sign bits = extra bits
               private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0') or
              (slv(value'high-LBV) = '1' and
                private_and_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '1'))) then
      valuex := to_sfixed (slv, HBV, LBV);
      value  := valuex (value'range);
      good   := true;
    else
      good := false;
    end if;

  end procedure oread;

  -- hex read and write
  procedure hwrite (
    l         : inout line;               -- input line
    value     : in    unresolved_ufixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is
  begin  -- Example 03.30

    write (l         => l,
           value     => to_hstring (value),
           justified => justified,
           field     => field);

  end procedure hwrite;

  -- purpose: writes fixed point into a line
  procedure hwrite (
    l         : inout line;               -- input line
    value     : in    unresolved_sfixed;  -- fixed point input
    justified : in    side  := right;
    field     : in    width := 0
  ) is
  begin  -- Example 03.30

    write (l         => l,
           value     => to_hstring (value),
           justified => justified,
           field     => field);

  end procedure hwrite;

  -- Hex Read and Write procedures for std_ulogic_vector.
  -- Modified from the original to be more forgiving.

  procedure char2quadbits (
    c           :     CHARACTER;
    result      : out std_ulogic_vector(3 downto 0);
    good        : out boolean;
    issue_error : in  boolean
  ) is
  begin

    case c is

      when '0' =>
        result := x"0"; good := true;

      when '1' =>
        result := x"1"; good := true;

      when '2' =>
        result := x"2"; good := true;

      when '3' =>
        result := x"3"; good := true;

      when '4' =>
        result := x"4"; good := true;

      when '5' =>
        result := x"5"; good := true;

      when '6' =>
        result := x"6"; good := true;

      when '7' =>
        result := x"7"; good := true;

      when '8' =>
        result := x"8"; good := true;

      when '9' =>
        result := x"9"; good := true;

      when 'A' | 'a' =>
        result := x"A"; good := true;

      when 'B' | 'b' =>
        result := x"B"; good := true;

      when 'C' | 'c' =>
        result := x"C"; good := true;

      when 'D' | 'd' =>
        result := x"D"; good := true;

      when 'E' | 'e' =>
        result := x"E"; good := true;

      when 'F' | 'f' =>
        result := x"F"; good := true;

      when 'Z' =>
        result := "ZZZZ"; good := true;

      when 'X' =>
        result := "XXXX"; good := true;

      when others =>
        assert not issue_error
          report fixed_generic_pkg'instance_name
                 & "hread Error: Read a '" & c &
                 "', expected a Hex character (0-F)."
          severity error;
        result := "UUUU";
        good   := false;

    end case;

  end procedure char2quadbits;

  -- purpose: Routines common to the hread routines
  procedure hread_common (
    l                : inout line;
    slv              : out   std_ulogic_vector;
    igood            : out   boolean;
    idex             : out integer;
    constant bpoint  : in integer;       -- binary point
    constant message : in    boolean;
    constant smath   : in    boolean
  ) is

    -- purpose: error message routine
    procedure errmes (
      constant mess : in string
    ) is     -- error message
    begin

      if (message) then
        if (smath) then
          report fixed_generic_pkg'instance_name
                 & "hread(sfixed) "
                 & mess
            severity error;
        else
          report fixed_generic_pkg'instance_name
                 & "hread(ufixed) "
                 & mess
            severity error;
        end if;
      end if;

    end procedure errmes;

    variable xgood    : boolean;
    variable nybble   : std_ulogic_vector (3 downto 0);        -- 4 bits
    variable c        : character;
    variable i        : integer;
    variable lastu    : boolean := false;       -- last character was an "_"
    variable founddot : boolean := false;  -- found a dot.

  begin

    skip_whitespace (l);

    if (slv'length > 0) then
      i := slv'high;
      read (l, c, xgood);

      while i > 0 loop

        if (xgood = false) then
          errmes ("Error: end of string encountered");
          exit;
        elsif (c = '_') then
          if (i = slv'length) then
            errmes ("Error: String begins with an ""_""");
            xgood := false;
            exit;
          elsif (lastu) then
            errmes ("Error: Two underscores detected in input string ""__""");
            xgood := false;
            exit;
          else
            lastu := true;
          end if;
        elsif (c = '.') then
          if (i + 1 /= bpoint) then
            errmes ("encountered ""."" at wrong index");
            xgood := false;
            exit;
          elsif (i = slv'length) then
            errmes ("encounted a ""."" at the beginning of the line");
            xgood := false;
            exit;
          elsif (founddot) then
            errmes ("Two ""."" encounted in input string");
            xgood := false;
            exit;
          end if;
          founddot := true;
          lastu    := false;
        else
          Char2QuadBits(c, nybble, xgood, message);
          if (not xgood) then
            exit;
          end if;
          slv (i downto i - 3) := nybble;
          i                    := i - 4;
          lastu                := false;
        end if;
        if (i > 0) then
          read (l, c, xgood);
        end if;

      end loop;

      idex  := i;
      igood := xgood;
    else
      idex  := -1;
      igood := true;                    -- read null string
    end if;

  end procedure hread_common;

  procedure hread (
    l     : inout line;
    value : out   unresolved_ufixed
  ) is

    constant HBV    : integer := (((private_maximum(4, (value'high+1)) + 3) / 4) * 4) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 3) / 4) * 4;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_ufixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    hread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => true,
                  smath   => false);

    if (igood) then
      if (not ((i = -1) and               -- We read everything, and high bits 0
               (private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0'))) then
        report fixed_generic_pkg'instance_name
               & "hread(ufixed): Vector truncated."
          severity error;
      else
        if (private_or_reduce(slv(value'low-LBV - 1 downto 0)) = '1') then
          assert no_warning
            report fixed_generic_pkg'instance_name
                   & "hread(ufixed): Vector truncated"
            severity warning;
        end if;
        valuex := to_ufixed (slv, HBV, LBV);
        value  := valuex (value'range);
      end if;
    end if;

  end procedure hread;

  procedure hread (
    l     : inout line;
    value : out   unresolved_ufixed;
    good  : out   boolean
  ) is

    constant HBV    : integer := (((private_maximum(4, (value'high+1)) + 3) / 4) * 4) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 3) / 4) * 4;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_ufixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    hread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => false,
                  smath   => false);

    if (igood and                   -- We did not get another error
        (i = -1) and                -- We read everything, and high bits 0
        (private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0')) then
      valuex := to_ufixed (slv, HBV, LBV);
      value  := valuex (value'range);
      good   := true;
    else
      good := false;
    end if;

  end procedure hread;

  procedure hread (
    l     : inout line;
    value : out   unresolved_sfixed
  ) is

    constant HBV    : integer := (((private_maximum(4, (value'high+1)) + 3) / 4) * 4) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 3) / 4) * 4;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_sfixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    hread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => true,
                  smath   => true);

    if (igood) then                       -- We did not get another error
      if (not ((i = -1)                   -- We read everything
               and ((slv(value'high-LBV) = '0' and  -- sign bits = extra bits
                      private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0') or
                     (slv(value'high-LBV) = '1' and
                       private_and_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '1')))) then
        report fixed_generic_pkg'instance_name
               & "hread(sfixed): Vector truncated."
          severity error;
      else
        if (private_or_reduce(slv(value'low-LBV - 1 downto 0)) = '1') then
          assert no_warning
            report fixed_generic_pkg'instance_name
                   & "hread(sfixed): Vector truncated"
            severity warning;
        end if;
        valuex := to_sfixed (slv, HBV, LBV);
        value  := valuex (value'range);
      end if;
    end if;

  end procedure hread;

  procedure hread (
    l     : inout line;
    value : out   unresolved_sfixed;
    good  : out   boolean
  ) is

    constant HBV    : integer := (((private_maximum(4, (value'high+1)) + 3) / 4) * 4) - 1;
    constant LBV    : integer := ((mine(0, value'low) - 3) / 4) * 4;
    variable slv    : std_ulogic_vector (HBV - LBV downto 0);  -- high bits
    variable valuex : unresolved_sfixed (HBV downto LBV);
    variable igood  : boolean;
    variable i      : integer;

  begin

    value := (value'range => 'U');
    hread_common (l       => l,
                  slv     => slv,
                  igood   => igood,
                  idex    => i,
                  bpoint  => - lbv,
                  message => false,
                  smath   => true);

    if (igood and                   -- We did not get another error
        (i = -1) and                -- We read everything
        ((slv(value'high-LBV) = '0' and  -- sign bits = extra bits
           private_or_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '0') or
          (slv(value'high-LBV) = '1' and
            private_and_reduce(slv(HBV - LBV downto value'high+1 - LBV)) = '1'))) then
      valuex := to_sfixed (slv, HBV, LBV);
      value  := valuex (value'range);
      good   := true;
    else
      good := false;
    end if;

  end procedure hread;

  -- TO_string functions.  Useful in "report" statements.
  -- Example:  report "result was " & TO_string(result);
  function to_string (
    value : unresolved_ufixed
  ) return string is

    variable s      : string(1 to value'length +1) := (others => ' ');
    variable subval : unresolved_ufixed (value'high downto -1);
    variable sindx  : integer;

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        if (value(value'high) = 'Z') then
          return TO_string (resize (sfixed(value), 0, value'low));
        else
          return TO_string (resize (value, 0, value'low));
        end if;
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return TO_string(subval);
        else
          return TO_string (resize (value, value'high, -1));
        end if;
      else
        sindx := 1;

        for i in value'high downto value'low loop

          if (i = -1) then
            s(sindx) := '.';
            sindx    := sindx + 1;
          end if;
          s(sindx) := MVL9_to_char(std_ulogic(value(i)));
          sindx    := sindx + 1;

        end loop;

        return s;
      end if;
    end if;

  end function to_string;

  function to_string (
    value : unresolved_sfixed
  ) return string is

    variable s      : string(1 to value'length + 1) := (others => ' ');
    variable subval : unresolved_sfixed (value'high downto -1);
    variable sindx  : integer;

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        return TO_string (resize (value, 0, value'low));
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return TO_string(subval);
        else
          return TO_string (resize (value, value'high, -1));
        end if;
      else
        sindx := 1;

        for i in value'high downto value'low loop

          if (i = -1) then
            s(sindx) := '.';
            sindx    := sindx + 1;
          end if;
          s(sindx) := MVL9_to_char(std_ulogic(value(i)));
          sindx    := sindx + 1;

        end loop;

        return s;
      end if;
    end if;

  end function to_string;

  function to_ostring (
    value : unresolved_ufixed
  ) return string is

    constant LNE    : integer := (-value'low+2) / 3;
    variable subval : unresolved_ufixed (value'high downto -3);
    variable lpad   : std_ulogic_vector (0 to (LNE * 3 + value'low) - 1);
    variable slv    : std_ulogic_vector (value'length-1 downto 0);

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        if (value(value'high) = 'Z') then
          return to_ostring (resize (sfixed(value), 2, value'low));
        else
          return to_ostring (resize (value, 2, value'low));
        end if;
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return to_ostring(subval);
        else
          return to_ostring (resize (value, value'high, -3));
        end if;
      else
        slv := to_sulv (value);
        if (is_x (value (value'low))) then
          lpad := (others => value (value'low));
        else
          lpad := (others => '0');
        end if;
        return to_ostring(slv(slv'high downto slv'high-value'high))
          & "."
          & to_ostring(slv(slv'high-value'high-1 downto 0) & lpad);
      end if;
    end if;

  end function to_ostring;

  function to_hstring (
    value : unresolved_ufixed
  ) return string is

    constant LNE    : integer := (-value'low+3) / 4;
    variable subval : unresolved_ufixed (value'high downto -4);
    variable lpad   : std_ulogic_vector (0 to (LNE * 4 + value'low) - 1);
    variable slv    : std_ulogic_vector (value'length-1 downto 0);

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        if (value(value'high) = 'Z') then
          return to_hstring (resize (sfixed(value), 3, value'low));
        else
          return to_hstring (resize (value, 3, value'low));
        end if;
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return to_hstring(subval);
        else
          return to_hstring (resize (value, value'high, -4));
        end if;
      else
        slv := to_sulv (value);
        if (is_x (value (value'low))) then
          lpad := (others => value(value'low));
        else
          lpad := (others => '0');
        end if;
        return to_hstring(slv(slv'high downto slv'high-value'high))
          & "."
          & to_hstring(slv(slv'high-value'high-1 downto 0) & lpad);
      end if;
    end if;

  end function to_hstring;

  function to_ostring (
    value : unresolved_sfixed
  ) return string is

    constant NE     : integer := ((value'high+1) + 2) / 3;
    variable pad    : std_ulogic_vector(0 to (NE * 3 - (value'high+1)) - 1);
    constant LNE    : integer := (-value'low+2) / 3;
    variable subval : unresolved_sfixed (value'high downto -3);
    variable lpad   : std_ulogic_vector (0 to (LNE * 3 + value'low) - 1);
    variable slv    : std_ulogic_vector (value'high - value'low downto 0);

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        return to_ostring (resize (value, 2, value'low));
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return to_ostring(subval);
        else
          return to_ostring (resize (value, value'high, -3));
        end if;
      else
        pad := (others => value(value'high));
        slv := to_sulv (value);
        if (is_x (value (value'low))) then
          lpad := (others => value(value'low));
        else
          lpad := (others => '0');
        end if;
        return to_ostring(pad & slv(slv'high downto slv'high-value'high))
          & "."
          & to_ostring(slv(slv'high-value'high-1 downto 0) & lpad);
      end if;
    end if;

  end function to_ostring;

  function to_hstring (
    value : unresolved_sfixed
  ) return string is

    constant NE     : integer := ((value'high+1) + 3) / 4;
    variable pad    : std_ulogic_vector(0 to (NE * 4 - (value'high+1)) - 1);
    constant LNE    : integer := (-value'low+3) / 4;
    variable subval : unresolved_sfixed (value'high downto -4);
    variable lpad   : std_ulogic_vector (0 to (LNE * 4 + value'low) - 1);
    variable slv    : std_ulogic_vector (value'length-1 downto 0);

  begin

    if (value'length < 1) then
      return NUS;
    else
      if (value'high < 0) then
        return to_hstring (resize (value, 3, value'low));
      elsif (value'low >= 0) then
        if (is_x (value(value'low))) then
          subval               := (others => value(value'low));
          subval (value'range) := value;
          return to_hstring(subval);
        else
          return to_hstring (resize (value, value'high, -4));
        end if;
      else
        slv := to_sulv (value);
        pad := (others => value(value'high));
        if (is_x (value (value'low))) then
          lpad := (others => value(value'low));
        else
          lpad := (others => '0');
        end if;
        return to_hstring(pad & slv(slv'high downto slv'high-value'high))
          & "."
          & to_hstring(slv(slv'high-value'high-1 downto 0) & lpad);
      end if;
    end if;

  end function to_hstring;

  -- From string functions allow you to convert a string into a fixed
  -- point number.  Example:
  --  signal uf1 : ufixed (3 downto -3);
  --  uf1 <= from_string ("0110.100", uf1'high, uf1'low); -- 6.5
  -- The "." is optional in this syntax, however it exist and is
  -- in the wrong location an error is produced.  Overflow will
  -- result in saturation.
  function from_string (
    bstring              : string;      -- binary string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(bstring);
    read (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_string: Bad string " & bstring
      severity error;
    return result;

  end function from_string;

  -- Octal and hex conversions work as follows:
  -- uf1 <= from_hstring ("6.8", 3, -3); -- 6.5 (bottom zeros dropped)
  -- uf1 <= from_ostring ("06.4", 3, -3); -- 6.5 (top zeros dropped)
  function from_ostring (
    ostring              : string;      -- Octal string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(ostring);
    oread (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_ostring: Bad string " & ostring
      severity error;
    return result;

  end function from_ostring;

  function from_hstring (
    hstring              : string;      -- hex string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_ufixed
  is

    variable result : unresolved_ufixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(hstring);
    hread (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_hstring: Bad string " & hstring
      severity error;
    return result;

  end function from_hstring;

  function from_string (
    bstring              : string;      -- binary string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(bstring);
    read (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_string: Bad string " & bstring
      severity error;
    return result;

  end function from_string;

  function from_ostring (
    ostring              : string;      -- Octal string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(ostring);
    oread (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_ostring: Bad string " & ostring
      severity error;
    return result;

  end function from_ostring;

  function from_hstring (
    hstring              : string;      -- hex string
    constant left_index  : integer;
    constant right_index : integer
  )
    return unresolved_sfixed
  is

    variable result : unresolved_sfixed (left_index downto right_index);
    variable l      : line;
    variable good   : boolean;

  begin

    l := new string'(hstring);
    hread (l, result, good);
    deallocate (l);
    assert (good)
      report fixed_generic_pkg'instance_name
             & "from_hstring: Bad string " & hstring
      severity error;
    return result;

  end function from_hstring;

  -- Same as above, "size_res" is used for it's range only.
  function from_string (
    bstring  : string;                  -- binary string
    size_res : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return from_string (bstring, size_res'high, size_res'low);

  end function from_string;

  function from_ostring (
    ostring  : string;                  -- Octal string
    size_res : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return from_ostring (ostring, size_res'high, size_res'low);

  end function from_ostring;

  function from_hstring (
    hstring  : string;                  -- hex string
    size_res : unresolved_ufixed
  )
    return unresolved_ufixed is
  begin

    return from_hstring(hstring, size_res'high, size_res'low);

  end function from_hstring;

  function from_string (
    bstring  : string;                  -- binary string
    size_res : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return from_string (bstring, size_res'high, size_res'low);

  end function from_string;

  function from_ostring (
    ostring  : string;                  -- Octal string
    size_res : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return from_ostring (ostring, size_res'high, size_res'low);

  end function from_ostring;

  function from_hstring (
    hstring  : string;                  -- hex string
    size_res : unresolved_sfixed
  )
    return unresolved_sfixed is
  begin

    return from_hstring (hstring, size_res'high, size_res'low);

  end function from_hstring;

  -- Direct conversion functions.  Example:
  --  signal uf1 : ufixed (3 downto -3);
  --  uf1 <= from_string ("0110.100"); -- 6.5
  -- In this case the "." is not optional, and the size of
  -- the output must match exactly.
  -- purpose: Calculate the string boundaries
  procedure calculate_string_boundry (
    arg         : in  string;           -- input string
    left_index  : out integer;          -- left
    right_index : out integer
  ) is       -- right

    -- examples "10001.111" would return +4, -3
    -- "07X.44" would return +2, -2 (then the octal routine would multiply)
    -- "A_B_._C" would return +1, -1 (then the hex routine would multiply)
    alias    xarg     : string (arg'length downto 1) is arg;  -- make it downto range
    variable l, r     : integer;            -- internal indexes
    variable founddot : boolean := false;

  begin

    if (arg'length > 0) then
      l := xarg'high - 1;
      r := 0;

      for i in xarg'range loop

        if (xarg(i) = '_') then
          if (r = 0) then
            l := l - 1;
          else
            r := r + 1;
          end if;
        elsif (xarg(i) = ' ' or xarg(i) = NBSP or xarg(i) = HT) then
          report fixed_generic_pkg'instance_name
                 & "Found a space in the input string " & xarg
            severity error;
        elsif (xarg(i) = '.') then
          if (founddot) then
            report fixed_generic_pkg'instance_name
                   & "Found two binary points in input string " & xarg
              severity error;
          else
            l        := l - i;
            r        := -i + 1;
            founddot := true;
          end if;
        end if;

      end loop;

      left_index  := l;
      right_index := r;
    else
      left_index  := 0;
      right_index := 0;
    end if;

  end procedure calculate_string_boundry;

  -- Direct conversion functions.  Example:
  --  signal uf1 : ufixed (3 downto -3);
  --  uf1 <= from_string ("0110.100"); -- 6.5
  -- In this case the "." is not optional, and the size of
  -- the output must match exactly.
  function from_string (
    bstring : string
  )                      -- binary string
    return unresolved_ufixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (bstring, left_index, right_index);
    return from_string (bstring, left_index, right_index);

  end function from_string;

  -- Direct octal and hex conversion functions.  In this case
  -- the string lengths must match.  Example:
  -- signal sf1 := sfixed (5 downto -3);
  -- sf1 <= from_ostring ("71.4") -- -6.5
  function from_ostring (
    ostring : string
  )                      -- Octal string
    return unresolved_ufixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (ostring, left_index, right_index);
    return from_ostring (ostring, ((left_index + 1) * 3) - 1, right_index * 3);

  end function from_ostring;

  function from_hstring (
    hstring : string
  )                      -- hex string
    return unresolved_ufixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (hstring, left_index, right_index);
    return from_hstring (hstring, ((left_index + 1) * 4) - 1, right_index * 4);

  end function from_hstring;

  function from_string (
    bstring : string
  )                      -- binary string
    return unresolved_sfixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (bstring, left_index, right_index);
    return from_string (bstring, left_index, right_index);

  end function from_string;

  function from_ostring (
    ostring : string
  )                      -- Octal string
    return unresolved_sfixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (ostring, left_index, right_index);
    return from_ostring (ostring, ((left_index + 1) * 3) - 1, right_index * 3);

  end function from_ostring;

  function from_hstring (
    hstring : string
  )                      -- hex string
    return unresolved_sfixed
  is

    variable left_index, right_index : integer;

  begin

    calculate_string_boundry (hstring, left_index, right_index);
    return from_hstring (hstring, ((left_index + 1) * 4) - 1, right_index * 4);

  end function from_hstring;

end package body fixed_generic_pkg;
