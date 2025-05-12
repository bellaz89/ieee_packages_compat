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
  --   Title     :  Standard multivalue logic package
  --             :  (STD_LOGIC_TEXTIO package declaration)
  --             :
  --   Library   :  This package shall be compiled into a library
  --             :  symbolically named IEEE.
  --             :
  --   Developers:  Accellera VHDL-TC and IEEE P1076 Working Group
  --             :
  --   Purpose   :  This packages is provided as a replacement for non-standard
  --             :  implementations of the package provided by implementers of
  --             :  previous versions of this standard. The declarations that
  --             :  appeared in those non-standard implementations appear in the
  --             :  package STD_LOGIC_1164 in this standard.
  --             :
  --   Note      :  No declarations or definitions shall be included in,
  --             :  or excluded from this package.
  --             :
  -- --------------------------------------------------------------------
  -- $Revision: 1305 $
  -- $Date: 2008-06-27 14:28:49 +0930 (Fri, 27 Jun 2008) $
  -- --------------------------------------------------------------------
use std.textio.all;

library ieee;
use ieee.std_logic_1164.std_logic;
use ieee.std_logic_1164.std_ulogic;
use ieee.std_logic_1164.std_logic_vector;
use ieee.std_logic_1164.std_ulogic_vector;

library ieee_compat;
use ieee_compat.std_logic_1164;

package std_logic_textio is

  alias read  is ieee_compat.std_logic_1164.READ [LINE, STD_ULOGIC];
  alias read  is ieee_compat.std_logic_1164.READ [LINE, STD_ULOGIC, BOOLEAN];
  alias read  is ieee_compat.std_logic_1164.READ [LINE, STD_ULOGIC_VECTOR];
  alias read  is ieee_compat.std_logic_1164.READ [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias write is ieee_compat.std_logic_1164.WRITE [LINE, STD_ULOGIC, SIDE, WIDTH];
  alias write is ieee_compat.std_logic_1164.WRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];

  alias hread  is ieee_compat.std_logic_1164.HREAD [LINE, STD_ULOGIC_VECTOR];
  alias hread  is ieee_compat.std_logic_1164.HREAD [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias hwrite is ieee_compat.std_logic_1164.HWRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];

  alias oread  is ieee_compat.std_logic_1164.OREAD [LINE, STD_ULOGIC_VECTOR];
  alias oread  is ieee_compat.std_logic_1164.OREAD [LINE, STD_ULOGIC_VECTOR, BOOLEAN];
  alias owrite is ieee_compat.std_logic_1164.OWRITE [LINE, STD_ULOGIC_VECTOR, SIDE, WIDTH];

end package std_logic_textio;
