# Fast Operations

The original fibu program had an elaborate shell, jrl-editor to add new lines. Whilst this was overall satisfactory,
the need arose to enter repeatedly the same type of transactions, to ease the input of that sort of transactions, the fast operations
were implemented.

The idea is to prepare some jrl lines with placeholders (preceded with a '#'), whilst those placeholders are free form and interpreted as strings in the 
descriptions, if those placeholders are encountered in the valuta field, they are interpreted as variable names, and stored globally for the given transaction.

If, in the valuta field, the variables are englobed in '()', they are supposed to be an expression to be evaled at run time.

> BEWARE: keep in mind that this is a one pass system, please be sure to have 'initialized' the variables, before using them.....


## CSV definition format, under the OPS section in the csv file

1. the first column defines the fast-op name
2. second column, we could define a fixed date (or TODO, a date periodicity, to be implemented later)
3. third column, the account to retrieve from, can be a range a fixed number or empty
4. fourth column, the account to credit to, can be a range a fixed number or empty
5. fith column, the description of the transaction
6. sixt column, the currency of the valuta, EUR by default
7. seventh column, the valuta, the amount to be exchanged
8. eigth column,fiers (TODO: multi etc to be implemented)

## Example 

Consider the following example:

``` csv
"COURSES","","1000-1003", "1999",  "Courses #lieu", "","#payement", ""
"COURSES","","1999",      "2011",  "Vêtements achetés chez Auchan", "", "", ""
"COURSES","","1999",      "3080",  "Couches bébé ", "", "#couches",""
"COURSES","","1999",      "3080",  "Divers bébé (#objet)", "", "#divers",""
"COURSES","","1999",      "3011",  "Bouffe achetée chez Auchan EUR (#payement - #montant - #couches - #divers)", "", "(#payement - #montant - #couches - #divers)",""
```

The first column tells us that all those lines pertain to the fast-op 'COURSES', no date give, thus by default, now. In the first line we see that
an account range was specified as retrieval account, this means that when running the fastop, the program will display the list of acceptable accounts
and ask for the user choice, by default the first account of the selection is preselected, just hitting enter will validate the default.

Then we can note the '#lieu' in the description, to allow us to specify wher ewe are making our purchases. and finally in valuta we have the 'variable' '#payment' where the app
will store the total amount payed.

If we consider the last line, we see that the valuta contains an expression '()'-enclosed, thus the program will automaticly eval that expression with the previously retrieved 
values.

To note, that after completing the fill-in of those lines, the resulting journal will hide the lines where the amount is 0, ask for confirmation of those lines, i
and if affermative, add them to the journal.


