XALib - eXtract from Array Library

A simple library to extract data from an array. Using the library will allow the develop to set the filter/order/field-selection criteria to be used. Currently the filter & order & selection are defined by a series of function/handler calls; maybe in future there might be a simple query/expression language.

The filter can then be run, producing an unordered set of keys which match. The order-function  then be run to make these be an ordered set.

Note that the great majority of the time, it is unnecessary extra work to extract an array containing only the desired entires, or only the desired fields within those entries - the developer can and should simply work with the ordered set of keys for the initial array.

However, there will be cases where it is useful to create this extracted array, and there is therefore a handler to do this, creating a new array by copying only the required fields from only the entries with matching keys.

Therefore a ‘query’ - either the one being defined or a named one- can have either or both a filter command set and/or an ordering command set.

For compatibility wit DBLib, it is possible to use the query being defined, and that is reset when used (or named). However, I recommend using named queries.

The basic handlers will therefore be something like

# Filtering

xaWhere key, value, [operator]

xaOpenParen
xaCloseParen

# Ordering

xaOrderBy key, [asc | desc], [numeric]


# Naming

xaNameQuery name



xaQuery ( array, [namedquery], [keys] )
        —-> list of matching keys, one per line, possibly ordered


# Extraction

xaCopy( array,  matchedkeys,  ListOfFieldKeys)
           —-> array with the specified fields from only those entries


Note there can be multiple xaWhere calls, and multiple xaOrderBy calls. The [multiple] xaWhere criteria are built into a command table which is used to run the filter part of the query. The [multiple] orderby commands are built into an ‘order’ table and will be executed in sequence - to allow one to take advantage of LC’s stable sort.

Thus, e.g.
Author=‘Asimov’ AND ( title contains ‘robot’ OR title contains ‘foundation’)

xaWhere “author”, “Asimov”    — operator defaults to ‘=‘
xaOpenParen                            — switches from the initial default of ‘AND’ to OR’
xaWhere “title”, “robot”, “contains”
xaWhere “title”, “foundation”, “contains”
xaCloseParen

xaOrderBy “price”

xaNameQuery “somenewname”


— and then we can use this new query

put xaQuery(sABooks, “somenewname”) into tSomeBooks
   - this uses the defined ‘where’ and ‘orderby’ criteria

— we could now just use this
repeat for each line K in tSomeBooks
   put sABooks[K][“title”] && “was written by” && sABooks[K][“author”] after msg
end repeat

— or we could extract just the desired fields of the selected entries
put “author,Title” into tFields
put xaCopy(sABooks, tSomeBooks, tFields) into tASome
  — this uses the current ‘select’ criteria, and then resets it

— and then use this smaller array in the same way
 —  and the smaller array will remain, even if we subsequently change the main data array !!)
repeat for each line K in the keys of tASome
   put tASome[K][“title”] && “was written by” && tASome[K][“author”] after msg
end repeat

Note that it will often be unnecessary to copy (i.e. actually extract) the entires in the array - very often you will simply generate the list of keys; i.e.  xaCopy is there only to satisfy fairly uncommon needs).



# Named Criteria (internal)

(need to figure out how to build it up effectively !!)

Is an array, with 2 keys - filter, sort

‘filter’ is a text value, with a number of lines, each has
  type - one of (, ), operators….

if type = ‘(‘
    concat = and or or
    matching close paren index

if type = “)”
   matching open paren
   next if true
   next of false

if type = anything else, i.e. an operator
   field = file name
   value = value
   next if true
   next if false

‘sort’ is a text value having a number of lines, each in order  being the key/direction/type


