# Track-pattern Comments


## A tool to associate comments with a custom fx entries.

Big thanks to Renoise hacker [fladd](https://www.renoise.com/user/93), whose [Track Comments](https://www.renoise.com/tools/track-comments) inspired this.

This code was written by going through the Track Comments code and pilfering stuff.  I then added cool things.

It's beta.  Don't bet the farm on it.

## What it does

The tool adds a right-click menu item to the track-pattern menu.  When selected, it looks to see if the current track pattern contains, someplace, a special fx entry.  Such entries are of the form `NGxx` where `xx` is a hex value from 00 to FF.

That `xx` value is keyed to a comment stored within the song comments.

If an existing comment marker is found an edit box comes for reading/editing.

If no existing marker is found then an empty edit box comes up so you can add a new comment. In that case a new comment marker is added on the current line.

The code assumes one comment marker per track pattern.  

## Known issues/quirks

Nothing in place for deleting comments.  That will be added.  You can delete a comment marker but the comment remains in the data stored in the song comments.

You can cut and paste fx columns values, so the same comment marker can be in more than one place, and you can manage to get multiple comments into  a single track pattern. The code currently looks for the closest marker so you can exploit this, but there's no current way to just add more comment markers to a track pattern if one already exists.



