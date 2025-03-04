local M = {}

---@class Dog
---@field type "dog"
---@field name string
---@field breed string

---@class Schnauser: Dog
---@field schnau string

---@class Cat
---@field type "cat"
---@field meow boolean

---@class (exact) Point
---@field x number
---@field y number

---@type Cat | Dog
local pet = {
  type = "dog",
  name = "a",
  breed = "lab",
}

function M.types() 
  local m = pet.meow
  local t = pet.type

  if pet.type == "cat" then
    ---@type Cat
    local c = pet
  else
    ---@type Cat
    local c = pet
    ---@type Dog
    local d = pet
  end

  ---@type Cat?
  local maybe_cat

  if maybe_cat == nil then
    print(maybe_cat)

    -- cast to unknown
    ---@cast maybe_cat -?
    print(maybe_cat)
  else
    ---@cast maybe_cat -?
    print(maybe_cat)
  end

   ---@enum colors
  local COLORS = {
    black = 0,
    red = 2,
    green = 4,
    yellow = 8,
    blue = 16,
    white = 32
  }

  ---@param color colors
  local function setColor(color) end
  setColor(COLORS.green)
end


---@param x string The name of the setting to set the value of
---@param y any The value of this setting
---@return integer
function M.wacka(x, y)
  return 0
end

return M


