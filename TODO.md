# TODO:

### MVP:

- [x] autosave
- [x] autoload
- [x] syntax highlighting for file text with vanilla vim syntax
- [x] syntax highlighting for file text with treesitter
- [x] user configuration
  - [x] keybinds with an on_attach(bufnr) function
  - [x] height / width
  - [x] file path
  - [x] color for mark
  - [x] color for annotation

### POLISH:

- [x] Waypoint window automatically resizes when window resizes
- [x] nicer colors / chars
  - [x] nicer unicode table chars
  - [x] nicer mark indicator chars
  - [x] color the mark indicator chars
  - [x] color the files
  - [x] color the line numbers
- [x] that weird scroll behavior I still can't figure out
- [x] the bug when saving and loading
- [x] the bug where marks at beginning/end of file don't have gaps
- [x] support for other movement-like keys
  - [x] H/M/L
  - [x] gg/G
  - [x] / and ?
  - [x] <C-d> and <C-u>
- [x] show A/B/C in footer of window
  - [x] make footer background equal to window background
- [x] limit horizontal scroll
- [x] look into whether the status line height messes up my window calculations
- [x] bug when navigated to from telescope
- [x] fix toggle bug
- [x] fix highlight when creating but not loading bug
- [x] only allow waypoints in files (e.g. not in nvim-tree)
- [x] remove annotations
- [x] left pad the file numbers instead of right padding
- [x] move cursor without triggering autocmd (excess draws)
- [x] handle weird interaction of / and scroll now that I have ignore_next_autocmd
    - have highlight in line, n, hhhhhh, n, l
- [x] keep track of the cursor position and restore to it when you open the floating window
- [x] fix bug where moving to bottom doesn't move view to bring bottom waypoint fully into view
- [x] goddamnit, I just realized the source of the bug. it's because the table chars are unicode, and therefore multiple chars long
    - nvim_win_get_cursor doesn't account for unicode.
    - solution: get rid of all uses of nvim_win_get_cursor and replace with vim.fn.getcurpos()
- [x] handle col vs curswant better so unicode doesn't confuse cursor state
- [x] fix syntax highlighting for makefile
- [x] don't allow growing then shrinking context to let the view go past the end of lines
- [x] fix issues with highlighting files you haven't opened yet
- [x] fix cursor jump bug when scrolling on window with short lines
- [x] pad each waypoint to width of window
- [x] add treesitter highlights
- [x] increase performance of highlighting
- [x] find out how TOhtml works with vanilla syntax and fix my vanilla syntax highlighter
- [x] fix all the extra spacing I put in the lua lsp type annotations
- [x] scope class declaration type annotations
- [x] figure out why my method of loading other files at startup doesn't work for treesitter highlights but does for vanilla
    - [x] figure out why some treesitter highlights aren't caught (e.g. headers in treesitter sometimes)
    - [x] figure out why some treesitter highlights seem to flicker
    - [x] figure out why some syntax highlights aren't caught (e.g. comments in zsh)
- [x] g? shows an alternate informational buffer when pressed in the floating window
- [x] allow numbers + motions
    - [x] allow number + j/k to move up number waypoints
    - [x] allow number + J/K to swap up number waypoints
    - [x] allow number + <> to indent number of times
- [x] keybind to swap waypoint to top of file
- [x] keybind to swap waypoint to bottom of file
- [x] get rid of the mark char in the floating window, it's redundant with the number
- [x] document common abbreviations in a comment somewhere
- [x] remove index hungarian, use comments instead
- [x] fix the bug where opening nvim-tree fucks up the window
- [x] add ability to toggle context
- [x] debug why buffers have line count 0 if you start a session made with mksession
- [x] fix bug where vanilla highlights at end of line don't get applied
- [x] make indentation saved by number of indents, not number of spaces
- config
- [x] g? shows keybinds
- [x] add bookmarks.nvim-style config validation
- [x] highlight table separators with WinSeparator
- [x] take indentation into account when padding rows so they all have the same number of spaces
- [x] add ability to move to next waypoint at the same indentation level
- [x] add ability to move to previous waypoint at one fewer indentation
- [x] add ability to move to previous waypoint at no indentation
- [x] handle the case where the file doesn't exist when opening
    - if the file doesn't exist, just show a message next to the waypoint that it doesn't exist, and don't allow the user to go to it.
- [x] think about maybe adding scrolloff so the next waypoint is always visible?
- [x] validate schema of file on load
- [x] in get_waypoint_context, if the file is out of bounds, show an out of bounds message
- [x] set max context in config
- [x] debug why treesitter highlights broke (confirmed that og syntax works)
- [x] indicate whether context for a mark is limited by file length (eof/bof)
- [x] do something about extmarks moving to top of file when you filter the whole file through some external tool (e.g. \b for biome for me)
  - [x] enrich data model
  - [x] listen on autocmd for state change
