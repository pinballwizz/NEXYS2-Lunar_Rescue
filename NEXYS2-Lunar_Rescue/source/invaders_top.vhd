-- Space Invaders top level for
-- ps/2 keyboard interface with sound and scan doubler MikeJ
--
-- Version : 0300
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : Moved the PS/2 interface to ps2kbd.vhd, added the ROM from mw8080.vhd
--
--      0300 : MikeJ tidy up for audio release
--------------------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;
--------------------------------------------------------------------------------------------
entity invaders_top is
	port(
	 SW_COIN                : in    std_logic;
	 SW_START               : in    std_logic;
	 SW_SHOOT               : in    std_logic;
	 SW_LEFT                : in    std_logic;
	 SW_RIGHT               : in    std_logic;

    O_VIDEO_R             : out   std_logic_vector(2 downto 0);
    O_VIDEO_G             : out   std_logic_vector(2 downto 0);
    O_VIDEO_B             : out   std_logic_vector(1 downto 0);
    O_HSYNC               : out   std_logic;
    O_VSYNC               : out   std_logic;

	O_AUDIO           : out   std_logic;

	I_RESET           : in    std_logic;
	I_CLK_REF         : in    std_logic
		);
end invaders_top;
--------------------------------------------------------------------------------------------
architecture rtl of invaders_top is

-- Signals
	signal I_RESET_L       : std_logic;
	signal Clk             : std_logic;
	signal Clk_x2          : std_logic;
	signal Rst_n_s         : std_logic;

	signal DIP             : std_logic_vector(8 downto 1);
	signal RWE_n           : std_logic;
	signal CAB			     : std_logic_vector(9 downto 0);
	signal Video           : std_logic;
	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal VideoRGB_o        : std_logic_vector(2 downto 0);
	signal VideoRGB_X2     : std_logic_vector(7 downto 0);
	signal HSync           : std_logic;
	signal VSync           : std_logic;
	signal HSync_X2        : std_logic;
	signal VSync_X2        : std_logic;
	signal hs       	   : std_logic;
	signal vs      		   : std_logic;

	signal AD              : std_logic_vector(15 downto 0);
	signal RAB             : std_logic_vector(12 downto 0);
	signal RDB             : std_logic_vector(7 downto 0);
	signal RWD             : std_logic_vector(7 downto 0);
	signal IB              : std_logic_vector(7 downto 0);
	signal SoundCtrl3      : std_logic_vector(5 downto 0);
	signal SoundCtrl5      : std_logic_vector(5 downto 0);

	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal rom_data_4      : std_logic_vector(7 downto 0);
	signal rom_data_5      : std_logic_vector(7 downto 0);
	signal ram_we          : std_logic;

	signal Audio           : std_logic_vector(7 downto 0);
	signal AudioPWM        : std_logic;
------------------------------------------------------------------------------------------------
begin

  I_RESET_L	 <= not I_RESET;
  DIP		 <= "00000000";
------------------------------------------------------------------------------------------------
-- Clocks
  u_clocks : entity work.INVADERS_CLOCKS
	port map (
	   I_CLK_REF  => I_CLK_REF,
	   I_RESET_L  => I_RESET_L,
	   --
	   O_CLK      => Clk,
	   O_CLK_X2   => Clk_x2
	 );
------------------------------------------------------------------------------------------------
-- Main
	core : entity work.invaderst
		port map(
			Rst_n      => I_RESET_L,
			Clk        => Clk,
			Coin       => not SW_COIN,
			Sel1Player => not SW_START,
			Sel2Player => '1',
			Fire       => not SW_SHOOT,
			MoveLeft   => not SW_LEFT,
			MoveRight  => not SW_RIGHT,
			DIP        => DIP,
			RDB        => RDB,
			IB         => IB,
			RWD        => RWD,
			RAB        => RAB,
			AD         => AD,
			SoundCtrl3 => SoundCtrl3,
			SoundCtrl5 => SoundCtrl5,
			Rst_n_s    => Rst_n_s,
			RWE_n      => RWE_n,
			Video      => Video,
			CAB		   => CAB,
			HSync      => HSync,
			VSync      => VSync
			);
