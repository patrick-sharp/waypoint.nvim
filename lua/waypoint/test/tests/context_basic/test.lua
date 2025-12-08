local describe = require('waypoint.test.test_list').describe
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")

describe('Context basic', function()
  floating_window.open()
  floating_window.IncreaseAfterContext(1)
  floating_window.IncreaseBeforeContext(1)
  floating_window.IncreaseContext(1)
  assert(state.after_context == 1)
  assert(state.before_context == 1)
  assert(state.context == 1)
  return true
end)
