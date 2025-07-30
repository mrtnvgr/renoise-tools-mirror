-- Collection Operations

parser:set_func (
   "dump_expr", {
      args = { { t = "symbol" }, { t = "expr" } },
      need_collection = true,
      args_optional = false,
      handle = function (parser, name, args, coll)
         return function (eval)
            local sym = args[1] (eval)
            local e = args[2] (eval)
            eval:log ("expr(" .. sym .. ") = " .. e)
            return coll (eval)
         end
      end
   }
)

parser:set_func (
   "dump", {
      args = { { t = "symbol" }, { t = "expr" } },
      need_collection = true,
      args_optional = true,
      handle = function (parser, name, args, coll)
         local symbolv = args[1]
         local num = args[2]

         return function (eval)
            local symbol = "unnamed"
            if (symbolv ~= nil) then
               symbol = symbolv (eval)
            end
            local coll_ev = coll (eval)
            local num_ev
            if (num ~= nil) then
               num_ev = num (eval)
               eval:log ("expr(" .. symbol .. ") = " .. num_ev)
            end
            eval:log ("dump(" .. symbol .. "):\n" .. coll_ev:debug_dump ())
            return coll_ev
         end
      end
   }
)

parser:set_func (
   "loop", {
      args = {
         { t = "modes", modes = { "clone", "repeat" }, modes_name = "loop-mode" },
         { t = "expr" }
      },
      need_collection = true,
      args_optional = true,
      handle = function (parser, name, args, coll)
         local lmode = "repeat"
         if (args[1] ~= nil) then
            lmode = args[1]
         end
         local cnt = args[2]

         return function (eval)
            local n
            if (cnt == nil) then
               n = eval.ctx.vars["N"]
            else
               n = cnt (eval)
            end

            local new_coll = CclCollection (eval)
            local last_env = eval.ctx.loop_env
            eval.ctx.loop_env = { }
            new_coll:append_looped (lmode, n, coll)
            eval.ctx.loop_env = last_env
            return new_coll
         end
      end
   }
)

parser:set_func (
   "slice", {
      args = { { t = "expr" } },
      need_collection = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            local old_N = eval.ctx.vars["N"];
            local N = args[1] (eval)
            eval.ctx.vars["N"] = N
            local collection = coll (eval)
            eval.ctx.vars["N"] = old_N
            return collection:adjust_length (N)
         end
      end
   }
)
parser:set_func (
   "reverse", {
      args = { },
      need_collection = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            return coll (eval):reverse ()
         end
      end
   }
)

parser:set_func (
   "align", {
      args = {
         { t = "modes", modes = { "top", "bottom", "middle" },
           modes_name = "align-position" },
         { t = "expr" }
      },
      need_collection = true,
      args_optional = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            local offs = 0
            if (args[2] ~= nil) then
               offs = args[2] (eval)
            end
            local coll_ev = coll (eval)
            local new_coll = coll_ev:align (eval.ctx.vars["N"], offs, args[1])
            return new_coll
         end
      end
   }
)

parser:set_func (
   "remove_track", {
      args = { { t = "expr" } },
      need_collection = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            local coll_ev = coll (eval):clone ();
            coll_ev:remove_track (args[1] (eval) + 1)
            return coll_ev
         end
      end
   }
)

parser:set_func (
   "memorize", {
      args = { { t = "symbol" } },
      need_collection = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            local name = args[1] (eval)
            if (eval.ctx.memorize[name] == nil) then
               eval.ctx.memorize[name] = coll (eval)
            end
            return eval.ctx.memorize[name]:clone ()
         end
      end
   }
)
function transform_for_each_line (tracknr, track, coll, func)
   ccl_eval.ctx.vars["T"] = tracknr - 1
   ccl_eval.ctx.vars["L"] = #track
   ccl_eval.ctx.coll      = coll
   for i, line in ipairs (track) do
      ccl_eval.ctx.vars["I"] = i - 1
      ccl_eval.ctx.line      = line
      func (i, line)
   end
end

