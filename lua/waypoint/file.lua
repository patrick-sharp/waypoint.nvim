local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local utils = require("waypoint.utils")

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
  local state_copy = utils.deep_copy(state)
  for _, waypoint in pairs(state_copy.waypoints) do
    local extmark = utils.extmark_for_waypoint(waypoint)
    waypoint.extmark_id = nil
    waypoint.line_number = extmark[1]
  end

  local data = vim.json.encode(state_copy)
  return data
end

function M.save()
  local data = encode()
  write_file(config.file, data)
end

function M.load()
  local data = read_file(config.file)
  if data == nil then return end
  local decoded = vim.json.decode(data)
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    vim.api.nvim_buf_del_extmark(bufnr, constants.ns, waypoint.extmark_id)
  end
  for _,waypoint in pairs(decoded.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    if bufnr == -1 then
      bufnr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(bufnr, waypoint.filepath)
      vim.api.nvim_buf_call(bufnr, vim.cmd.edit)
    end
    local line_nr = waypoint.line_number
    local virt_text = nil
    if waypoint.annotation then
      virt_text = { {"  " .. waypoint.annotation, constants.hl_annotation} }
    end
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.ns, line_nr, -1, {
      id = line_nr + 1,
      sign_text = ">",
      priority = 1,
      sign_hl_group = constants.hl_sign,
      virt_text = virt_text,
      virt_text_pos = "eol",  -- Position at end of line
    })
    waypoint.line_number = nil
    waypoint.extmark_id = extmark_id
  end
  vim.cmd("highlight " .. constants.hl_sign .. " guifg=" .. config.sign_color .. " guibg=NONE")
  vim.cmd("highlight " .. constants.hl_annotation .. " guifg=" .. config.annotation_color .. " guibg=NONE")

  for k,v in pairs(decoded) do
    state[k] = v
  end
end

return M
