---@class waypoint.Config
---@field color_sign string
---@field color_footer_after_context string
---@field color_footer_before_context string
---@field color_footer_context string
---@field window_width number
---@field window_height number
---@field file string
---@field mark_char string
---@field telescope_filename_width integer
---@field telescope_linenr_width integer
---@field indent_width integer
---@field scroll_increment integer
---@field enable_highlight boolean
---@field keybindings waypoint.Keybindings

---@class waypoint.Keybindings
---@field global_keybindings waypoint.GlobalKeybindings
---@field waypoint_window_keybindings waypoint.WaypointWindowKeybindings
---@field help_keybindings waypoint.HelpKeybindings
---
---@class waypoint.GlobalKeybindings
---@field current_waypoint        string | table<string>
---@field next_waypoint           string | table<string>
---@field prev_waypoint           string | table<string>
---@field first_waypoint          string | table<string>
---@field last_waypoint           string | table<string>
---@field prev_neighbor_waypoint  string | table<string>
---@field next_neighbor_waypoint  string | table<string>
---@field prev_top_level_waypoint string | table<string>
---@field next_top_level_waypoint string | table<string>
---@field outer_waypoint          string | table<string>
---@field inner_waypoint          string | table<string>
---@field open_waypoint_window    string | table<string>
---@field toggle_waypoint         string | table<string>

---@class waypoint.WaypointWindowKeybindings
---@field exit_waypoint_window     string | table<string>
---@field increase_context         string | table<string>
---@field decrease_context         string | table<string>
---@field increase_before_context  string | table<string>
---@field decrease_before_context  string | table<string>
---@field increase_after_context   string | table<string>
---@field decrease_after_context   string | table<string>
---@field reset_context            string | table<string>
---@field toggle_annotation        string | table<string>
---@field toggle_path              string | table<string>
---@field toggle_full_path         string | table<string>
---@field toggle_line_num          string | table<string>
---@field toggle_file_text         string | table<string>
---@field toggle_context           string | table<string>
---@field toggle_sort              string | table<string>
---@field show_help                string | table<string>
---@field set_quickfix_list        string | table<string>
---@field indent                   string | table<string>
---@field unindent                 string | table<string>
---@field reset_waypoint_indent    string | table<string>
---@field reset_all_indent         string | table<string>
---@field scroll_right             string | table<string>
---@field scroll_left              string | table<string>
---@field reset_horizontal_scroll  string | table<string>
---@field next_waypoint            string | table<string>
---@field prev_waypoint            string | table<string>
---@field first_waypoint           string | table<string>
---@field last_waypoint            string | table<string>
---@field outer_waypoint           string | table<string>
---@field inner_waypoint           string | table<string>
---@field next_neighbor_waypoint   string | table<string>
---@field prev_neighbor_waypoint   string | table<string>
---@field next_top_level_waypoint  string | table<string>
---@field prev_top_level_waypoint  string | table<string>
---@field delete_waypoint          string | table<string>
---@field current_waypoint         string | table<string>
---@field move_waypoint_down       string | table<string>
---@field move_waypoint_up         string | table<string>

---@class waypoint.HelpKeybindings
---@field exit_help string | table<string>

---@type waypoint.Config
local M = {
  color_sign = "NONE",
  color_footer_after_context = "#ff7777",
  color_footer_before_context = "#77ff77",
  color_footer_context = "#7777ff",
  window_width = 0.8,
  window_height = 0.8,
  file = "./nvim-waypoints.json",
  mark_char = "◆",
  telescope_filename_width = 30,
  telescope_linenr_width = 5,
  indent_width = 4,
  scroll_increment = 6,
  enable_highlight = true,
  keybindings = {
    global_keybindings = {
      current_waypoint        = "mc",
      prev_waypoint           = "mp",
      next_waypoint           = "mn",
      first_waypoint          = "mg",
      last_waypoint           = "mG",
      prev_neighbor_waypoint  = "m[",
      next_neighbor_waypoint  = "m]",
      prev_top_level_waypoint = "m{",
      next_top_level_waypoint = "m}",
      outer_waypoint          = "mo",
      inner_waypoint          = "mi",
      open_waypoint_window    = "mf",
      toggle_waypoint         = "mt",
    },
    waypoint_window_keybindings = {
      exit_waypoint_window    = {"mf", "q", "<esc>"},
      increase_context        = "c",
      decrease_context        = "C",
      increase_before_context = "b",
      decrease_before_context = "B",
      increase_after_context  = "a",
      decrease_after_context  = "A",
      reset_context           = {"R", "rc"},
      toggle_annotation       = "ta",
      toggle_path             = "tp",
      toggle_full_path        = "tf",
      toggle_line_num         = "tl",
      toggle_file_text        = "tn",
      toggle_context          = "tc",
      toggle_sort             = "ts",
      show_help               = "g?",
      set_quickfix_list       = "Q",
      indent                  = "",
      unindent                = "",
      reset_waypoint_indent   = "",
      reset_all_indent        = "",
      scroll_right            = "",
      scroll_left             = "",
      reset_horizontal_scroll = "",
      next_waypoint           = "",
      prev_waypoint           = "",
      first_waypoint          = "",
      last_waypoint           = "",
      outer_waypoint          = "",
      inner_waypoint          = "",
      next_neighbor_waypoint  = "",
      prev_neighbor_waypoint  = "",
      next_top_level_waypoint = "",
      prev_top_level_waypoint = "",
      delete_waypoint         = "",
      current_waypoint        = "",
      move_waypoint_down      = "",
      move_waypoint_up        = "",
    },
    help_keybindings = {
      exit_help = {"q", "<esc>", "g?"}
    },
  }
}

return M