function transform_or_filter_impl (parser, name, args, coll)
   if (#args == 1) then
      return function (eval)
         local coll_ev = coll (eval):clone ()

         coll_ev:foreach_track (function (tracknr, track)
            local kill_lines = { }
            transform_for_each_line (tracknr, track, coll_ev, function (i, line)
               local res = args[1] (eval)
               if (name == "filter" and res == 0) then
                  table.insert (kill_lines, i)
               end
            end)
            if (name == "filter") then
               coll_ev:remove_track_lines (tracknr, kill_lines)
            end

         end)
         return coll_ev
      end

   elseif (#args == 2) then
      return function (eval)
         local tracknr = args[1] (eval) + 1
         local coll_ev = coll (eval):clone ()
         local track = coll_ev:track (tracknr)

         if (track == nil) then
            return coll_ev
         end

         local kill_lines = { }
         transform_for_each_line (tracknr, track, coll_ev, function (i, line)
            local res = args[2] (eval)
            if (name == "filter" and res == 0) then
               table.insert (kill_lines, i)
            end
         end)
         if (name == "filter") then
            coll_ev:remove_track_lines (tracknr, kill_lines)
         end

         return coll_ev
      end

   else
      return function (eval) return coll (eval) end
   end
end

parser:set_func (
   "transform", {
      args = { { t = "expr" }, { t = "expr" } },
      need_collection = true,
      args_optional = true,
      handle = transform_or_filter_impl,
   }
)

parser:set_func (
   "filter", {
      args = { { t = "expr" }, { t = "expr" } },
      need_collection = true,
      args_optional = true,
      handle = transform_or_filter_impl,
   }
)

parser:set_func (
   "automation", {
      args = { { t = "expr" }, { t = "symbol" }, { t = "symbol" }, { t = "expr" }, { t = "expr" } },
      need_collection = true,
      handle = function (parser, name, args, coll)
         return function (eval)
            local tracknr = args[1] (eval) + 1
            local devname = args[2] (eval)
            local trackname = args[3] (eval)
            local param, err = find_automation_parameter (tracknr, devname, trackname)
            if (err ~= nil) then
               eval:err ("Error: Track " .. tracknr
                         .. ", Device '" .. devname .. "'"
                         .. ", Parameter '" .. trackname .. "': " .. err)
            end

            local step = args[4] (eval)
            local co   = coll (eval):clone ()
            local trk  = co:track (tracknr)

            if (trk == nil) then
               return co
            end

            ccl_eval.ctx.vars["T"] = tracknr - 1
            ccl_eval.ctx.vars["L"] = #trk
            ccl_eval.ctx.coll      = co

            local atm_lines = { }
            for i = 0, #trk, step do
               local idx = math.floor (i)
               if (idx + 1 > #trk) then
                  break
               end
               local timeslot = math.floor (i * 256 - idx * 256)

               ccl_eval.ctx.vars["I"] = idx + timeslot / 256
               ccl_eval.ctx.line      = trk[idx + 1]
               local val = clamp_range (0, 1, args[5] (eval))

               if (atm_lines[idx + 1] == nil) then
                  atm_lines[idx + 1] = { param = param }
               end

               table.insert (atm_lines[idx + 1], { timeslot / 256, val })
            end

            for i, atm in ipairs (atm_lines) do
               trk[i]:apply_automation (atm)
            end

            return co
         end
      end
   }
)

-- Sources

parser:set_func (
   "clip", {
      args = { { t = "symbol" } },
      args_optional = false,
      handle = function (parser, name, args, coll)
         return function (eval)
            local new_coll = CclCollection (eval)
            new_coll:add_clip (args[1] (eval))
            return new_coll
         end
      end
   }
)

parser:set_func (
   "empty", {
      args = { { t = "expr" }, { t = "expr" } },
      args_optional = false,
      handle = function (parser, name, args, coll)
         return function (eval)
            local new_coll = CclCollection (eval)
            new_coll:append_track_empty (args[1] (eval) + 1, args[2] (eval))
            return new_coll
         end
      end
   }
)

parser:set_func (
   "input", {
      args = { },
      args_optional = true,
      handle = function (parser, name, args, coll)
         local input_clos = parser.input_clos
         return function (eval)
            local r
            if (input_clos ~= nil) then
               r = eval.ctx.inputf[input_clos]
            end
            if (r == nil) then
               r = function () return CclCollection (eval) end
            end
            return r (eval)
         end
      end
   }
)

parser:set_func (
   "selection", {
      args = { },
      args_optional = true,
      handle = function (parser, name, args, coll)
         local input_clos = parser.input_clos
         return function (eval)
            local r
            if (eval.selectionf ~= nil) then
               r = eval.selectionf
            end
            if (r == nil) then
               r = function () return CclCollection (eval) end
            end
            return r (eval)
         end
      end
   }
)
parser:set_func (
   "select", {
      args = { custom = function (parser)
         local debug = false

         if (parser:la_keywords ({ "debug" })) then
            parser:expect_keywords ({ "debug" })
            debug = true
         end

         local selection = { }
         local idx = 1

         while (not parser:la ("%)")) do
            local mode
            if (parser:la_keywords ({
               "any", "first", "last", "next", "prev", "other", "shuffle" })
            ) then
               mode = parser:expect_keywords ({
                  "any", "first", "last", "next", "prev", "other", "shuffle" })
            else
               mode = "any"
            end
            local num = parser:p_expr ()
            parser:expect (":", "':'")
            local coll = parser:p_collection ()
            table.insert (selection, {
               weight = num,
               collection = coll,
               mode = mode,
               idx = idx
            })
            idx = idx + 1
         end

         local id = parser.select_idx;
         parser.select_idx = parser.select_idx + 1

         return { debug, id, selection }
      end },
      handle = function (parser, name, args, coll)
         local debug     = args[1]
         local id        = args[2]
         local selection = args[3]

         return function (eval)
            local d = eval.debug_selection
            eval.debug_selection = debug
            local coll = eval:sel (id, selection)
            eval.debug_selection = d
            return coll
         end
      end
   }
)

parser:set_func (
   "switch", {
      args = { custom = function (parser)
         local colls = { }
         local idx = parser:p_expr ()
         parser:expect (":", "':'")

         while (not parser:la ("%)")) do
            table.insert (colls, parser:p_collection ())
         end

         return { idx, colls }
      end },
      handle = function (parser, name, args, coll)
         local idx = args[1]
         local colls = args[2]

         return function (eval)
            local i = math.floor (idx (eval) + 1)
            if (i >= 1 and i <= #colls) then
               return colls[i] (eval)
            else
               return CclCollection (eval)
            end
         end
      end
   }
)

-- TEMPLATE:
--parser:set_func (
--   "x", {
--      args = { { t = "symbol" } },
--      need_collection = true,
--      args_optional = true,
--      handle = function (parser, name, args, coll)
--      end
--   }
--)
