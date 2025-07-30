
Rubber Band
===========

An audio time-stretching and pitch-shifting library and utility program.

Written by Chris Cannam, chris.cannam@breakfastquay.com.
Copyright 2007-2018 Particular Programs Ltd.

Rubber Band is a library and utility program that permits changing the
tempo and pitch of an audio recording independently of one another.

See http://breakfastquay.com/rubberband/ for more information.


Licence
=======

Rubber Band is distributed under the GNU General Public License. See
the file COPYING for more information. Please refer to
http://breakfastquay.com/rubberband/ for source code and for details
about commercial licences.

This package contains a build of the Rubber Band command-line tool for
macOS.  This program is built using the Rubber Band library, and
requires libsndfile (http://www.mega-nerd.com/libsndfile/) to have
been installed via Homebrew.


Using the Rubber Band command-line tool
=======================================

The basic incantation is

  $ rubberband -t <timeratio> -p <pitchratio> <infile.wav> <outfile.wav>

For example,

  $ rubberband -t 1.5 -p 2.0 test.wav output.wav

stretches the file test.wav to 50% longer than its original duration,
shifts it up in pitch by one octave, and writes the output to output.wav.

Several further options are available: run "rubberband -h" for help.
In particular, different types of music may benefit from different
"crispness" options (-c <n> where <n> is from 0 to 6).


Copyright notes for included libraries
======================================

Speex
-----

Copyright 2002-2007 	Xiph.org Foundation
Copyright 2002-2007 	Jean-Marc Valin
Copyright 2005-2007	Analog Devices Inc.
Copyright 2005-2007	Commonwealth Scientific and Industrial Research 
                        Organisation (CSIRO)
Copyright 1993, 2002, 2006 David Rowe
Copyright 2003 		EpicGames
Copyright 1992-1994	Jutta Degener, Carsten Bormann

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

- Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

- Neither the name of the Xiph.org Foundation nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

