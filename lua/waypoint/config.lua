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
---@field enable_relative_waypoint_numbers boolean
---@field max_context                      integer
---@field waypoint_dir                     string
---@field keybindings                      waypoint.Keybindings
---@field max_undo_history                 integer
---@field max_msg_history                  integer

---@class waypoint.Keybindings
---@field global_keybindings          waypoint.GlobalKeybindings
---@field waypoint_window_keybindings waypoint.WaypointWindowKeybindings
---@field help_keybindings            waypoint.HelpKeybindings

---@alias waypoint.Keybinding string | string[]

---@class waypoint.GlobalKeybindings
---@field current_waypoint          waypoint.Keybinding
---@field next_waypoint             waypoint.Keybinding
---@field prev_waypoint             waypoint.Keybinding
---@field first_waypoint            waypoint.Keybinding
---@field last_waypoint             waypoint.Keybinding
---@field prev_neighbor_waypoint    waypoint.Keybinding
---@field next_neighbor_waypoint    waypoint.Keybinding
---@field prev_top_level_waypoint   waypoint.Keybinding
---@field next_top_level_waypoint   waypoint.Keybinding
---@field outer_waypoint            waypoint.Keybinding
---@field inner_waypoint            waypoint.Keybinding
---@field open_waypoint_window      waypoint.Keybinding
---@field toggle_waypoint           waypoint.Keybinding
---@field append_waypoint           waypoint.Keybinding
---@field insert_waypoint           waypoint.Keybinding
---@field append_annotated_waypoint waypoint.Keybinding
---@field insert_annotated_waypoint waypoint.Keybinding
---@field delete_waypoint           waypoint.Keybinding

---@class waypoint.WaypointWindowKeybindings
---@field exit_waypoint_window     waypoint.Keybinding
---@field increase_context         waypoint.Keybinding
---@field decrease_context         waypoint.Keybinding
---@field increase_before_context  waypoint.Keybinding
---@field decrease_before_context  waypoint.Keybinding
---@field increase_after_context   waypoint.Keybinding
---@field decrease_after_context   waypoint.Keybinding
---@field reset_context            waypoint.Keybinding
---@field toggle_path              waypoint.Keybinding
---@field toggle_full_path         waypoint.Keybinding
---@field toggle_line_num          waypoint.Keybinding
---@field toggle_file_text         waypoint.Keybinding
---@field toggle_context           waypoint.Keybinding
---@field toggle_sort              waypoint.Keybinding
---@field show_help                waypoint.Keybinding
---@field set_quickfix_list        waypoint.Keybinding
---@field indent                   waypoint.Keybinding
---@field unindent                 waypoint.Keybinding
---@field reset_waypoint_indent    waypoint.Keybinding
---@field reset_all_indent         waypoint.Keybinding
---@field scroll_right             waypoint.Keybinding
---@field scroll_left              waypoint.Keybinding
---@field reset_horizontal_scroll  waypoint.Keybinding
---@field next_waypoint            waypoint.Keybinding
---@field prev_waypoint            waypoint.Keybinding
---@field first_waypoint           waypoint.Keybinding
---@field last_waypoint            waypoint.Keybinding
---@field outer_waypoint           waypoint.Keybinding
---@field inner_waypoint           waypoint.Keybinding
---@field next_neighbor_waypoint   waypoint.Keybinding
---@field prev_neighbor_waypoint   waypoint.Keybinding
---@field next_top_level_waypoint  waypoint.Keybinding
---@field prev_top_level_waypoint  waypoint.Keybinding
---@field delete_waypoint          waypoint.Keybinding
---@field current_waypoint         waypoint.Keybinding
---@field move_waypoint_down       waypoint.Keybinding
---@field move_waypoint_up         waypoint.Keybinding
---@field move_waypoints_to_file   waypoint.Keybinding
---@field move_waypoint_to_top     waypoint.Keybinding
---@field move_waypoint_to_bottom  waypoint.Keybinding
---@field undo                     waypoint.Keybinding
---@field redo                     waypoint.Keybinding

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
---@field enable_relative_waypoint_numbers nil | boolean
---@field max_context                      nil | integer
---@field waypoint_dir                     nil | string
---@field keybindings                      nil | waypoint.Keybindings
---@field max_undo_history                 nil | integer
---@field max_msg_history                  nil | integer

