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
  tu.assert_eq(nil, res)
  tu.assert_eq(false, ok)

  ok = ring_buffer.repush(rb)
  tu.assert_eq(false, ok)

  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(nil, res)
  tu.assert_eq(false, ok)

  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(nil, res)
  tu.assert_eq(false, ok)

  -- push

  ring_buffer.push(rb, 1)
  tu.assert_eq(1, rb.size)
  tu.assert_eq(1, #rb.array)
  ring_buffer.push(rb, 2)
  tu.assert_eq(2, rb.size)
  tu.assert_eq(2, #rb.array)
  ring_buffer.push(rb, 3)
  tu.assert_eq(3, rb.size)
  tu.assert_eq(3, #rb.array)
  ring_buffer.push(rb, 4)
  tu.assert_eq(4, rb.size)
  tu.assert_eq(4, #rb.array)
  ring_buffer.push(rb, 5)
  tu.assert_eq(4, rb.size)
  tu.assert_eq(4, #rb.array)
  ring_buffer.push(rb, 6)
  tu.assert_eq(4, rb.size)
  tu.assert_eq(4, #rb.array)

  -- pop

  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(6, res)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(5, res)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(4, res)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(3, res)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.pop(rb)
  tu.assert_eq(nil, res)
  tu.assert_eq(false, ok)

  -- repush and peek

  ok = ring_buffer.repush(rb)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(3, res)
  tu.assert_eq(true, ok)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(4, res)
  tu.assert_eq(true, ok)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(5, res)
  tu.assert_eq(true, ok)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(true, ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(6, res)
  tu.assert_eq(true, ok)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(false, ok)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(6, res)
  tu.assert_eq(true, ok)

  -- pop twice, push once, try to repush, push again

  ring_buffer.pop(rb)
  ring_buffer.pop(rb)
  ring_buffer.push(rb, 7)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(7, res)
  tu.assert_eq(true, ok)
  ok = ring_buffer.repush(rb)
  tu.assert_eq(false, ok)
  ring_buffer.push(rb, 8)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(8, res)
  tu.assert_eq(true, ok)

  -- clear

  ring_buffer.clear(rb)
  tu.assert_eq(0, rb.size)
  res, ok = ring_buffer.peek(rb)
  tu.assert_eq(nil, res)
  tu.assert_eq(false, ok)
end)
