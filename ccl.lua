--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/ccl.lua
============================================================================]]--
require 'ccl_line'
require 'ccl_parser'

ccl_eval = { }

function ccl_eval:init (str, syms, rsyms, defs, mfunc, N)
   self.ctx = {
      vars     = {
         N     = N,
         PI    = math.pi,
         INFDB = math.infdb,
      },
      local_vars = { },
      args     = { },
      loop_env = { },
      vectors  = { },
      memorize = { },
      lists    = { },
      inputf   = { },
      while_stop = nil,
      err = { "?", 0 },
   }
   self.str = str
   self.defs = defs
   self.syms = syms
   self.rsyms = rsyms
   self.mfunc = mfunc
   self.clip_cache = { }
   self.log_str = ""
end

function ccl_eval:init_input ()
   local coll = CclCollection (self)
   coll:add_selection ()
   self.selectionf = function (eval) return coll:clone () end
end

function ccl_eval:symbol2num (sym)
   local num = self.rsyms[sym]
   if (num == nil) then
      table.insert (self.syms, sym)
      self.rsyms[sym] = #self.syms
      num = #self.syms
   end
   return num
end

function ccl_eval:num2symbol (num)
   local sym = self.syms[num]
   if (sym == nil) then
      self:err ("Symbol with number " .. num .. " does not exist!")
   end
   return sym
end

function ccl_eval:log (line)
   local depth = 0
   local str = string.rep ("  ", depth) .. line
   self.log_str = self.log_str .. str .. "\n"
end

function ccl_eval:err (msg)
   error ("Error at line " .. self.ctx.err[1] .. ": " .. msg .. ", at '"
          .. string.sub (self.str, self.ctx.err[2], self.ctx.err[2] + 10) .. "'")
end

function ccl_eval:pos_msg (msg)
   print ("Eval at " .. self.ctx.err[1] .. ": " .. msg .. " '"
          .. string.sub (self.str, self.ctx.err[2], self.ctx.err[2] + 10) .. "'")
end

function ccl_eval:sel_handle_mode (id, mode, idx, selection)
   local ctx

   if (mode == "first") then
      ctx = { mode = "jump", idx = 1 }

   elseif (mode == "last") then
      ctx = { mode = "jump", idx = #selection }

   elseif (mode == "next") then
      ctx = { mode = "jump", idx = (idx % #selection) + 1 }

   elseif (mode == "prev") then
      if (idx == 1) then
         ctx = { mode = "jump", idx = #selection }
      else
         ctx = { mode = "jump", idx = idx - 1 }
      end

   elseif (mode == "other") then
      ctx = { mode = "exclude", idx = idx }

   elseif (mode == "shuffle") then
      local shuffled_selection = { }
      for i, item in ipairs (selection) do
         if (item.mode == "shuffle" and i ~= idx) then
            table.insert (shuffled_selection, item)
         end
      end
      shuffle (shuffled_selection)
      ctx = { mode = "shuffle", list = shuffled_selection }
   end

   self.ctx.loop_env[id] = ctx
end

function ccl_eval:sel_impl (id, selection, exclude)
   local eselect = { }
   for _, item in ipairs (selection) do
      table.insert (eselect, {
         weight = item.weight (self), mode = item.mode, collection = item.collection
      })
   end

   local sel = select_random_weight (eselect, exclude)
   if (sel == nil) then
      sel = { 1, eselect[1] }
   end

   if (self.debug_selection) then
      self:log ("selection " .. id .. " selected " .. sel[1] .. " (" .. sel[2].mode .. ")")
   end

   self:sel_handle_mode (id, sel[2].mode, sel[1], selection)

   return sel[2].collection (self)
end

function ccl_eval:sel (id, selection)

   if (#selection == 0) then
      return { }
   end

   local ctx = self.ctx.loop_env[id]

   if (ctx == nil) then
      return self:sel_impl (id, selection, nil)
   else
      if (ctx.mode == "exclude") then
         if (self.debug_selection) then
            self:log ("selection " .. id .. " exclude: " .. ctx.idx)
         end
         return self:sel_impl (id, selection, ctx.idx)

      elseif (ctx.mode == "jump") then
         if (self.debug_selection) then
            self:log ("selection " .. id .. " jump: " .. ctx.idx)
         end
         local sel = selection[ctx.idx]
         self:sel_handle_mode (id, sel.mode, ctx.idx, selection)
         return sel.collection (self)

      elseif (ctx.mode == "shuffle") then
         if (self.debug_selection) then
            local s = ""
            for _, i in ipairs (ctx.list) do
               s = s .. " " .. i.idx
            end
            self:log ("selection " .. id .. " shuffle:" .. s)
         end

         local sel = table.remove (ctx.list)
         if (#ctx.list <= 0) then
            -- remove context after shuffle list is done
            self.ctx.loop_env[id] = nil
         -- else: context stays
         end
         return sel.collection (self)

      else
         self:err ("SELECTION BROKEN, unknown ctx mode: " .. ctx.mode)
      end
   end
   -- control never reaches!
end

function ccl_eval:mcall (funcid, args, assign)
   local mfunc = self.mfunc[funcid]
   if (mfunc == nil) then
      self:err ("Error: Function " .. funcid .. " not defined!")
   end


   local old_args = self.ctx.args
   self.ctx.args = args

   local old_vars = self.ctx.local_vars
   self.ctx.local_vars = { }
   self.ctx.local_vars["V"] = assign

   local res = mfunc (self)

   self.ctx.args = old_args
   self.ctx.local_vars = old_vars

   return res
end
