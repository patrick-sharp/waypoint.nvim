local p = require("waypoint.print")

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
  if not t then return nil end

  local cur = t
  for _, k in ipairs(keys) do
    if not cur[k] then return nil end
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
---@param str string
---@return integer
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
--- @return integer # the sum of the absolute differences between the rgb values of the hl_groups' background colors
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
--- @param t                       table
--- @param schema                  table
--- @param forbid_extra_properties boolean
--- @return boolean, any, any, string whether it matches, the first non-matching key, the first non-matching value, and the expected type
function M.validate(t, schema, forbid_extra_properties)
  if forbid_extra_properties then
    for k,v in pairs(t) do
      if schema[k] == nil then
        return false, k, v, "nil"
      end
    end
  end
  -- check that each property in t matches the schema
  for k,v in pairs(schema) do
    if type(v) == "string" then
      if (type(t[k]) ~= v) then
        return false, k, type(t[k]), v
      end
    elseif type(v) == "table" then
      local success, k_, v_, expected = M.validate(t[k], v, forbid_extra_properties)
      if not success then
        return false, k_, v_, expected
      end
    else
      return false, nil, nil, ""
    end
  end
  return true, nil, nil, ""
end

function M.file_exists(file_path)
  local f = io.open(file_path)
  if f then
    f:close()
  end
  return f ~= nil
end

function M.split(str, pattern)
  local result = {}
  local front = 1
  local back, pattern_back = string.find(str, pattern)
  while back do
    table.insert(result, string.sub(str, front, back - 1))
    front = pattern_back + 1
    back, pattern_back = string.find(str, pattern, front)
  end
  if front <= #str then
    table.insert(result, string.sub(str, front))
  end

  return result
end

---@param t string[]
---@param keybinding string | string[]
function M.add_stringifed_keybindings_to_table(t, keybinding)
  if type(keybinding) == "string" then
    table.insert(t, keybinding)
  else
    for i, kb in ipairs(keybinding) do
      if i ~= 1 then
        table.insert(t, " or ")
      end
      table.insert(t, kb)
    end
  end
end

---@param t table
function M.len(t)
  local count = 0
  for _,_ in pairs(t) do
    count = count + 1
  end
  return count
end

-- checks for truthy values in table
---@param t table
function M.any(t)
  for _,v in ipairs(t) do
    if v then return v end
  end
  return false
end

-- checks for falsy values in table.
-- return false for empty table, because a table full of nils is considered empty.
---@param t table
function M.all(t)
  if #t == 0 then return false end
  for _,v in ipairs(t) do
    if not v then return v end
  end
  return true
end

---@param bufnr integer
---@return boolean
function M.is_buffer_valid(bufnr)
  return vim.fn.bufloaded(bufnr) ~= 0
end

---@param absolute_path string
---@return string
function M.relative_path(absolute_path)
  return vim.fn.fnamemodify(absolute_path, ":.")
end

---@param bufnr integer
---@return string
function M.buf_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return vim.fn.fnamemodify(path, ":.")
end
return M
