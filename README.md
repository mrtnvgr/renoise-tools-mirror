# cycler

![](https://forum.renoise.com/uploads/default/original/3X/5/7/5710a18c00617b926dda8bc481667beb51bec752.gif)

A small popup editor that lets you generate regular pattern in the `Pattern Editor` via [cycle](https://renoise.github.io/pattrns/guide/cycles.html) strings and regular [pattrns scripts](https://renoise.github.io/pattrns/index.html).

Provides one key-binding in *Pattern Editor / Tools*

- `Open cycler window`

You can also open the window from the right-click menu of the *Pattern Editor*.

## usage

There are two modes the `cycler` window can be in
* `edit` mode is where you can edit the code and have it render to the pattern
* `select` mode is for navigating the song without closing the window

### edit mode

* the text editor field should be focused
* type in some `cycle` expression, like `<a2 g2 c3> [- <f3 d3 g3>*2], <c3 e3 d3>`
* the pattern will be automatically overwritten
* if there are errors in your code, they will be shown below
* press `escape` to switch to [select mode](#select-mode)

### select mode

* switch between different tracks with the `left` and `right` keys
* select instruments to be used by default for the cycle's output with `up` and `down` (if you specify an instrument in the cycle via `c:#2` that will be kept)
* go to other patterns in the sequence by holding `alt` and pressing `up` and `down`
* you can go back to editing by pressing `enter`
* `escape` will close the window
* keys not listed above will be relayed to Renoise, so you can control other aspects of the song window defocusing the window

### raw script

You can choose between `cycle` and `raw` below the script
* `cycle` is the default generation method, it will essentially paste your text into a Phrase Script like `return cycle("YOUR_TEXT_HERE")`, so that you don't have to type in the wrap around the string, nor the quotes.
* `raw` mode lets you write a regular `Phrase Script`

### vim keys

When in `select` mode, you can use `h j k l` instead of the arrows

### limitations

`cycler` tries to remember your scripts on a per-pattern and per-track basis, but this is implemented in a rudimentary fashion, if you are reordering or adding new tracks or pattern, expect your scripts to me jumbled or even lost.

