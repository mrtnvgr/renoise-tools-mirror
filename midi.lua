MidiType = {
  noteon = 8,
  noteoff = 9,
  aftertouch = 10,
  cc = 11,
  program = 12,
  pressure = 13,
  pitch = 14,
}

Midi = {
  name = nil,
  out = nil,
  inp = nil,
  message = nil,
  outputs = {},
  inputs = {},
}

---@alias MidiMsg {type:integer, channel:integer, note:integer, value:integer}

---@type fun(x:any|nil, d:any) : any
function table_contains(table, value)
  for i, v in ipairs(table) do
    if v == value then
      return i
    end
  end
  return 0
end

function refresh_io()
  Midi.outputs = renoise.Midi.available_output_devices()
  Midi.inputs = renoise.Midi.available_input_devices()
end

function on_device_change()
  refresh_io()
  if Midi.name then
    if not table_contains(Midi.outputs, Midi.name) then
      print("lost output "..Midi.name)
      -- Midi.inp:close()
    end
    if not table_contains(Midi.input, Midi.name) then
      print("lost input "..Midi.name)
      -- Midi.inp:close()
    end
  end 
  print("TODO midi changed!!!")
end

---@type fun(m:integer[]):MidiMsg
function midi_message(m)
  local status = string.format("%X", m[1])
  return {
    type = tonumber(status:sub(1,1), 16),
    channel = tonumber(status:sub(2,2), 16),
    note = m[2],
    value = m[3]
  }
end

---@type fun(device_name:string, on_message:fun(m:MidiMsg)):boolean
function connect_midi(device_name, on_message)
  refresh_io()
  rprint(Midi.inputs)
  rprint(Midi.outputs)
  if table_contains(Midi.inputs, device_name) > 0 then
    print("connected midi input on " .. device_name)
    Midi.on_message = function(m)
      -- rprint(midi_message(m))
      print("in------")
      rprint(m)
      on_message(midi_message(m))
    end
    Midi.inp = renoise.Midi.create_input_device(device_name, Midi.on_message)
    Midi.name = device_name
  end
  if table_contains(Midi.outputs, device_name) > 0 then
    print("connected midi output on " .. device_name)
    Midi.out = renoise.Midi.create_output_device(device_name)
    Midi.name = device_name
  end
  if Midi.name then 
    return true 
  else 
    return false 
  end
end

renoise.Midi.devices_changed_observable():add_notifier(on_device_change)


function midi(t, note, value, channel)
  if channel == nil then channel = 0 end
  return { tonumber(string.format("%X", t + 1) .. string.format("%X", channel), 16), note, value }
end


function new_grid(w, h)
  local g = {}
  for y = 1, h do
    local row = {}
    for x = 1, w do
      table.insert(row, 0)
    end
    table.insert(g, row)
  end
  return g
end


function new_leds(w, h)
  local ls = {
    buffer = new_grid(w, h),
    out = new_grid(w, h),
    dirty = false,
  }
  return ls
end


mapping = {
  { 32, 33, 34, 35, 36, 37, 38, 39 },
  { 24, 25, 26, 27, 28, 29, 30, 31 },
  { 16, 17, 18, 19, 20, 21, 22, 23 },
  { 8,  9,  10, 11, 12, 13, 14, 15 },
  { 0,  1,  2,  3,  4,  5,  6,  7  },
}

function note_to_grid(n)
  for y = 1, #mapping do
    for x = 1, #mapping[y] do
      if mapping[y][x] == n then return { x = x, y = y} end
    end
  end
  return nil
end

function update_leds(ls)
  if ls.dirty then
    ls.dirty = false
    for y = 1, #ls.buffer do
      for x = 1, #ls.buffer[y] do
        local l = ls.buffer[y][x]
        if l ~= ls.out[y][x] then
          ls.out[y][x] = l
          if Midi.name then
            local m = midi(MidiType.noteon, mapping[y][x], l)
            -- print("out ----")
            -- rprint(m)
            Midi.out:send(m)
          end
        end
      end
    end
  end
end