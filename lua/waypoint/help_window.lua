local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.util")
local uw = require("waypoint.util_waypoint")

local kb_separator = " or "

M.global_keybindings_description = {
  {"append_waypoint"          ,  "Create a waypoint on the current line, and add it to end of the waypoint list"}                      ,
  {"insert_waypoint"          ,  "Create a waypoint on the current line, and add it immediately after the current waypoint"}           ,
  {"append_annotated_waypoint",  "Create an annotated waypoint on the current line, and add it to end of the waypoint list"}           ,
  {"insert_annotated_waypoint",  "Create an annotated waypoint on the current line, and add it immediately after the current waypoint"},
  {"delete_waypoint"          ,  "Delete the waypoint on the current line"}                                                            ,
  {"open_waypoint_window"     ,  "Show the waypoint window"}                                                                           ,
}

M.waypoint_window_keybindings_description = {
  {"jump_to_waypoint"          , "Jump to the current waypoint's location"}                     ,
  {"delete_waypoint"           , "Delete the current waypoint from the waypoint list"}          ,
  {"move_waypoint_down"        , "Move the current waypoint before the previous waypoint"}      ,
  {"move_waypoint_up"          , "Move the current waypoint after the next waypoint"}           ,
  {"move_waypoint_to_top"      , "Move the current waypoint to the top of the waypoint list"}   ,
  {"move_waypoint_to_bottom"   , "Move the current waypoint to the bottom of the waypoint list"},
  {"exit_waypoint_window"      , "Exit the waypoint window"}                                    ,
  {"increase_context"          , "Increase the number of lines shown around each waypoint"}     ,
  {"decrease_context"          , "Decrease the number of lines shown around each waypoint"}     ,
  {"increase_before_context"   , "Increase the number of lines shown before each waypoint"}     ,
  {"decrease_before_context"   , "Decrease the number of lines shown before each waypoint"}     ,
  {"increase_after_context"    , "Increase the number of lines shown after each waypoint"}      ,
  {"decrease_after_context"    , "Decrease the number of lines shown after each waypoint"}      ,
  {"reset_context"             , "Show no lines around each waypoint"}                          ,
  {"toggle_path"               , "Toggle whether the file path appears"}                        ,
  {"toggle_full_path"          , "Toggle whether the full file path appears"}                   ,
  {"toggle_line_num"           , "Toggle whether the line number appears"}                      ,
  {"toggle_file_text"          , "Toggle whether the file text appears"}                        ,
  {"toggle_context"            , "Toggle whether any lines are shown around each waypoint"}     ,
  {"toggle_sort"               , "Toggle whether waypoints are sorted by file and line"}        ,
  {"show_help"                 , "Show this help window"}                                       ,
  {"set_quickfix_list"         , "Set the quickfix list to locations of all waypoints"}         ,
  {"indent"                    , "Increase the indentation of the current waypoint"}            ,
  {"unindent"                  , "Decrease the indentation of the current waypoint"}            ,
  {"reset_waypoint_indent"     , "Set the current waypoint's indentation to zero"}              ,
  {"reset_all_indent"          , "Set the indentation of all waypoints to zero"}                ,
  {"reselect_visual"           , "Re-select the previously selected range of waypoints"}        ,
  {"next_waypoint"             , "Move to the next waypoint in the waypoint window"}            ,
  {"prev_waypoint"             , "Move to the previous waypoint in the waypoint window"}        ,
  {"first_waypoint"            , "Move to the first waypoint in the waypoint window"}           ,
  {"last_waypoint"             , "Move to the last waypoint in the waypoint window"}            ,
  {"transfer_waypoints_to_file", "Transfer waypoints from one file to another file"}            ,
  {"undo"                      , "Undo the last change to the waypoints"}                       ,
  {"redo"                      , "Redo the last undone change to the waypoints"}                ,
}

M.help_keybindings_description = {
  {"exit_help", "Exit help and return to the waypoint window"},
}

---@param kb_group table
---@return integer
local function find_max_keybinding_width(kb_group)
  local kb_width_override = 0
  for _,v in pairs(kb_group) do
    local width
    if type(v) == "string" then
      width = u.vislen(v)
    else
      width = 0
      for i, kb_ in ipairs(v) do
        width = width + u.vislen(kb_)
        if i < #v then
          width = width + u.vislen(kb_separator)
        end
      end
    end
    kb_width_override = math.max(kb_width_override, width)
  end
  return kb_width_override
end

local function find_max_kb_desc_width(kb_group)
  local result = 0

  for _, kb in ipairs(kb_group) do
    local width = u.vislen(kb[2])
    if width > result then
      result = width
    end
  end

  return result
end

local kb_width_override = 0
kb_width_override = math.max(kb_width_override, find_max_keybinding_width(config.keybindings.global_keybindings))
kb_width_override = math.max(kb_width_override, find_max_keybinding_width(config.keybindings.waypoint_window_keybindings))
kb_width_override = math.max(kb_width_override, find_max_keybinding_width(config.keybindings.help_keybindings))

local kb_description_width_override = 0
kb_description_width_override = math.max(kb_description_width_override, find_max_kb_desc_width(config.keybindings.global_keybindings))
kb_description_width_override = math.max(kb_description_width_override, find_max_kb_desc_width(config.keybindings.waypoint_window_keybindings))
kb_description_width_override = math.max(kb_description_width_override, find_max_kb_desc_width(config.keybindings.help_keybindings))