- [x] fix bug where buffers loaded by file.load don't have treesitter highlights (maybe regular ones too?)
- [x] fix my type annotations from table<T> to T[]
- [x] get rid of the optimization to vary the widths of the waypoint context if it hits eof or bof
- [x] add display of what toggles are on in the border of the waypoint window
- [x] fix all the lua lsp diagnostic warnings that you can
- [x] find out how telescope does
    - [x] releases (they use git tags)
    - [x] tests
- [x] change line numbers so they're stored 1-indexed
- [x] add a list of waypoint-specific messages
- [x] swap out nvim_buf_set_keymap for vim.keymap.set with {buffer = x} so I don't have to declare global lua functions
- [x] figure out some way to deal with extmarks moving around when you autoformat
- [x] tests
- [x] add ability to move all waypoints in a file to another file (fixes renaming file)
- [x] figure out how to make choosing a file to move waypoints to a good experience (telescope, fzf, etc)
- [x] fix bug where toggles don't change in help mode
- [x] fix bug where if you go to waypoint without extmark it prints a cryptic error
- [x] decide once and for all what I want to do about annotations
    - [x] annotations should be displayed instead of file text
- [x] add ability to add waypoint with annotation
- [x] make it so that waypoints get converted to saved waypoints when the buffer closes, and converted back to regular ones when the buffer is opened
    - use ryan fleury's megastruct idea.
- [x] fix visual mode issue (highlight 4-8/11, o, expand context 10 times, reset context)
    - [x] fix issue with not being able to move through tabs in visual mode
- [x] delete the toggle waypoint function
- [x] fix issue with tabs (or multiwidth chars) in file text
- [x] fix issue with col resetting on next/prev waypoint
- [x] remove state.view to simplify logic
- [x] add ability to add waypoint inserted after the current waypoint, not just at the end
    - [x] write tests for them
- [ ] increase the performance of highlights and draw calls in general
- [ ] think about persisting waypoints on every waypoint state change. maybe every time the waypoint window closes
    - [ ] take inspiration from harpoon and bookmarks about when the file gets saved and where
        - https://github.com/nvim-lua/plenary.nvim/blob/master/lua/plenary/path.lua
        - maybe use vim.schedule to do it async if worried about perf?
- [ ] fix bugs around closing buffers with waypoints in them (use BufDelete autocmd)
- [ ] write a test for a file getting renamed while open (use BufFilePost autocmd)
- [ ] add perf logging for each function (use require('jit.p'))
- [ ] switch to making new state for saving / loading instead of mutating existing state to get there
- [ ] create better error handling and reporting
    - [ ] if highlighting fails for some reason, just show an error message and turn off highlighting
- [ ] implement some kind of thing to handle errors and rollback state if you encounter them
- [ ] increase ability to recover from erroneous state (grep for <TBD>)
- [ ] remove all asserts from the code
    - [ ] replace them with something that will only panic in debug mode, and just log in release mode
- [ ] when you change directory, reload waypoints from file (DirChanged autocmd)
- [ ] see if you can fix the markdown header treesitter highlight bug
- [ ] get rid of the rest of the global lua functions in floating_window, replacing them with module-scoped functions
- [ ] add cumulative indent (in visual mode)
- [ ] write test for:
    - have waypoint in file
    - delete region of text with waypoint's extmark
    - waypoint should be deleted
    - undo text change
    - waypoint should be restored
- [ ] write test for:
    - have waypoint saved in json file
    - open vim
    - error opening file
    - waypoint should still be in "persisted mode"
    - waypoint should be restored
    - bulk delete, undo, redo (causes assertion error at the moment)
- [ ] think about adding some kind of error handling to draw_waypoint_window that will just display an error if pcall happens, so you don't have to fight through cumulative errors to close the window
- [ ] write documentation
    - [ ] quickstart workflow
    - [ ] video
- [ ] write alternatives
    - [ ] vim marks
        - can't reorder/indent
        - finite number
        - can only be per file or global, not per project
        - can't see context around mark
        - no syntax highlighting
        - tons of noise from the automatically populated marks
    - [ ] bookmarks.nvim
        - can't reorder/indent
        - state gets stale easily
        - can't see context around bookmark
        - no syntax highlighting
    - [ ] harpoon
        - only supports one mark per file
        - can't reorder/indent
        - can't see context around mark
- [ ] replace some of my homemade stuff with vim builtins
    - [x] vim.deepcopy
    - [ ] vim.ringbuf
- [ ] only highlight text that is currently on screen to save perf
    - [ ] make resize callback redraw the window so it will re-highlight

### ADVANCED FEATURES:

