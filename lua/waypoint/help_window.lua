local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.util")
local uw = require("waypoint.util_waypoint")

local kb_separator = " or "

M.global_keybindings_description = {
  {"append_waypoint"          ,  "Create a waypoint on the current line and add it to the waypoint list after the current waypoint"}               ,
  {"append_waypoint_end"      ,  "Create a waypoint on the current line and add it to the end of the waypoint list"}                               ,
  {"insert_waypoint_beginning",  "Create a waypoint on the current line and add it to the beginning of the waypoint list"}                         ,
  {"edit_waypoint_name"       ,  "Edit the name of the waypoint on the current line (if multiple are on the same line, priortizes bottom of list)"},
  {"delete_waypoint"          ,  "Delete the waypoint on the current line (if multiple are on the same line, priortizes bottom of list)"}          ,
  {"open_waypoint_window"     ,  "Show the waypoint window"}                                                                                       ,
  {"set_quickfix_list"        ,  "Set the quickfix list to locations of all waypoints"}                                                            ,
  {"undo_waypoint_action"     ,  "Undo the last change to any waypoint"}                                                                           ,
  {"clear_waypoint_name"      ,  "Clear the name of the waypoint on the current line if multiple are on the same line, priortizes bottom of list"} ,
}

M.waypoint_window_keybindings_description = {
  {"jump_to_waypoint"          , "Jump to current waypoint"}                                            ,
  {"next_waypoint"             , "Move to next waypoint"}                                               ,
  {"prev_waypoint"             , "Move to previous waypoint"}                                           ,
  {"first_waypoint"            , "Move to first waypoint"}                                              ,
  {"move_to_waypoint"          , "Move to waypoint [count], defaulting to last waypoint"}               ,
  {"delete_waypoint"           , "Delete current waypoint(s)"}                                          ,
  {"move_waypoint_down"        , "Move current waypoint(s) down"}                                       ,
  {"move_waypoint_up"          , "Move current waypoint(s) up"}                                         ,
  {"move_waypoint_to_top"      , "Move current waypoint(s) to top of waypoint list"}                    ,
  {"move_waypoint_to_bottom"   , "Move current waypoint(s) to bottom of waypoint list"}                 ,
  {"exit_waypoint_window"      , "Exit waypoint window"}                                                ,
  {"increase_context"          , "Increase context (number of lines shown around each waypoint)"}       ,
  {"decrease_context"          , "Decrease context (number of lines shown around each waypoint)"}       ,
  {"increase_before_context"   , "Increase before context (number of lines shown before each waypoint)"},
  {"decrease_before_context"   , "Decrease before context (number of lines shown before each waypoint)"},
  {"increase_after_context"    , "Increase after context (number of lines shown after each waypoint)"}  ,
  {"decrease_after_context"    , "Decrease after context (number of lines shown after each waypoint)"}  ,
  {"reset_context"             , "Set context, before context, and after context to zero"}              ,
  {"edit_waypoint_name"        , "Edit name of current waypoint"}                                       ,
  {"clear_waypoint_name"       , "Clear name of current waypoint"}                                      ,
  {"set_quickfix_list"         , "Set quickfix list to locations of all waypoints"}                     ,
  {"indent"                    , "Increase indentation of current waypoint"}                            ,
  {"unindent"                  , "Decrease indentation of current waypoint"}                            ,
  {"reset_waypoint_indent"     , "Set current waypoint's indentation to zero"}                          ,
  {"reset_all_indent"          , "Set indentation of all waypoints to zero"}                            ,
  {"reselect_visual"           , "Re-select previously selected range of waypoints"}                    ,
  {"transfer_waypoints_to_file", "Transfer waypoints from one file to another"}                         ,
  {"undo"                      , "Undo"}                                                                ,
  {"redo"                      , "Redo"}                                                                ,
  {"toggle_name"               , "Toggle name"}                                                         ,
  {"toggle_path"               , "Toggle column for file path"}                                         ,
  {"toggle_line_num"           , "Toggle column for line number"}                                       ,
  {"toggle_file_text"          , "Toggle column for file text "}                                        ,
  {"toggle_full_path"          , "Toggle whether full file path is shown vs. just file name"}           ,
  {"toggle_context"            , "Toggle whether context is shown"}                                     ,
  {"toggle_sort"               , "Toggle whether waypoints are sorted by file and line"}                ,
  {"show_help"                 , "Show this help window"}                                               ,
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

local function on_off(toggle)
  if toggle then
    return "ON    ", constants.hl_toggle_on
  else
    return "OFF   ", constants.hl_toggle_off
  end
end

function M.get_help_window_lines()
  local lines = {}
  local highlights = {}

  local show_path, show_path_hl = on_off(state.show_path)
  local show_line_num, show_line_num_hl = on_off(state.show_line_num)
  local show_waypoint_text, show_waypoint_text_hl = on_off(state.show_waypoint_text)
  local show_name, show_name_hl = on_off(state.show_name)
  local show_full_path, show_full_path_hl = on_off(state.show_full_path)
  local show_context, show_context_hl = on_off(state.show_context)
  local sort, sort_hl = on_off(state.sort_by_file_and_line)

  local toggles = {
    {"Show waypoint name", show_name, "Show file path", show_path, "Show line number", show_line_num, "Show waypoint text", show_waypoint_text},
    {"Show context", show_context, "Show full file path", show_full_path, "Sort by file and line number", sort, "", ""},
  }
  local toggle_highlights = {
    {constants.hl_keybinding, show_name_hl,    constants.hl_keybinding, show_path_hl, constants.hl_keybinding, show_line_num_hl, constants.hl_keybinding, show_waypoint_text_hl},
    {constants.hl_keybinding, show_context_hl, constants.hl_keybinding, show_full_path_hl, constants.hl_keybinding, sort_hl, {}, {}},
  }
  local indents = { 2, 2 }
  local col_types = {"string", "string", "string", "string", "string", "string", "string", "string"}
  local aligned_toggles = uw.align_waypoint_table(toggles, col_types, toggle_highlights, { indents = indents })
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
