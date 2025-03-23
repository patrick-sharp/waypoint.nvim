local M = {}

local state = require("waypoint.state")
local constants = require("waypoint.constants")

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

  -- figure out how each line is highlighted
  --- @type table<table<<HighlightRange>>
  local hlranges = {}
  local treesitter = false
  local nohighlight = false
  if #vim.treesitter.highlighter.active > 0 then
    print("UNFINISHED")
    treesitter = true
  elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
    for i,line in pairs(lines) do
      local line_hlranges = {}
      local synstack = vim.fn.synstack(i + start_line_nr_i0, 1)
      local synid = nil
      local name = nil
      local curr = nil
      if #synstack > 0 then
        synid = synstack[#synstack]
        name = vim.fn.synIDattr(synid, "name")
        curr = {
          nsid = 0,
          name = name,
          col_start = 1,
          col_end = -1,
        }
      end
      for col=2,#line do
        synstack = vim.fn.synstack(i + start_line_nr_i0, col)
        if #synstack > 0 then
          synid = synstack[#synstack]
          name = vim.fn.synIDattr(synid, "name")
          if not curr then
            curr = {
              nsid = 0,
              name = name,
              col_start = col,
              col_end = -1,
            }
          end
          if curr and name == curr.name  then
            curr.col_end = col
          end
        else
          if curr then
            table.insert(line_hlranges, curr)
          end
        end
      end
      table.insert(line_hlranges, curr)
      table.insert(hlranges, line_hlranges)
    end
  else
    nohighlight = true
  end

  assert(#lines == #hlranges or treesitter or nohighlight, "#lines == " .. #lines ..", #hlranges == " .. #hlranges .. ", but they should be the same" )
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


--- @param t table<table<string>>
--- @param table_cell_types table<string>
--- @param highlights table<table<string | table<HighlightRange>>>   rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
--- @return table<string>
function M.align_table(t, table_cell_types, highlights)
  if #t == 0 then
    return {}
  end
  assert(#t == #highlights, "#t == " .. #t ..", #highlights == " .. #highlights .. ", but they should be the same" )
  local nrows = #t
  local ncols = #t[1]

  -- figure out how wide each table column is
  local widths = {}
  local byte_widths = {}
  for i=1,ncols do
    local max_width = 0
    local max_byte_width = 0
    for j=1,nrows do
      if t[j] ~= "" then
        local field = t[j][i]
        if field == nil then
          M.p(t[j])
        end
        max_width = math.max(vim.fn.strchars(field), max_width)
        max_byte_width = math.max(#field, max_width)
      end
    end
    table.insert(widths, max_width)
    table.insert(byte_widths, max_byte_width)
  end

  -- now that we know how wide each table is, we can figure out how the 
  -- highlight groups of each line will be adjusted
  for i,row_highlights in pairs(highlights) do
    local offset = 0 -- how much to add to col_start and col_end
    for j,col_highlights in pairs(row_highlights) do
      if type(col_highlights) == "string" then
        row_highlights[j] = {{
          nsid = constants.ns,
          name = col_highlights,
          col_start = offset,
          col_end = offset + byte_widths[j],
        }}
      else
        for _,hlrange in pairs(col_highlights) do
          hlrange.col_start = hlrange.col_start + offset
          hlrange.col_end = hlrange.col_start + offset + byte_widths[j]
        end
      end
      offset = offset + #constants.table_separator + byte_widths[j] + 2
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
          padded = string.rep(" ", widths[j] - vim.fn.strchars(field)) .. field
        else
          padded = field .. string.rep(" ", widths[j] - #field)
        end
        table.insert(fields, padded)
      end
      table.insert(result, table.concat(fields, " " .. constants.table_separator .. " "))
    end
  end
  return result
end

-- if this isn't true, then you shouldn't be able to put a waypoint in it
function M.is_file_buffer()
  return vim.bo.buftype == ""
end

return M
