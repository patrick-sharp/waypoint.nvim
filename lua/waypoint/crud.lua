local M = {}
local state = require("waypoint.state")
local utils = require("waypoint.utils")
local constants = require("waypoint.constants")

function M.remove_waypoint(bufnr, file_path, cur_line_nr)
  local extmark_id = utils.get_in(state.waypoints, {file_path, cur_line_nr}).extmark_id
  vim.api.nvim_buf_del_extmark(bufnr, constants.waypoint_ns, extmark_id)
  utils.delete_in(state.waypoints, {file_path, cur_line_nr})

  ---@type table<Waypoint>
  local new_waypoints = {}
  for waypoint in pairs(state.window.waypoints) do
    if not (waypoint.file_path == file_path and waypoint.line_nr == cur_line_nr) then
      table.insert(new_waypoints, waypoint)
    end
  end
  state.window.waypoints = new_waypoints
end

function M.toggle_waypoint()
  --- @type string
  local file_path = vim.fn.expand("%")

  --- @type integer
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number

  local existing_waypoint = utils.get_in(state.waypoints, {file_path, cur_line_nr})
  print(vim.inspect(existing_waypoint))

  ---@type integer
  local bufnr = vim.api.nvim_get_current_buf()

  if not existing_waypoint then
    local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.waypoint_ns, cur_line_nr - 1, -1, {
      id = cur_line_nr,
      sign_text = ">",
      priority = 1,
      sign_hl_group = constants.hl_group,
      -- number_hl_group = "waypoints_hl_nr",
      -- line_hl_group = "waypoints_hl_ln",
      virt_text = { {"  <===■■===> Highlighted Text", constants.hl_group} },  -- "Error" is a predefined highlight group
      virt_text_pos = "eol",  -- Position at end of line
      --virt_text_pos = "overlay",
      --hl_group = "Search",
    })

    -- local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.waypoint_ns, cur_line_nr - 1, -1, {
    --   sign_text = "0",
    --   sign_hl_group = "MyBlueHighlight",  -- This highlights the marked character in blue
    --   virt_text = { {" Blue Text", "MyBlueHighlight"} },  -- Virtual text in blue
    --   virt_text_pos = "eol",  -- Position at the end of the line
    -- })

    ---@type Waypoint
    local waypoint = {
      filepath = file_path,
      line_nr = cur_line_nr,
      line_text = vim.api.nvim_get_current_line(),
      annotation = "default annotation",
      extmark_id = extmark_id,
    }
    utils.set_in(state.waypoints, {file_path, cur_line_nr}, waypoint)
    table.insert(state.window.waypoints, waypoint)
  else
    M.remove_waypoint(bufnr, file_path, cur_line_nr)
  end
  vim.cmd("highlight " .. constants.hl_group .. " guifg=" .. constants.color .. " guibg=NONE") -- Blue text, no background
end

return M
