---@class waypoint.Config
---@field color_sign                       string
---@field color_footer_after_context       string
---@field color_footer_before_context      string
---@field color_footer_context             string
---@field color_toggle_on                  string
---@field color_toggle_off                 string
---@field window_width                     number
---@field window_height                    number
---@field file                             string
---@field mark_char                        string
---@field telescope_filename_width         integer
---@field telescope_linenr_width           integer
---@field indent_width                     integer
---@field scroll_increment                 integer
---@field enable_highlight                 boolean
---@field enable_relative_waypoint_numbers boolean -- not implemented yet
---@field max_context                      integer
---@field keybindings                      waypoint.Keybindings

---@class waypoint.Keybindings
---@field global_keybindings          waypoint.GlobalKeybindings
---@field waypoint_window_keybindings waypoint.WaypointWindowKeybindings
---@field help_keybindings            waypoint.HelpKeybindings
---
---@class waypoint.GlobalKeybindings
---@field current_waypoint        string | string[]
---@field next_waypoint           string | string[]
---@field prev_waypoint           string | string[]
---@field first_waypoint          string | string[]
---@field last_waypoint           string | string[]
---@field prev_neighbor_waypoint  string | string[]
---@field next_neighbor_waypoint  string | string[]
---@field prev_top_level_waypoint string | string[]
---@field next_top_level_waypoint string | string[]
---@field outer_waypoint          string | string[]
---@field inner_waypoint          string | string[]
---@field open_waypoint_window    string | string[]
---@field toggle_waypoint         string | string[]

---@class waypoint.WaypointWindowKeybindings
---@field exit_waypoint_window     string | string[]
---@field increase_context         string | string[]
---@field decrease_context         string | string[]
---@field increase_before_context  string | string[]
---@field decrease_before_context  string | string[]
---@field increase_after_context   string | string[]
---@field decrease_after_context   string | string[]
---@field reset_context            string | string[]
---@field toggle_annotation        string | string[]
---@field toggle_path              string | string[]
---@field toggle_full_path         string | string[]
---@field toggle_line_num          string | string[]
---@field toggle_file_text         string | string[]
---@field toggle_context           string | string[]
---@field toggle_sort              string | string[]
---@field show_help                string | string[]
---@field set_quickfix_list        string | string[]
---@field indent                   string | string[]
---@field unindent                 string | string[]
---@field reset_waypoint_indent    string | string[]
---@field reset_all_indent         string | string[]
---@field scroll_right             string | string[]
---@field scroll_left              string | string[]
---@field reset_horizontal_scroll  string | string[]
---@field next_waypoint            string | string[]
---@field prev_waypoint            string | string[]
---@field first_waypoint           string | string[]
---@field last_waypoint            string | string[]
---@field outer_waypoint           string | string[]
---@field inner_waypoint           string | string[]
---@field next_neighbor_waypoint   string | string[]
---@field prev_neighbor_waypoint   string | string[]
---@field next_top_level_waypoint  string | string[]
---@field prev_top_level_waypoint  string | string[]
---@field delete_waypoint          string | string[]
---@field current_waypoint         string | string[]
---@field move_waypoint_down       string | string[]
---@field move_waypoint_up         string | string[]

---@class waypoint.HelpKeybindings
---@field exit_help string | string[]



-- Classes for the user's config provided on plugin setup

---@class waypoint.ConfigOverride
---@field color_sign                       nil | string
---@field color_footer_after_context       nil | string
---@field color_footer_before_context      nil | string
---@field color_footer_context             nil | string
---@field color_toggle_on                  nil | string
---@field color_toggle_off                 nil | string
---@field window_width                     nil | number
---@field window_height                    nil | number
---@field file                             nil | string
---@field mark_char                        nil | string
---@field telescope_filename_width         nil | integer
---@field telescope_linenr_width           nil | integer
---@field indent_width                     nil | integer
---@field scroll_increment                 nil | integer
---@field enable_highlight                 nil | boolean
---@field enable_relative_waypoint_numbers nil | boolean -- not implemented yet
---@field max_context                      nil | integer
---@field keybindings                      nil | waypoint.Keybindings

