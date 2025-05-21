local p = require ("waypoint.print")

local M = {}

--- @class waypoint.HighlightRange
--- col_start and col_end values are byte indexed because that's what 
--- nvim_buf_add_highlight uses. That is unlike state.view.col, which is column
--- index (i.e. it accounts for unicode chars being multiple bytes long).
--- @field nsid integer
--- @field hl_group string | integer   if the range comes from treesitter, it will be an id. If it comes from vanilla vim, it will be a name.
--- @field col_start integer one-indexed inclusive column start for highlight
--- @field col_end integer one-indexed inclusive column end for highlight.

function M.log(...)
  if not debug then return end
  p(...)
end

function M.get_in(t, keys)
  local cur = t
  for _, k in ipairs(keys) do
    if not cur[k] then
      return nil
    end
    cur = cur[k]
  end
  return cur
end


function M.set_in(t, keys, value)
  if #keys == 0 then
    return
  end

  local cur = t
  for i = 1, #keys - 1 do
    local k = keys[i]
    if not cur[k] then
      cur[k] = {}
    end
    cur = cur[k]
  end

  cur[keys[#keys]] = value
end


function M.delete_in(t, keys)
  if #keys == 0 then
    return
  end

  local cur = t
  for i = 1, #keys - 1 do
    local k = keys[i]
    if not cur[k] then
      return
    end
    cur = cur[k]
  end

  cur[keys[#keys]] = nil
end


function M.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


function M.deep_copy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[M.deep_copy(orig_key)] = M.deep_copy(orig_value)
    end
    setmetatable(copy, M.deep_copy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end


function M.clamp(x, min, max)
  if x < min then
    return min
  elseif max and x > max then
    return max
  end
  return x
end

-- length of the string as actually appears on screen.
-- takes tabs and unicode into account
function M.vislen(str)
  local num_tabs = 0
  for k = 1, #str do
    local char = str:sub(k, k)
    if char == "\t" then
      num_tabs = num_tabs + 1
    end
  end
  local strchars = vim.fn.strchars(str)
  return strchars + (vim.o.tabstop - 1) * num_tabs
end


-- if this isn't true, then you shouldn't be able to put a waypoint in it
function M.is_file_buffer()
  return vim.bo.buftype == ""
end


local function split_rgb(color)
  local red = math.floor(color / (256 * 256))
  local blue = math.floor(color / 256 % 256)
  local green = color % 256
  return red, green, blue
end

--- @param a string the first hl_group
--- @param b string the first hl_group
--- @return integer the sum of the absolute differences between the rgb values of the hl_groups' background colors
function M.hl_background_distance(a, b)
  local bg_a = vim.api.nvim_get_hl(0, {name = a, link = false}).bg
  local bg_b = vim.api.nvim_get_hl(0, {name = b, link = false}).bg

  bg_a = bg_a or 0
  bg_b = bg_b or 0

  local red_a, green_a, blue_a = split_rgb(bg_a)
  local red_b, green_b, blue_b = split_rgb(bg_b)

  -- this is a crude measure of how different the colors are.
  local red_distance = math.abs(red_a - red_b)
  local green_distance = math.abs(green_a - green_b)
  local blue_distance = math.abs(blue_a - blue_b)
  local distance = red_distance + green_distance + blue_distance
  return distance
end

-- NOTE: this does not handle unions (values that can have multiple types) or variable-length tables
---@return boolean, any, any whether it matches, the first non-matching key, and the first non-matching value
function M.validate(t, schema)
  -- check that no extra properties are in t
  for k,v in pairs(t) do
    if schema[k] == nil then
      return false, k, v
    end
  end
  -- check that each property in t matches the schema
  for k,v in pairs(schema) do
    if type(v) == "string" then
      if (type(t[k]) ~= v) then
        return k, type(t[k])
      end
    elseif type(v) == "table" then
      local success, k_, v_ = M.validate(t[k], v)
      if not success then
        return false, k_, v_
      end
    else
      return false, nil, nil
    end
  end
  return true, nil, nil
end

return M
