-- This file keeps track of where all the waypoints are and the state of the floating window

---@class waypoint.Waypoint
---@field extmark_id    integer the id of the extmark within the buffer. Note that these are not unique globally. Can become stale if extmark is deleted for any reason (e.g. the buffer is closed)
---@field linenr        integer the zero-indexed line number the waypoint is on. Can become stale if a buffer edit causes the extmark to move.
---@field bufnr         string the buffer number the waypoint is in. can become stale if the file is deleted and reopened.
---@field filepath      string used as a backup if the bufnr becomes stale.
---@field indent        integer
---@field has_separator boolean whether we should render a blank line directly after this waypoint
---@field annotation    string | nil
---@field error         string | nil

---@class waypoint.View
---@field lnum    integer | nil the line number the cursor is on. if nil, default to the line the waypoint is on.
---@field col     integer the column the cursor is on. zero indexed. keep in mind due to unicode shenanigans I never use this to restore the view. I manipulate the cursor in a unicode save way using getcursorcharpos and setcursorcharpos. never with with winsaveview or winrestview.
---@field leftcol integer the left column visible on the screen.

---@class waypoint.State
---@field load_error            string | nil if there was an error loading the file. if so, we show it in the waypoint window
---@field wpi                   integer | nil   the index of the currently selected waypoint.
---@field waypoints             table<waypoint.Waypoint> all the waypoints in this session.
---@field context               integer the number of lines above and below the waypoint that will also appear in the waypoint window. adds with before_context and after_context.
---@field before_context        integer the number of lines above the waypoint that will also appear in the waypoint window. adds with context and after_context.
---@field after_context         integer the number of lines below the waypoint that will also appear in the waypoint window. adds with context and before_context.
---@field show_annotation       boolean
---@field show_path             boolean
---@field show_full_path        boolean
---@field show_line_num         boolean
---@field show_file_text        boolean
---@field show_context          boolean whether or not to show the context around the waypoint instead of just the line of text the waypoint is on
---@field sort_by_file_and_line boolean whether or not to show the context around the waypoint instead of just the line of text the waypoint is on
---@field view                  waypoint.View

---@type waypoint.State
local M = {
  load_error      = nil,
  wpi             = nil,
  waypoints       = {},
  context         = 0,
  before_context  = 0,
  after_context   = 0,

  show_annotation = true,
  show_path       = true,
  show_full_path  = false,
  show_line_num   = true,
  show_file_text  = true,
  show_context    = true,

  sort_by_file_and_line = false,

  view = {
    lnum     = nil,
    col      = 0,
    leftcol  = 0,
  },
}

return M