---@class waypoint.KeybindingsOverride
---@field global_keybindings          nil | waypoint.GlobalKeybindingsOverride
---@field waypoint_window_keybindings nil | waypoint.WaypointWindowKeybindingsOverride
---@field help_keybindings            nil | waypoint.HelpKeybindingsOverride
---
---@class waypoint.GlobalKeybindingsOverride
---@field current_waypoint        nil | string | string[]
---@field prev_waypoint           nil | string | string[]
---@field next_waypoint           nil | string | string[]
---@field first_waypoint          nil | string | string[]
---@field last_waypoint           nil | string | string[]
---@field prev_neighbor_waypoint  nil | string | string[]
---@field next_neighbor_waypoint  nil | string | string[]
---@field prev_top_level_waypoint nil | string | string[]
---@field next_top_level_waypoint nil | string | string[]
---@field outer_waypoint          nil | string | string[]
---@field inner_waypoint          nil | string | string[]
---@field open_waypoint_window    nil | string | string[]
---@field toggle_waypoint         nil | string | string[]

---@class waypoint.WaypointWindowKeybindingsOverride
---@field exit_waypoint_window     nil | string | string[]
---@field increase_context         nil | string | string[]
---@field decrease_context         nil | string | string[]
---@field increase_before_context  nil | string | string[]
---@field decrease_before_context  nil | string | string[]
---@field increase_after_context   nil | string | string[]
---@field decrease_after_context   nil | string | string[]
---@field reset_context            nil | string | string[]
---@field toggle_path              nil | string | string[]
---@field toggle_full_path         nil | string | string[]
---@field toggle_line_num          nil | string | string[]
---@field toggle_file_text         nil | string | string[]
---@field toggle_context           nil | string | string[]
---@field toggle_sort              nil | string | string[]
---@field show_help                nil | string | string[]
---@field set_quickfix_list        nil | string | string[]
---@field indent                   nil | string | string[]
---@field unindent                 nil | string | string[]
---@field reset_waypoint_indent    nil | string | string[]
---@field reset_all_indent         nil | string | string[]
---@field scroll_right             nil | string | string[]
---@field scroll_left              nil | string | string[]
---@field reset_horizontal_scroll  nil | string | string[]
---@field next_waypoint            nil | string | string[]
---@field prev_waypoint            nil | string | string[]
---@field first_waypoint           nil | string | string[]
---@field last_waypoint            nil | string | string[]
---@field outer_waypoint           nil | string | string[]
---@field inner_waypoint           nil | string | string[]
---@field next_neighbor_waypoint   nil | string | string[]
---@field prev_neighbor_waypoint   nil | string | string[]
---@field next_top_level_waypoint  nil | string | string[]
---@field prev_top_level_waypoint  nil | string | string[]
---@field delete_waypoint          nil | string | string[]
---@field current_waypoint         nil | string | string[]
---@field move_waypoint_down       nil | string | string[]
---@field move_waypoint_up         nil | string | string[]

---@class waypoint.HelpKeybindingsOverride
---@field exit_help nil | string | string[]


---@type waypoint.Config
local M = {
  color_sign = "NONE",
  color_footer_after_context = "#ff7777",
  color_footer_before_context = "#77ff77",
  color_footer_context = "#7777ff",
  color_toggle_on = "#00ff00",
  color_toggle_off = "#777777",
  window_width = 0.8,
  window_height = 0.8,
  file = "./nvim-waypoints.json",
  mark_char = "◆",
  telescope_filename_width = 30,
  telescope_linenr_width = 5,
  indent_width = 4,
  scroll_increment = 6,
  enable_highlight = true,
  enable_relative_waypoint_numbers = false, -- not implemented yet
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
      exit_waypoint_window    = {"ms", "mf", "q", "<esc>"},
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
