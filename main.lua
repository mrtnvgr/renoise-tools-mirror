--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Main tool integration code
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Revision History
-- 1.1  - Released 05/2011
--
--        - FIX: Workaround for 'drumkit' instruments with akp akai programs
--        - FIX: Extra CR line endings on Unix based systems
--        - FIX: Loading REX files will clear the instrument if required
--        - ADD: support for '.s' Akai S1000/S3000 samples
--        - ADD: support for '.p' Akai S1000 programs
--        - ADD: support for '.sfz' rgc:audio SFZ instruments
--        - ADD: additional folders to sample search path for OSX
--
-- 1.0  - Released 09/05/2011 in conjunction with Renoise 2.7 Final
--
--        Supported import formats are:
--        
--          Samples:
--            * Akai MPC2000/2000XL (.snd)
--            * Korg Trinity/Triton (.ksf)
--            * Propellerheads Recycle (.rex)
--
--          Instruments:
--            * Akai MPC1000 Programs (.pgm)
--            * Akai MPC2000/2000XL Programs (.pgm)
--            * Akai S5000/S6000/Z4/Z8 Programs (.akp)
--            * Apple/EMagic Logic EXS24 Patches (.exs)
--            * Korg Trinity/Triton Multisamples (.kmp)
--            * Korg Trinity/Triton Peformance Scripts (.ksc)
--            * Propellerheads Reason NN-XT Patches (.sxt) [partial]
--            * Roland MV8x000 Patches (.mv0) [samples only]
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "support/aiff_tools"
require "support/binary_ops"
require "support/dprint"
require "support/file_parsing"
require "support/file_tools"
require "support/hex_ops"
require "support/memory_parsing"
require "support/ProcessSlicer" -- from com.Renoise.MidiConvert.xrnx
require "support/wav_tools"

require "samples/akai-s1000s"
require "samples/korg-ksf"
require "samples/mpc2000-snd"
require "samples/recycle-rex"

require "instruments/akai-s1000p"
require "instruments/akai-s5s6"
require "instruments/korg-kmp"
require "instruments/korg-ksc"
require "instruments/reason-nnxt"
require "instruments/mpcCommon-pgm"
require "instruments/mpc2000-pgm"
require "instruments/mpc1000-pgm"
require "instruments/logic-exs24"
require "instruments/rgc-sfz"
require "instruments/roland-mv8x00"
