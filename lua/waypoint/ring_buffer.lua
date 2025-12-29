local M = {}

---@class waypoint.RingBuffer
---@field start_idx integer index of earliest inserted element
---@field end_idx   integer index of latest inserted element
---@field array        any[]
---@field size         integer
---@field capacity     integer

local default_capacity = 32

---@param capacity integer | nil
---@return waypoint.RingBuffer
function M.new(capacity)
  return {
    start_idx = -1,
    end_idx = -1,
    array = {},
    size = 0,
    capacity = capacity or default_capacity,
  }
end

---@param this waypoint.RingBuffer
function M.curr_idx(this)
  if this.start_idx == -1 then
    return 1
  end
  return (this.start_idx - 1 + math.max(this.size - 1, 0)) % this.capacity + 1
end

---@param this waypoint.RingBuffer
function M.push(this, element)
  if this.start_idx == -1 then
    this.start_idx = 1
  elseif this.size == this.capacity then
    this.start_idx = this.start_idx % this.capacity + 1
  end
  this.size = math.min(this.size + 1, this.capacity)
  local idx = M.curr_idx(this)
  this.array[idx] = element
  this.end_idx = idx
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
  if this.start_idx == -1 or M.curr_idx(this) == this.end_idx then
    return false
  end

  this.size = this.size + 1
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

---@param this waypoint.RingBuffer
function M.clear(this)
  this.start_idx = -1
  this.end_idx = -1
  this.array = {}
  this.size = 0
end

return M
