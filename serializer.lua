--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/serializer.lua
============================================================================]]--

-- Parses a string like: "234\t<234 bytes>\n"
function sub_len_str (str, offs)
   local s, e = str:find ("\t", offs)
   if (s == nil) then
      error ("bad serialized string found! [" .. str .. "] at " .. offs)
   end
   --d-- print ("X[" .. str:sub (offs, s - 1) .. "]")
   local vlen = tonumber (str:sub (offs, s - 1))
   offs = e + 1

   local value = ""
   value = str:sub (offs, (offs + vlen) - 1)
   offs = offs + vlen + 1

   return offs, value
end

-- Deseralizes a table, more or less clumsy!
function deserialize_table (str, offs)
   local table = {}
   if (not offs) then
      offs = 1
   end
   while (str:len () >= offs) do

      local ktype = str:sub (offs, offs)
      offs = offs + 1

      local s, e = str:find ("\t", offs)
      if (s == nil) then
         error ("bad serialized string found! [" .. str .. "] at " .. offs)
      end
      local key = str:sub (offs, s - 1)
      offs = e + 1

      local vtype = str:sub (offs, offs)
      offs = offs + 1

      local value
      offs, value = sub_len_str (str, offs)

      if (ktype == "n") then
         key = tonumber (key)
      end

      local svalue = value

      if (vtype == "b") then
         value = (value == "true")
      elseif (vtype == "t") then
         if (value ~= "") then
            local oo
            oo, value = deserialize_table (value)
         else
            value = {}
         end
      elseif (vtype == "n") then
         value = tonumber (value)
      end

      table[key] = value
      --d-- print ("FO " .. s .. " : " .. e .. " [" .. key .. "] = "
      --           .. vtype .. "[" .. svalue .. "] " .. offs)
   end

   return offs, table
end

-- Serializes a table more or less well. Good enough for this tool.
-- XXX: the serialization is not very perfect. it does not really escape the keys correctly.
function serialize_table (table, skip_keys)
   local str = ""

   for key,val in pairs (table) do
      local skip = false

      for _,skk in pairs (skip_keys) do
         if (skk == key) then
            skip = true
            break
         end
      end

      if (type (key) == "number") then
         key = "n" .. ("%d"):format (key) .. "\t"
      elseif (type (key) == "string") then
         key = "s" .. key .. "\t"
      else
         error ("don't support non numeric or string keys! " .. key)
      end

      if (not skip) then
         str = str .. key

         if (type (val) == "string") then
            str = str .. "s" .. val:len () .. "\t" .. val .. "\n"

         elseif (type (val) == "boolean") then
            if (val) then
               str = str .. "b4\ttrue" .. "\n"
            else
               str = str .. "b5\tfalse" .. "\n"
            end

         elseif (type (val) == "number") then
            local valstr = ("%d"):format (val)
            str = str .. "n" .. valstr:len () .. "\t" .. valstr .. "\n"

         elseif (type (val) == "table") then
            local tbl_str = serialize_table (val, {})
            str = str .. "t" .. tbl_str:len () .. "\t" .. tbl_str .. "\n"

         else
            error ("clips can't store stuff of type " .. type (val))
         end
      end
   end

   return str
end

-- A database class that stores content on the song itself.
class "InstrumentDB"
   function InstrumentDB:__init (instr_name)
      self.name = instr_name
   end

   -- Much thanks for this to aklt [anders AT bladre.dk] and his fabulous Marks tool!
   function InstrumentDB:get_instr ()
      for i, instrument in ripairs (renoise.song ().instruments) do
         if instrument.name == self.name then
            return instrument.samples[1]
         end
      end

      local index = #renoise.song ().instruments + 1
      renoise.song ():insert_instrument_at (index)
      local instrument = renoise.song ().instruments[index]
      instrument.name = self.name

      return instrument.samples[1]
   end

   -- Read static data from the sample name of the data instrument
   function InstrumentDB:get_value ()
      local str = self:get_instr ().name
      local oo, data = deserialize_table (str)
      return data
   end

   -- Read static data from the sample name of the data instrument
   function InstrumentDB:get ()
      local static = {}

      local str = self:get_instr ().name
      local offs = 1

      while (str:len () >= offs) do
         local data
         offs, data = sub_len_str (str, offs)

         local oo, clip_data = deserialize_table (data)
         clip_data.data = data
         static[clip_data.id] = clip_data
      end

      return static
   end

   -- Writes the static data to the sample of the data instrument
   function InstrumentDB:set_value (table)
      local sample = self:get_instr ()
      sample.name = serialize_table (table, { })
   end

   -- Writes the static data to the sample of the data instrument
   function InstrumentDB:set (table)
      local sample = self:get_instr ()

      local clip_data = ""
      for _,clip in pairs (table) do
         if (clip.data) then
            clip_data = clip_data .. clip.data:len () .. "\t" .. clip.data .. "\n"
         end
      end

      sample.name = clip_data
   end


