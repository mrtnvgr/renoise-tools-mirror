--[[ *** Simple Mathematical Functions *** ]]--

-- Simple Value Functions

parser:set_math_func ("rand", function (eval)
   if (#eval.ctx.args == 0) then
      return math.random ()
   elseif (#eval.ctx.args == 1) then
      return math.random (0, eval.ctx.args[1])
   else
      return math.random (eval.ctx.args[1], eval.ctx.args[2])
   end
end)

parser:set_math_func (
   "abs", function (eval) return math.abs (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "ceil", function (eval) return math.ceil (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "floor", function (eval) return math.floor (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "round", function (eval) return math.floor (eval.ctx.args[1] + 0.5) end, false, 1)
parser:set_math_func (
   "rad2deg", function (eval) return math.deg (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "deg2rad", function (eval) return math.rad (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "max", function (eval)
      local m
      for _, v in ipairs(eval.ctx.args) do
         if (m == nil or m < v) then
            m = v
         end
      end
      if (m == nil) then
         m = 0
      end
      return m
   end)
parser:set_math_func (
   "min", function (eval)
      local m = nil
      for _, v in ipairs(eval.ctx.args) do
         if (m == nil or m > v) then
            m = v
         end
      end
      if (m == nil) then
         m = 0
      end
      return m
   end)

-- Trigonometric Functions
parser:set_math_func (
   "cos", function (eval) return math.cos (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "acos", function (eval) return math.acos (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "cosh", function (eval) return math.cosh (eval.ctx.args[1]) end, false, 1)

parser:set_math_func (
   "sin", function (eval) return math.sin (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "asin", function (eval) return math.asin (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "sinh", function (eval) return math.sinh (eval.ctx.args[1]) end, false, 1)

parser:set_math_func (
   "tan", function (eval) return math.tan (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "atan", function (eval) return math.atan (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "atan2", function (eval) return math.atan2 (eval.ctx.args[1], eval.ctx.args[1]) end, false, 2)
parser:set_math_func (
   "tanh", function (eval) return math.tanh (eval.ctx.args[1]) end, false, 1)

-- Interpolation Functions

parser:set_math_func (
   "clip", function (eval)
      local a = eval.ctx.args[1]
      local b = eval.ctx.args[2]
      local x = eval.ctx.args[3]
      if (b < a) then
         b, a = a, b
      end
      if (x < a) then
         x = a
      elseif (x > b) then
         x = b
      end
      return x
   end, false, 3)

parser:set_math_func (
   "wrap", function (eval)
      local a = eval.ctx.args[1]
      local b = eval.ctx.args[2]
      local x = eval.ctx.args[3]
      if (b < a) then
         b, a = a, b
      end
      local diff = b - a
      if (diff == 0) then
         return 0
      end
      local last -- just a small safety for float math, possibly not neccessary
      while (last ~= x and x < a) do
         last = x
         x = x + diff
      end
      last = nil
      while (last ~= x and x >= b) do
         last = x
         x = x - diff
      end
      return x
   end, false, 3)

parser:set_math_func (
   "map1", function (eval)
      local a = eval.ctx.args[1]
      local b = eval.ctx.args[2]
      local x = eval.ctx.args[3]
      if (b < a) then
         b, a = a, b
      end
      if (x < a) then
         x = a
      elseif (x > b) then
         x = b
      end
      if ((b - a) == 0) then
         return 0
      end
      return ((x - a) / (b - a))
   end, false, 3)


parser:set_math_func (
   "lerp", function (eval)
      local x = eval.ctx.args[3]
      if (x < 0) then
         x = 0
      elseif (x > 1) then
         x = 1
      end
      return (eval.ctx.args[1] * (1 - x) + eval.ctx.args[2] * x)
   end, false, 3)

parser:set_math_func (
   "cerp", function (eval)
      local x = eval.ctx.args[3];
      x = (1 - math.cos (x * math.pi)) / 2
      return (eval.ctx.args[1] * (1 - x) + eval.ctx.args[2] * x)
   end, false, 3)

-- More Math Functions

parser:set_math_func (
   "sqrt", function (eval) return math.sqrt (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "pow", function (eval) return math.pow (eval.ctx.args[1], eval.ctx.args[2]) end, false, 2)
parser:set_math_func (
   "exp", function (eval) return math.exp (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "log", function (eval) return math.log (eval.ctx.args[1]) end, false, 1)

-- Renoise Specific Functions

parser:set_math_func (
   "lin2db", function (eval) return math.lin2db (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "db2lin", function (eval) return math.db2lin (eval.ctx.args[1]) end, false, 1)
parser:set_math_func (
   "db2fader", function (eval) return math.db2fader (eval.ctx.args[1], eval.ctx.args[2], eval.ctx.args[3]) end, false, 3)
parser:set_math_func (
   "fader2db", function (eval) return math.fader2db (eval.ctx.args[1], eval.ctx.args[2], eval.ctx.args[3]) end, false, 3)

--[[ *** Dump/Debug Functions *** ]]--

parser:set_math_func ("show", function (eval)
   local str = ""
   local last = 0
   local name
   for i, a in ipairs (eval.ctx.args) do
      if (i == 1) then
         name = a
      else
         str = str .. " " .. a
         last = a
      end
   end
   eval:log ("show(" .. name .. ") =" .. str)
   return last
end, true)

parser:set_math_func ("showhex", function (eval)
   local str = ""
   local last = 0
   local name
   for i, a in ipairs (eval.ctx.args) do
      if (i == 1) then
         name = a
      else
         str = str .. " " .. string.format ("%X", a)
         last = a
      end
   end
   eval:log ("showhex(" .. name .. ") =" .. str)
   return last
end, true)

--[[ *** Conversion Functions *** ]]--

parser:set_math_func ("note2num", function (eval)
   return note2num (eval.ctx.args[1])
end, true, 1)

parser:set_math_func ("fx2num", function (eval)
   local chrs = eval.ctx.args[1]
   local val = 0
   for i = 1, chrs:len (), 1 do
      val = bit.lshift (val, 8)
      val = val + (FXCHR2NUM[chrs:sub(i, i)] - 1)
   end
   return val
end, true, 1)

--[[ *** Column Access Functions *** ]]--

function line_col_access_input (eval)
   local col       = eval.ctx.args[1] + 1
   local new_value = eval.ctx.local_vars["V"]
   local line      = eval.ctx.line
   if (eval.ctx.args[2] ~= nil) then
      local offs = 0
      if (eval.ctx.args[3] ~= nil) then
         offs = eval.ctx.args[3]
      end
      line = eval.ctx.coll:get_track_line (
               eval.ctx.args[2] + 1,
               eval.ctx.vars["I"] + 1 + offs)
   end
   return col, new_value, line
end

parser:set_math_func ("instr", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:note_col (col, 2)
   if (new_value ~= nil) then
      new_value = wrap_to_range (0, 255, new_value)
      line:note_col (col, 2, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("dly", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:note_col (col, 5)
   if (new_value ~= nil) then
      new_value = wrap_to_range (0, 255, new_value)
      line:note_col (col, 5, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("pan", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:note_col (col, 4)
   if (new_value ~= nil) then
      line:note_col (col, 4, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("vol", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:note_col (col, 3)
   if (new_value ~= nil) then
      line:note_col (col, 3, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("note", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:note_col (col, 1)
   if (new_value ~= nil) then
      new_value = wrap_to_range (0, 121, new_value)
      line:note_col (col, 1, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("fx", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:fx_col (col, 1)
   if (new_value ~= nil) then
      line:fx_col (col, 1, new_value)
      val = new_value
   end
   return val
end, false, -1)

parser:set_math_func ("amt", function (eval)
   local col, new_value, line = line_col_access_input (eval)

   local val = line:fx_col (col, 2)
   if (new_value ~= nil) then
      line:fx_col (col, 2, new_value)
      val = new_value
   end
   return val
end, false, -1)

--[[ *** Special Functions *** ]]--

parser:set_math_func (
   "clip_track", function (eval)
      local trk = get_clip_track_idx (eval.ctx.args[1])
      if (trk == nil) then
         eval:err ("Error: Can't find clip '" .. eval.ctx.args[1] .. "'")
      end
      return trk - 1
   end, true)

parser:set_math_func (
   "track", function (eval)
      local trk = get_track_idx_by_name (eval.ctx.args[1])
      if (trk == nil) then
         eval:err ("Error: Can't find track '" .. eval.ctx.args[1] .. "'")
      end
      return trk - 1
   end, true)

parser:set_math_func (
   "sym2num", function (eval)
      return eval:symbol2num (eval.ctx.args[1])
   end, true)

parser:set_math_func (
   "sym_cat", function (eval)
      local concat = ""
      for _, a in ipairs (eval.ctx.args) do
         concat = concat .. a
      end
      return eval:symbol2num (concat)
   end, true, 0)

parser:set_math_func (
   "sym_cat_space", function (eval)
      local concat = ""
      if (#eval.ctx.args == 1) then
         concat = eval.ctx.args[1] .. " "
      else
         for _, a in ipairs (eval.ctx.args) do
            if (concat == "") then
               concat = concat .. a
            else
               concat = concat .. " " .. a
            end
         end
      end
      return eval:symbol2num (concat)
   end, true, 0)

parser:set_math_func (
   "sym_cat_num", function (eval)
      return eval:symbol2num (eval.ctx.args[1] .. eval.ctx.args[2])
   end, true, 2)

--[[ *** Vector/Data Structure Functions *** ]]--

parser:set_math_func ("vector_init", function (eval)
   local v = { }
   eval.ctx.vectors[eval.ctx.args[1]] = v

   local last = 0
   for i = 2, #eval.ctx.args do
      v[i - 1] = eval.ctx.args[i]
      last = v[i - 1]
   end

   return last
end, true, -1)

parser:set_math_func ("vector", function (eval)
   local v = eval.ctx.vectors[eval.ctx.args[1]]
   if (v == nil) then
      v = { }
      eval.ctx.vectors[eval.ctx.args[1]] = v
   end

   local idx = eval.ctx.args[2]
   local new_value = eval.ctx.local_vars["V"]
   if (new_value ~= nil) then
      v[idx + 1] = new_value
   end

   local r = v[idx + 1]
   if (r == nil) then
      r = 0
   end

   return r
end, true, 2)

parser:set_math_func ("list_init", function (eval)
   local v = { }
   eval.ctx.lists[eval.ctx.args[1]] = v

   local last = 0
   for i = 2, #eval.ctx.args do
      v[i - 1] = eval.ctx.args[i]
      last = v[i - 1]
   end

   return last
end, true, -1)

parser:set_math_func ("list_push", function (eval)
   local l = eval.ctx.lists[eval.ctx.args[1]]
   if (l == nil) then
      l = { }
      eval.ctx.lists[eval.ctx.args[1]] = l
   end
   local val = eval.ctx.args[2]
   table.insert (l, val)
   return val
end, true, 2)

parser:set_math_func ("list_unshift", function (eval)
   local l = eval.ctx.lists[eval.ctx.args[1]]
   if (l == nil) then
      l = { }
      eval.ctx.lists[eval.ctx.args[1]] = l
   end
   local val = eval.ctx.args[2]
   table.insert (l, 1, val)
   return val
end, true, 2)

parser:set_math_func ("list_pop", function (eval)
   local l = eval.ctx.lists[eval.ctx.args[1]]
   if (l == nil) then
      return 0
   end
   local val = table.remove (l)
   if (val == nil) then
      return 0
   end
   return val
end, true, 1)

parser:set_math_func ("list_is_empty", function (eval)
   local l = eval.ctx.lists[eval.ctx.args[1]]
   if (l == nil) then
      return 1
   end
   if (#l > 0) then
      return 0
   else
      return 1
   end
end, true, 1)

parser:set_math_func ("list_shift", function (eval)
   local l = eval.ctx.lists[eval.ctx.args[1]]
   if (l == nil) then
      return 0
   end
   local val = table.remove (l, 1)
   if (val == nil) then
      return 0
   end
   return val
end, true, 1)

--[[ *** Indirect Call Functions *** ]]--

parser:set_math_func ("call", function (eval)
   local nargs = { }
   if (#eval.ctx.args > 1) then
      for i = 2, #eval.ctx.args do
         table.insert (nargs, eval.ctx.args[i])
      end
   end
   local r = eval:mcall (eval.ctx.args[1], nargs, eval.ctx.local_vars["V"])
   return r
end, true)


--[[ *** Support/Parser Code *** ]]--

function parser:p_math_func (id)
   self:expect ("%(", "'('")
   local args = { }

   if (self:mfunc_wants_symbol (id)) then
      local n = self:p_symbol ()
      table.insert (args, function (eval) return n (eval) end)

   else
      if (not self:la ("%)")) then
         table.insert (args, self:p_expr ())
      end
   end

   local argspec = self:mfunc_args (id)

   while (self:la (",")) do
      self:expect (",", "','")
      if (argspec == 0 and self:mfunc_wants_symbol (id)) then
         table.insert (args, self:p_symbol ())
      else
         table.insert (args, self:p_expr ())
      end
   end
   self:expect ("%)", "')'")

   if (argspec ~= nil) then
      if (argspec < 0) then
         argspec = -argspec
         if (#args < argspec) then
            self:err (
               "Error: Function '" .. id .. "' requires at least "
               .. argspec .. " arguments.")
         end
      elseif (argspec > 0) then
         if (#args ~= argspec) then
            self:err (
               "Error: Function '" .. id .. "' requires exactly "
               .. argspec .. " arguments.")
         end
      end
   end

   local assign
   if (self:la ("=[^=]")) then
      self:expect ("=", "'='")
      assign = self:p_expr ()
   end

   local f = self.mfunc[id];
   if (f == nil) then
      self:err ("Mathematical function '" .. id .. "' not defined!")
   end

   return self:penv (function (eval)
      local nargs = { }
      for _, e in ipairs (args) do
         table.insert (nargs, e (eval))
      end

      local ass
      if (assign ~= nil) then
         ass = assign (eval)
      end

      return eval:mcall (id, nargs, ass)
   end)
end

function parser:p_variable_or_func ()
   local id = self:p_identifier ()

   if (self:la ("%(")) then
      return self:p_math_func (id)

   elseif (self:la ("=[^=]")) then
      self:expect ("=", "'='")
      if (id:sub (1, 1) ~= "x" and id:sub (1, 1) ~= "X") then
         self:err ("Assignment to non-mathematical variables is not possible!")
      end
      local expr = parser:p_expr ()
      if (id:sub (1, 1) == "X") then
         return function (eval)
            local res = expr (eval)
            eval.ctx.vars[id] = res
            return res
         end
      else
         return function (eval)
            local res = expr (eval)
            eval.ctx.local_vars[id] = res
            return res
         end
      end
   end

   return function (eval)
      local r
      if (id:sub (1, 1) == "A") then
         local a = tonumber (id:sub (2, id:len ()))
         r = eval.ctx.args[a + 1]
      else
         r = eval.ctx.local_vars[id]
         if (r == nil) then
            r = eval.ctx.vars[id]
         end
      end
      if (r == nil) then
         r = 0
      end
      return r
   end
end

function parser:p_expr ()
   if (self:la_keywords ({ "if" })) then
      local alts = { }
      self:expect ("if", "'if'")
      self:expect ("%(", "'('")
      local bool = self:p_expr ()
      self:expect ("%)", "')'")
      local stmt = self:p_expr ()
      table.insert (alts, { bool, stmt })

      while (self:la_keywords ({ "elsif" })) do
         self:expect ("elsif")
         self:expect ("%(", "'('")
         bool = self:p_expr ()
         self:expect ("%)", "')'")
         stmt = self:p_expr ()
         table.insert (alts, { bool, stmt })
      end

      local elsestmt
      if (self:la_keywords ({ "else" })) then
         self:expect ("else")
         elsestmt = self:p_expr ()
      end

      return function (eval)
         local res
         for _, cond in ipairs (alts) do
            local c = cond[1] (eval)
            if (c ~= 0) then
               res = cond[2] (eval)
               break
            end
         end
         if (res == nil) then
            if (elsestmt ~= nil) then
               res = elsestmt (eval)
            else
               res = 0
            end
         end
         return res
      end

   elseif (self:la_keywords ({ "while" })) then
      self:expect ("while", "'while'")
      self:expect ("%(", "'('")
      local bool = self:p_expr ()
      self:expect ("%)", "')'")
      local stmt = self:p_expr ()

      return function (eval)
         local old_stop = eval.ctx.while_stop
         eval.ctx.while_stop = nil
         local last = 0
         while (eval.ctx.while_stop == nil and bool (eval) ~= 0) do
            last = stmt (eval)
         end
         if (eval.ctx.while_stop) then
            last = eval.ctx.while_stop
         end
         eval.ctx.while_stop = old_stop
         return last
      end

   elseif (self:la_keywords ({ "break" })) then
      self:expect ("break", "'break'")
      self:expect ("%(", "'('")
      local bool = self:p_expr ()
      self:expect ("%)", "')'")

      return function (eval)
         local f = bool (eval)
         eval.ctx.while_stop = f
         return f
      end

   elseif (self:la ("{")) then
      local stmts = { }
      self:expect ("{", "'{'")
      while (not self:la ("}")) do
         table.insert (stmts, parser:p_expr ())
      end
      self:expect ("}", "'}'")

      return function (eval)
         local last_val = 0
         for _, s in ipairs (stmts) do
            last_val = s (eval)
         end
         return last_val
      end

   else
      return parser:p_bool ()
   end
end

function parser:p_bool ()
   if (self:la_keywords ({ "not" })) then
      self:expect ("not", "not")
      local a = self:p_expr ()
      return function (eval) return p_bool2number (not (a (eval) ~= 0)) end

   else
      local a = self:p_comp ()

      if (self:la_keywords ({ "and", "or" })) then
         local op = self:expect_keywords ({ "and", "or" })
         local e = self:p_expr ()

         if (op == "and") then
            return function (eval)
               local v = a (eval)
               if (v ~= 0) then
                  return e (eval)
               else
                  return 0
               end
            end

         else -- or
            return function (eval)
               local v = a (eval)
               if (v ~= 0) then
                  return 1
               else
                  return e (eval)
               end
            end
         end
      end

      return a
   end
end

function p_bool2number (b)
   if (b) then return 1 else return 0 end
end

function parser:p_comp ()
   local a = self:p_arith ()
   if (self:la_keywords ({ "<=", ">=", "<", ">", "==", "!=" })) then
      local op = self:expect_keywords ({ "<=", ">=", "<", ">", "==", "!=" })
      local b = self:p_arith ()
      if (op == "<") then
         return function (eval) return p_bool2number (a (eval) < b (eval)) end
      elseif (op == ">") then
         return function (eval) return p_bool2number (a (eval) > b (eval)) end
      elseif (op == "<=") then
         return function (eval) return p_bool2number (a (eval) <= b (eval)) end
      elseif (op == ">=") then
         return function (eval) return p_bool2number (a (eval) >= b (eval)) end
      elseif (op == "==") then
         return function (eval) return p_bool2number (a (eval) == b (eval)) end
      elseif (op == "!=") then
         return function (eval) return p_bool2number (a (eval) ~= b (eval)) end
      end
   end
   return a
end

function parser:p_arith ()
   local na = self:p_fact ()

   if (self:la ("[-+]")) then
      local o = self:expect ("[-+]", "'-' or '+'")
      local nb = self:p_arith ()

      if (o == "+") then
         return function (eval)
            return na (eval) + nb (eval)
         end
      else
         return function (eval)
            return na (eval) - nb (eval)
         end
      end
   end

   return na
end

function parser:p_fact ()
   local na = self:p_number ()

   if (self:la ("[*/%%]")) then
      local o = self:expect ("[*/%%]", "'*', '%' or '/'")
      local nb = self:p_fact ()

      if (o == "*") then
         return function (eval)
            return na (eval) * nb (eval)
         end

      elseif (o == "%") then
         return function (eval)
            return na (eval) % nb (eval)
         end

      else
         return function (eval)
            local ne = nb (eval)
            if (ne == 0) then
               ne = 1
            end
            return na (eval) / ne
         end
      end
   end

   return na
end

function parser:p_number ()
   if (self:la ("%(")) then
      self:expect ("%(", "'('")
      local n = parser:p_expr ()
      self:expect ("%)", "')'")
      return function (eval)
         return n (eval)
      end

   elseif (self:la ("[-+0-9]")) then
      local sign = "+"
      if (self:la ("[+%-]")) then
         sign = self:expect ("[+%-]", "'+' or '-'")
      end
      local hex = false
      if (self:la ("0x")) then
         self:expect ("0x", "'0x'")
         hex = true
      end
      local n
      if (hex) then
         n = tonumber (self:expect ("[0-9a-fA-F][0-9a-fA-F]*", "hex number"), 16)
      else
         local num_p1 = self:expect ("[0-9][0-9]*", "number")
         local num_p2 = ""
         if (self:la ("%.")) then
            num_p2 = self:expect ("%.[0-9]*", "fractional part")
         end
         n = tonumber (num_p1 .. num_p2)
      end
      if (sign == "-") then
         n = n * -1;
      end
      return function (eval)
         return n
      end

   else
      return parser:p_variable_or_func ()
   end
end

