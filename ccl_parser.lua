--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/ccl_parser.lua
============================================================================]]--
parser = {
   o_func = { },
   o_mfunc = { },
   o_mfunc_attr = { },
}

function parser:init (s)
   self.str = s
   self.pos = 1
   self.line = 1
   self.select_idx = 1
   self.defs = { }
   self.def_is_op = { }
   self.syms = { }
   self.rsyms = { }
   self.func = { }
   self.mfunc = { }
   self.input_clos = nil
   for k, v in pairs (self.o_func) do
      self.func[k] = v
   end
   for k, v in pairs (self.o_mfunc) do
      self.mfunc[k] = v
   end
end

function parser:penv (func)
   local err = { self.line, self.pos, }

   return function (eval)
      local perr = eval.ctx.err
      eval.ctx.err = err
      return func (eval) -- hopefully a tailcall?!
   end
end

function parser:add_symbol (sym)
   if (self.rsyms[sym] == nil) then
      table.insert (self.syms, sym)
      self.rsyms[sym] = #self.syms
   end
end

function parser:skip (pattern)
   local m = string.match (self.str, "^" .. pattern, self.pos)
   if (m ~= nil) then
      self.pos = self.pos + m:len ()
      for w in string.gmatch (m, "\n") do
         self.line = self.line + 1
      end
   end
end

function parser:skip_ws ()
   self:skip ("%s+")
   if (self.str:sub (self.pos, self.pos) == "#") then
      local e = string.find (self.str, "\n", self.pos + 1, true)
      self.line = self.line + 1
      self.pos = e
      self:skip_ws () -- in case there are more comments!
   end
end

function parser:expect_keywords (patterns, name)
   self:skip_ws ()
   for i,v in ipairs (patterns) do
      local m = string.match (self.str, "^" .. v .. "[^%a%d_]", self.pos)
      if (m ~= nil) then
         m = m:sub (1, m:len () - 1)
         self.pos = self.pos + m:len ()
         return m
      end
   end

   self:err ("Parser error, expected " .. name)
end

function parser:expect (pattern, name)
   self:skip_ws ()
   local m = string.match (self.str, "^" .. pattern, self.pos)
   if (m == nil) then
      self:err ("Parser error, expected " .. name)
   else
      self.pos = self.pos + m:len ()
   end
   return m
end

function parser:la_keywords (patterns)
   self:skip_ws ()
   for i, v in ipairs (patterns) do
      if  (string.match (self.str, "^" .. v .. "[^%a%d_]", self.pos) ~= nil) then
         return true
      end
   end
   return false
end

function parser:la (pattern)
   self:skip_ws ()
   return (string.match (self.str, "^" .. pattern, self.pos) ~= nil)
end

function parser:err (msg)
   error ("Parser error at line " .. self.line .. ": " .. msg .. ", at '"
          .. string.sub (self.str, self.pos, self.pos + 10) .. "'")
end

function parser:pos_msg (msg)
   print ("Parser at " .. self.line .. ": " .. msg .. ": "
          .. string.sub (self.str, self.pos, self.pos + 10))
end

function parser:p_identifier ()
   return self:expect ("[%a_][%-%a%d_]*", "identifier")
end

function parser:p_symbol ()
   if (self:la_keywords ({ "sym" })) then
      self:expect ("sym", "'sym'")
      self:expect ("%(", "'('")
      local expr = self:p_expr ()
      self:expect ("%)", "')'")
      return self:penv (function (eval) return eval:num2symbol (expr (eval)) end)

   elseif (self:la ("[^),%s][^,)]*[^),%s]")) then
      local verbatim = self:expect ("[^),%s][^,)]*[^),%s]", "verbatim symbol")
      self:add_symbol (verbatim)
      return function (eval) return verbatim end

   elseif (self:la ("[^),%s]")) then

      local verbatim = self:expect ("[^),%s]", "verbatim symbol")
      self:add_symbol (verbatim)
      return function (eval) return verbatim end
   else
      return nil
   end
end

function parser:set_math_func (name, func, sym_arg, arg_num)
   self.o_mfunc[name] = func
   self.o_mfunc_attr[name] = { wants_sym = sym_arg, arg_num = arg_num }
end

function parser:mfunc_wants_symbol (name)
   if (self.o_mfunc_attr[name] ~= nil) then
      return self.o_mfunc_attr[name].wants_sym
   end
   return false
end

function parser:mfunc_args (name)
   if (self.o_mfunc_attr[name] ~= nil) then
      return self.o_mfunc_attr[name].arg_num
   end
   return nil
