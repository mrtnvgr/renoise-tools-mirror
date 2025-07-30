--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/util.lua
============================================================================]]--

-- Converts an effects column to a clip id
function fx2id (fx_col)
   if (fx_col.number_string:sub (1, 1) ~= "Y") then
      return nil
   end
   local first_val = fx_col.number_value - 0x2200;
   return bit.lshift (first_val, 8) + fx_col.amount_value
end

-- Mapping a number to a fx character
NUM2FXSTR = {
   "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D",
   "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R",
   "S", "T", "U", "V", "W", "X", "Y", "Z",
}
FXCHR2NUM = { }
for i, c in ipairs (NUM2FXSTR) do
   FXCHR2NUM[c] = i
end

-- Converts note strings to numbers and back
NOTE_OFFS = {
   ["C"] = 0; ["D"] = 2; ["E"] = 4; ["F"] = 5; ["G"] = 7; ["A"] = 9; ["B"] = 11;
   [ 0] = "C"; [ 2] = "D"; [ 4] = "E"; [ 5] = "F"; [ 7] = "G"; [ 9] = "A"; [11] = "B";
};

function note2num(n)
   if (n == "off" or n == "OFF" or n == "Off") then
      return 120
   end

   local m = { n:match("(.)(#?)-?(%d)") }

   if (m[1] ~= nil) then
      local offs = NOTE_OFFS[m[1]];
      if (m[2] == "#") then
         offs = offs + 1
      end
      offs = offs + 12 * tonumber (m[3]);
      return offs
   end

   return 121
end

function num2note(num, sep)
   local fsep
   if (sep == nil) then
      fsep = ""
      sep = "-"
   else
      fsep = sep
   end
   if (num == 120) then return "OFF"
   elseif (num == 121) then return "---"
   end
   local note = num % 12;
   local oct  = num / 12;
   local shrp = "";
   local note_str = NOTE_OFFS[note];
   if (note_str == nil) then
      note_str = NOTE_OFFS[note - 1];
      shrp = "#";
   end
   local str = string.format ("%s%s%s%s%d", note_str, fsep, shrp, sep, oct)
   return str
end

function get_note_value(note)
   return note - 4
end

-- Converts clip id to a "human readable" string
function id2str (id)
   local num_val = bit.rshift (id, 8)
   local amt_val = bit.band (id, 0xff)
   return ("%s%02X"):format (NUM2FXSTR[num_val + 1], amt_val)
end

function clip2str (clip)
   return ("%s: %s"):format (id2str (clip.id), clip.name)
end

-- Converts clip id to an fx column
function id2fx (id, fx_col)
   fx_col.number_value = bit.rshift (id, 8) + 0x2200
   fx_col.amount_value = bit.band (id, 0xff)
end

-- Small utility to clone a position table
function clone_pos (pos)
   return {
      pattern = pos.pattern,
      track   = pos.track,
      line    = pos.line
   }
end

-- The random selection function. Select an item randomly
-- from a list based on it's weight.
function select_random_weight (list, not_item_idx)
   local weight_sum = 0

   for _, item in ipairs (list) do
      if (item.weight > 0) then -- nop :)
         weight_sum = weight_sum + item.weight
      end
   end

   if (not_item_idx) then
      weight_sum = weight_sum - list[not_item_idx].weight
   end

   local selection = math.random (0, weight_sum)

   weight_sum = 0

   for i, item in ipairs (list) do
      if (item.weight > 0
          and (not_item_idx == nil
               or not_item_idx ~= i))
      then
         weight_sum = weight_sum + item.weight

         if (weight_sum >= selection) then
            return { i, item, selection }
         end
      end
   end

   return nil
end

function shuffle (list)
   if (#list > 1) then
      for i = 0, #list - 2 do
         local idx = #list - i
         local j = math.random (1, idx)
         local tmp = list[j]
         list[j] = list[idx]
         list[idx] = tmp
      end
   end
end

function wrap_to_range (from, to, val)
   while (val > to) do
      val = val - to
   end
   while (val < from) do
      val = val + (to - from)
   end
   return val
end

function clamp_range (from, to, val)
   if (val < from) then val = from
   elseif (val > to) then val = to
   end
   return val
end

function table_for_idx_ordered (tbl, func)
   local max_i = 0
   for i, _ in pairs (tbl) do
      if (max_i < i) then max_i = i end
   end
   if (max_i == 0) then
      return
   end
   for i = 1, max_i do
      if (tbl[i] ~= nil) then
         func (i, tbl[i])
      end
   end
end

function table_shallow_clone (tbl)
   local nt = { }
   for i, v in pairs (tbl) do
      nt[i] = v
   end
   return nt
end