---@class waypoint.KeybindingsOverride
---@field global_keybindings          nil | waypoint.GlobalKeybindingsOverride
---@field waypoint_window_keybindings nil | waypoint.WaypointWindowKeybindingsOverride
---@field help_keybindings            nil | waypoint.HelpKeybindingsOverride
---
---@class waypoint.GlobalKeybindingsOverride
---@field current_waypoint          nil | waypoint.Keybinding
---@field prev_waypoint             nil | waypoint.Keybinding
---@field next_waypoint             nil | waypoint.Keybinding
---@field first_waypoint            nil | waypoint.Keybinding
---@field last_waypoint             nil | waypoint.Keybinding
---@field prev_neighbor_waypoint    nil | waypoint.Keybinding
---@field next_neighbor_waypoint    nil | waypoint.Keybinding
---@field prev_top_level_waypoint   nil | waypoint.Keybinding
---@field next_top_level_waypoint   nil | waypoint.Keybinding
---@field outer_waypoint            nil | waypoint.Keybinding
---@field inner_waypoint            nil | waypoint.Keybinding
---@field open_waypoint_window      nil | waypoint.Keybinding
---@field toggle_waypoint           nil | waypoint.Keybinding
---@field append_waypoint           nil | waypoint.Keybinding
---@field insert_waypoint           nil | waypoint.Keybinding
---@field append_annotated_waypoint nil | waypoint.Keybinding
---@field insert_annotated_waypoint nil | waypoint.Keybinding
---@field delete_waypoint           nil | waypoint.Keybinding

---@class waypoint.WaypointWindowKeybindingsOverride
---@field exit_waypoint_window     nil | waypoint.Keybinding
---@field increase_context         nil | waypoint.Keybinding
---@field decrease_context         nil | waypoint.Keybinding
---@field increase_before_context  nil | waypoint.Keybinding
---@field decrease_before_context  nil | waypoint.Keybinding
---@field increase_after_context   nil | waypoint.Keybinding
---@field decrease_after_context   nil | waypoint.Keybinding
---@field reset_context            nil | waypoint.Keybinding
---@field toggle_path              nil | waypoint.Keybinding
---@field toggle_full_path         nil | waypoint.Keybinding
---@field toggle_line_num          nil | waypoint.Keybinding
---@field toggle_file_text         nil | waypoint.Keybinding
---@field toggle_context           nil | waypoint.Keybinding
---@field toggle_sort              nil | waypoint.Keybinding
---@field show_help                nil | waypoint.Keybinding
---@field set_quickfix_list        nil | waypoint.Keybinding
---@field indent                   nil | waypoint.Keybinding
---@field unindent                 nil | waypoint.Keybinding
---@field reset_waypoint_indent    nil | waypoint.Keybinding
---@field reset_all_indent         nil | waypoint.Keybinding
---@field scroll_right             nil | waypoint.Keybinding
---@field scroll_left              nil | waypoint.Keybinding
---@field reset_horizontal_scroll  nil | waypoint.Keybinding
---@field next_waypoint            nil | waypoint.Keybinding
---@field prev_waypoint            nil | waypoint.Keybinding
---@field first_waypoint           nil | waypoint.Keybinding
---@field last_waypoint            nil | waypoint.Keybinding
---@field outer_waypoint           nil | waypoint.Keybinding
---@field inner_waypoint           nil | waypoint.Keybinding
---@field next_neighbor_waypoint   nil | waypoint.Keybinding
---@field prev_neighbor_waypoint   nil | waypoint.Keybinding
---@field next_top_level_waypoint  nil | waypoint.Keybinding
---@field prev_top_level_waypoint  nil | waypoint.Keybinding
---@field delete_waypoint          nil | waypoint.Keybinding
---@field current_waypoint         nil | waypoint.Keybinding
---@field move_waypoint_down       nil | waypoint.Keybinding
---@field move_waypoint_up         nil | waypoint.Keybinding
---@field move_waypoints_to_file   nil | waypoint.Keybinding
---@field move_waypoint_to_top     nil | waypoint.Keybinding
---@field move_waypoint_to_bottom  nil | waypoint.Keybinding
---@field undo                     nil | waypoint.Keybinding
---@field redo                     nil | waypoint.Keybinding

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
  enable_relative_waypoint_numbers = false,
  max_context = 20,
  waypoint_dir = vim.fn.stdpath("state") .. "/waypoint/",
  keybindings = {
    global_keybindings = {
      open_waypoint_window      = {"ms"},
      current_waypoint          = "mc",
      prev_waypoint             = "mp",
      next_waypoint             = "mn",
      first_waypoint            = "mg",
      last_waypoint             = "mG",
      prev_neighbor_waypoint    = "m[",
      next_neighbor_waypoint    = "m]",
      prev_top_level_waypoint   = "m{",
      next_top_level_waypoint   = "m}",
      outer_waypoint            = "mo",
      inner_waypoint            = "mi",

      toggle_waypoint           = "mt",

      append_waypoint           = "ma",
      insert_waypoint           = "mi",
      append_annotated_waypoint = "mA",
      insert_annotated_waypoint = "mI",
      delete_waypoint           = "md",
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
      toggle_path             = "sp",
      toggle_line_num         = "sn",
      toggle_full_path        = "sf",
      toggle_file_text        = "st",
      toggle_context          = "sc",
      toggle_sort             = "ss",
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
      move_waypoint_to_top    = "sgg",
      move_waypoint_to_bottom = "sG",
      move_waypoints_to_file  = "rw",
      undo                    = "u",
      redo                    = "<C-r>",
    },
    help_keybindings = {
      exit_help = {"q", "<esc>", "g?"}
    },
  },
  max_undo_history = 32,
  max_msg_history = 32,
}

return M
