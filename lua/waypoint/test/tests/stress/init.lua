-- Load test for huge amounts of highlighting and waypoints

local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local crud = require"waypoint.waypoint_crud"
local file = require"waypoint.file"
local floating_window = require"waypoint.floating_window"
local state = require"waypoint.state"
local Timer = require"waypoint.timer"
local u = require"waypoint.util"

local function assert_fast(expected, actual)
  assert(actual <= expected, "draw was too slow (" .. actual .. " > " .. expected .. "ms)")
end

describe('Stress', function()
  local total_lines = 1000000
  local lines_between_waypoints = 1000

  local lines = {}
  local function add_line(str)
    lines[#lines+1] = str
  end

  state.should_notify = false

  for _=1,total_lines do
    add_line("Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
  end

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(bufnr)

  local line = 1
  while line <= total_lines do
    u.goto_line(line)
    crud.append_waypoint_wrapper()
    line = line + lines_between_waypoints
  end

  local ms

  ms = 15
  local timer = Timer.start()
  floating_window.open()
  floating_window.close()

  assert_fast(ms, timer:stop())

  ms = 50
  state.context = 10
  timer:reset()
  floating_window.open()
  floating_window.close()
  assert_fast(ms, timer:stop())
end, true)

describe('Stress syntax', function()
  local total_lines = 50000
  local lines_between_waypoints = 1000

  local lines = {}
  local function add_line(str)
    lines[#lines+1] = str
  end

  local section_nested_scopes_start = 1
  local section_nested_scopes_end = math.floor(total_lines / 3)
  if section_nested_scopes_end % 2 == 1 then
    section_nested_scopes_end = section_nested_scopes_end - 1
  end

  local section_giant_table_start = section_nested_scopes_end + 1
  local section_giant_table_end = section_giant_table_start + math.floor(total_lines / 3)

  local nesting_level = 32
  local num_outer = math.floor((section_nested_scopes_end - section_nested_scopes_start) / (nesting_level * 2 + 1))
  local outer_end = 1 + num_outer * nesting_level + 1

  -- generate deeply nested scopes
  add_line("-- Section: Nested Scopes")
  for _ = 1, num_outer do
    for j = 1, nesting_level do
      add_line(string.rep(" ", j - 1) .. "do -- " .. j)
    end
    add_line(string.rep(" ", nesting_level) .. "local leaf_node = 'leaf'")
    for j = 1, nesting_level do
      add_line(string.rep(" ", nesting_level - j) .. "end -- " .. nesting_level - j + 1)
    end
  end

  for _ = outer_end + 1, section_nested_scopes_end do
    add_line("-- blank")
  end

  -- generate massive table constructors
  add_line("local giant_table = {")
  while #lines < section_giant_table_end do
    local format_string = "  ['key_%d'] = { val = %d, fn = function(x) return x + %d end },"
    add_line(string.format(format_string, #lines, #lines, math.random(100)))
  end
  add_line("}")

  -- high-complexity logic mix
  add_line("local function complex_logic(...)")
  while #lines < total_lines do
    local r = math.random(1, 3)
    if r == 1 then
      add_line("  if (math.sin(os.time()) > 0.5) then print('branch') else local x = 1 end")
    elseif r == 2 then
      add_line("  for i=1, 10 do (function(v) return v*v end)(i) end")
    else
      add_line("  local co = coroutine.wrap(function() coroutine.yield(true) end)")
    end
  end
  add_line("end")

  -- create the buffer
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
  vim.api.nvim_set_option_value("syntax", "lua", { buf = bufnr })
  file.buffer_init(bufnr)

  -- I don't know if this is actually necessary
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end
  vim.api.nvim_set_current_buf(bufnr)

  -- uncomment this to make this test fast. it disables syntax highlighting on the new buffer so the treesitter highlight grabber won't run
  -- vim.api.nvim_set_option_value("filetype", "text", { buf = bufnr })
  -- vim.api.nvim_set_option_value("syntax", "text", { buf = bufnr })


  local line = 1
  while line <= total_lines do
    u.goto_line(line)
    crud.append_waypoint_wrapper()
    line = line + lines_between_waypoints
  end

  local ms

  -- getting highlights from treesitter means this can be slow
  ms = 150
  local timer = Timer.start()
  floating_window.open()
  floating_window.close()
  assert_fast(ms, timer:stop())

  ms = 150
  state.context = 28
  timer:reset()
  floating_window.open()
  floating_window.close()
  assert_fast(ms, timer:stop())
end, true)
