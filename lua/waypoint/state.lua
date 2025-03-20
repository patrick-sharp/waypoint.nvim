-- This file keeps track of where all the waypoints are and the state of the floating window

---@class Waypoint
---@field annotation string | nil
---@field extmark_bufnr integer
---@field extmark_id integer the id of the extmark within the buffer. Note that these are not unique globally
---@field filepath string
---@field indent integer

---@class State
---@field wpi                integer | nil
---@field waypoints          table<Waypoint>
---@field context            integer
---@field before_context     integer
---@field after_context      integer
---@field scroll_col         integer
---@field cursor_x           integer | nil
---@field cursor_y           integer | nil
---@field topline            integer | nil
---@field show_annotation    boolean
---@field show_path          boolean
---@field show_full_path     boolean
---@field show_line_num      boolean
---@field show_file_text     boolean

-- TODO:
-- state should be a table of extmark ids, and just use the extmarks to maintain state

---@type State
local M = {
  wpi =              nil,
  waypoints          = {},
  context            = 0,
  before_context     = 0,
  after_context      = 0,
  topline            = nil, -- when nil, window will just center on current waypoint
  scroll_col         = 0,
  cursor_x           = 0,
  cursor_y           = nil, -- when nil, will be equal to line of current waypoint
  show_annotation    = true,
  show_path          = true,
  show_full_path     = false,
  show_line_num      = true,
  show_file_text     = true,
}

return M
