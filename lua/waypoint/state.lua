-- This file keeps track of where all the waypoints are and the state of the floating window

-- waypoints take the "fat struct" approach, which is like a tagged union but where the object has all possible keys and they're all nullable.
-- I have never done this before, but some people on twitter (Ryan Fleury and Ginger Bill) seem to like it.
-- I normally go the tagged union route in typescript, but the lua language server doesn't do a great job providing type warnings for tagged unions.
-- This approach seems less elegant, but I like trying new things.
--
-- in thiss scheme, a waypoint with a buffer will be have bufnr and extmark id.
-- bufferless waypoints will have the file path, linenr, and line text
-- Bufferless waypoints exist to keep track of a waypoint's location when there's no accompanying buffer (and therefore no extmark)
-- Bufferless waypoints are the format saved to the waypoint json file.
-- when a buffer with waypoints is closed, we hook onto the BufUnload autocmd to convert buffer waypoints into bufferless waypoints

---@class waypoint.Waypoint
---@field has_buffer    boolean
---@field extmark_id    integer | nil the id of the extmark within the buffer. Note that these are not unique globally. Can become stale if extmark is deleted for any reason (e.g. the buffer is closed)
---@field bufnr         integer | nil the buffer number the waypoint is in. can become stale if the file is deleted and reopened.
---@field indent        integer
---@field annotation    string | nil
---@field filepath      string | nil relative path to file the waypoint is in. Does NOT start with ./, i.e. a path to ./lua/myfile.lua would be stored as lua/myfile.lua
---@field text          string | nil
---@field linenr        integer | nil the one-indexed line number the waypoint is on. Can become stale if a buffer edit causes the extmark to move.
---@field error         string | nil

---@class waypoint.View
---@field lnum    integer | nil the line number the cursor is on. if nil, default to the line the waypoint is on.
---@field col     integer the column the cursor is on. zero indexed. keep in mind due to unicode shenanigans I never use this to restore the view. I manipulate the cursor in a unicode save way using getcursorcharpos and setcursorcharpos. never with with winsaveview or winrestview.
---@field leftcol integer the left column visible on the screen.

---@class waypoint.State
---@field load_error            string | nil if there was an error loading the file. if so, we show it in the waypoint window
---@field wpi                   integer | nil the index of the currently selected waypoint.
---@field vis_wpi               integer | nil the index of the other side of the visual selection. to deal with "o" (i.e. moving to the other end of highlighted text), it can check where the cursor is on the CursorMoved callback and update wpi/vis_wpi accordingly.
---@field waypoints             waypoint.Waypoint[] all the waypoints in this session.
---@field sorted_waypoints      waypoint.Waypoint[] all the waypoints in this session, sorted by file and line number. tables in this array are pointers to the same tables in state.waypoints, just in a different order
---@field context               integer the number of lines above and below the waypoint that will also appear in the waypoint window. adds with before_context and after_context.
---@field before_context        integer the number of lines above the waypoint that will also appear in the waypoint window. adds with context and after_context.
---@field after_context         integer the number of lines below the waypoint that will also appear in the waypoint window. adds with context and before_context.
---@field show_path             boolean
---@field show_full_path        boolean
---@field show_line_num         boolean
---@field show_file_text        boolean
---@field show_context          boolean whether or not to show the context around the waypoint instead of just the line of text the waypoint is on
---@field sort_by_file_and_line boolean whether or not to show the context around the waypoint instead of just the line of text the waypoint is on
---@field view                  waypoint.View
---@field should_notify         boolean whether or not to actually print when message.notify is called

---@type waypoint.State
local M = {
  load_error       = nil,
  wpi              = nil,
  waypoints        = {},
  sorted_waypoints = {},
  context          = 0,
  before_context   = 0,
  after_context    = 0,

  show_path        = true,
  show_full_path   = false,
  show_line_num    = true,
  show_file_text   = true,
  show_context     = true,

  sort_by_file_and_line = false,

  view = {
    lnum     = nil,
    col      = 0,
    leftcol  = 0,
  },
  should_notify = true,
}

return M
