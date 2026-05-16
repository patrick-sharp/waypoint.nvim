---@class waypoint.Config
---@field color_sign                       string
---@field color_footer_after_context       string
---@field color_footer_before_context      string
---@field color_footer_context             string
---@field color_toggle_on                  string
---@field color_toggle_off                 string
---@field window_width                     number
---@field window_height                    number
---@field file                             string the file where waypoints are saved
---@field mark_char                        string
---@field telescope_filename_width         integer
---@field telescope_linenr_width           integer
---@field indent_width                     integer
---@field scroll_increment                 integer
---@field enable_highlight                 boolean
---@field enable_relative_waypoint_numbers boolean
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
---@field open_waypoint_window      waypoint.Keybinding
---@field append_waypoint           waypoint.Keybinding
---@field insert_waypoint           waypoint.Keybinding
---@field append_annotated_waypoint waypoint.Keybinding
---@field insert_annotated_waypoint waypoint.Keybinding
---@field delete_waypoint           waypoint.Keybinding

---@class waypoint.WaypointWindowKeybindings
---@field exit_waypoint_window       waypoint.Keybinding
---@field increase_context           waypoint.Keybinding
---@field decrease_context           waypoint.Keybinding
---@field increase_before_context    waypoint.Keybinding
---@field decrease_before_context    waypoint.Keybinding
---@field increase_after_context     waypoint.Keybinding
---@field decrease_after_context     waypoint.Keybinding
---@field reset_context              waypoint.Keybinding
---@field toggle_name                waypoint.Keybinding
---@field toggle_path                waypoint.Keybinding
---@field toggle_full_path           waypoint.Keybinding
---@field toggle_line_num            waypoint.Keybinding
---@field toggle_file_text           waypoint.Keybinding
---@field toggle_context             waypoint.Keybinding
---@field toggle_sort                waypoint.Keybinding
---@field show_help                  waypoint.Keybinding
---@field set_quickfix_list          waypoint.Keybinding
---@field indent                     waypoint.Keybinding
---@field unindent                   waypoint.Keybinding
---@field reset_waypoint_indent      waypoint.Keybinding
---@field reset_all_indent           waypoint.Keybinding
---@field next_waypoint              waypoint.Keybinding
---@field prev_waypoint              waypoint.Keybinding
---@field first_waypoint             waypoint.Keybinding
---@field delete_waypoint            waypoint.Keybinding
---@field jump_to_waypoint           waypoint.Keybinding
---@field move_to_waypoint           waypoint.Keybinding
---@field move_waypoint_down         waypoint.Keybinding
---@field move_waypoint_up           waypoint.Keybinding
---@field transfer_waypoints_to_file waypoint.Keybinding
---@field move_waypoint_to_top       waypoint.Keybinding
---@field move_waypoint_to_bottom    waypoint.Keybinding
---@field undo                       waypoint.Keybinding
---@field redo                       waypoint.Keybinding
---@field reselect_visual            waypoint.Keybinding

---@class waypoint.HelpKeybindings
---@field exit_help string | string[]



-- Classes for the user's config provided on plugin setup

---@class waypoint.ConfigOverride
---@field color_sign                       string?
---@field color_footer_after_context       string?
---@field color_footer_before_context      string?
---@field color_footer_context             string?
---@field color_toggle_on                  string?
---@field color_toggle_off                 string?
---@field window_width                     number?
---@field window_height                    number?
---@field file                             string?
---@field mark_char                        string?
---@field telescope_filename_width         integer?
---@field telescope_linenr_width           integer?
---@field indent_width                     integer?
---@field scroll_increment                 integer?
---@field enable_highlight                 boolean?
---@field enable_relative_waypoint_numbers boolean?
---@field waypoint_dir                     string?
---@field keybindings                      waypoint.Keybindings?
---@field max_undo_history                 integer?
---@field max_msg_history                  integer?

---@class waypoint.KeybindingsOverride
---@field global_keybindings          waypoint.GlobalKeybindingsOverride?
---@field waypoint_window_keybindings waypoint.WaypointWindowKeybindingsOverride?
---@field help_keybindings            waypoint.HelpKeybindingsOverride?
---
---@class waypoint.GlobalKeybindingsOverride
---@field open_waypoint_window      waypoint.Keybinding?
---@field append_waypoint           waypoint.Keybinding?
---@field insert_waypoint           waypoint.Keybinding?
---@field append_annotated_waypoint waypoint.Keybinding?
---@field insert_annotated_waypoint waypoint.Keybinding?
---@field delete_waypoint           waypoint.Keybinding?