end

function parser:set_func (name, spec)
   self.o_func[name] = spec
end

require 'ccl_funcs'

require 'ccl_math'

function parser:p_func ()
   local name = self:p_identifier ()

   local spec = self.func[name]
   if (spec == nil) then
      if (self.defs[name] ~= nil) then -- user defined functions!
         spec = {
            args = { expr = true },
            need_collection = (self.def_is_op[name] ~= nil),
            handle = function (parser, name, args, coll)
               return self:penv (function (eval)
                  local old_args = eval.ctx.args
                  local old_inputf = eval.ctx.inputf[name]
                  if (old_inputf == nil) then
                     eval.ctx.inputf[name] = coll
                  end

                  local new_args = { }
                  for _, argf in ipairs (args) do
                     table.insert (new_args, argf(eval))
                  end

                  eval.ctx.args = new_args
                  local rcoll = eval.defs[name] (eval)
                  eval.ctx.inputf[name] = old_inputf
                  eval.ctx.args = old_args

                  return rcoll
               end)
            end
         }
      else
         self:err (
            "Expected known identifier or definition, "
            .. "but '" .. name .. "' is not defined.")
      end
   end

   local args = { }

   self:expect ("%(", "'('")
   if (spec.args.expr) then
      while (not self:la ("%)")) do
         table.insert (args, self:p_expr ())
         if (not self:la (",")) then
            break
         end
         self:expect (",", "','")
      end

   elseif (spec.args.custom) then
      args = spec.args.custom (self)

   else
      for i, a in ipairs (spec.args) do
         if (spec.args_optional and self:la ("%)")) then
            break
         end

         if (a.t == "modes") then
            local m = self:expect_keywords (a.modes, a.modes_name)
            table.insert (args, m)

         elseif (a.t == "expr") then
            local e = self:p_expr ()
            table.insert (args, e)

         elseif (a.t == "symbol") then
            local n = self:p_symbol ()
            table.insert (args, n)

         else
            self:err ("bad function specification for " .. name)
         end

         if (spec.args_optional and self:la ("%)")) then
            break
         end

         if ((not a.no_delim) and i < #spec.args) then
            self:expect (",", "','")
         end
      end
   end
   self:expect ("%)", "')'")

   local coll
   if (spec.need_collection) then
      coll = self:p_collection ()
   end

   return self:penv (spec.handle (self, name, args, coll))
end

function parser:p_collection ()
   if (self:la ("{")) then
      self:expect ("{", "'{'")
      local src_colls = { }
      while (not self:la ("}")) do
         local lin = self:p_collection ()
         table.insert (src_colls, lin)
      end
      self:expect ("}", "'}'")

      return self:penv (function (eval)
         local new_coll = CclCollection (eval)
         for _, coll in ipairs (src_colls) do
            new_coll:append (coll (eval))
         end
         return new_coll
      end)

   elseif (self:la ("%[")) then
      self:expect ("%[", "'['")

      local src_colls = { }
      while (not self:la ("%]")) do
         local coll = self:p_collection ()
         table.insert (src_colls, coll)
      end

      self:expect ("%]", "']'")

      return self:penv (function (eval)
         local new_coll = CclCollection (eval)
         for _, coll in ipairs (src_colls) do
            new_coll:merge (coll (eval))
         end
         return new_coll
      end)

   else

      return parser:p_func ()
   end
end

function parser:p_definition ()
   local def =
      self:expect_keywords (
         { "operation", "source", "function" },
         "'operation', 'source' or 'function'")

   self:expect ("%(", "'('")
   local n = self:p_identifier ()
   self:expect ("%)", "')'")

   if (def == "operation") then
      self.defs[n] = function() return { } end -- just a placeholder!
      self.def_is_op[n] = true
      local old_input_clos = self.input_clos
      self.input_clos = n
      self.defs[n] = self:p_collection ()
      self.input_clos = old_input_clos

   elseif (def == "source") then
      self.defs[n] = function() return { } end -- just a placeholder!
      self.defs[n] = self:p_collection ()

   else
      if (self.o_mfunc[n] ~= nil) then
         self:err ("Function '" .. n .. "' cannot be redefined!")
      end
      self.mfunc[n] = function() return 0 end
      self.mfunc[n] = self:p_expr ()
   end
end

function parser:p_prog ()
   while (self:la_keywords ({ "operation", "source", "function" })) do
      self:p_definition ()
   end
   return self:p_collection ()
end
