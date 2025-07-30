# genpad

The idea here is to have some handy popups that can be controlled with a few keys (mostly just the arrows) to offer a sort of gamepad like control-scheme (although the tool doesn't respond to actual gamepad inputs out-of-the-box).

Provides key-bindings under *Tools* in both the *Pattern Editor* and *Phrase Editor*, they can also be launched from the right-click context menu inside each editor. Look for entries named as `genpad - [name-of-pad]`.

There are a few different pads available in this tool, all of them serving a somewhat singular function

* [chorder](#chorder) - fast chord input method using harmonic intervals
* [euclidean](#euclidean) - spread notes and hits based on equal distribution algorithm
* [bars](#bars) - length and time signature helper for patterns
* [glider](#glider) - generate glide commands based on note lengths

## chorder

![chorder|580x224](https://forum.renoise.com/uploads/default/original/3X/d/d/dd124746bf5fa7509f89e5f3040cc36ef2cd305b.gif)

Create chords faster by stacking intervals.

### usage

- Launch `chorder` from the pattern or phrase editor
- Press `Right` to stack notes a consonant interval apart from the last note
- Press `Left` to do the same but for dissonant intervals
- `Up` and `Down` will change the selected intervals and the last note as well, the currently active intervals will be displayed at the bottom of the window.
- `Backspace` will remove a note

Consonant intervals include major and perfect intervals while dissonant intervals include minor or diminished intervals. This allows you to quickly type out chords of different qualities using combos as if your were in a fighting game.

> :ninja: For example...
>* pluck a major seventh chord by doing :arrow_right: :arrow_left: :arrow_right: 
>* or bath in a minor seventh with  :arrow_left: :arrow_right: :arrow_left:
>* go far out with a [dominant seventh sharp nine](https://en.wikipedia.org/wiki/Dominant_seventh_sharp_ninth_chord) by executing :arrow_right: :arrow_left: :arrow_left: :arrow_right: :arrow_up:
>* or spam the [circle of fifths](https://en.wikipedia.org/wiki/Circle_of_fifths) with  :arrow_right: :arrow_up: :arrow_up: :arrow_right: :arrow_right: :arrow_right: :arrow_right: :arrow_right: ...

You can also access different functions to modify your chord further by holding down `Shift` or `Control`/`Command`

#### holding shift

- `Left` and `Right` will move the bottom note up - and the top note down - an octave (or more if the same note already exist at that octave)
- `Up` and `Down` will shift the entire chord by octaves (or semitones if you hold down `Control` as well as `Shift`)

#### holding control

- `Left` and `Right` will select the previous or next note in the chord (displayed with a `*` sign at the top), you can use `Backspace` to delete the currently selected note
- `Up` and `Down` will transpose the selected note

#### play and retrigger

*Only relevant in the Pattern Editor* 

If playing the edited pattern on loop to listen to your chord isn't enough, you can somewhat preview the edited notes by playing the pattern from the currently edited line with by holding down `Space` (playback is stopped when you let go). Unfortunately, notes will be dropped sometimes. 

You can also toggle `retrigger` mode with `Shift + Space`, this will automatically retrigger the pattern whenever you add or modify notes.


## euclidean

![euclid|250x450](https://forum.renoise.com/uploads/default/original/3X/9/7/9774e4ac6209b5f09a7f171d868e326100e7516f.gif)

Generate [euclidean rhythms](https://en.wikipedia.org/wiki/Euclidean_rhythm) from a set of notes in a pattern or a phrase.

### usage

- Have some notes in a pattern or a phrase
- Launch the euclidean genpad.
- Select parameters using the `Up` and `Down` arrow
- Adjust them by pressing `Left` or `Right` (hold `Ctrl/Command` for bigger steps)
- The pattern will be continuously changed while you are adjusting
- Press `Enter` or bounce around when you are happy

You can start from a single note or multiple notes, you can even use chords or a mix of single notes and chords. These notes will be collected when you launch the genpad and will be used as a *note-pool* to fill your pulses. If there are less notes in the pool than pulses you picked, they will be repeated over and over.

You can select a range inside the pattern to only generate the rhythm there, if you haven't selected anything or only selected a single line, the rhythm will be generated over the entire pattern.

### parameters

### rhythm

- `pulses` - the number of pulses to distribute over the selected steps
- `steps` - how many steps to distribute the pulses over
- `rotate` - rotate the generated pulse-rhythm across the steps
- `offset` - rotate the resulting rhythm by a line offset in the pattern

#### notes

- `cycle` - cycle the pattern of notes you have (if you only selected a single note or the same one multiple times, this parameter will have no effect on the output)
- `repeats` - number of times to use each note from your *note-pool*, for example if you have notes *C, E, B* and set `repeats` to 2 the pattern will contain notes as *C, C, E, E, B, B*

#### swing

- `swing` - the amount of swing to apply to pulses that fall into the *swing-window*
- `size` - how many lines to repeat the swing pattern over, by default this should match your LPB
- `window` - where to start applying the swing inside the `size`, for example if you have 4 lines-per-beat with a swing `size` of 4, a window of 2 will mean the swing amount will be applied to lines 3 and 4 in each beat
- `shift` - shift the *swing-window* around to swing different parts of the beat

#### delay

- `delay` - apply a uniform delay to every generated note
- `snap` - by default the generated notes will be quantized to lines, if you want actual equal distribution of pulses you can switch this to `none` and have wonky rhythms

You can reset each parameter to the default value using `Backspace`.

## bars

![bars](https://forum.renoise.com/uploads/default/original/3X/4/b/4bbbba73327ef70ddb862932861044f7ed0cba85.gif)

Manage the timing of your patterns from a dialog that can create new patterns with length based on beats and bars. If you want, it can write FX commands for you as well to change BPM, LPB, TPL, it might even make you BFF with odd time signature changes.

### usage

- Open the pad using the key-binding you've set up
- Select fields with `Up` and `Down`
- Set values with `Left` and `Right` (hold ctrl/command for coarse stepping)
- Press `Enter` to apply your parameters

#### parameters

- `beats` - how many beats you want to have in the pattern
- `bars` - each bar will have the previous number of beats inside it
- `LPB mode` select what to do with the lines-per-beat value
  - `keep` - no `ZL` command will be written, the pattern will play at your current LPB
  - `edit` - a `ZLxx` command will be inserted into the first line of the master track
- `n lines` - becomes available on `edit LPB`, it affects how many lines each beat has
- `BPM mode` select what to do with your pattern's beats-per-minute setting
  - `keep` - no `ZT` command will be written, the pattern will play at your current BPM
  - `edit` - a `ZTxx` command will be inserted into the first line of the master track
  - `calc` - same as `edit` but lets you pick a new BPM based on an integer ratio, useful for metric modulation
- `n beats` - set your desired new BPM value
- ` * x `, `/ y` - these lines will only appear on `calc BPM` mode, they will let you pick values to calculate the new BPM with  the equation `BPM * (x / y)`
- `TPL mode` select what to do with the ticks-per-line setting
  - `keep` - no `ZK` command will be written, the pattern will play at your current TPL
  - `edit` - a `ZKxx` command wil be inserted into the first line of your master track
- `n ticks` - avalaible when `edit TPL` is set, use it to pick the desired TPL
- `n patterns` - select how many new patterns to insert after your current pattern with the settings you have chosen
  - to modify the current pattern, set this to zero. `edit pattern` will appear and no new pattern will be created when pressing `Enter`.

#### odd meters and fractional beats

In case you wanted to use fractional beats (like 3.5 to achieve a 7/8 rhythm while keeping beats as quarter notes), you can hold down `Shift` while stepping the `beats` parameter. This lets you to pick from all proper fractions based on the selected LPB value.

If you want to know what fraction you need to achieve a certain time signature, you can divide your beat value (the denominator in the time signature) by 4, then divide your beats (from the time signature) by the result.

For example to solve for 7/8

```
Quarter = 8 / 4 = 2
Beats = 7 / Quarter = 3.5
```

So you'd pick *3 + 1/2* for `beats`.

Or for 13/16

```
Quarter = 16 / 4 = 4
Beats = 13 / Quarter = 3.25
```

Gets you *3 + 1/4* for `beats`.

Unfortunately, your line highlight in these cases will be disconnected from the actual beats after the first bar. One workaround is to set the *Pattern highlight* in your *Song Options* to the length of your bar or to only use patterns containing a single bar.

You could also just set the number of beats based on the numerator in your time signature (for example 7 for 7/8) but then you'd also need to double your BPM if you wanted to keep quarter notes as 1 beat. Unfortunately the `ZT` command to set the tempo only allows for BPMs up to 255, so if you do this you will not be able to change tempo mid-song and whatever effect you use that relies on BPM will have to be adjusted accordingly.


## glider

> brought to you by [@icasiino](https://www.instagram.com/icasiino)

A pad that generates glide commands (`-Gxx`) that arrive at your note in a desired number of lines. You need to launch it from a note that has a previous note in the pattern and the pad will fill up the sample FX column with the calculated glide commands.

#### parameters

- `lines` - how many lines should the glide take up (between 1 and the length of the note)
- `steps` - how many steps to distribute the necessary glides onto (by default this is the same as `lines`, when lowered, an euclidean pattern will be used for equal distribution)
- `remainder` - often the exact glide value needed is not divisible by the number of lines you select (which is why there is always a `-GFF` inserted at the end of glides), you can choose to `spread` the remainder across steps or `drop` it. The effects of the choice won't be audible in most cases, but `drop` is there if you want the glide to be completely uniform.

### usage

The pad will have different start settings depending on where you are launching it from (you can still change the settings while it's open of course)
* From the exact line of the note you want to glide: it will cover the entire duration of the note
* Further down from inside the note: it will glide until that line


## vim keys for all pads

If you are using vim or just don't like arrows keys, you can also use the `H J K L` (:arrow_left: :arrow_down: :arrow_up: :arrow_right:) keys to navigate, and `X` instead of `Backspace`.

