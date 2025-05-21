local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local highlight = require("waypoint.highlight")
local pretty = require "waypoint.prettyjson"
local p = require "waypoint.print"

local function write_file(path, content)
  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions
  local fd = uv.fs_open(path, "w", 438)  -- 438 is octal 0666
  assert(fd)
  local stat = uv.fs_fstat(fd)
  assert(stat)
  vim.uv.fs_write(fd, content, -1)
  uv.fs_close(fd)
end


local function read_file(path)
  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions
  local fd = uv.fs_open(path, "r", 438)  -- 438 is octal 0666
  if fd == nil then return nil end
  local stat = uv.fs_fstat(fd)
  assert(stat)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  assert(data)
  return data
end

local function encode()
  local state_copy = u.deep_copy(state)
  for _, waypoint in pairs(state_copy.waypoints) do
    local extmark = uw.extmark_for_waypoint(waypoint)
    -- extmarks don't persist between sessions, so clear this information
    waypoint.extmark_id = nil
    waypoint.extmark_bufnr = nil
    waypoint.line_number = extmark[1]
  end

  local data = pretty(state_copy)
  return data
end

function M.save()
  if #state.waypoints == 0 then
    return
  end
  local data = encode()
  write_file(config.file, data)
end

-- loads the buffer (so its text can be accessed) and triggers syntax
-- highlighting for the buffer
local function buffer_init(bufnr)
  vim.fn.bufload(bufnr)
  -- without this, vim won't apply syntax highlighting to the new buffer
  vim.api.nvim_exec_autocmds("BufRead", { buffer = bufnr })
  vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)

  -- these few lines force treesitter to highlight the buffer even though it's not in an open window
  local buf_highlighter = vim.treesitter.highlighter.active[bufnr]
  if buf_highlighter then
    -- one-indexed
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    -- seems to work with marks even at end of files, so topline must be an
    -- inclusive zero-indexed bound
    buf_highlighter._on_win(nil, nil, bufnr, 0, line_count - 1)
  end
end

local file_schema = {
  waypoints = "table",
  wpi = "integer",
  show_annotation = "boolean",
  show_path = "boolean",
  show_full_path = "boolean",
  show_line_num = "boolean",
  show_file_text = "boolean",
  show_context = "boolean",
  after_context = "integer",
  before_context = "integer",
  context = "integer",
  view = {
    lnum = "integer",
    col = "integer",
    leftcol = "integer",
  },
}

function M.load()
  local data = read_file(config.file)
  if data == nil then return end
  local decoded = vim.json.decode(data)
  local is_valid, k, v = u.validate(decoded, file_schema)
  if not is_valid then
    state.load_error = table.concat({
      "Error loading waypoints from file: expected value of type ",
      tostring(file_schema[k]),
      " for key ", tostring(k),
      ", but received ", tostring(v), "."
    })
    print(state.load_error)
    return
  end

  -- before we load in the waypoints in from a file, delete the current ones.
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    vim.api.nvim_buf_del_extmark(bufnr, constants.ns, waypoint.extmark_id)
  end
  for _,waypoint in pairs(decoded.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    if bufnr == -1 then
      -- TODO: check if file even exists
      bufnr = vim.fn.bufadd(waypoint.filepath)
    end
    buffer_init(bufnr)
    -- zero-indexed line number
    local line_nr = waypoint.line_number
    local virt_text = nil

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_nr < line_count then
      local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.ns, line_nr, -1, {
        id = line_nr + 1,
        sign_text = config.mark_char,
        priority = 1,
        sign_hl_group = constants.hl_sign,
        virt_text = virt_text,
        virt_text_pos = "eol",  -- Position at end of line
      })
      waypoint.line_number = nil
      waypoint.extmark_id = extmark_id
    else
      -- TODO: handle errors in such a way that the user can go check them out later
      -- keep in mind that if we get here, then waypoint won't start correctly.
      -- this is more a message for me to debug than anything else
      print("line " .. line_nr + 1 .. " out of bounds for " .. waypoint.filepath .. " bufnr " .. bufnr .. " with line count " .. line_count)
    end
  end

  highlight.highlight_custom_groups()

  for k,v in pairs(decoded) do
    state[k] = v
  end
end

return M
