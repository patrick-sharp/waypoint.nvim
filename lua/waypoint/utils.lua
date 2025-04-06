local M = {}

local state = require("waypoint.state")
local constants = require("waypoint.constants")
local treesitter_highlights = require("waypoint.highlight_treesitter")
local vanilla_highlights = require("waypoint.highlight_vanilla")

--- @class HighlightRange
--- col_start and col_end values are byte indexed because that's what 
--- nvim_buf_add_highlight uses. That is unlike state.view.col, which is column
--- index (i.e. it accounts for unicode chars being multiple bytes long).
--- @field nsid        integer
--- @field name        string 
--- @field col_start   integer
--- @field col_end     integer

local debug = true

function M.p(...)
  local args_table = { n = select('#', ...), ... }
  local inspected = {}
  for i=1, args_table.n do
    table.insert(inspected, vim.inspect(args_table[i]))
  end
  print(table.concat(inspected, " "))
end

local p = M.p

function M.log(...)
  if not debug then return end
  M.p(...)
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


function M.buf_find_waypoint(filepath, line_nr)
  local bufnr = vim.fn.bufnr(filepath)
  for i, waypoint in ipairs(state.waypoints) do
    if waypoint.filepath == filepath then
      local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
      local extmark_row = extmark[1] + 1 -- have to do this because extmark line numbers are 0 indexed
      if extmark_row == line_nr then
        return i
      end
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
--- @return { [1]: integer, [2]: integer }, table<string>, integer, integer, table<table<HighlightRange>>
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
    -- local finish_01 = vim.loop.hrtime()
    -- local finish_02 = vim.loop.hrtime()
    -- print("PERFfff:", (finish_02 - finish_01) / 1e6)

  -- figure out how each line is highlighted
  --- @type table<table<HighlightRange>>
  local hlranges = {}
  local treesitter = false
  local no_active_highlights = false

  local has_treesitter, ts_highlight = pcall(require("vim.treesitter.highlighter"))
  local file_uses_treesitter = has_treesitter and ts_highlight.active[bufnr]
  if file_uses_treesitter then
    print("UNFINISHED")
    treesitter = true
  elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
    hlranges = vanilla_highlights.get_vanilla_syntax_highlights(bufnr, lines, start_line_nr_i0)
  else
    no_active_highlights = true
  end

  assert(#lines == #hlranges or treesitter or no_active_highlights, "#lines == " .. #lines ..", #hlranges == " .. #hlranges .. ", but they should be the same" )
  return extmark, lines, marked_line_idx_0i, start_line_nr_i0, hlranges
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


--- @param t table<table<string>>
--- @param table_cell_types table<string>
--- @param highlights table<table<string | table<HighlightRange>>>   rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
--- @param win_width integer
--- @return table<string>
function M.align_table(t, table_cell_types, highlights, win_width)
  if #t == 0 then
    return {}
  end
  assert(#t == #highlights, "#t == " .. #t ..", #highlights == " .. #highlights .. ", but they should be the same" )
  local nrows = #t
  local ncols = #t[1]

  -- figure out how wide each table column is
  local widths = {}
  for i=1,ncols do
    local max_width = 0
    for j=1,nrows do
      if t[j] ~= "" then
        local field = t[j][i]
        if field == nil then
          M.p(t[j])
        end
        max_width = math.max(M.vislen(field), max_width)
      end
    end
    table.insert(widths, max_width)
  end

  -- now that we know how wide each table is, we can figure out how the 
  -- highlight groups of each line will be adjusted
  for i,row_highlights in pairs(highlights) do
    -- how much to add to col_start and col_end
    -- note that this is a byte offset, not a character offset
    local offset = 0
    for j,col_highlights in pairs(row_highlights) do
      local field = t[i][j]
      local padded_byte_length = widths[j] - M.vislen(field) + #field
      if type(col_highlights) == "string" then
        -- accounting for tabs and unicode characters
        row_highlights[j] = {{
          nsid = constants.ns,
          name = col_highlights,
          col_start = offset,
          col_end = offset + padded_byte_length
        }}
      else
        for _,hlrange in pairs(col_highlights) do
          hlrange.col_start = hlrange.col_start + offset - 1
          hlrange.col_end = hlrange.col_end + offset
        end
      end
      -- the extra 2 for the spaces on either side of the table separator
      offset = offset + padded_byte_length + #constants.table_separator + 2
    end
  end

  local result = {}
  for i=1,nrows do
    if t[i] == "" then
      table.insert(result, "")
    else
      local fields = {}
      assert(#table_cell_types == #t[i])
      for j=1,ncols do
        local field = t[i][j]
        local padded
        if table_cell_types[j] == "number" then
          padded = string.rep(" ", widths[j] - M.vislen(field)) .. field
        else
          local num_padding_spaces = widths[j] - M.vislen(field)
          padded = field .. string.rep(" ", num_padding_spaces)
        end
        table.insert(fields, padded)
      end
      table.insert(result, table.concat(fields, " " .. constants.table_separator .. " "))
      local row_len = M.vislen(result[#result])
      if row_len < win_width then
        local num_padding_spaces = win_width - row_len
        result[#result] = result[#result] .. string.rep(" ", num_padding_spaces)
      end
    end
  end
  return result
end

-- if this isn't true, then you shouldn't be able to put a waypoint in it
function M.is_file_buffer()
  return vim.bo.buftype == ""
end

return M
