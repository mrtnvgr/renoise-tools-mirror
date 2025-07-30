# chunk_chops

Compose new patterns using a set of meta commands to chunk existing patterns into a new one.

Provides two key-bindings in *Pattern Editor / Tools*

- `Render Chunk Pattern`
- `Render Chunk Pattern With New Seed`

They are available in the context menu of the pattern editor as well.

### setup

- Create an empty track to serve as your *chunk track*
- Name it as `@`
- Have two FX columns

### usage

- Type chunking information into your chunk track
- Run one of the *Render...* commands mentioned above
- Alternatively, enable *Render / On Change* in the settings (enabled by default)

### chunking

- The first FX column controls what pattern to take the chunk from
- The second FX column can control what lines to take

#### pattern commands

You need to have one of these in the first FX column to start a new chunk

- `-Pxx` : chunk from pattern at index `xx`
- `-Sxx` : chunk from sequence step `xx`
- `-Uxx` : chunk from `xx` above the current sequence step
- `-Dxx` : chunk from `xx` below the current sequence step
- `-Rxx` : chunk from a random pattern with seed `xx`
- `-Exx` : chunk from a new random pattern every line with seed `xx`
- `-O--` : stop chunking (works like `OFF` commands for notes, without it the chunk will continue until the end of the pattern or another pattern command)

#### pattern flags

Append to the front of an existing pattern command

- `S---` : only chunk a single line

### line commands

By default, chunks start copying from the same line where they start at.
For example a chunk starting in the middle of the pattern will copy from the middle of the other pattern. You can modify this using line commands in the second FX column.

The first character will determine the type of line selection

- `--xx` : the default mode, offsets by `xx` lines
- `Bmxx` : specify the line offset in terms of beats
- `Lxxx` : specify an absolute line number
- `Rmxx` : start from a random line with seed `xx`

The second  character will set what the `xx` values mean

- `-Dxx` : start chunking `xx` below the current line
- `-Uxx` : start chunking `xx` above the current line
- `-Rxx` : sample random lines with seed `xx` (for beat mode only the beat will be picked randomly, the rest of the chunk will stay as it was, otherwise each line will be sampled from a new random location)

### examples

- chunk from pattern `1`
> `-P01 ----`

- chunk from beat `4` of the pattern at the second sequence step

> `-S02 B004` 

- chunk from `4` lines below the current line from a random pattern
> `-R00 -D04` 
- chunk at a random line from `4` sequence above
> `-U04 R000` 
- chunk at a random beat from `5` sequence above
> `-U05 BR00`
- chunk completely random lines from pattern `8`
> `-P08 RR00`
- copy a single line from `8` from the pattern `4`
> `SP04 L008`
 

### additional commands

There are a few more commands you can use inside the `Vol` or `Pan` columns of the first note column.

- `K-` : keep the line as it is (useful for when you want to preserve some handwritten lines while chunking the rest)
- `C-` : clear the line
- `N-` : no rendering, everything will be skipped after this

If you want to protect an entire pattern from re-rendering simply mute the chunk track at the particular step in the pattern matrix (middle click on a pattern).

Transpose the chunked notes

- `Dx` : lower by `x` semitones
- `Ux` : raise by `x` semitones
- `Bx` : lower to `x` octaves below
- `Ax` : raise to `x` octaves above

Transpose the instrument of notes

- `Ix` : raise by `x`
- `Jx` : lower by `x`

If you want to cover more lines with the same transposition your can repeat any of these with zero for `x`, this will transponse to whatever value is at the top of the chain. For example this will raise four consecutive lines by 4 semitones.
```
U4
U0
U0
U0
```

- `OFF`: you can put an `OFF` into the note column to write a note off across all tracks

### track selection

By default tracks that come after your chunk track will be modified on render. If you wish to render to only specific tracks you can use one of the following techniques.

- Prepend a # (hashtag) character to the names of the tracks you want to preserve  
` | @ | chunked | #kept | chunked | chunked |`
- Every track that comes before your chunk track will be left alone  
` | kept | kept | @ | chunked | chunked | chunked |`
- Name your chunk track as `@Tx` where x is the number of tracks to modify after it (for example `@T2` will only affect the two closest track on the right)  
` | kept | kept | @T2 | chunked | chunked | kept |`
- Name your chunk track as `@G` and put it inside a group, this will only render to the tracks inside the group
` | kept < @G | chunked | chunked | chunked > kept |`

### settings

- `Track Prefix` sets what you need in your track's name to be recognized as a chunk track

#### Render

- `On Change` - enable to have your chunking get auto-rendered whenever you change lines
- `Watch Interval` - ticks to wait before auto-rendering after lines changed (increase this if the auto-rendering is too quick for you)
- `Render` - run a render now

#### Randomness

Random commands use a seed to have randomly generated values stay reproducible, you can unlock this seed to have each render get a new seed, otherwise you can change the `xx` values after random commands to have a new offset from the seed (and so a new random output). You can also force a seed change using the *Render with new seed* commands.

- `Lock Seed` - keep the random seed locked
- `$eed to Track` - write the seed into the name of the track as $*seed* to preserve the seed for the song, otherwise your seed might change between project (since it is saved globally with the tool preferences)

#### Pattern

- `Pattern Format` - set how numbers are interpreted for pattern commands (decimal or hexadecimal)
- `Line Format` - same for line and beat indices
- `Automation` - toggle chunking automation info (this might not work as well)

Note: if you set a format to decimal but have a hexadecimal value in you chunk track like `-P0A` it will still get interpreted as hex.

#### Colors
- `Change` - enable changing the chunk track's color while editing and rendering
- `Assign Edited` - press this to assign the currently selected track's color as edited color
- `Assign Rendered` - same as above for the rendered color

