local M = {}

local constants = require'waypoint.constants'
local test_list = require'waypoint.test.test_list'
local _ = require'waypoint.test.tests.context_basic.test'

local border = "\n================================================================\n"
local PASS = "PASS"
local FAIL = "FAIL"

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
  if #pass == 0 and #fail == 0 then
    summary = "NO TESTS RUN"
  elseif #fail == 0 then
    summary = "ALL TESTS PASSED\nPASSED " .. tostring(#pass) .. "/" .. tostring(#pass) .. " TESTS"
  else
    summary = "SOME TESTS FAILED\nPASSED " .. tostring(#pass) .. "/" .. tostring(#pass + #fail) .. " TESTS"
  end
  file:write(summary .. "\n")
  file:write(border)
  file:write("\n")

  for _,test in ipairs(pass) do
    file:write(PASS .. " " .. test.name .. "\n")
  end
  if #fail > 0 then
    file:write("\n")
  end
  for _,test in ipairs(fail) do
    file:write(FAIL .. " " .. test.name .. "\n")
    if test.err then
      file:write(FAIL .. " " .. vim.inspect(test.err))
    end
  end

  file:write(border)
  file:write("\n" .. summary)
  file:close()
end

function M.run_tests()
  for _,test in ipairs(test_list.tests) do
    -- run test
    test.pass, test.err = pcall(test.fn)
  end

  log_test_output()
end

return M
