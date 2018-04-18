script "xaLib"

-- XALib - eXtract from Array Library

constant KxaVersion = 0.1

function xaVersion
   return KxaVersion
end xaVersion

local sACurrentQuery, sCurrentConcat
local sANamedQueries

private command _xaReset
   -- resets the current query. Happpens implicitly after an anonymous query is executed.
   put empty into sACurrentQuery
end _xaReset

command xaNameQuery pName
   -- store the query currently being built, with name pName
   if sACurrentQuery is empty then
      return "attempt to name query when none exists"  & pName for error
   end if
   _xaComplete
   put sACurrentQuery into sANamedQueries[pName]
   _xaReset
end xaNameQuery

command xaWhere pKey, pVal, pOperator
   -- define the next test clause in the query filter
   -- pKey - the firld of the array to be checked
   -- pVal - the value to be used
   -- pOperator (optional) - operator to use, default to "="
   local tA
   put pKey into tA["field"]
   if pOperator is empty then put "=" into pOperator
   if pOperator is among the items of "<,<=,=,>=,>,<>,contains" then
      put pOperator into tA["type"]
   else
      return "bad operator" & pOperator for error
   end if
   put pVal into tA["value"]
   
   put empty into tA[true]
   put empty into tA[false]
   
   local t
   put the number of lines in the keys of sACurrentQuery["filter"] into t
   add 1 to t
   
   if t = 1 then put "AND" into sCurrentConcat
   
   if sCurrentConcat = "AND" then
      put t+1 into tA[true]
      put -2 into tA[false]  -- i.e. go to end of this clause with a 'fail'
   else
      put -1 into tA[true]  -- i.e. go to end of this clause with a 'suceed'
      put t+1 into tA[false]
   end if
   put tA into sACurrentQuery["filter"][t]
end xaWhere

command xaOpenParen
   -- open a parenthetical clause
   -- NB expressions are *FULLY* parenthesised, the top-levels clauses being ANDed
   --        so each level of parens switches between AND and OR 
   -- TODO - NOT ??
   local t, tA
   put the number of lines in the keys of sACurrentQuery["filter"] into t
   add 1 to t
   
   put "(" into tA["type"]
   put t+1 into tA[true]
   put t+1 into tA[false]
   
   if sCurrentConcat = "OR" then
      put "AND" into sCurrentConcat
   else
      put "OR" into sCurrentConcat
   end if
   put empty into tA["match"]
   
   put tA into sACurrentQuery["filter"][t]
   
end xaOpenParen

command xaOrderBy pKey, pDir, pType
   -- define the next test clause in the order sequence
   put pKey & COMMA & pDir & COMMA & pType &CR after sACurrentQuery["order"]
end xaOrderBy


command xaCloseParen
   local t, tA
   put the number of lines in the keys of sACurrentQuery["filter"] into t
   add 1 to t
   
   put ")" into tA["type"]
   
   if sCurrentConcat = "OR" then
      put "AND" into sCurrentConcat
   else
      put "OR" into sCurrentConcat
   end if
   
   -- and now it is like any other clause
   if sCurrentConcat = "AND" then
      put t+1 into tA[true]
      put -2 into tA[false]  -- i.e. go to end of this clause with a 'fail'
   else
      put -1 into tA[true]  -- i.e. go to end of this clause with a 'succeed'
      put t+1 into tA[false]
   end if
   put tA into sACurrentQuery["filter"][t]
   
   -- and scan backwards to find matching openparen
   repeat with i = t-1 to 1 step -1
      if sACurrentQuery["filter"][i]["type"] = "(" AND sACurrentQuery["filter"][i]["match"] is empty then
         put t into sACurrentQuery["filter"][i]["match"]
         put 1 into sACurrentQuery["filter"][t]["match"]
         
         -- and fill in all 'complete' values
         repeat with j = i to t-1
            if sACurrentQuery["filter"][j][true] = -1 then put t into sACurrentQuery["filter"][j][true]
            if sACurrentQuery["filter"][j][false] = -2 then put t into sACurrentQuery["filter"][j][false]
         end repeat
         
         exit repeat
      end if
   end repeat
   if sACurrentQuery["filter"][t]["match"] = 0 then
      return "Unmatching parens - too many closes", sACurrentQuery for error
   end if
