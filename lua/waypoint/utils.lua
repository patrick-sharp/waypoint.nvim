local M = {}

local state = require("waypoint.state")
local constants = require("waypoint.constants")

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


function M.buf_find_waypoint(line_nr)
  -- note that this is just for the current buffer
  local marks = vim.api.nvim_buf_get_extmarks(0, constants.ns, 0, -1, {})
  for i, mark in ipairs(marks) do
    local extmark_row = mark[2] + 1 -- have to do this because extmark line numbers are 0 indexed
    if extmark_row == line_nr then
      return i
    end
  end
  return -1
end

--- @param waypoint Waypoint
--- @return { [1]: integer, [2]: integer }
function M.extmark_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --- @type { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
  return extmark
end

--- @param waypoint Waypoint
--- @return { [1]: integer, [2]: integer }, table<string>, integer, integer
function M.extmark_lines_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --- @type { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})

  local extmark_line_nr_i0 = extmark[1]

  local start_line_nr_i0 = M.clamp(extmark[1] - state.context - state.before_context, 0)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local end_line_nr_i0 = M.clamp(extmark[1] + 1 + state.context + state.after_context, 0, line_count)

  local marked_line_idx_0i = extmark_line_nr_i0 - start_line_nr_i0
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line_nr_i0, end_line_nr_i0, false)
  return extmark, lines, marked_line_idx_0i, start_line_nr_i0
end


function M.clamp(x, min, max)
  if x < min then
    return min
  elseif max and x > max then
    return max
  end
  return x
end

--- @param t table<table<string>>
--- @return table<string>
function M.align_table(t)
  if #t == 0 then
    return {}
  end
  local nrows = #t
  local ncols = #t[1]

  local widths = {}
  for i=1,ncols do
    local max_width = 0
    for j=1,nrows do
      local field = t[j][i]
      if field == nil then
        print(vim.inspect(t[j]))
      end
      max_width = math.max(#field, max_width)
    end
    table.insert(widths, max_width)
  end

  local result = {}
  for i=1,nrows do
    local fields = {}
    for j=1,ncols do
      local field = t[i][j]
      local padded = field .. string.rep(" ", widths[j] - #field)
      table.insert(fields, padded)
    end
    table.insert(result, table.concat(fields, " | "))
  end
  return result
end


return M
