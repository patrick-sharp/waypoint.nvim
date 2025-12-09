local describe = require('waypoint.test.test_list').describe
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")

describe('Context basic', function()
  floating_window.open()

  floating_window.increase_after_context()
  assert(state.after_context == 1)
  floating_window.increase_before_context()
  assert(state.before_context == 1)
  floating_window.increase_context()
  assert(state.context == 1)

  floating_window.decrease_after_context()
  assert(state.after_context == 0)
  floating_window.decrease_before_context()
  assert(state.before_context == 0)
  floating_window.decrease_context()
  assert(state.context == 0)

  floating_window.decrease_after_context()
  assert(state.after_context == 0)
  floating_window.decrease_before_context()
  assert(state.before_context == 0)
  floating_window.decrease_context()
  assert(state.context == 0)

  floating_window.close()

  return true
end)
