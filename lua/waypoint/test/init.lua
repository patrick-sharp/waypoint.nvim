local M = {}

local constants = require'waypoint.constants'
local floating_window = require'waypoint.floating_window'
local test_list = require'waypoint.test.test_list'
local state = require'waypoint.state'

-- these files call test_list.describe, which adds tests to the list
local _ = require'waypoint.test.tests.context_basic'
local _ = require'waypoint.test.tests.help'
local _ = require'waypoint.test.tests.levenshtein'
local _ = require'waypoint.test.tests.missing_file'
local _ = require'waypoint.test.tests.missing_file_complex'
local _ = require'waypoint.test.tests.move'
local _ = require'waypoint.test.tests.ring_buffer'
local _ = require'waypoint.test.tests.sort'
local _ = require'waypoint.test.tests.toggles'
-- other tests to write
-- * deleting waypoints
-- * loading from files
-- * toggling off different parts of the file
-- * moving waypoints around
-- * advanced navigations (outer/inner/neighbor/top/bottom)
-- * navigations outside the waypoint window (next/previous etc.)
-- * indentation
-- * doing normal crud operations with waypoints in missing files or outside file range
-- * multiple waypoints getting moved onto the same line by a filter
-- * rename file and make sure waypoints in that file are updated

local border = "\n================================================================\n"
local PASS = "✓ PASS"
local FAIL = "𐄂 FAIL"

local function log_test_output()
  local file = io.open(constants.test_output_file, "w")
  if not file then
    error("Could not open test output file for writing")
  end
  ---@type waypoint.Test[]
  local pass = {}
  ---@type waypoint.Test[]
  local fail = {}
  for _,test in ipairs(test_list.tests) do
    if test.pass then
      table.insert(pass, test)
    else
      table.insert(fail, test)
    end
  end

  local summary
  local passed_fraction = "Passed " .. tostring(#pass) .. "/" .. tostring(#pass + #fail) .. " tests"
  if #pass == 0 and #fail == 0 then
    summary = "NO TESTS RUN"
  elseif #fail == 0 then
    summary = "✓ ALL TESTS PASSED\n" .. passed_fraction
  elseif #pass > 0 then
    summary = "𐄂 SOME TESTS FAILED\n" .. passed_fraction
  else
    summary = "𐄂 ALL TESTS FAILED\n" .. passed_fraction
  end
  file:write(summary .. "\n")
  file:write(border)

  if #pass > 0 then
    file:write("\n")
  end
  for _,test in ipairs(pass) do
    file:write(PASS .. " " .. test.name .. "\n")
  end

  if #fail > 0 then
    file:write("\n")
  end
  for i,test in ipairs(fail) do
    local extra_newline = ""
    if i > 1 then
      extra_newline = "\n"
    end
    file:write(extra_newline .. FAIL .. " " .. test.name .. "\n")
    if test.err then
      file:write(tostring(test.err) .. "\n")
    end
  end

  file:write(border)
  file:write("\n" .. summary)
  file:close()
  vim.notify("Test output saved to " .. constants.test_output_file, vim.log.levels.INFO)
end

-- open a new no name buffer and close everything else
local function clear_buffers()
  vim.api.nvim_command('enew')
  local bufs = vim.api.nvim_list_bufs()
  local current_buf = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(bufs) do
    if buf ~= current_buf then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

function M.run_tests()
  state.should_notify = false
  for _,test in ipairs(test_list.tests) do
    floating_window.clear_state_and_close()
    _, test.err = xpcall(test.fn, debug.traceback)
    test.pass = not test.err
    floating_window.clear_state_and_close()
    clear_buffers()
    vim.cmd.normal('<C-c>') -- this resets vim.v.count and vim.v.count1, which can persist between tests otherwise
  end
  state.should_notify = true

  log_test_output()
  vim.cmd.edit({args = {constants.test_output_file}, bang=true})
end

---@param opts vim.api.keyset.create_user_command.command_args
function M.run_test(opts)
  local test_name = opts.args
  local matches = false

  for _,test in ipairs(test_list.tests) do
    if test.name == test_name then
      matches = true
      clear_buffers()
      floating_window.clear_state_and_close()
      test.fn()
      break
    end
  end
  if not matches then
    vim.notify('No test named ' .. test_name, vim.log.levels.ERROR)
  end
end

return M
