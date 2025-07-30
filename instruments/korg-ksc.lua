--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Korg Triton KSC Peformance Script Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function ksc_import(filename)
  -- Main import function for ksc files
  local l
  local line_number = 0
  local patch_path
  local patch_name
  
  patch_path, patch_name = split_filename(filename)
  
  if patch_path == "" then
    return false
  elseif patch_name == "" then
    return false
  end  

  
  for l in io.lines(filename) do
    -- remove redundant CR on unix systems
    local cr_replaced = 0
    l, cr_replaced = l:gsub(string.char(13), "")
    dprint("cr_replaced:", cr_replaced)

    line_number = line_number + 1
    if line_number == 1 then
      if l ~= "#KORG Script Version 1.0" then
        dprint("ksc_import: invalid file")
        -- broken file
        return false
      end
    end
    if io.exists(patch_path .. patch_name .. "/" .. l) then
      kmp_import(patch_path .. patch_name .. "/" .. l)
    elseif io.exists(patch_path .. l) then
      kmp_import(patch_path .. l)
    end
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
ksc_integration = { category = "instrument",
                    extensions = {"ksc"},
                    invoke = ksc_import}       

if renoise.tool():has_file_import_hook("instrument", {"ksc"}) == false then
  renoise.tool():add_file_import_hook(ksc_integration)
end
