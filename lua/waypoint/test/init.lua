local M = {}

local constants = require'waypoint.constants'
local floating_window = require'waypoint.floating_window'
local test_list = require'waypoint.test.test_list'

-- these files call test_list.describe, which adds tests to the list
local _ = require'waypoint.test.tests.context_basic.test'

local border = "\n================================================================\n"
local PASS = "✓ PASS"
local FAIL = "⃠⃠𐄂 FAIL"

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
  for _,test in ipairs(fail) do
    file:write(FAIL .. " " .. test.name .. "\n")
    if test.err then
      file:write(tostring(test.err) .. "\n")
    end
  end

  file:write(border)
  file:write("\n" .. summary)
  file:close()
  vim.notify("Test output saved to " .. constants.test_output_file, vim.log.levels.INFO)
end

function M.run_tests()
  for _,test in ipairs(test_list.tests) do
    floating_window.clear_state_and_close()
    test.pass, test.err = pcall(test.fn)
    floating_window.clear_state_and_close()
  end

  log_test_output()
end

return M
