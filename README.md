# launch_lanes

[![see demo on youtube](https://img.youtube.com/vi/GdiBloBg2v0/0.jpg)](https://www.youtube.com/watch?v=GdiBloBg2v0)

Schedule launching different patterns in the Pattern Matrix for an Live-inspired jamming workflow.

Works by creating and managing two patterns at the top of your song (your *launch lanes*). You can schedule different track patterns to be aliased and played inside these. Contrary to similar pre-exising (and often outdated) tools, this one aims to avoid reimplementing a clip-matrix style interface for launching and instead relies on the built-in pattern matrix to select pattern.

>Disclaimer: This is a beta version without extensive testing, rough edges remain, not recommended to use in a live-performance setting yet

## actions

- `Play` will play the selected pattern next
- `Stop` will stop any pattern playing on the selected track
- `Solo` will play the selected pattern next while scheduling everything else to stop
- `Step` will step to the next pattern in the song

## usage

### enable lanes

- Open the control panel from *Tools/launch_lanes*
- Toggle lanes by ticking the checkbox in the top-left corner
- You also have keybindings such as
  - *LL - Toggle Lanes*
  - *LL - Open Controls*
- Keep the Pattern Matrix visible to see what you are doing

### built-in keys

If you keep your focus on the control panel you can use the built-in keymaps

- Navigate the pattern matrix with the arrow keys
- Launch the pattern under your cursor using `Space`
- Stop them with `Backspace`
- Solo a pattern using `Enter`
- Alternatively, hold down modifier keys to use different actions with `Space`
- See the `Keymap` tab on the panel for details

The tool also provides shortcuts for these actions to work without having to open or focus the dialog (search for `LL -` in *Edit / Preferences / Keys* to see all available keybindings)

### swap

By default, each action will be scheduled to execute when the current pattern finished playing, but you can use the `Swap` mode to apply any action immediately. 

- While focusing the dialog, hold `Alt` (`Control` on Mac) when pressing an action
- For the assignable keybindings each action has an `Arm` and a `Swap` variant

### rows

Each action can be applied to the entire row of tracks (keybindings are called `Row Arm Play` and so on)

### key-grid

When focusing the dialog you can use your keyboard as a grid controller to launch patterns relative to your cursor without having to navigate. The modifier keys will work the same way. You can see and setup your key characters on the `Keymap` tab. 

By default the keys correspond to a US keyboard and have 4 rows of 9 tracks, each row having a key at the end that will launch the entire row. You can offset the "window" these keys map to by navigating with the arrow keys, your cursor in the matrix will correspond to `1` from below

```
    tracks                rows
s | 1 2 3 4 5 6 7 8 9  |  0
e | Q W E R T Y U I O  |  P
q | A S D F G H J K L  |  ;
  | Z X C V B N M , .  |  /
```

### play controls

This tab allows you to configure how to play patterns

- `Length` allows you to pick a `Fixed` length for your lanes or let it be set `Auto`matically based on any pattern you launch. Patterns that are longer than the current length will be cut while shorter patterns will play in the beginning (the tool uses the built-in pattern aliasing to compose patterns).
- `Mode` sets how to launch new patterns 
  - `Once` will stop after a pattern has been played
  - `Loop` will run continuously
  - `Step` will go to the next pattern in the song after it has played the current one
- `On Gap` lets you customize what the `Step` variant does when it reaches a gap in the matrix
  - `Ignore` will continue playing regardless of what's the next pattern
  - `Jump` will skip gaps and play patterns after the gaps
  - `Stop` will stop playing once it reaches a gap
  - `Wrap` will go back until the first gap above and play from there, this is useful to play *pattern chains* that are longer than your cycle length, all you have to do is surround an island of patterns with gaps
- `Gaps` determine what will count as a gap for a stepping playhead
  - `Empty` - patterns without any notes
  - `Muted` - pattern slots that have been muted (they have `X` symbol over them in the matrix)
  - `Section` - sections in your song will be used as gaps
  - `Automation` - when ticked, patterns that only contain automation will count as gaps

### settings

This tab has general settings for how the tool behaves

- `After` sets what your cursor will do after you executed some action
  - `Keep` will do nothing, your cursor stays where it was
  - `Right` will move your cursor to the next track, this is useful to quickly act on multiple pattern in a row
  - `Last` will move your cursor to whichever direction you stepped last, similar to `Right`, just a bit more quirky
- `Wrap` modes affect your matrix navigation while using the dialog
  - `None` will behave as the built-in navigation, edges of the matrix will stop your cursor
  - `Track` will wrap around the matrix horizontally
  - `Pattern` will do the same vertically
  - `Both` wraps both tracks and patterns
- `Highlight` lets you pick your preferred pattern highlight mode
  - `None` will not make any visible changes
  - `Slot Colors` will apply a white slot color to playing patterns, and a flashing one for armed ones, the downside is that setting slot colors create undo actions in your project, so if you want to launch things while you work on other stuff, your undo will be rather messed up.
  - `Selection` will use the pattern slot selection feature in Renoise to highlight armed and playing tracks, this is a bit hard to see (especially on certain themes) and it will make selecting patterns in the matrix impossible, but it will leave your undo stack alone.