function default_prefs()
  return {
    default_note_transform = "O",
    hex_pattern = 1,
    hex_line = 2,
    change_color = true,
    dirty_color_r = 175,
    dirty_color_g = 97,
    dirty_color_b = 58,
    idle_color_r = 70,
    idle_color_g = 179,
    idle_color_b = 118,
    track = 1,
    auto_render_delay = 3,
    auto_render = true,
    seed = 0,
    help = 1,
    write_seed = true,
    keep_seed = true,
    enabled = true,
    prefix = "@",
    automation = true,
  }
end

ChunkTrackType = {
  all = "",
  track = "t",
  group = "g",
}

PatternType = {
  absolute = "P",
  down = "D",
  up = "U",
  sequence = "S",
  random = "R",
  random_patterns = "E",
  off = "O",
}
PatternTypes = enum_lookup(PatternType)

PatternFlag = {
  empty = "0",
  single_line = "S",
}
PatternFlags = enum_lookup(PatternFlag)

LineMode = {
  up = "U",
  down = "D",
  random = "R",
}
LineModes = enum_lookup(LineMode)

LineType = {
  empty = "0",
  absolute = "L",
  beat = "B",
  random = "R",
}
LineTypes = enum_lookup(LineType)

EffectType = {
  keep = "K",
  clear = "C",
  up_instrument = "I",
  down_instrument = "J",
  up_note = "U",
  down_note = "D",
  up_octave = "A",
  down_octave = "B",
  no = "N",
  yes = "Y",
}
EffectTypes = enum_lookup(EffectType)

command_cheat = [[

# chunk pattern commands (first FX column)

-Pxx: pattern at index xx
-Sxx: sequence step xx
-Uxx: xx above the current sequence step
-Dxx: xx below the current sequence step
-Rxx: a random pattern with seed xx
-Exx: a new random pattern every line with seed xx
-O--: stop chunking (works like OFF commands for notes, without it the chunk will continue until the end of the pattern or another pattern command)

# pattern flags (first FX column)

S---: only chunk a single line

# line commands (second FX column)

--xx: the default mode, offsets by xx lines
Bmxx: specify the line offset in terms of beats
Lxxx: specify an absolute line number
Rmxx: start from a random line with seed xx

# line command mods (second FX column)

-Dxx: start chunking xx below the current line
-Uxx: start chunking xx above the current line
-Rxx: sample random lines with seed xx (for beat mode only the beat will be picked randomly, the rest of the chunk will stay as it was, otherwise each line will be sampled from a new random location)

# skip commands (Vol or Pan column)

K-: keep the line as it is (useful for when you want to preserve some handwritten lines while chunking the rest)
C-: clear the line
N-: no rendering, everything will be skipped after this

If you want to protect an entire pattern from re-rendering simply mute the chunk track at the particular step in the pattern matrix (middle click on a pattern).

# note commands (Vol or Pan column)

Dx: lower note by x semitones
Ux: raise note by x semitones
Bx: lower note to x octaves below
Ax: raise note to x octaves above

Ix: raise instrument by x
Jx: lower instrument by x

# note column

OFF: write a note off across all tracks

]]

usage = [[

Compose new patterns using a set of meta commands to chunk existing patterns into a new one.

Provides two key-bindings in *Pattern Editor / Tools*

- Render Chunk Pattern
- Render Chunk Pattern With New Seed

They are available in the context menu of the pattern editor as well.

# setup

- Create an empty track to serve as your *chunk track*
- Name it as @
- Have two FX columns

# usage

- Type chunking information into your chunk track
- Run one of the *Render...* commands mentioned above
- Alternatively, enable *Render / On Change* in the settings (enabled by default)

# chunking

- The first FX column controls what pattern to take the chunk from
- The second FX column can control what lines to take


# examples

- chunk from pattern 1
> -P01 ----

- chunk from beat 4 of the pattern at the second sequence step
> -S02 B004

- chunk from 4 lines below the current line from a random pattern
> -R00 -D04 

- chunk at a random line from 4 sequence above
> -U04 R000 

- chunk at a random beat from 5 sequence above
> -U05 BR00

- chunk completely random lines from pattern 8
> -P08 RR00

- copy a single line from 8 from the pattern 4
> SP04 L008
 
See [Commands] for a list of all commands and their function

# repeating VOL/PAN commands

If you want to cover more lines with the same transposition your can repeat any of these with zero for x, this will transponse to whatever value is at the top of the chain. For example this will raise four consecutive lines by 4 semitones.

U4
U0
U0
U0

# track selection

By default whatever track comes after your chunk track will be modified on render but you have a few ways to edit only specific tracks.

- Prepend a # (hashtag) character to the names of the tracks you want to preserve
` | @ | chunked | #kept | chunked | chunked |`
- Every track that comes before your chunk track will be left alone
` | kept | kept | @ | chunked | chunked | chunked |`
- Name your chunk track as @Tx where x is the number of tracks to modify after it (for example @T2 will only affect the two closest track on the right)
` | kept | kept | @T2 | chunked | chunked | kept |`
- Name your chunk track as @G and put it inside a group, this will only affect the group
` | kept < @G | chunked | chunked | chunked > kept |`
]]