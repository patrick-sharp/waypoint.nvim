-- Load test for huge amounts of highlighting and waypoints

local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local crud = require"waypoint.waypoint_crud"
local file = require"waypoint.file"
local floating_window = require"waypoint.floating_window"
local state = require"waypoint.state"
local Timer = require"waypoint.timer"
local u = require"waypoint.utils"

describe('Stress', function()
  local total_lines = 1000000
  local lines_between_waypoints = 1000

  local lines = {}
  local function add_line(str)
    lines[#lines+1] = str
  end

  state.should_notify = false

  local timer = Timer.start()
  for _=1,total_lines do
    add_line("Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
  end

  u.log(timer:stop())

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(bufnr)

  timer:reset()
  local line = 1
  while line <= total_lines do
    u.goto_line(line)
    crud.append_waypoint_wrapper()
    line = line + lines_between_waypoints
  end
  u.log("append waypoints", timer:stop())

  u.log("<TRACKDATA>")
  for k,v in pairs(u.track_data) do
    u.log(k, v.total)
  end
  u.log("</TRACKDATA>")

  -- local timer = Timer.start()
  timer:reset()
  floating_window.open()
  floating_window.close()
  u.log("draw", timer:stop())

  state.context = 10
  timer:reset()
  floating_window.open()
  floating_window.close()
  u.log("draw with context 10", timer:stop())
end)

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

  -- 1. Generate Deeply Nested Scopes (The Stack Stressor)
  add_line("-- Section: Nested Scopes")
  for i = section_nested_scopes_start + 1, section_nested_scopes_end / 2 - 1 do
    add_line("do -- level " .. i)
  end
  add_line("  local leaf_node = 'bottom of the stack'")
  for i = section_nested_scopes_start + 1, section_nested_scopes_end / 2 - 1 do
    add_line("end -- " .. i)
  end

  -- 2. Generate Massive Table Constructors (The Memory Stressor)
  add_line("local giant_table = {")
  while #lines < section_giant_table_end do
    local format_string = "  ['key_%d'] = { val = %d, fn = function(x) return x + %d end },"
    add_line(string.format(format_string, #lines, #lines, math.random(100)))
  end
  add_line("}")

  -- 3. High-Complexity Logic Mix
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
  -- vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
  -- vim.api.nvim_set_option_value("syntax", "lua", { buf = bufnr })
  file.buffer_init(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  -- uncomment this to make this test fast
  -- vim.api.nvim_set_option_value("filetype", "text", { buf = bufnr })
  -- vim.api.nvim_set_option_value("syntax", "text", { buf = bufnr })

  local timer = Timer.start()

  timer:reset()
  local line = 1
  while line <= total_lines do
    u.goto_line(line)
    crud.append_waypoint_wrapper()
    line = line + lines_between_waypoints
  end
  u.log("append waypoints", timer:stop())

  u.log("<TRACKDATA>")
  for k,v in pairs(u.track_data) do
    u.log(k, v.total)
  end
  u.log("</TRACKDATA>")

  -- local timer = Timer.start()
  timer:reset()
  floating_window.open()
  floating_window.close()
  u.log("draw", timer:stop())

  state.context = 10
  timer:reset()
  floating_window.open()
  floating_window.close()
  u.log("draw with context 10", timer:stop())
end)