---@param lines string[]
---@param highlights waypoint.HighlightRange[][][]
---@param keybindings_group table
---@param keybindings_description table
---@param keybindings_group_title string
---@param keybindings_group_name string
---@param width_override (integer?)[]?
local function insert_lines_for_keybindings(lines, highlights, keybindings_group, keybindings_description, keybindings_group_title, keybindings_group_name, width_override)
  table.insert(lines, "")
  table.insert(lines, keybindings_group_title .. " keybindings")
  table.insert(highlights, {})
  table.insert(highlights, {})

  local keybindings = {}
  local keybindings_highlights = {}
  local indents = {}

  for _, action_and_description in pairs(keybindings_description) do
    indents[#indents+1] = 2
    local action = action_and_description[1]
    local description = action_and_description[2]
    assert(keybindings_group[action], "No " .. keybindings_group_name.. " keybinding found for " .. action)
    local kb
    local kb_hl
    if type(keybindings_group[action]) == 'string' then
      kb = { keybindings_group[action], description, }
      kb_hl = {
        {{
          nsid = constants.ns,
          hl_group = constants.hl_keybinding,
          col_start = 1,
          col_end = #keybindings_group[action],
        }},
        {},
      }
    elseif type(keybindings_group[action]) == 'table' then
      local kb_col = {}
      local kb_hl_col = {}
      local offset = 1
      for i, kb_ in ipairs(keybindings_group[action]) do
        table.insert(kb_col, kb_)
        table.insert(kb_hl_col, {
          nsid = constants.ns,
          hl_group = constants.hl_keybinding,
          col_start = offset,
          col_end = offset + #kb_ - 1,
        })
        offset = offset + #kb_ + #kb_separator
        if i < #keybindings_group[action] then
          table.insert(kb_col, kb_separator)
        end
      end
      kb = {table.concat(kb_col), description}
      kb_hl = {kb_hl_col, {}}
    else
      error("Type of " .. keybindings_group_name.. " keybinding for" .. action .. " should be string or table")
    end
    table.insert(keybindings, kb)
    table.insert(keybindings_highlights, kb_hl)
  end
  local aligned_keybindings = uw.align_waypoint_table(
    keybindings,
    {"string", "string"},
    keybindings_highlights,
    {
      column_separator = "",
      width_override = width_override,
      indents = indents,
    }
  )
  for i=1,#keybindings do
    table.insert(lines, aligned_keybindings[i])
    local row_highlights = {}
    for j=1,#keybindings_highlights[i] do
      for k=1,#keybindings_highlights[i][j] do
        table.insert(row_highlights, keybindings_highlights[i][j][k])
      end
    end
    table.insert(highlights, row_highlights)
  end
end

function M.get_help_window_lines()
  local lines = {}
  local highlights = {}

  -- info about state
  local prop_names = {
    {"show_path", "Show file path"},
    {"show_line_num", "Show line number"},
    {"show_waypoint_text", "Show waypoint text"},
    "",
    {"show_full_path", "Show full file path"},
    {"show_context", "Show context"},
    {"sort_by_file_and_line", "Sort by file and line number"},
  }

  ---@type string[][]
  local toggles = {}
  ---@type waypoint.HighlightRange[][][]
  local toggle_highlights = {}
  ---@integer[]
  local indents = {}
  for _,key_name in ipairs(prop_names) do
    indents[#indents+1] = 2
    if key_name == "" then
      table.insert(toggles, {"", ""})
      table.insert(toggle_highlights, {{}, {}})
    else
      local key = key_name[1]
      local name = key_name[2]
      local on_off
      local hl_group
      if state[key] then
        on_off = "ON"
        hl_group = constants.hl_toggle_on
      else
        on_off = "OFF"
        hl_group = constants.hl_toggle_off
      end
      table.insert(toggles, { name, on_off })
      table.insert(toggle_highlights,
        {{}, {{
          nsid = constants.ns,
          hl_group = hl_group,
          col_start = 1,
          col_end = #on_off,
        }}}
      )
    end
  end
  local aligned_toggles = uw.align_waypoint_table(toggles, {"string", "string"}, toggle_highlights, { indents = indents})
  table.insert(lines, "Toggles")
  table.insert(highlights, {})
  for i=1,#toggles do
    table.insert(lines, aligned_toggles[i])
    local row_highlights = {}
    for j=1,#toggle_highlights[i] do
      for k=1,#toggle_highlights[i][j] do
        table.insert(row_highlights, toggle_highlights[i][j][k])
      end
    end
    table.insert(highlights, row_highlights)
  end

  -- show keybindings

  local width_override = {kb_width_override, kb_description_width_override}

  insert_lines_for_keybindings(lines, highlights, config.keybindings.global_keybindings, M.global_keybindings_description, "Global", "global", width_override)
  insert_lines_for_keybindings(lines, highlights, config.keybindings.waypoint_window_keybindings, M.waypoint_window_keybindings_description, "Waypoint window", "waypoint window", width_override)
  insert_lines_for_keybindings(lines, highlights, config.keybindings.help_keybindings, M.help_keybindings_description, "Help", "help", width_override)

  assert(#lines == #highlights)
  return lines, highlights
end

return M
