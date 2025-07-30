# Swap Chop

Tool to automate the insertion of volume changes among a pair of adjacent note columns.

The idea is to add a series of volume commands so that the volume of the two columns swaps back and forth.

It works but it's still under development.

## Some explanation

Suppose you have a track with two note columns.  

In the first you have a full-pattern sample playing some colossal beat.

In the second you have *another* colossal, but different, beat.

The goal is to switch between them during the playing of the pattern.

If you did this by hand you would need to go through the pattern lines and set the note coumn value of one to "00" and the note column volume of the other to (say) "70".

Perhaps you want them to swap every 6th line.  Or maybe every 6th but also every 10th line. 

You can do it but it's tedious.

`Swap Chop` automates this volume-setting work.

You get a simple GUI where you set the active volume for each note column.  There is a text field where you can hand-enter a series of line numbers.

There is also a text field where you can enter a simple formula for generating line numbers.

The line numbers always start at zero.  And the first note column is set the active while the second is set to volume zero.

Note that you should not include an commas in your line-number list.

### Auto-generate line numbers


`+ i j k` means line numbers increment by i, then j, then k, then i, then j, etc.


For example: 

`+ 3 5` would give you `3 8 11 16 19 24 ...` up to the number to lines in the current pattern.

 `+ 3 2 5` would give you `3 5 10 13 15 20 23 25  ...` up to the number to lines in the current pattern.


`/ i j k` gives you all the lines evenly divisible by any of i, j, k, etc.

For example: 

`/ 3 5` would give you `3 5 6 9 10 12 15 18 20 21 ...` up to the number to lines in the current pattern.

`/ 6` would give you `6 12 18 24 30 ...` up to the number to lines in the current pattern.



You should be able to use any number of integers with either of those commands.

** Note that you should not include an commas in your line-generating function. **

Each time you run a line-generation function the generated numbers are *added* to the current list. 

This allows you to construct a more complex sequence my combining different line-generation functions.

There is a `clear` button to clear the current list; you can also hand-edit that list to fine-tune the values.

You must click the `Go` button in order to apply the results.


** Note: Be mindful of what note column you have selected **

The tool operates on the currently selected note column and the column to the right.  It makes no effort to handle hidden columns.

If the results seem odd check to see what column you've selected.

(OTOH you may want to exploit this quirk to get novel results.)
