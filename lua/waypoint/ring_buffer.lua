local M = {}

---@class waypoint.RingBuffer
---@field earliest_idx integer index of earliest inserted element
---@field latest_idx   integer index of latest inserted element
---@field array        any[]
---@field size         integer
---@field capacity     integer

local default_capacity = 32

---@param capacity integer | nil
---@return waypoint.RingBuffer
function M.new(capacity)
  return {
    idx = 0,
    earliest_idx = 0,
    latest_idx = 0,
    array = {},
    size = 0,
    capacity = capacity or default_capacity,
  }
end

---@param this waypoint.RingBuffer
function M.curr_idx(this)
  return (this.earliest_idx + this.size - 1) % this.capacity
end

---@param this waypoint.RingBuffer
function M.push(this, element)
  this.size = math.min(this.size + 1, this.capacity)
  local idx = M.curr_idx(this)
  this[idx] = element
  this.latest_idx = idx
  if this.earliest_idx == 0 then
    this.earliest_idx = 1
  elseif idx == this.earliest_idx then
    this.earliest_idx = (idx + 1) % this.capacity
  end
end

---@param this waypoint.RingBuffer
---@return any, boolean # return popped item and true if successful, or nil and false if could not pop
function M.pop(this)
  if this.size == 0 then
    return nil, false
  end
  local idx = M.curr_idx(this)
  local result = this.array[idx]
  this.size = this.size - 1
  return result, true
end

---@param this waypoint.RingBuffer
---@return boolean # return true if successful, or false if unsuccessful
function M.repush(this)
  if M.curr_idx(this) == this.latest_idx then
    return false
  end

  this.size = math.min(this.size + 1, this.capacity)
  return true
end

---@param this waypoint.RingBuffer
---@return any, boolean # return popped item and true if successful, or nil and false if could not pop
function M.peek(this)
  if this.size == 0 then
    return nil, false
  end
  local idx = M.curr_idx(this)
  return this.array[idx], true
end

return M
