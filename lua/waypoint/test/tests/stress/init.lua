-- Load test for huge amounts of highlighting and waypoints

local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local crud = require"waypoint.waypoint_crud"
local Timer = require"waypoint.timer"
local floating_window = require"waypoint.floating_window"
local state = require"waypoint.state"
local u = require"waypoint.utils"

describe('Stress', function()
  --local total_lines = 1000000
  local total_lines = 300
  local lines_between_waypoints = 1

  local lines = {}
  local function add_line(str)
    lines[#lines+1] = str
  end

  state.should_notify = false

  local timer = Timer.start()
  for _=1,total_lines do
    add_line("lkajsdhflakjsdhflkajsdhflkasjdhflakjsdhfalkjsdhf")
  end

  u.log(timer:stop())

  -- -- 1. Generate Deeply Nested Scopes (The Stack Stressor)
  -- add_line("-- Section: Nested Scopes")
  -- for i = 1, 5000 do
  --   add_line(string.rep("  ", i % 50) .. "do -- level " .. i)
  -- end
  -- add_line("  local leaf_node = 'bottom of the stack'")
  -- for i = 5000, 1, -1 do
  --   add_line(string.rep("  ", i % 50) .. "end")
  -- end
  --
  -- -- 2. Generate Massive Table Constructors (The Memory Stressor)
  -- add_line("local giant_table = {")
  -- while #lines < total_lines / 2 do
  --   add_line(string.format("  ['key_%d'] = { val = %d, fn = function(x) return x + %d end },", #lines, #lines, math.random(100)))
  -- end
  -- add_line("}")
  --
  -- -- 3. High-Complexity Logic Mix
  -- add_line("local function complex_logic(...)")
  -- while #lines < total_lines - 10 do
  --   local r = math.random(1, 3)
  --   if r == 1 then
  --     add_line("  if (math.sin(os.time()) > 0.5) then print('branch') else local x = 1 end")
  --   elseif r == 2 then
  --     add_line("  for i=1, 10 do (function(v) return v*v end)(i) end")
  --   else
  --     add_line("  local co = coroutine.wrap(function() coroutine.yield(true) end)")
  --   end
  -- end
  -- add_line("end")

  local bufnr = vim.api.nvim_create_buf(true, false)

  timer:reset()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  u.log(timer:stop())

  timer:reset()
  vim.api.nvim_set_current_buf(bufnr)
  u.log(timer:stop())


  timer:reset()
  local line = 1
  while line <= total_lines do
    u.goto_line(line)
    crud.append_waypoint_wrapper()
    line = line + lines_between_waypoints
  end
  u.log(timer:stop())

  -- local timer = Timer.start()
  -- timer:reset()
  -- floating_window.open()
  -- floating_window.close()
  -- u.log(timer:stop())

  -- state.context = 10
  -- timer:reset()
  -- floating_window.open()
  -- floating_window.close()
  -- u.log(timer:stop())



end)