---@class waypoint.WaypointWindowKeybindingsOverride
---@field exit_waypoint_window       waypoint.Keybinding?
---@field increase_context           waypoint.Keybinding?
---@field decrease_context           waypoint.Keybinding?
---@field increase_before_context    waypoint.Keybinding?
---@field decrease_before_context    waypoint.Keybinding?
---@field increase_after_context     waypoint.Keybinding?
---@field decrease_after_context     waypoint.Keybinding?
---@field reset_context              waypoint.Keybinding?
---@field toggle_name                waypoint.Keybinding?
---@field toggle_path                waypoint.Keybinding?
---@field toggle_full_path           waypoint.Keybinding?
---@field toggle_line_num            waypoint.Keybinding?
---@field toggle_file_text           waypoint.Keybinding?
---@field toggle_context             waypoint.Keybinding?
---@field toggle_sort                waypoint.Keybinding?
---@field show_help                  waypoint.Keybinding?
---@field set_quickfix_list          waypoint.Keybinding?
---@field indent                     waypoint.Keybinding?
---@field unindent                   waypoint.Keybinding?
---@field reset_waypoint_indent      waypoint.Keybinding?
---@field reset_all_indent           waypoint.Keybinding?
---@field next_waypoint              waypoint.Keybinding?
---@field prev_waypoint              waypoint.Keybinding?
---@field first_waypoint             waypoint.Keybinding?
---@field delete_waypoint            waypoint.Keybinding?
---@field jump_to_waypoint           waypoint.Keybinding?
---@field move_to_waypoint           waypoint.Keybinding?
---@field move_waypoint_down         waypoint.Keybinding?
---@field move_waypoint_up           waypoint.Keybinding?
---@field transfer_waypoints_to_file waypoint.Keybinding?
---@field move_waypoint_to_top       waypoint.Keybinding?
---@field move_waypoint_to_bottom    waypoint.Keybinding?
---@field undo                       waypoint.Keybinding?
---@field redo                       waypoint.Keybinding?
---@field reselect_visual            waypoint.Keybinding?

---@class waypoint.HelpKeybindingsOverride
---@field exit_help nil | string | string[]


---@type waypoint.Config
local M = {
  color_sign = "NONE",
  color_footer_after_context = "#ff7777",
  color_footer_before_context = "#77ff77",
  color_footer_context = "#7777ff",
  color_toggle_on = "#50C878",
  -- color_toggle_on = "#04a307",
  color_toggle_off = "#777777",
  window_width = 0.85,
  window_height = 0.85,
  file = "waypoint.nvim.json",
  mark_char = "◆",
  telescope_filename_width = 30,
  telescope_linenr_width = 5,
  indent_width = 4,
  scroll_increment = 6,
  enable_highlight = true,
  enable_relative_waypoint_numbers = false,
  waypoint_dir = vim.fn.stdpath("state") .. "/waypoint/",
  keybindings = {
    global_keybindings = {
      open_waypoint_window      = {"ms"},
      append_waypoint           = "ma",
      insert_waypoint           = "mi",
      append_annotated_waypoint = "mA",
      insert_annotated_waypoint = "mI",
      delete_waypoint           = "md",
    },
    waypoint_window_keybindings = {
      exit_waypoint_window        = {"ms", "<esc>", "<C-c>"},
      increase_context            = "c",
      decrease_context            = "C",
      increase_before_context     = "b",
      decrease_before_context     = "B",
      increase_after_context      = "a",
      decrease_after_context      = "A",
      toggle_name                 = "mn",
      toggle_path                 = "mp",
      toggle_line_num             = "ml",
      toggle_file_text            = "mt",
      toggle_full_path            = "mf",
      toggle_context              = "mc",
      toggle_sort                 = "ms",
      show_help                   = "g?",
      set_quickfix_list           = "mq",
      indent                      = ">",
      unindent                    = "<",
      reset_context               = "rc",
      reset_waypoint_indent       = "ri",
      reset_all_indent            = "rI",
      prev_waypoint               = "k",
      next_waypoint               = "j",
      first_waypoint              = "gg",
      delete_waypoint             = "d",
      jump_to_waypoint            = "<CR>",
      move_to_waypoint            = "G",
      move_waypoint_up            = "K",
      move_waypoint_down          = "J",
      move_waypoint_to_top        = "mgg",
      move_waypoint_to_bottom     = "mG",
      transfer_waypoints_to_file  = "mT",
      undo                        = "u",
      redo                        = "<C-r>",
      reselect_visual             = "gv",
    },
    help_keybindings = {
      exit_help = {"q", "<esc>", "g?"}
    },
  },
  max_undo_history = 100,
  max_msg_history = 100,
}

return M
