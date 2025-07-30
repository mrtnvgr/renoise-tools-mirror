-- CDP Interface v0.68 by Aftab Hussain aka afta8 - fathand@gmail.com - 3rd December 2016
-- Tool idea, feature suggestions, testing and ALL PROCESS DEFINITIONS by Djeroek - Makes awesome music too, check it out: http://plugexpert.bandcamp.com/

--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
    self:add_property("Version", "Unknown Version")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value
local tool_version = manifest:property("Version").value


--------------------------------------------------------------------------------
-- Setup and Globals
--------------------------------------------------------------------------------

-- Interpolate/Scale
local function interpolate(pos, min, max) -- Input must be 0 to 1
  return pos*(max-min)+min
end

function ReverseInterpolate(output, min, max)
  return (output-min)/(max-min)
end

-- Round to decimal places
local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Clamp values
local function clamp_value(input, min_val, max_val)
  return math.min(math.max(input, min_val), max_val)
end

-- Placeholder for breakpoint editor window
local brk_dialog = nil

-- Set up preferences
local options = renoise.Document.create("ScriptingToolPreferences") {
  prog_path = "no_path",
} 
renoise.tool().preferences = options

-- Return the sample rate for the sample
function get_srate() 
  return renoise.song().selected_sample.sample_buffer.sample_rate
end 

-- Return the number of cycles in a sample
function get_cycles()
  local smp_buffer = renoise.song().selected_sample.sample_buffer  
  local num_frames = smp_buffer.number_of_frames
  local smp_data= {}
  local function read_sample()
    for n = 1, num_frames do
      smp_data[n] = smp_buffer:sample_data(1, n)
    end
  end
  read_sample()
  local count = 0
  for n = 1, #smp_data-1 do
    if (smp_data[n] >= 0) and (smp_data[n+1] <= 0) or 
       (smp_data[n] <= 0) and (smp_data[n+1] >= 0) then 
       count = count + 1
    end            
  end
  return math.floor(count/2)
end

-- Return the length of the sample in milliseconds
function get_length()
  local smp_buffer = renoise.song().selected_sample.sample_buffer
  return (smp_buffer.number_of_frames/smp_buffer.sample_rate)*1000 
end

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Breakpoint envelope
require('Envelope')
local brk_env_points = nil


-- Functions to convert paths so that they can be stored in prefs
local function convert_path(path)
  return string.gsub(path, "/", "S_L_A_S_H")
end

local function revert_path(path)
  return string.gsub(path, "S_L_A_S_H", "/")
end


-- Placeholder for CDP Housekeep and Submix commands, needed for splitting and joining channels on stereo samples
local housekeep_c2 = nil
local housekeep_c4 = nil
local housekeep_c5 = nil
local submix = nil

-- Default URL for CDP Function Docs and function to update when a process is selected 
local process_url = "http://www.ensemble-software.net/CDPDocs/html/alphindex.htm"
local function update_process_url(dsp_preset)
  if dsp[dsp_preset]["cmds"].url == nil then
    process_url = "http://www.ensemble-software.net/CDPDocs/html/alphindex.htm"
  else
    process_url = dsp[dsp_preset]["cmds"].url
  end
end

-- Function to identify arg type
local function arg_type(a)
  local type = type(a)
  if type == "table" then
    return a.type
  else
    return type
  end
end


-- Function to refresh terminal from cmd_output
local function update_terminal(cmd_output, mode)
  local file = io.open(cmd_output, 'r')
  for line in file:lines() do
    --print(line)
    if not ( (string.find(line, "min") and string.find(line, "min")) or (string.len(line) == 0) ) then
      vb.views["terminal_output"].text = vb.views["terminal_output"].text..line.."\n" 
      vb.views["terminal_output"]:scroll_to_last_line()
    end
  end
end  


-- Function to build table with ins/smp references converted to file paths and ready for argument string
local function create_argument_table(args)
  local new_args = {}
  for a = 1, #args do
    if type(args[a]) == "table" then -- it is a sample reference
      new_args[a] = args[a].path -- Replace sample reference with file path
    else
      new_args[a] = args[a]
    end
  end
  return new_args
end


-- Function to build argument string ready for execute
local function create_arg_string(args)
  local arg_string = " "
  for a = 1, #args do
    if args[a] ~= "" then
      arg_string = arg_string..args[a].." "
    end
  end
  return arg_string
end


-- PVOC Conversions
local function wav_to_ana(input_path, pvoc)
  local output_path = os.tmpname("ana")
  -- Construct argument string
  local pvoc_arg_string = create_arg_string(pvoc.argument)
  pvoc_arg_string = " "..input_path.." "..output_path..pvoc_arg_string
  -- Run pvoc anal
  local cmd_output = os.tmpname('txt')  
  os.execute(pvoc.anal_command..pvoc_arg_string.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)
  os.remove(input_path)  
  return output_path 
end

local function ana_to_wav(input_path, pvoc)
  local output_path = os.tmpname("wav")
  local pvoc_arg_string = " "..input_path.." "..output_path 
  -- Run pvoc synth
  local cmd_output = os.tmpname('txt')  
  os.execute(pvoc.synth_command..pvoc_arg_string.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)     
  os.remove(input_path)     
  return output_path  
end


-- Repitch conversions
local function wav_to_frq(input_path, pvoc, getpitch)
  local output_frq_path = os.tmpname("frq")
  local output_ana_path = os.tmpname("ana")
  -- Do the PVOC
  local input_ana_path = wav_to_ana(input_path, pvoc)
  -- Getpitch convert to frq, construct arg string
  local getpitch_arg_string  = create_arg_string(getpitch.argument)
  getpitch_arg_string = " "..input_ana_path.." "..output_ana_path.." "..output_frq_path.." "..getpitch_arg_string
  -- Run getpitch
  local cmd_output = os.tmpname('txt')  
  os.execute(getpitch.command..getpitch_arg_string.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)  
  os.remove(input_path)
  os.remove(output_ana_path) -- Not needed     
  return output_frq_path 
end


-- Stereo processing
local function stereo_to_mono(input_path)
  local cmd_output = os.tmpname('txt')  
  os.execute(housekeep_c2.." "..input_path.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)         
  -- Add path info to l and r tables
  local l_path = string.sub(input_path, 1, -5).."_c1.wav"
  local r_path = string.sub(input_path, 1, -5).."_c2.wav"
  os.remove(input_path)
  return l_path, r_path
end

local function mono_to_stereo(l_input_path, r_input_path)
  local output_path = os.tmpname("wav")  
  local cmd_output = os.tmpname('txt')  
  os.execute(submix.." "..l_input_path.." "..r_input_path.." "..output_path.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)
  os.remove(l_input_path)
  os.remove(r_input_path)
  return output_path
end

local function mix_to_mono(input_path)
  local output_path = os.tmpname("wav")
  local cmd_output = os.tmpname('txt')  
  os.execute(housekeep_c4.." "..input_path.." "..output_path.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)         
  os.remove(input_path)
  return output_path
