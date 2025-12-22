local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local tu = require'waypoint.test.util'
local ring_buffer = require"waypoint.ring_buffer"

describe('Ring buffer', function()
  local capacity = 4
  local rb = ring_buffer.new(capacity)
  ---@type integer
  local res
  ---@type boolean
  local ok

  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, nil)
  tu.assert_eq(ok, false)

  ok = ring_buffer.repush(rb)
  tu.assert_eq(ok, false)

  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, nil)
  tu.assert_eq(ok, false)

  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, nil)
  tu.assert_eq(ok, false)

  -- push

  ring_buffer.push(rb, 1)
  tu.assert_eq(rb.size, 1)
  ring_buffer.push(rb, 2)
  tu.assert_eq(rb.size, 2)
  ring_buffer.push(rb, 3)
  tu.assert_eq(rb.size, 3)
  ring_buffer.push(rb, 4)
  tu.assert_eq(rb.size, 4)
  ring_buffer.push(rb, 5)
  tu.assert_eq(rb.size, 4)
  ring_buffer.push(rb, 6)
  tu.assert_eq(rb.size, 4)

  -- pop

  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, 6)
  tu.assert_eq(ok, true)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, 5)
  tu.assert_eq(ok, true)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, 4)
  tu.assert_eq(ok, true)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, 3)
  tu.assert_eq(ok, true)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(res, nil)
  tu.assert_eq(ok, false)

  -- repush and peek

  ok = ring_buffer.repush(rb)
  tu.assert_eq(ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 3)
  tu.assert_eq(ok, true)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 4)
  tu.assert_eq(ok, true)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 5)
  tu.assert_eq(ok, true)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 6)
  tu.assert_eq(ok, true)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(not ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 6)
  tu.assert_eq(ok, true)

  -- pop twice and push new values
  ring_buffer.pop(rb)
  ring_buffer.pop(rb)
  ring_buffer.push(rb, 7)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 7)
  tu.assert_eq(ok, true)
  ring_buffer.push(rb, 8)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, 8)
  tu.assert_eq(ok, true)

  -- clear

  ring_buffer.clear(rb)
  tu.assert_eq(rb.size, 0)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(res, nil)
  tu.assert_eq(ok, false)
end)
