# value_stepper

![](https://forum.renoise.com/uploads/default/original/2X/c/c04753c1b55335beff4385310ef9e124181b9335.gif)  

Adjust values via keyboard by a set amount. Similar to the *Transpose One Note Up* inside Renoise but works for other values as well such as instrument number, volume, panning, delay and effect parameters.

Provides four key-bindings in *Pattern Editor / Column Operations*:

- Step value up
- Step value down
- Step value up (by 16)
- Step value down (by 16)

The default step size is 1 but you can change it in *Tools / value stepper*

The same keys bindings are provided in *Phrase Editor / Column Operations*

Note: the greater stepping on notes is done by octaves instead of 16.

### settings

- **step size** (default is 1)
- **ignore edit mode** (enabling this will make stepping work even if you aren't in edit mode)
- **select instrument with step** (when changing instrument numbers also select the instrument)
- **auto-blank** (a panning value of `40` (centered) and a volume value of `80` (max volume) gets converted to an empty column (technically `FF`) to have a cleaner pattern)
- **relative mode** (see below)
- **repeat last** (starts relative stepping from last value as opposed to last + offset)

### block selection

When selecting multiple columns and lines, you need to place your cursor inside the selection on the column you want to step. You can only block-step columns of the same type at once. (this extends to the type of commands inside FX columns as well, for example when you place your cursor on a `-Sxx` command only other `-Sxx` commands will get stepped inside your selection)

Inside the settings you can find different modes that control how block stepping is done.

- **step non-empty values** (all selected columns that have other than the default value will get stepped, this mode pairs well with disabling the **auto-blank** setting)
- **step values with notes** (only steps empty columns if they have a note)
- **step all values** (steps everything inside the selection)

### relative mode

![](https://forum.renoise.com/uploads/default/original/2X/5/555c60c894e06ae0f5330e1ab0deb1ab5090f353.gif)

There is an optional **relative mode** that can be enabled in the settings window. It starts stepping empty columns from the nearest non-empty value inside the pattern (searching backwards). Good for writing melodies and creating continuous effect lines.

A keybinding exist for toggling relative mode in "Pattern Editor / Tools" called :
  - Toggle relative mode (value stepper)