end xaCloseParen

function xaQuery pArray, pNamedQuery, pKeyList
   -- pArray - the array to be "filtered"
   -- pNamedQuery (optiona)  name of a previously save query to use, else use the current one
   -- pKeyList - list of keys which are to be searched (otherwise the whole array)
   local tAQo, tAQf
   if pNamedQuery is empty then
      -- finalize and use the current query
      _xaComplete
      put sACurrentQuery["filter"] into tAQf
      put sACurrentQuery["order"] into tAQo
   else
      put sANamedQueries[pNamedQuery]["filter"] into tAQf
      put sANamedQueries[pNamedQuery]["order"] into tAQo
   end if
   
   local tTrueFalse, tIndex, tMax, toDo
   
   local tNextIndex, tNewKeys, tKeys,  tAQL
   
   put empty into tNewKeys
   if pKeyList is empty then
      put the keys of pArray into tKeys
   else
      put pKeyList into tKeys
   end if
   
   if tAQf is not empty then
      repeat for each line K in tKeys
         put FALSE into tTrueFalse
         put 1 into tIndex
         put the number of lines in the keys of tAQf into tMax
         
         repeat  forever -- while tIndex <= tMax, but should never happen
            put tAQf[tIndex] into tAQL
            switch tAQL["type"]
               case "("
               case ")"
                  -- fall through - use the existing value for tTrueFalse
                  break
               case "<"
                  put ( pArray[K][tAQL["field"]] <    tAQL["value"]  ) into tTrueFalse
                  break
               case "<="
                  put ( pArray[K][tAQL["field"]] <=    tAQL["value"]  ) into tTrueFalse
                  break
               case "="
                  put ( pArray[K][tAQL["field"]] =   tAQL["value"]  ) into tTrueFalse
                  break
               case "=>"
                  put ( pArray[K][tAQL["field"]]  >=    tAQL["value"]  ) into tTrueFalse
                  break
               case ">"
                  put ( pArray[K][tAQL["field"]] >    tAQL["value"]  ) into tTrueFalse
                  break
               case "<>"
                  put ( pArray[K][tAQL["field"]] <>    tAQL["value"]  ) into tTrueFalse
                  break
                  
               case "contains"
                  put ( pArray[K][tAQL["field"]] contains   tAQL["value"]  ) into tTrueFalse
                  break
                  
               default
                  return "bad operator" for error
                  break
            end switch
            put tAQL[tTrueFalse]  into tNextIndex
            
            if tNextIndex < 0 then
               if tNextIndex = -1 then
                  put K &CR after tNewKeys
               end if
               exit repeat
            end if
            put tNextIndex into tIndex
         end repeat
         
      end repeat
   else
      put tKeys into tNewKeys
   end if
   
   -- TODO put in the ordering !!!
   if tAQo is not empty then
      repeat for each line L in tAQo
         put "sort lines of tNewKeys" && item 2 of L && item 3 of L & \
               " by pArray[each][" & quote & item 1 of L & quote & "]" into toDo
         do toDo
      end repeat
   end if
   
   if pNamedQuery is empty then
      _xaReset
   end if
   return tNewKeys
   
end xaQuery

private command _xaComplete
   -- finish off a query 
   --  ensure there were enough close parens
   -- change the last line to be a succeed (i.e. defaulted to AND at top level)
   local t
   put the number of lines in the keys of sACurrentQuery["filter"] into t
   put -1 into sACurrentQuery["filter"][t][true]
end _xaComplete