- [x] delete waypoint from floating window with dd
- [x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
- [x] quickfixlist for waypoints
- [x] telescope for waypoints
- [x] add some features from harpoon
  - [x] jump to currently selected waypoint while outside the float window
  - [x] jump to first waypoint while outside the float window
  - [x] jump to last waypoint while outside the float window
  - [x] jump to and select next waypoint while outside the float window
  - [x] jump to and select prev waypoint while outside the float window
- [x] view where everything is sorted by file by line
    - [x] keybind: ts to toggle sort 
- [x] add option for relative waypoint numbers
- [x] allow for fixing of waypoints for missing files, allowing user to switch all waypoints to a different file
- [ ] add ability to undo changing waypoints with u
    - [x] moving up and down
    - [x] moving waypoints to different files
    - [x] creating
    - [x] deleting
    - [x] indenting and unindenting
    - [x] moving waypoints to the top and bottom
    - [x] make the cursor behave better at undo (i.e. move to last change even if change didn't affect the wpi)
    - [ ] fix bugs with undo
        - [x] bug when you run sort test, delete, undo
        - [ ] bug when you run missing file test, delete a buffer, undo
- [ ] add soft deletes for waypoints
    - [ ] handle the case where the extmark gets deleted (hide the waypoint, but allow it to be brought back if they undo the extmark deletion)
    - [ ] when you undo and that causes a soft delete (i.e. waypoint in new state has no extmark), display a message that waypoint is not shown because its extmark was deleted
- [ ] add visual mode (use ModeChanged command and vim.api.nvim_get_mode().mode)
    - [x] stub visual mode
    - [x] make visual mode work correctly with context
    - [x] make gv work properly
        - [x] fix bug where reselect_visual doesn't account for context
    - [x] delete_waypoint
    - [ ] move_waypoint_down
    - [ ] move_waypoint_up
    - [ ] move_waypoint_to_top
    - [ ] move_waypoint_to_bottom
    - [ ] exit_waypoint_window
    - [ ] increase_context
    - [ ] decrease_context
    - [ ] increase_before_context
    - [ ] decrease_before_context
    - [ ] increase_after_context
    - [ ] decrease_after_context
    - [ ] reset_context
    - [ ] toggle_path
    - [ ] toggle_full_path
    - [ ] toggle_line_num
    - [ ] toggle_file_text
    - [ ] toggle_context
    - [ ] toggle_sort
    - [ ] show_help
    - [ ] set_quickfix_list
    - [ ] indent
    - [ ] unindent
    - [ ] reset_waypoint_indent
    - [ ] reset_all_indent
    - [ ] reselect_visual
    - [ ] next_waypoint
    - [ ] prev_waypoint
    - [ ] first_waypoint
    - [ ] last_waypoint
    - [ ] outer_waypoint
    - [ ] inner_waypoint
    - [ ] prev_neighbor_waypoint
    - [ ] next_neighbor_waypoint
    - [ ] prev_top_level_waypoint
    - [ ] next_top_level_waypoint
    - [ ] move_waypoints_to_file
    - [ ] undo
    - [ ] redo


still got some weird treesitter behavior
it seems like in the skhd repo I'm using, it will only properly highlight some highlights if the highlight is onscreen or close to it
some, like header 2, appear to never work

look into TextChanged, TextChangedI, and FileChangedShell autocmds for watching
when a file changed in order to keep the extmarks in the right place as the
file changes

There isn't an autommand for all file changes. here's a list of ones you should cover:

FileChangedShell file changed by something besides vim
    locate_waypoints_in_file as if new load
    covers delete and external rename case

redundancy?
store extmark id, text, line number
when extmark updates, update text and line number too
what to do if buffer update causes two extmarks to be on the same line?
what to do if buffer updates and location can't be found?
what to do if file changes name or is deleted?

how to use luajit profiler
https://luajit.org/ext_profiler.html

require('jit.p').start('f', '/tmp/nvim_profile.txt')

-- Execute the code you want to profile, for example:
-- require('my_slow_plugin').some_function()
-- Or run a series of complex edits

-- Stop the session and write the profile
require('jit.p').stop()

for undo:
if you undo a change and the extmark doesn't exist, recreate it at its old line number.
if it does exist, just point at that extmark. 
this could easily be stale, but I think that's fine. I don't want to disorient
with use of the levenshtein match finder on simple actions like undo, and I
think it's fine if the extmark is gone for the line number to be stale
otherwise, would have to always keep phantom extmarks for every state in the undo history. not reasonable.

extmark recap:
extmark id of nil means bufferless waypoint
extmark id of -1 means out of bounds
extmark id that should be valid but has no extmark = don't show the waypoint, its mark was deleted.

normal file undo test
make 3 waypoints
delete one extmark by editing file
should not show in window
undo file edit
should show in window again

weird file undo test
make 3 waypoints
delete one waypoint in waypoint window
edit file, erasing the line where the waypoint was
undo deletion of waypoint in waypoint window
should show as error: can't locate file with text \<text\>
    should try to locate un-deleted waypoint with nonexistent extmark same way as in loaded file

weird file undo test #2
make 3 waypoints
delete waypoint #1 in waypoint window
delete waypoint #2 by erasing its extmark
edit file, erasing the line where waypoint #1 was
undo deletion of waypoint in waypoint window
how to disambiguate between intentional delete/undo vs just waypoint with stale extmark?
    have to retain some state somewhere I guess

