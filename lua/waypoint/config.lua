---@class waypoint.Config
---@field color_sign                  string
---@field color_footer_after_context  string
---@field color_footer_before_context string
---@field color_footer_context        string
---@field window_width                number
---@field window_height               number
---@field file                        string
---@field mark_char                   string
---@field telescope_filename_width    integer
---@field telescope_linenr_width      integer
---@field indent_width                integer
---@field scroll_increment            integer
---@field enable_highlight            boolean
---@field max_context                 integer
---@field keybindings                 waypoint.Keybindings

---@class waypoint.Keybindings
---@field global_keybindings          waypoint.GlobalKeybindings
---@field waypoint_window_keybindings waypoint.WaypointWindowKeybindings
---@field help_keybindings            waypoint.HelpKeybindings
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



-- Classes for the user's config provided on plugin setup

---@class waypoint.ConfigOverride
---@field color_sign                  nil | string
---@field color_footer_after_context  nil | string
---@field color_footer_before_context nil | string
---@field color_footer_context        nil | string
---@field window_width                nil | number
---@field window_height               nil | number
---@field file                        nil | string
---@field mark_char                   nil | string
---@field telescope_filename_width    nil | integer
---@field telescope_linenr_width      nil | integer
---@field indent_width                nil | integer
---@field scroll_increment            nil | integer
---@field enable_highlight            nil | boolean
---@field max_context                 nil | integer
---@field keybindings                 nil | waypoint.Keybindings

---@class waypoint.KeybindingsOverride
---@field global_keybindings          nil | waypoint.GlobalKeybindingsOverride
---@field waypoint_window_keybindings nil | waypoint.WaypointWindowKeybindingsOverride
---@field help_keybindings            nil | waypoint.HelpKeybindingsOverride
---
---@class waypoint.GlobalKeybindingsOverride
---@field current_waypoint        nil | string | table<string>
---@field prev_waypoint           nil | string | table<string>
---@field next_waypoint           nil | string | table<string>
---@field first_waypoint          nil | string | table<string>
---@field last_waypoint           nil | string | table<string>
---@field prev_neighbor_waypoint  nil | string | table<string>
---@field next_neighbor_waypoint  nil | string | table<string>
---@field prev_top_level_waypoint nil | string | table<string>
---@field next_top_level_waypoint nil | string | table<string>
---@field outer_waypoint          nil | string | table<string>
---@field inner_waypoint          nil | string | table<string>
---@field open_waypoint_window    nil | string | table<string>
---@field toggle_waypoint         nil | string | table<string>

---@class waypoint.WaypointWindowKeybindingsOverride
---@field exit_waypoint_window     nil | string | table<string>
---@field increase_context         nil | string | table<string>
---@field decrease_context         nil | string | table<string>
---@field increase_before_context  nil | string | table<string>
---@field decrease_before_context  nil | string | table<string>
---@field increase_after_context   nil | string | table<string>
---@field decrease_after_context   nil | string | table<string>
---@field reset_context            nil | string | table<string>
---@field toggle_path              nil | string | table<string>
---@field toggle_full_path         nil | string | table<string>
---@field toggle_line_num          nil | string | table<string>
---@field toggle_file_text         nil | string | table<string>
---@field toggle_context           nil | string | table<string>
---@field toggle_sort              nil | string | table<string>
---@field show_help                nil | string | table<string>
---@field set_quickfix_list        nil | string | table<string>
---@field indent                   nil | string | table<string>
---@field unindent                 nil | string | table<string>
---@field reset_waypoint_indent    nil | string | table<string>
---@field reset_all_indent         nil | string | table<string>
---@field scroll_right             nil | string | table<string>
---@field scroll_left              nil | string | table<string>
---@field reset_horizontal_scroll  nil | string | table<string>
---@field next_waypoint            nil | string | table<string>
---@field prev_waypoint            nil | string | table<string>
---@field first_waypoint           nil | string | table<string>
---@field last_waypoint            nil | string | table<string>
---@field outer_waypoint           nil | string | table<string>
---@field inner_waypoint           nil | string | table<string>
---@field next_neighbor_waypoint   nil | string | table<string>
---@field prev_neighbor_waypoint   nil | string | table<string>
---@field next_top_level_waypoint  nil | string | table<string>
---@field prev_top_level_waypoint  nil | string | table<string>
---@field delete_waypoint          nil | string | table<string>
---@field current_waypoint         nil | string | table<string>
---@field move_waypoint_down       nil | string | table<string>
---@field move_waypoint_up         nil | string | table<string>

---@class waypoint.HelpKeybindingsOverride
---@field exit_help nil | string | table<string>


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
  max_context = 20,
  keybindings = {
    global_keybindings = {
      open_waypoint_window    = {"ms", "mf"},
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
      toggle_waypoint         = "mt",
    },
    waypoint_window_keybindings = {
      exit_waypoint_window    = {"ms", "q", "<esc>"},
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
      indent                  = ">",
      unindent                = "<",
      reset_waypoint_indent   = "ri",
      reset_all_indent        = "rI",
      scroll_right            = "zL",
      scroll_left             = "zH",
      reset_horizontal_scroll = {"0", "rs"},
      prev_waypoint           = "k",
      next_waypoint           = "j",
      first_waypoint          = "gg",
      last_waypoint           = "G",
      outer_waypoint          = {"o", "I"},
      inner_waypoint          = "i",
      prev_neighbor_waypoint  = "[",
      next_neighbor_waypoint  = "]",
      prev_top_level_waypoint = "{",
      next_top_level_waypoint = "}",
      delete_waypoint         = "dd",
      current_waypoint        = "<CR>",
      move_waypoint_up        = "K",
      move_waypoint_down      = "J",
    },
    help_keybindings = {
      exit_help = {"q", "<esc>", "g?"}
    },
  }
}

return M
