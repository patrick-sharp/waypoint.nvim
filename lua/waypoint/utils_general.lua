local p = require ("waypoint.print")

local M = {}

--- @class waypoint.HighlightRange
--- col_start and col_end values are byte indexed because that's what 
--- nvim_buf_add_highlight uses. That is unlike state.view.col, which is column
--- index (i.e. it accounts for unicode chars being multiple bytes long).
--- @field nsid integer
--- @field hl_group string | integer   if the range comes from treesitter, it will be an id. If it comes from vanilla vim, it will be a name.
--- @field col_start integer one-indexed inclusive column start for highlight
--- @field col_end integer one-indexed inclusive column end for highlight

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


return M