------------------------------------------------------------------------------------------------
-- Roms
	u_rom_0 : entity work.LRESCUE_PROM_1
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_0
		);
	--
	u_rom_1 : entity work.LRESCUE_PROM_2
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_1
		);
	--
	u_rom_2 : entity work.LRESCUE_PROM_3
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_2
		);
	--
	u_rom_3 : entity work.LRESCUE_PROM_4
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_3
		);
		
	u_rom_4 : entity work.LRESCUE_PROM_5
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_4
		);
		
	u_rom_5 : entity work.LRESCUE_PROM_6
	  port map (
		CLK         => Clk,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_5
		);
------------------------------------------------------------------------------------------------
-- RomSel
	p_rom_data : process(AD, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5)
	begin
	  IB <= (others => '0');
	  case AD(15 downto 11) is
		when "00000" => IB <= rom_data_0;
		when "00001" => IB <= rom_data_1;
		when "00010" => IB <= rom_data_2;
		when "00011" => IB <= rom_data_3;
		when "01000" => IB <= rom_data_4;
		when "01001" => IB <= rom_data_5;
		when others => null;
	  end case;
	end process;
------------------------------------------------------------------------------------------------
-- Ram
	ram_we <= not RWE_n;

	rams : for i in 0 to 3 generate
	  u_ram : component RAMB16_S2
	  port map (
		do   => RDB((i*2)+1 downto (i*2)),
		addr => RAB,
		clk  => Clk,
		di   => RWD((i*2)+1 downto (i*2)),
		en   => '1',
		ssr  => '0',
		we   => ram_we
		);
	end generate;
------------------------------------------------------------------------------------------------
-- Video
 Overlay : entity work.LunarRescue_Overlay
		port map(
			Video  	    => Video,
			CLK			 => Clk,
			Rst_n_s		 => Rst_n_s,
			HSync  	    => HSync,
			VSync  	    => VSync,
			CAB			 => CAB,
			VideoRGB		 => VideoRGB_o
		);
------------------------------------------------------------------------------------------------
-- Scandoubler		
  u_dblscan : entity work.DBLSCAN
	port map (
	  RGB_IN(7 downto 3) => "00000",
	  RGB_IN(2 downto 0) => VideoRGB_o,
	  HSYNC_IN           => HSync,
	  VSYNC_IN           => VSync,

	  RGB_OUT            => VideoRGB_X2,
	  HSYNC_OUT          => HSync_X2,
	  VSYNC_OUT          => VSync_X2,
	  --  NOTE CLOCKS MUST BE PHASE LOCKED !!
	  CLK                => Clk,
	  CLK_X2             => Clk_x2
	);

  O_VIDEO_R <= VideoRGB_X2(2)&VideoRGB_X2(2)&VideoRGB_X2(2);
  O_VIDEO_G <= VideoRGB_X2(1)&VideoRGB_X2(1)&VideoRGB_X2(1);
  O_VIDEO_B <= VideoRGB_X2(0)&VideoRGB_X2(0);
  O_HSYNC   <= not HSync_X2;
  O_VSYNC   <= not VSync_X2;
-----------------------------------------------------------------------------------------------
-- Audio
  u_audio : entity work.invaders_audio
	port map (
	  Clk => Clk,
	  S1  => SoundCtrl3,
	  S2  => SoundCtrl5,
	  Aud => Audio
	  );
------------------------------------------------------------------------------------------------
-- DAC
  u_dac : entity work.dac
	generic map(
	  msbi_g => 7
	)
	port  map(
	  clk_i   => Clk,
	  res_n_i => Rst_n_s,
	  dac_i   => Audio,
	  dac_o   => AudioPWM
	);

    O_AUDIO <= AudioPWM;
------------------------------------------------------------------------------------------------
end;