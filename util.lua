---@generic T
---@param x T?
---@param v T
---@return T
function maybe_or(x, v)
  if x == nil then return v else return x end
end

function clamp(a, min, max)
  return math.min(math.max(min, a), max)
end

function sign(x)
  if x < 0 then
    return -1
  else
    return 1
  end
end

function hex(i)
  return ("%X"):format(i)
end

function inside_range(v, a, b)
  return v >= a and v <= b
end

local chars = {
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
}

local values = {
  ["0"] = 0,
  ["1"] = 1,
  ["2"] = 2,
  ["3"] = 3,
  ["4"] = 4,
  ["5"] = 5,
  ["6"] = 6,
  ["7"] = 7,
  ["8"] = 8,
  ["9"] = 9,
  ["A"] = 10,
  ["B"] = 11,
  ["C"] = 12,
  ["D"] = 13,
  ["E"] = 14,
  ["F"] = 15,
  ["G"] = 16,
  ["H"] = 17,
  ["I"] = 18,
  ["J"] = 19,
  ["K"] = 20,
  ["L"] = 21,
  ["M"] = 22,
  ["N"] = 23,
  ["O"] = 24,
  ["P"] = 25,
  ["Q"] = 26,
  ["R"] = 27,
  ["S"] = 28,
  ["T"] = 29,
  ["U"] = 30,
  ["V"] = 31,
  ["W"] = 32,
  ["X"] = 33,
  ["Y"] = 34,
  ["Z"] = 35,
}

function to_char(x)
  return chars[clamp(x + 1, 1, 36)]
end

function from_char(c)
  return values[c]
end

function string:split(s, separator)
  local a = {}
  for str in string.gmatch(s, "([^" .. separator .. "]+)") do
    table.insert(a, str)
  end
  return a
end

function table:index_of(t, v)
  for i, k in pairs(t) do
    if k == v then
      return i
    end
  end
  return -1
end

function table:find(t, matcher)
  for i, k in pairs(t) do
    if matcher(t[i]) then
      return i
    end
  end
  return nil
end

function table:map(t, f)
  local _t = {}
  for i, k in pairs(t) do
    _t[i] = f(k)
  end
  return _t
end
