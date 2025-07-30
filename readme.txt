---------------------------------------------------------------------------------------------------------
-- ReNoam
-- (c) 2012 Ralf Kibiger | f+d+k (fdk@kibiger.com)
-- Creation Date: 2012-01-01
-- Last modified: 2012-01-18
---------------------------------------------------------------------------------------------------------


Short instructions on how to use ReNoam v0.8

-------------------------------------------------------------
GUI:
-------------------------------------------------------------

The big text area is where you will edit your grammar.
	When you start the tool for the first time, there is a small example grammar
	(along with a short blurp by me).

The buttons below the grammar area:
Generate:
	This will parse your input, constructing the grammar object for the tool.
	Next it will generate a sequence of numbers by using the given grammar.
	Those numbers will be used to append corresponding patterns in the pattern
	sequencer/pattern matrix.
Save:
	Saves your input in a text file.
Load:
	Loads a grammar from a text file.
Close:
	If you use this button to close the tool, the text in the text area is stored
	in the preferences, and will be restored at next start.


-------------------------------------------------------------
Basic usage recipe:
-------------------------------------------------------------

+ Create some nice unique patterns and sort them.
+ Start ReNoam
+ Write or load a grammar
+ Hit the generate button

If you don't like the outcome, focus renoise, undo, and try again.

-------------------------------------------------------------
On grammars:
-------------------------------------------------------------
In v0.8 there are two grammar types supported:
ReNoamGrammarType = cfg
or
ReNoamGrammarType = pcfg

-------------------------------------------------------------
Quirks, Bugs, etc.:
-------------------------------------------------------------

RIGHT NOW, YOU HAVE TO MAKE SURE YOUR GRAMMAR IS OK!

E.g. for every symbol appearing on the right hand side of some rule,
there has to be at least one rule with this symbol on the left hand side.
(Except the symbol is a valid number, which makes it a terminal symbol.)

If you use recursion (e.g. A -> A B) - and you probably do - make sure there
won't be infinite loops without some alternative rule to bail out (e.g. A -> 5)


Basic grammar checking will come soon.





Ralf Kibiger | f+d+k (fdk@kibiger.com)
2012-01-18




