end

local function mix_to_stereo(input_path)
  local output_path = os.tmpname("wav")
  local cmd_output = os.tmpname('txt')  
  os.execute(housekeep_c5.." "..input_path.." "..output_path.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)         
  os.remove(input_path)
  return output_path
end


-- Process function
local function run_command(command, gui_arguments)
  
  -- Convert GUI arguments and create temp files
  local arguments = create_argument_table(gui_arguments)    

  -- Construct argument string
  local arg_string = create_arg_string(arguments)
  
  -- Execute command
  local cmd_output = os.tmpname('txt')  
  os.execute(command..arg_string.." > "..cmd_output)
  update_terminal(cmd_output)
  os.remove(cmd_output)

  -- Set status of output
  local status = nil
  for a = 1, #gui_arguments do    
    if (arg_type(gui_arguments[a]) == "out_wav") or (arg_type(gui_arguments[a]) == "out_ana") then  
      if io.exists(arguments[a]) then -- Check if a file was produced
        status = "ok"
      else
        status = "error"
      end              
    end
  end
      
  return status    
end


-- Called by the GUI
local function run_process(command, gui_arguments, pvoc, getpitch, channels)

  local status = nil

  -- Clear terminal
  vb.views["terminal_output"]:clear()

  -- Scan through input files and return max number of channels that need processing
  local function get_max_channels()
    for a = 1, #gui_arguments do     
      if (arg_type(gui_arguments[a]) == "in_wav") or (arg_type(gui_arguments[a]) == "in_ana") then -- If it is an input sample  
        if renoise.song().instruments[gui_arguments[a].ins].samples[gui_arguments[a].smp].sample_buffer.number_of_channels == 2 then
          return 2
        end 
      end
    end
    return 1
  end
  
  -- Scan through args and find where the output sample goes
  local function find_output_dest(args)
    for a = 1, #args do
      if (arg_type(args[a]) == "out_wav") or (arg_type(args[a]) == "out_ana") then -- If it is an output sample  
        return args[a]  
      end
    end
  end

  -- For processes that have multiple inputs check if input channels are mismatched
  local function check_mismatch()
    local chans = 0
    for a = 1, #gui_arguments do     
      if (arg_type(gui_arguments[a]) == "in_wav") or (arg_type(gui_arguments[a]) == "in_ana") then -- If it is an input sample  
        if chans == 0 then
          chans = renoise.song().instruments[gui_arguments[a].ins].samples[gui_arguments[a].smp].sample_buffer.number_of_channels
        elseif chans ~= renoise.song().instruments[gui_arguments[a].ins].samples[gui_arguments[a].smp].sample_buffer.number_of_channels then
          return true
        end
      end
    end
    return false
  end
    
  -- Check for mismatched channels on multi inputs and if true treat it like a 2in2out process i.e. any mono sample get converted to stereo
  if (channels == "any") and check_mismatch() then channels = "2in2out" end 

  
  -- Function to create new gui_arguments for each channel
  local function create_stereo_args(args)    
    -- Set up tables that will be returned
    local new_args_l =  table.rcopy(args)
    local new_args_r =  table.rcopy(args)    
                
    -- Loop through args and pre-process source samples
    for a = 1, #args do              
      if  (arg_type(args[a]) == "in_wav") or (arg_type(args[a]) == "in_ana") or (arg_type(args[a]) == "in_frq") then -- If it is an input sample 
       
        -- Save sample from renoise into tempfile
        args[a].path = os.tmpname("wav") -- Update input table
        local smp = renoise.song().instruments[args[a].ins].samples[args[a].smp].sample_buffer  
        smp:save_as(args[a].path, "wav")
        
        -- If it is a stereo sample and the process only supports mono                                                                                           
        if (renoise.song().instruments[args[a].ins].samples[args[a].smp].sample_buffer.number_of_channels == 2) and (channels ~= "any") and (channels ~= "1in2out") and (channels ~= "2in2out") then 
          -- Split sample into two mono samples (also os.remove source file)          
          new_args_l[a].path, new_args_r[a].path = stereo_to_mono(args[a].path)
          
          -- Convert to ana if PVOC process (also os.remove source file) 
          if arg_type(args[a]) == "in_ana" then -- File must be converted first
            new_args_l[a].path = wav_to_ana(new_args_l[a].path, pvoc)
            new_args_r[a].path = wav_to_ana(new_args_r[a].path, pvoc)          
          end                            
                             
          -- Convert to frq if getpitch process (also os.remove source file) 
          if arg_type(args[a]) == "in_frq" then -- File must be converted first
            new_args_l[a].path = wav_to_frq(new_args_l[a].path, pvoc, getpitch)
            new_args_r[a].path = wav_to_frq(new_args_r[a].path, pvoc, getpitch)          
          end                                   
                                 
        else -- It is a mono sample or process supports stereo input or sounds need mixing into a mono file       
          new_args_l[a].path = args[a].path 
          
          if (renoise.song().instruments[args[a].ins].samples[args[a].smp].sample_buffer.number_of_channels == 2) and (channels == "1in2out") then -- Mix source to mono
            new_args_l[a].path = mix_to_mono(new_args_l[a].path)          
          end
          
          if (renoise.song().instruments[args[a].ins].samples[args[a].smp].sample_buffer.number_of_channels == 1) and (channels == "2in2out") then -- Mix source to stereo
            new_args_l[a].path = mix_to_stereo(new_args_l[a].path)          
          end
          
          -- Convert to ana if PVOC process (also os.remove source file)
          if arg_type(args[a]) == "in_ana" then -- File must be converted first
            new_args_l[a].path = wav_to_ana(new_args_l[a].path, pvoc)         
          end
          
          -- Convert to frq if getpitch process (also os.remove source file) 
          if arg_type(args[a]) == "in_frq" then -- File must be converted first
            new_args_l[a].path = wav_to_frq(new_args_l[a].path, pvoc, getpitch)         
          end
                    
          -- Set right channel path to be same as left channel
          new_args_r[a].path = new_args_l[a].path                                   
        end -- if stereo
               
      elseif (arg_type(args[a]) == "out_wav") or (arg_type(args[a]) == "out_ana") then -- If it is an output sample       
        -- Set destination sample path
        new_args_l[a].path = os.tmpname(string.sub(arg_type(args[a]),-3,-1))
        new_args_r[a].path = os.tmpname(string.sub(arg_type(args[a]),-3,-1))        
      end -- If it is an input sample                  
    
    end -- Loop         
    return new_args_l, new_args_r -- Only left channel is used for mono samples       
  end   

  local function launch_commands()         
  
    -- Run the mono or stereo process
    local max_channels = get_max_channels() 
    local outfile = nil
    
    if (max_channels == 1) or (channels == "any") or (channels == "1in2out") or (channels == "2in2out") then -- It is a mono sample or process supports stereo input or 1in2out or 2in2out
    
      local args_l = create_stereo_args(gui_arguments)    
      status = run_command(command, args_l)    
      local out_l = find_output_dest(args_l)
            
      -- PVOC Convert back to wav from ana (also os.remove source file)
      if arg_type(out_l) == "out_ana" then -- File must be converted
        out_l.path = ana_to_wav(out_l.path, pvoc)
      end
    
      if out_l then outfile = out_l.path end
      
    elseif max_channels == 2 then    
    
      local args_l, args_r = create_stereo_args(gui_arguments)    
      status = run_command(command, args_l)
      if status == "error" then return end -- Prevent processing both channels if error on 1st channel
      status = run_command(command, args_r)        
      local out_l = find_output_dest(args_l)
      local out_r = find_output_dest(args_r)
    
      -- PVOC Convert back to wav from ana (also os.remove source file)
      if arg_type(out_l) == "out_ana" then -- File must be converted
        out_l.path = ana_to_wav(out_l.path, pvoc)
        out_r.path = ana_to_wav(out_r.path, pvoc)
      end
      
      if out_l then outfile = mono_to_stereo(out_l.path, out_r.path) end
           
    end -- max channels

    -- Load sample into renoise  
    local out_dest = find_output_dest(gui_arguments)
    if out_dest then
      local out_smp = renoise.song().instruments[out_dest.ins].samples[out_dest.smp].sample_buffer 
      if io.exists(outfile) then 
        out_smp:load_from(outfile) 
        os.remove(outfile)   
      end
    end  
  end -- launch commands

  launch_commands()
      
  -- Mop up any remaining temp samples
  for a = 1, #gui_arguments do
    if type(gui_arguments[a]) == "table" then 
      if gui_arguments[a].path ~= nil then
        os.remove(gui_arguments[a].path)
      end
    end
  end
    
  -- Error message 
  if status == "error" then
    renoise.app():show_error("An output file was not produced - Check your settings")
  end  
  
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
      
  -- Set viewbuilder
  vb = renoise.ViewBuilder()
      
  -- Load path from preferences  
  local path = revert_path(options.prog_path.value)  
  -- If path not previously set, prompt user
  if path == "no_path" then
    path = renoise.app():prompt_for_path("Select path to CDP executables")
    options.prog_path.value = convert_path(path)
  end

  -- Load the dsp command definitions
  dofile("definitions.lua")

  --[[
  -- Check if environment variable is set
  if os.getenv("CDP_SOUND_EXT") ~= "wav" then
    renoise.app():show_custom_prompt("Environment variable not set", vb:text {text = " Your installation of CDP is incomplete \n Please review the CDP installation instructions and ensure the Environment variable has been set. \n Without this setting a large number processes will not work"}, {"OK"})
  end     
  --]]
      
  --[[
  if (io.exists(path.."user_definitions.lua")) then
    dofile(path.."user_definitions.lua")
  end
  --]]
  
  ----------------------------------------------------------------------------------------------
  
  -- Populate dsp presets 
  local dsp_presets = table.keys(dsp) 
  print("Number of CDP process definitions: "..#dsp_presets) -- get number of presets
  
  -- Function to return a filtered preset list  
  local function filter_presets(filter)
    dsp_presets = table.keys(dsp) 
    table.sort(dsp_presets)
    local filtered_presets = {}
    local count = 1
    for n = 1, #dsp_presets do 
      if dsp[dsp_presets[n]].cmds.exe == filter then 
      filtered_presets[count] = dsp_presets[n]
      count = count + 1
      end
    end
    dsp_presets = filtered_presets
  end
  
  -- Get list of commands
  local exe_list = {}
  for n = 1, #dsp_presets do
    exe_list[dsp[dsp_presets[n]].cmds.exe] = 1
  end
  exe_list = table.keys(exe_list)
  table.sort(exe_list)
  
  -- Set up list for initial launch
  filter_presets(exe_list[1])  

  ----------------------------------------------------------------------------------------------

  -- Set up PVOC definitions
  local pvoc_params = {}
  pvoc_params["arg1"] = { name = "Points", switch = "-c", min = 2, max = 32768, def = 1024, tip = "PVOC: The number of analysis points (2-32768 – powers of 2 only) More points give better frequency resolution, but worse time resolution: i.e., detail is lost in rapidly changing spectra" }
  pvoc_params["arg2"] = { name = "Overlap", switch = "-o", min = 1, max = 4, def = 3, tip = "PVOC: Filter overlap factor (1 – 4)" }    

  -- Set up Repitch definitions
  local repitch_params = {}
  repitch_params["arg1"] = { name = "TRange", switch = "-t", min = 0, max = 6, def = 1, tip = "Tuning range(semitones) within which harmonics are accepted as in tune" }
  repitch_params["arg2"] = { name = "MinWin", switch = "-g", min = 0, max = 977, def = 2, tip = "Minimum number of adjacent windows that must be pitched, for a pitch-value to be registered" }
  repitch_params["arg3"] = { name = "SNR", switch = "-s", min = 0, max = 1000, def = 80, tip = "Signal to noise ratio, in decibels - Windows which are more than SdB below maximum level in sound, are assumed to be noise, and any detected pitch value is assumed spurious" }
  repitch_params["arg4"] = { name = "Harmonics", switch = "-n", min = 1, max = 8, def = 5, tip = "How many of the 8 loudest peaks in spectrum must be harmonics to confirm sound is pitched" }
  repitch_params["arg5"] = { name = "Low Freq", switch = "-l", min = 10, max = 2756, def = 10, tip = "Frequency of LOWEST acceptable pitch" }            
  repitch_params["arg6"] = { name = "Top Freq", switch = "-h", min = 10, max = 2756, def = 2756, tip = "Frequency of TOPMOST acceptable pitch" }
  repitch_params["arg7"] = { name = "Alt Pitch", switch = "-a", tip = "Alternative pitch-finding algorithm (avoid N < 2)" }      
  repitch_params["arg8"] = { name = "Retain", switch = "-z", tip = "Retain unpitched windows (set them to -1)" }

  -- Set up Submix balance params
  local balance_params = {}
  balance_params["arg1"] = { name = "Dry/Wet", switch = "-k", min = 0, max = 1, def = 1, input = "brk", tip = "Set the mix between the original and effected sound" }
  
  
  -- Function to determine if current preset is pvoc or repicth
  local function preset_type(preset)
    local type = nil
    for a = 1, table.count(preset)-1 do
      if preset["arg"..a].input == "ana" then 
        type = "pvoc"
      elseif preset["arg"..a].input == "frq" then 
        return "getpitch"
      end      
    end
    return type
  end
  
  ----------------------------------------------------------------------------------------------
  
  -- Set up variable to store input file path for input files and function to switch on or off
  local input_file = {}
  local function input_file_switch(path, mode, num)
    if mode == true then
      input_file[num] = path
      vb.views["arg_"..num.."_input"].color = {60, 150, 50}
    else
      input_file[num] = nil
      vb.views["arg_"..num.."_input"].color = {0, 0, 0}
    end
  end
  
  -- Set up variable to store output file path for input files and function to switch on or off
  local output_file = {}
  local function output_file_switch(path, mode, num)
    if mode == true then
      output_file[num] = path
      vb.views["arg_"..num.."_output"].color = {50, 60, 150}
    else
      output_file[num] = nil
      vb.views["arg_"..num.."_output"].color = {0, 0, 0}
    end
  end
  
  
  -- Return filetypes for input output dialogues
  local filetypes ={}
    function filetypes.input(type)
      local filetypes = nil
      if type == "brk" then 
        filetypes = {"*.txt","*.brk"}
      elseif type == "txt" then
        filetypes = {"*.txt","*.brk"}
      elseif type == "frq" then 
        filetypes = {"*.frq","*.brk"}
      elseif type == "trn" then
        filetypes = {"*.trn", "*.brk"}
      elseif type == "for" then
        filetypes = {"*.for"}
      elseif type == "env" then
        filetypes = {"*.env"}
      elseif type == "data" then
        filetypes = {"*.*"}
      end
      return filetypes
    end
    function filetypes.output(type)
      if type == "frq" then 
        return ".frq" 
      elseif type == "trn" then
        return ".trn"
      elseif type == "brk" then
        return ".brk"
      elseif type == "txt" then
        return ".txt"
      elseif type == "for" then
        return ".for"
      elseif type == "env" then
        return ".env"
      end
    end
  
    
  -- Function to build command portion
  local function build_command(exe, mode)  
    if os.platform() == 'WINDOWS' then
      exe = exe..".exe"
    end
    return path..exe.." "..mode  
  end 

----------------------------------------------------------------------------------------------
-- Breakpoint editor
----------------------------------------------------------------------------------------------

  -- Setup breakpoint editor pop out window
  local function show_brk_dialog(type, num, scale_min, scale_max, smp_length)

    -- This block makes sure a non-modal dialog is shown once.
    -- If the dialog is already opened, it will be focused.
    if brk_dialog and brk_dialog.visible then
      brk_dialog:show()
      return
    end
  
    -- The ViewBuilder is the basis
    local vb = renoise.ViewBuilder()
  
    -- Globals      
    local envelope = Envelope(394,150)
    --local envelopes = {}  
    local time_min = 0
    local time_max = smp_length
    
    
    -- Points to text field, grab points from table of time/value items then add to the multiline textfield
    local function points_to_text(points)    
      vb.views["textfield"]:clear()
      for p = 1, #points do    
        local time = interpolate(points[p].time, vb.views["time_min"].value, vb.views["time_max"].value)
        time = round(time/1000, 3)
        local value = interpolate(points[p].value, vb.views["value_min"].value, vb.views["value_max"].value) 
        value = round(value, 2)
        vb.views["textfield"].text = vb.views["textfield"].text..time.."\t"..value.."\n"
      end    
    end


    -- Triggers getting of envelope data, updates global envelope variable and calls points_to_text function
    local function get_envelopes()
      brk_env_points = envelope:GetPoints()       
      if #brk_env_points > 0 then 
        points_to_text(brk_env_points) 
      end   
    end

    
    -- Set the envelope notifier so that text field and global variable is always updated when envelope GUI is updated
    envelope.notifier = get_envelopes

    
    -- Gets information from the text field and converts into a time value table compatible with the envelope
    local function get_points()            
      local text = vb.views["textfield"].paragraphs
      local points = {}
      local points_idx = nil
      
      local s_time_min = vb.views["time_min"].value
      local s_time_max = vb.views["time_max"].value
      local s_scale_min = vb.views["value_min"].value
      local s_scale_max = vb.views["value_max"].value
            
      if #text > 0 then
        for n = 1, #text do
          local text_len = string.len(text[n])
          local text_spc = string.find(text[n], " ")
          if text_len > 0  and text_spc and text_len > text_spc then
              local time = tonumber( string.sub(text[n], 1, text_spc-1 ) )
              local value = tonumber( string.sub(text[n], text_spc+1, text_len) )              
              if time and value then               
                points_idx = #points+1
                points[points_idx] = {}
                points[points_idx]["time"] = ReverseInterpolate(time*1000, s_time_min, s_time_max)
                points[points_idx]["value"] = ReverseInterpolate(value, s_scale_min, s_scale_max)
              end
          end  
        end
        return points  
      end
    end


    ----------------------------
    -- GUI
    ----------------------------


    -- The content of the dialog, built with the ViewBuilder.
    local content = vb:column {
      margin = 10,
      spacing = 8,       
    }

    
    -- Text field
    local text =  vb:multiline_textfield {
        id = "textfield",
        width = 165,
        height = 150,
        notifier = function(value)                  
          if vb.views["textfield"].edit_mode and type == "brk" then 
            envelope.notifier = function () end
            local points = get_points()
            if points and #points > 0 then
              envelope:SetPoints(points)
            end
            envelope.notifier = get_envelopes
          end
        end        
      }
    
   
    -- Value scaling controls
    local vscale_controls = vb:row {   
        vb:text{ text = "Value Scale:", width = 85 },
        vb:valuebox {
          id = "value_min",
          tooltip = "Set minimum value for envelope range",
          min = scale_min,
          max = scale_max,
          value = scale_min,
          width = 70,
          notifier = function(value)
            get_envelopes()
          end    
        },      
        vb:valuebox {
          id = "value_max",
          tooltip = "Set maximum value for envelope range",
          min = scale_min,
          max = scale_max,
          value = scale_max,
          width = 70,
          notifier = function(value)
            get_envelopes()
          end    
        }      
      }
    
        
    -- Time scaling controls
    local tscale_controls = vb:row {    
        vb:text{ text = "Time Scale(ms):", width = 85 },    
        vb:valuebox {
          id = "time_min",
          tooltip = "Set minimum time value for envelope time range",
          min = time_min,
          max = time_max,
          value = time_min,
          width = 70,
          notifier = function(value)
            get_envelopes()
          end    
        },      
        vb:valuebox {
          id = "time_max",
          tooltip = "Set maximum time value for envelope time range",
          min = time_min,
          max = time_max,
          value = time_max,
          width = 70,
          notifier = function(value)
            get_envelopes()
          end    
        }      
      }
    
      -- Load, save and apply controls
    local space = vb:space { height = 10 }    
    local load_save = vb:row {
        vb:button {
          text = "Load",
          tooltip = "Load breakpoint data from file",
          notifier = function() 
            local filepath = renoise.app():prompt_for_filename_to_read({"*.txt","*.brk"}, "Load "..type.." file")
            local file = io.open(filepath, "r")
            if file then
              vb.views["textfield"]:clear()
              for line in file:lines() do          
                vb.views["textfield"].text = vb.views["textfield"].text..line.."\n" 
                vb.views["textfield"]:scroll_to_last_line()
              end
              file:close() 
            end                
          end
        },        
        vb:button {
          text = "Save",
          tooltip = "Save breakpoint data to file",
          notifier = function()
            local filepath = renoise.app():prompt_for_filename_to_write(type, "Save "..type.." file")
            local file = io.open(filepath, "w")
            if file then
              file:write(vb.views["textfield"].text)         
              file:close()
            end        
          end
        },
        vb:space { width = 113 },
        vb:button {
          text = "Apply",
          tooltip = "Apply current enevelope data to process",
          notifier = function()
            local proc_env = os.tmpname(type)
            local file = io.open(proc_env, "w")
            if file then
              file:write(vb.views["textfield"].text)         
              file:close()
              -- Update button and store path for main tool
              input_file_switch(proc_env, true, num)
            end          
          end
        }        
      }    
    
        
    -- Setup GUI
    local c_row1 = vb:row{}
    local c_row2 = vb:row{spacing = 8}
    local c_controls = vb:column{}
    local env_controls = vb:row{}    
    env_controls:add_child( vb:text{ text = "Envelope Controls:", width = 125 } )
    env_controls:add_child( envelope.GUI_INIT )
    env_controls:add_child( vb:space {width = 10} )
    env_controls:add_child( envelope.GUI_REMOVE )
    env_controls:add_child( envelope.GUI_ADD ) 
       
    local dialog_title = "Create text input"
    
    c_row2:add_child(text)
    
    if type == "brk" then 
      c_row1:add_child(envelope.GUI)
      c_controls:add_child(env_controls)
      c_controls:add_child( vb:space {height = 10} )
      c_controls:add_child(vscale_controls)
      c_controls:add_child(tscale_controls)
      c_row2:add_child(c_controls)
      dialog_title = "Create breakpoint envelope"
    end
    
    content:add_child(c_row1)
    content:add_child(c_row2)
    
    if type == "brk" then 
      c_controls:add_child(space)
      c_controls:add_child(load_save)
    else
      content:add_child(space)
      content:add_child(load_save)     
    end
    
       
    -- Key passthrough function
    local function keyhandler(dialog, key)
      return key
    end
           
    brk_dialog = renoise.app():show_custom_dialog(dialog_title, content, keyhandler)    
  
    -- Load last used envelope
    if brk_env_points then
      envelope:SetPoints(brk_env_points)
    else
      brk_env_points = envelope:GetPoints()
    end
    
    if type == "brk" then 
      get_envelopes()
    end
    
  end

  ----------------------------------------------------------------------------------------------
  -- END Breakpoint editor
  ----------------------------------------------------------------------------------------------

  -- Establish type of argument
  local function arg_type(arg)
    local type = "value"
    if arg.switch ~= nil then 
      if (arg.min ~= nil) and (arg.max ~= nil) then 
        if arg.input == "brk" then
          type = "switchvaluevariable"
        else 
          type = "switchvalue"
        end
      elseif arg.input == "data" then
        type = "switchdata"
      elseif arg.input == "txt" then
        type = "switchtext"  
      else  
        type = "switch" 
      end    
    elseif arg.input ~= nil then
      if arg.input == "brk" then 
        type = "valuevariable"
      elseif arg.input == "string" then
        type = "string"
      elseif arg.input == "txt" then
        type = "text"
      elseif arg.input == "frq" then
        type = "in_frq"          
      elseif (arg.input == "trn") or (arg.input == "for") or (arg.input == "env") or (arg.input == "data") then 
        type = "input"
      elseif arg.input == "wav" then
        type = "in_wav"
      elseif arg.input == "ana" then
        type = "in_ana"
      end
    elseif arg.output ~= nil then
      if arg.output == "wav" then 
        type = "out_wav"
      elseif arg.output == "ana" then
        type = "out_ana"
      --elseif arg.output == "frq" then
      --  type = "out_frq"  
      else
        type = "output"    
      end
    end
    return type
  end    

  ----------------------------------------------------------------------------------------------

  -- Return a default value for setting up controls
  local function arg_val(arg, param)
    if param == "active" then
      if (arg_type(arg) == "switchvalue") or 
         (arg_type(arg) == "switchvaluevariable") or
         (arg_type(arg) == "switchdata") or
         (arg_type(arg) == "switchtext") then
        return false
      else
        return true
      end      
    elseif param == "min" then
      return arg.min    
    elseif param == "max" then 
      return arg.max    
    elseif param == "def" then
      if arg.def ~= nil then
        return arg.def
      else
        return arg.max/2
      end        
    elseif param == "tip" then
      return arg.tip            
    end  
  end

  ----------------------------------------------------------------------------------------------

  -- Containers for all argument parameter sliders
  local arguments_column = vb:column {} -- Initialise with empty  
  local control_ids = {} -- Container for control id's - Need this to remove them later    
  
  -- Function to build arguments parameter row
  local function build_arg_params_row(arg, num)
    
    -- GUI size settings
    local TEXT_WIDTH = 80
    local SLIDER_WIDTH = 270
    
    -- Create row container
    local arg_row = vb:row { }

    -- Create vb containers
    local label = nil
    local ins_select = nil
    local smp_select = nil
    local checkbox = nil
    local slider = nil
    local value_field = nil
    local input_button = nil
    local string_field = nil
    local output_button = nil

    -- Create argument label
    label = vb:text {
      width = TEXT_WIDTH,
      align = "center",
      text = arg.name
    }
        
    -- Create instrument & sample selector    
    if (arg_type(arg) == "in_wav") or 
       (arg_type(arg) == "out_wav") or 
       (arg_type(arg) == "in_ana") or 
       (arg_type(arg) == "out_ana") or 
       (arg_type(arg) == "in_frq") then -- or (arg_type(arg) == "out_frq") then

      -- Update instrument list
      local ins_list = {}
      for n = 1, #renoise.song().instruments do 
        ins_list[n] = renoise.song().instruments[n].name        
      end
        
      -- Populate samples list on demand
      local function get_samples(ins)
        local smp_list = {}
        for n = 1, #renoise.song().instruments[ins].samples do
          smp_list[n] = renoise.song().instruments[ins].samples[n].name
        end
        return smp_list          
      end
        
      -- Add GUI elements        
      control_ids[#control_ids+1] = "arg_"..num.."_ins_select" -- Log the id for later removal
      ins_select = vb:popup {
        id = "arg_"..num.."_ins_select",
        width = 133,
        height = 20,
        tooltip = arg_val(arg, "tip"),
        items = ins_list,
        value = renoise.song().selected_instrument_index,
        notifier = function(value) 
          vb.views["arg_"..num.."_smp_select"].items = get_samples(value)
          vb.views["arg_"..num.."_smp_select"].value = 1
        end
      }
      control_ids[#control_ids+1] = "arg_"..num.."_smp_select" -- Log the id for later removal                   
      smp_select =  vb:popup {
        id = "arg_"..num.."_smp_select",
        width = 133,
        height = 20,
        tooltip = arg_val(arg, "tip"),
        items = get_samples(vb.views["arg_"..num.."_ins_select"].value),
        value = renoise.song().selected_sample_index,
        notifier = function(value)
        end             
      }
    end            
            
    -- Create switch checkbox
    if (arg_type(arg) == "switch") or 
       (arg_type(arg) == "switchvalue") or 
       (arg_type(arg) == "switchvaluevariable") or 
       (arg_type(arg) == "switchdata") or
       (arg_type(arg) == "switchtext") then
       
      control_ids[#control_ids+1] = "arg_"..num.."_switch" -- Log the id for later removal 
      checkbox = vb:checkbox {
        id = "arg_"..num.."_switch",
        width = 20,
        height = 20,
        tooltip = arg_val(arg, "tip"),
        notifier = function(value)
          if arg_type(arg) == "switchvalue" then
            vb.views["arg_"..num.."_slider"].active = value
            vb.views["arg_"..num.."_value"].active = value
          elseif arg_type(arg) == "switchvaluevariable" then 
            vb.views["arg_"..num.."_slider"].active = value
            vb.views["arg_"..num.."_value"].active = value
            vb.views["arg_"..num.."_input"].active = value
          elseif (arg_type(arg) == "switchdata") or
                 (arg_type(arg) == "switchtext") then 
            vb.views["arg_"..num.."_input"].active = value
          end
        end
      } 
      SLIDER_WIDTH = SLIDER_WIDTH - 20 -- Reduce slider size to accomodate checkbox
    end 
    
    -- Create input buttons
    if (arg_type(arg) == "valuevariable") or 
       (arg_type(arg) == "switchvaluevariable") or 
       (arg_type(arg) == "switchdata") or 
       (arg_type(arg) == "switchtext") or
       (arg_type(arg) == "input") or 
       (arg_type(arg) == "text") or 
       (arg_type(arg) == "in_frq") then
       
      input_file[num] = nil -- Clear any existing variable
      control_ids[#control_ids+1] = "arg_"..num.."_input" -- Log the id for later removal 
      input_button = vb:button {
        id = "arg_"..num.."_input",
        width = 20,
        height = 20,
        active = arg_val(arg, "active"),
        text = "↓",
        tooltip = arg_val(arg, "tip"),       
        notifier = function()
        
          if (arg_type(arg) == "input") or 
             (arg_type(arg) == "in_frq") or
             (arg_type(arg) == "switchdata") then
             
            local path = renoise.app():prompt_for_filename_to_read(filetypes.input(arg.input), "Select input file")
            if path ~= "" then
              path = '"'..path..'"' -- In case path has spaces in it
              input_file_switch(path, true, num)          
            end
         
          elseif (arg_type(arg) == "valuevariable") or 
                 (arg_type(arg) == "switchvaluevariable") then -- It is a parameter that can vary over time
            show_brk_dialog("brk", num, arg.min, arg.max, length)
          
          elseif (arg_type(arg) == "text") or
                 (arg_type(arg) == "switchtext") then 
            show_brk_dialog("txt", num)   
          end
          
        end
      }
      SLIDER_WIDTH = SLIDER_WIDTH - 20
    end        
                
    -- Create the slider & value field 
    if (arg_type(arg) == "value") or 
       (arg_type(arg) == "switchvalue") or 
       (arg_type(arg) == "valuevariable") or 
       (arg_type(arg) == "switchvaluevariable") then
             
      -- Create slider  
      control_ids[#control_ids+1] = "arg_"..num.."_slider" -- Log the id for later removal  
      slider = vb:slider {
        id = "arg_"..num.."_slider",
        active = arg_val(arg, "active"),
        tooltip = arg_val(arg, "tip"),
        min = arg_val(arg, "min"),
        max = math.max(arg_val(arg, "min"), arg_val(arg, "max")), -- ensures max is always bigger than min
        value = clamp_value(arg_val(arg, "def"), arg_val(arg, "min"), math.max(arg_val(arg, "min"), arg_val(arg, "max"))), -- ensures def value is always in range
        width = SLIDER_WIDTH,
        height = 20,
        notifier = function(value)
          vb.views["arg_"..num.."_value"].value = value
          -- Reset any input file attached to param
          if (arg_type(arg) == "valuevariable") or 
             (arg_type(arg) == "switchvaluevariable") then 
            input_file_switch(nil, false, num)
          end
        end  
      }       
      -- Create the value field
      control_ids[#control_ids+1] = "arg_"..num.."_value" -- Log the id for later removal     
      value_field = vb:valuefield {
        id = "arg_"..num.."_value",
        -- Get settings from slider
        active = vb.views["arg_"..num.."_slider"].active,
        tooltip = vb.views["arg_"..num.."_slider"].tooltip,
        min = vb.views["arg_"..num.."_slider"].min,
        max = vb.views["arg_"..num.."_slider"].max,
        value = vb.views["arg_"..num.."_slider"].value,
        notifier = function(value)
          vb.views["arg_"..num.."_slider"].value = value
        end
      }            
    end 
       
    -- Create string field
    if arg_type(arg) == "string" then
      control_ids[#control_ids+1] = "arg_"..num.."_string" -- Log the id for later removal 
      string_field = vb:textfield {
        id = "arg_"..num.."_string",
        width = 267,
        height = 20,
        value = arg_val(arg, "def"),
        tooltip = arg_val(arg, "tip"),
      } 
    end     

    -- Create output button
    if arg_type(arg) == "output" then
      output_file[num] = nil -- Clear any existing variable
      control_ids[#control_ids+1] = "arg_"..num.."_output" -- Log the id for later removal 
      output_button = vb:button {
        id = "arg_"..num.."_output",
        width = 20,
        height = 20,
        active = true,
        text = "→",
        tooltip = arg_val(arg, "tip"),       
        notifier = function()
          local path = renoise.app():prompt_for_filename_to_write(filetypes.output(arg.output), "Set output file name and location")
          output_file_switch(path, true, num)
        end
      }
    end        
    
    -- Add the controls
    if label ~= nil then arg_row:add_child(label) end
    if ins_select ~= nil then arg_row:add_child(ins_select) end
    if smp_select ~= nil then arg_row:add_child(smp_select) end
    if checkbox ~= nil then arg_row:add_child(checkbox) end
    if input_button ~= nil then arg_row:add_child(input_button) end
    if slider ~= nil then arg_row:add_child(slider) end
    if value_field ~= nil then arg_row:add_child(value_field) end
    if string_field ~= nil then arg_row:add_child(string_field) end
    if output_button ~= nil then arg_row:add_child(output_button) end
    
    return arg_row  
  end

  ----------------------------------------------------------------------------------------------

  -- Function to build arguments sliders
  local function build_args_column(dsp_preset)
    local args_col = vb:column { margin = 8, style = 'group' }
        
    -- Add command description if it exists
    if dsp[dsp_preset]["cmds"].tip ~= nil then
      local cmd_tip = vb:multiline_text {
        width = 418,
        height = 60,
        text = dsp[dsp_preset]["cmds"].tip   
      }   
      args_col:add_child(cmd_tip)
      args_col:add_child(vb:space { height = 8 })
    end
                      
    -- Loop through main arguments and add to GUI
    local args_container = vb:column { margin = 4 }
    for arg = 1, table.count(dsp[dsp_preset])-1 do
      local row = build_arg_params_row(dsp[dsp_preset]["arg"..arg], arg)        
      args_container:add_child(row)    
    end
    args_col:add_child(args_container)
              
    -- Add PVOC sliders if required
    if (preset_type(dsp[dsp_preset]) == "pvoc") or (preset_type(dsp[dsp_preset]) == "getpitch") then      
      local pvoc_container = vb:column { margin = 4, style = 'panel' }
      pvoc_container:add_child(vb:text { width = 410, text = "PVOC Analysis Settings", font = "mono", align = "center" })
      for arg = 1, 2 do
        local row = build_arg_params_row(pvoc_params["arg"..arg], "pvoc"..arg)        
        pvoc_container:add_child(row)    
      end
      args_col:add_child(vb:space { height = 2 })     
      args_col:add_child(pvoc_container)
    end

    -- Add RePitch sliders if required
    if preset_type(dsp[dsp_preset]) == "getpitch" then
      local getpitch_container = vb:column { margin = 4, style = 'panel' }
      getpitch_container:add_child(vb:text { width = 410, text = "GetPitch Extraction Settings", font = "mono", align = "center" })   
      for arg = 1, 8 do
        local row = build_arg_params_row(repitch_params["arg"..arg], "getpitch"..arg)        
        getpitch_container:add_child(row)    
      end
      args_col:add_child(vb:space { height = 4 })     
      args_col:add_child(getpitch_container)      
    end
    
    --[[
    -- Add dry wet controls
    local balance_container = vb:column { margin = 4, style = 'panel' }
    balance_container:add_child(vb:text { width = 410, text = "Dry/Wet", font = "mono", align = "center" })   
    for arg = 1, 1 do
      local row = build_arg_params_row(balance_params["arg"..arg], "balance"..arg)        
      balance_container:add_child(row)    
    end
    args_col:add_child(vb:space { height = 4 })     
    args_col:add_child(balance_container)     
    --]]
                        
    return args_col 
  end
  
  ----------------------------------------------------------------------------------------------
  
  -- The content column, contains everything.
  local content = vb:column { margin = 10, spacing = 8 }

  -- DSP Selector    
  local selector_row = vb:row {     
    
    -- Title
    vb:text {
      text = "EXE Filter ",
      --font = "bold"
    },
    
    --vb:space { width = 2 },
    
    -- Filter popup
    vb:popup {
      id = "cmd_select",
      width = 80,
      value = 1,
      items = exe_list,
      notifier = function(value)       
        filter_presets(exe_list[value]) -- Get a filtered preset list
        vb.views["dsp_select"].items = dsp_presets 
        vb.views["dsp_select"].value = 1
        -- From preset popup function
        content:remove_child(arguments_column) -- Clear previous argument sliders             
        for id = 1, #control_ids do -- Remove any previous vb id'd
          vb.views[control_ids[id]] = nil
        end
        arguments_column = build_args_column(dsp_presets[1]) -- Generate new argument sliders based on selected preset
        update_process_url(dsp_presets[1]) -- Update process docs url
        content:add_child(arguments_column) -- Add new argument sliders
      end
    },
        
    -- Preset popup
    vb:popup {
      id = "dsp_select",
      width = 190,
      value = 1,
      items = dsp_presets,
      notifier = function(value)        
        content:remove_child(arguments_column) -- Clear previous argument sliders             
        for id = 1, #control_ids do -- Remove any previous vb id'd
          vb.views[control_ids[id]] = nil
        end
        
        -- Close breakpoint editor if open
        if (brk_dialog and brk_dialog.visible) then
          brk_dialog:close()
        end
        
        -- Generate new GUI
        arguments_column = build_args_column(dsp_presets[value]) -- Generate new argument sliders based on selected preset
        update_process_url(dsp_presets[value]) -- Update process docs url
        content:add_child(arguments_column) -- Add new argument sliders
      end
    },
     
    
    ----------------------------------------------------------------------------------------------
    
    -- Open online docs
    vb:button {
      text = "?",
      tooltip = "Open the CDP function reference in a browser",
        notifier = function()          
          
          if os.platform() == "WINDOWS" then
            os.execute("start "..process_url)
          elseif os.platform() == "MACINTOSH" then  
            os.execute("open "..process_url)
          elseif os.platform() == "LINUX" then
            os.execute("xdg-open "..process_url)
          end
          --renoise.app():open_url(process_url) -- Doesn't work on URL's containing #
            
      end
    },
        
    --vb:space { width = 4 },   
    
    ----------------------------------------------------------------------------------------------
   
    -- GUI Refresh
    vb:button {
      text = "↻",
      tooltip = "Recalculate GUI slider ranges",
       
      notifier = function()
        content:remove_child(arguments_column) -- Clear previous argument sliders             
        for id = 1, #control_ids do -- Remove any previous vb id'd
          vb.views[control_ids[id]] = nil
        end
    
        -- Close breakpoint editor if open
        if (brk_dialog and brk_dialog.visible) then
          brk_dialog:close()
        end
        
        -- Recalculate presets ranges
        dofile("definitions.lua")
        --[[
        if (io.exists(path.."user_definitions.lua")) then
          dofile(path.."user_definitions.lua")
        end
        --]]
    
        -- Generate new GUI
        arguments_column = build_args_column(dsp_presets[vb.views["dsp_select"].value]) -- Generate new argument sliders based on selected preset
        content:add_child(arguments_column) -- Add new argument sliders
      end
    },
        
    --vb:space { width = 4 },

    ----------------------------------------------------------------------------------------------    
    
    -- Process button
    vb:button {
      text = "Process",
      width = 73,
     
      notifier = function()
                                                          
        local preset = vb.views["dsp_select"].value
        local settings = dsp[dsp_presets[preset]]          
        
        -- Function to build command arguments table                    
        local function build_argument(settings, num_args, id)           
          local args = {}
          -- Get argument values from GUI
          for arg_num = 1, num_args do
            local type = arg_type(settings["arg"..arg_num])
            if type == "value" then                
              args[arg_num] = vb.views["arg_"..id..arg_num.."_slider"].value
            elseif type == "string" then
              args[arg_num] = vb.views["arg_"..id..arg_num.."_string"].value            
            elseif type == "switchvalue" then              
              if vb.views["arg_"..id..arg_num.."_switch"].value == true then               
                args[arg_num] = settings["arg"..arg_num].switch..vb.views["arg_"..id..arg_num.."_slider"].value
              else
                args[arg_num] = ""
              end                
            elseif type == "switch" then              
              if vb.views["arg_"..id..arg_num.."_switch"].value == true then 
                args[arg_num] = settings["arg"..arg_num].switch 
              else
                args[arg_num] = ""
              end            
            elseif type == "valuevariable" then
              if input_file[arg_num] ~= nil then
                args[arg_num] = input_file[arg_num]
              else
                args[arg_num] = vb.views["arg_"..id..arg_num.."_slider"].value
              end
            elseif type == "switchvaluevariable" then
              if vb.views["arg_"..id..arg_num.."_switch"].value == true then
                if input_file[arg_num] ~= nil then
                  args[arg_num] = settings["arg"..arg_num].switch..input_file[arg_num]
                else
                  args[arg_num] = settings["arg"..arg_num].switch..vb.views["arg_"..id..arg_num.."_slider"].value
                end  
              else
                args[arg_num] = ""
              end
            elseif (type == "switchdata") or (type == "switchtext") then 
              if vb.views["arg_"..id..arg_num.."_switch"].value == true then
                if input_file[arg_num] ~= nil then
                  args[arg_num] = settings["arg"..arg_num].switch..input_file[arg_num]
                else
                  local path = renoise.app():prompt_for_filename_to_read(filetypes.input(settings["arg"..arg_num].input), "Select input file")
                  if path == nil then break end
                  path = '"'..path..'"' -- In case path has spaces in it
                  args[arg_num] = settings["arg"..arg_num].switch..path
                end  
              else
                args[arg_num] = ""
              end              
            elseif type == "text" then
              if input_file[arg_num] ~= nil then
                args[arg_num] = input_file[arg_num]
              else
                local path = renoise.app():prompt_for_filename_to_read(filetypes.input(settings["arg"..arg_num].input), "Select input file")
                if path == nil then break end
                path = '"'..path..'"' -- In case path has spaces in it
                args[arg_num] = path
              end
            elseif type == "in_frq" then 
              if input_file[arg_num] ~= nil then
                args[arg_num] = input_file[arg_num] -- If a file has been imported go with that
              else -- Get sound from ins/sample selector
                local sound = {}
                sound.type = type
                sound.ins = vb.views["arg_"..arg_num.."_ins_select"].value 
                sound.smp = vb.views["arg_"..arg_num.."_smp_select"].value
                args[arg_num] = sound                              
              end                 
            elseif type == "input" then
              if input_file[arg_num] == nil then -- Ask for input file if not already specified
                local path = renoise.app():prompt_for_filename_to_read(filetypes.input(settings["arg"..arg_num].input), "Select input file")
                if path == nil then break end
                path = '"'..path..'"' -- In case path has spaces in it
                args[arg_num] = path
              else  
                args[arg_num] = input_file[arg_num]
              end
            elseif type == "output" then
              local path = output_file[arg_num]
              if path == nil then -- Ask for output path if not already specified
                path = renoise.app():prompt_for_filename_to_write(filetypes.output(settings["arg"..arg_num].output), "Set output file name and location")
                if path == nil then break end -- If cancel is pressed
              end
              os.remove(path) -- Remove file if it already exists (enables overwriting on file)
              path = '"'..path..'"' -- In case path has spaces in it
              args[arg_num] = path
            elseif (type == "in_wav") or (type == "out_wav") or (type == "in_ana") or (type == "out_ana") then
              local sound = {}
              sound.type = type
              sound.ins = vb.views["arg_"..arg_num.."_ins_select"].value 
              sound.smp = vb.views["arg_"..arg_num.."_smp_select"].value
              args[arg_num] = sound
            end
          end                        
          return args
        end
              
        ----------------------------------------------------------------------------------------------
                  
        local command = build_command(settings.cmds.exe, settings.cmds.mode)
        local argument = build_argument(settings, table.count(settings)-1, "") -- Construct main argument string
        
        local pvoc = {}
        pvoc.anal_command = build_command("pvoc", "anal 1")
        pvoc.synth_command = build_command("pvoc", "synth")                    
        if (preset_type(settings) == "pvoc") or (preset_type(settings) == "getpitch") then
          pvoc.argument = build_argument(pvoc_params, 2, "pvoc")
        end
        
        local getpitch = {}
        getpitch.command = build_command("repitch", "getpitch 1")                   
        if (preset_type(settings) == "getpitch") then
          getpitch.argument = build_argument(repitch_params, 8, "getpitch")
        end
                
        local channels = "mono"
        if settings.cmds.channels ~= nil then channels = settings.cmds.channels end
        
        housekeep_c2 = build_command("housekeep", "chans 2")
        housekeep_c4 = build_command("housekeep", "chans 4")
        housekeep_c5 = build_command("housekeep", "chans 5")
        submix = build_command("submix", "interleave")
          
        --[[      
        print("Command: ")                                      
        rprint(command)
        print("---------")
        
        print("Argument: ")                                      
        rprint(argument)
        print("---------")
        
        print("PVOC: ")                                      
        rprint(pvoc)
        print("---------")
        
        print("Getpitch: ")                                      
        rprint(getpitch)
        print("---------")
        
        print("Channels: ")                                      
        rprint(channels)
        print("---------")
        --]]                                      
                                              
        run_process(command, argument, pvoc, getpitch, channels)          
      end
    }         
  } -- End row
  
  ----------------------------------------------------------------------------------------------
  
  -- Display for terminal output
  local terminal_row = vb:row {   
    vb:multiline_text {
      id = "terminal_output",
      style = "border",
      width = 434,
      height = 100,
      font = "mono",
      text = ":Terminal Output:"  
    }    
  }

  ----------------------------------------------------------------------------------------------
          
  -- Add items to view for initial launch
  content:add_child(selector_row)
  content:add_child(terminal_row)
  arguments_column = build_args_column(dsp_presets[1])
  update_process_url(dsp_presets[1])  
  content:add_child(arguments_column) 
  
     
  -- Key passthrough function
  local function keyhandler(dialog, key)
    return key
  end
      
  -- Displays a user designed layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name.." v"..tool_version, content, keyhandler)      

end

----------------------------------------------------------------------------------------------

local function start_tool()
  
  -- Check a sample is selected
  local error_msg = "Select a sample before running this tool"
  if renoise.song().selected_sample ~= nil then
    if renoise.song().selected_sample.sample_buffer.has_sample_data ~= false then
      show_dialog()
    else
      renoise.app():show_error(error_msg)
    end   
  else
    renoise.app():show_error(error_msg)     
  end
  
end 



--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = start_tool  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = start_tool
}


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
