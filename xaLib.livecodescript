script "xaLib"

-- XALib - eXtract from Array Library

constant KxaVersion = 0.2

function xaVersion
   return KxaVersion
end xaVersion

local sACurrentQuery, sCurrentConcat, sNextConcat, sCurrentValueCount
local sANamedQueries

-- make available for external use - mainly for development purposes where
--   we can exit the debuggger part-way through defining a query
command xaReset  
   -- resets the current query. Happpens implicitly after an anonymous query is executed.
   put empty into sACurrentQuery
   put empty into sNextConcat
   put empty into sCurrentConcat
end xaReset

command xaNameQuery pName
   -- store the query currently being built, with name pName
   if sACurrentQuery is empty then
      return "attempt to name query when none exists"  & pName for error
   end if
   _xaComplete
   put sACurrentQuery into sANamedQueries[pName]
   xaReset
end xaNameQuery

command xaWhere pKey, pVal, pOperator
   -- define the next test clause in the query filter
   -- pKey - the firld of the array to be checked
   -- pVal - the value to be used
   -- pOperator (optional) - operator to use, default to "="
   
   if pOperator is empty then put "=" into pOperator
   if pOperator is among the items of "<,<=,=,>=,>,<>,contains" then
      -- nothing needs done
   else
      return "bad operator" & pOperator for error
   end if
   
   if sACurrentQuery["filter"] is empty then
      put 1 into sCurrentValueCount
      -- BEWARE - built-in assumption about the names (tKeys) used in xaQuery
      
      put "repeat for each line K in tKeys" &CR & "if " into sACurrentQuery["filter"]
   end if
   if sCurrentConcat is empty then
      if sNextConcat is empty then
         put "AND" into sCurrentConcat
      else
         put sNextConcat into sCurrentConcat
      end if
   else
      put " " & sCurrentConcat & " " after sACurrentQuery["filter"]
   end if
   
   put pVal into sACurrentQuery["values"][sCurrentValueCount]
   put "pA[K]['" & pKey  & "']" && pOperator && "tt" & sCurrentValueCount after sACurrentQuery["filter"]
   add 1 to sCurrentValueCount
   
end xaWhere

command xaOpenParen
   -- open a parenthetical clause
   -- NB expressions are *FULLY* parenthesised, the top-levels clauses being ANDed
   --        so each level of parens switches between AND and OR 
   -- TODO - NOT ??
   local t, tA
   if  sACurrentQuery["filter"] is empty then
      put 1 into sCurrentValueCount
      -- BEWARE - built-in assumption about the names ( tKeys ) used in xaQuery
      put "repeat for each line K in tKeys" &CR & "if " into sACurrentQuery["filter"]
   end if
   put " " & sCurrentConcat & " ( " after sACurrentQuery["filter"]
   
   if sCurrentConcat = "OR" then
      put "AND" into sNextConcat
   else
      put "OR" into sNextConcat
   end if
   put empty into sCurrentConcat
end xaOpenParen

command xaOrderBy pKey, pDir, pType
   -- define the next test clause in the order sequence
   
   -- BEWARE - built-in assumption about the names (pA, tNewkeys ) used in xaQuery
   put "sort lines of tNewKeys" && pDir && pType & \
         " by pA[each][" & quote & pKey & quote & "]" &CR after sACurrentQuery["order"]
end xaOrderBy

command xaCloseParen
   put " )" after sACurrentQuery["filter"]
   
   if sCurrentConcat = "OR" then
      put "AND" into sCurrentConcat
   else
      put "OR" into sCurrentConcat
   end if
   
end xaCloseParen

function xaQuery pA, pNamedQuery, pKeyList
   -- pArray - the array to be "filtered"
   -- pNamedQuery (optiona)  name of a previously save query to use, else use the current one
   -- pKeyList - list of keys which are to be searched (otherwise the whole array)
   local tAQo, tAQf, tAQv
   
   if pNamedQuery is empty then
      -- finalize and use the current query
      _xaComplete
      put sACurrentQuery["filter"] into tAQf
      put sACurrentQuery["order"] into tAQo
      put sACurrentQuery["values"] into tAQv
      xaReset
   else
      put sANamedQueries[pNamedQuery]["filter"] into tAQf
      put sANamedQueries[pNamedQuery]["order"] into tAQo
      put sANamedQueries[pNamedQuery]["values"] into tAQv
   end if
   
   local toDo
   local tt1,tt2,tt3,tt4,tt5,tt6,tt7,tt8,tt9,tt10
   local tNewKeys, tKeys
   
   put empty into tNewKeys
   if pKeyList is empty then
      put the keys of pA into tKeys
   else
      put pKeyList into tKeys
   end if
   
   if tAQf is not empty then
      repeat for each key K in tAQv
         do "put tAQv[K] into tt" &K
      end repeat
      
      do tAQf
   else
      put tKeys into tNewKeys
   end if
   
   repeat for each line L in tAQo
      do L
   end repeat
   
   return tNewKeys
   
end xaQuery

function xaCopy pArray, pKeys, pFields
   -- return a copy the subset of the array, with a key in pKeys, and the fields in pFields
   local tAReturn
   
   if pFields is empty then -- faster to copy whole entry
      repeat for each key K in pKeys
         put pArray[K] into tAReturn[K]
      end repeat
   else
      repeat for each key K in pKeys
         repeat for each key F in pArray[K]
            put pArray[K][F] into tAReturn[K][F]
         end repeat
      end repeat
   end if
   return tAReturn
end xaCopy

private command _xaComplete
   -- finish off a query 
   -- TODO  ensure there were enough close parens
   
   -- BEWARE - built-in assumption about the names (pA, tKeys, tNewkeys ) used in xaQuery
   put " then put K & CR after tNewKeys" & CR &\
         "end repeat" after sACurrentQuery["filter"]
   replace "'" with quote in sACurrentQuery["filter"]
end _xaComplete
