---@class TemplateModel
---@field line integer
---@field state string

---@type fun() : TemplateModel
local function TemplateModel()
  return {
    line = 0,
    state = "base"
  }
end

---@type table <string, UpdateKeys<TemplateModel>>
local updates = {
  base = {
    left = function(m)
      return m
    end,
    right = function (m)
      return m
    end,
    up = function (m)
      return m
    end,
    down = function (m)
      return m
    end,
    back = function(m)
      return m
    end
  },
  shift = {
    left = function(m)
      return m
    end,
    right = function (m)
      return m
    end,
    up = function (m)
      return m
    end,
    down = function (m)
      return m
    end,
    back = function(m)
      return m
    end
  }

}

---@type fun(s:renoise.Song, m : TemplateModel)
local function apply(s, m)
end

---@type PadInit<TemplateModel>
local function init(s)
  local  model = TemplateModel()
  model.line = s.selected_line_index
  return model
end

---@type PadUpdate<TemplateModel>
local function update(s, m, e)
  if e.modifiers == "shift" then 
    m.state = "shift"
  else
    m.state = "base"
  end

  if updates[m.state] then
    if updates[m.state][e.name] then
      m = updates[m.state][e.name](m)
      apply(s, m)
      return {PadMessage.model, m}
    end
  end
  if e.name == "return" then
    return {PadMessage.close, m}
  else
    return {PadMessage.ignore}
  end
end

---@type PadView<TemplateModel>
local function view(s, vb, m)
  local v = vb:column{
    height = 200,
  }
  return v
end

---@type PadModule<TemplateModel>
TemplatePad = {
  update = update,
  init = init,
  view = view
}