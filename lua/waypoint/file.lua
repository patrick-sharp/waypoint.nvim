local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local highlight = require("waypoint.highlight")

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
    waypoint.extmark_id = nil
    waypoint.line_number = extmark[1]
  end

  local data = vim.json.encode(state_copy)
  return data
end

function M.save()
  if #state.waypoints == 0 then
    return
  end
  local data = encode()
  write_file(config.file, data)
end

function M.load()
  local data = read_file(config.file)
  if data == nil then return end
  local decoded = vim.json.decode(data)
  -- before we load in the waypoints in from a file, delete the current ones.
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    vim.api.nvim_buf_del_extmark(bufnr, constants.ns, waypoint.extmark_id)
  end
  for _,waypoint in pairs(decoded.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    if bufnr == -1 then
      bufnr = vim.fn.bufadd(waypoint.filepath)
      vim.fn.bufload(bufnr)
      -- without this, vim won't apply syntax highlighting to the new buffer
      vim.api.nvim_exec_autocmds("BufRead", { buffer = bufnr })
      vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
      -- vim.treesitter.highlighter._on_win(nil, nil, bufnr, -1, -1)

      -- vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
      -- vim.treesitter.start(bufnr, 'markdown')
      -- vim.treesitter.start(bufnr)

      -- do
      --   vim.api.nvim_create_autocmd("FileType", {
      --     pattern = "markdown",
      --     callback = function()
      --         pcall(vim.treesitter.start)
      --     end
      --   })
      --
      --   vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
      -- end

      -- do
      --   -- Step 2: Set the filetype (important for Treesitter to know which parser to use)
      --   vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown') -- Adjust filetype as needed
      --   -- Step 3: Read the file content if needed
      --   vim.api.nvim_buf_call(bufnr, function()
      --     vim.cmd('silent! edit')  -- This loads file content without switching to it
      --   end)
      --   -- Step 4: Start Treesitter parser
      --   -- vim.treesitter.start(bufnr, 'markdown')  -- Specify language explicitly
      --   local parser = vim.treesitter.get_parser(bufnr, 'markdown')
      --   parser:parse() -- Force initial parse
      --
      --   -- Step 5: Create and attach highlighter manually
      --   local highlighter = vim.treesitter.highlighter.new(parser)
      --     vim.api.nvim_buf_call(bufnr, function()
      --     -- This executes in the buffer context
      --     highlighter:highlight(0, -1)
      --   end)
      -- end

    end
    local line_nr = waypoint.line_number
    local virt_text = nil
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
  end

  highlight.highlight_custom_groups()

  for k,v in pairs(decoded) do
    state[k] = v
  end
end

return M
