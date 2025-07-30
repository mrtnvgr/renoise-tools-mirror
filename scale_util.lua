-- based on scalefinder note ordering:
-- notes = { 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#' };
BLACKS = { false, true, false, false, true, false, true, false, false, true, false, true }

NOTE_OFFS = {
   ["C"] = 0;
   ["D"] = 2;
   ["E"] = 4;
   ["F"] = 5;
   ["G"] = 7;
   ["A"] = 9;
   ["B"] = 11;
   [ 0] = "C";
   [ 2] = "D";
   [ 4] = "E";
   [ 5] = "F";
   [ 7] = "G";
   [ 9] = "A";
   [11] = "B";
};

function note2num(n)
   if (n == "off" or n == "OFF" or n == "Off") then
      return 120
   end

   local m = { n:match("(.)(#?)-(%d)") }

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
