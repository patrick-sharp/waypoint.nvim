# waypoint.nvim

## Abbreviations used in this codebase

I frequently use the following abbreviations in this codebase:
* wp: waypoint
* wpi: waypoint index, the index of the currently selected waypoint
* bufnr: buffer number
* linenr: line number
* winnr: window numbe
* ts: treesitter, the language parser library


## TODO:

### MVP:
[x] autosave
[x] autoload
[x] syntax highlighting for file text with vanilla vim syntax
[x] syntax highlighting for file text with treesitter
[x] user configuration
  [ ] keybinds with an on_attach(bufnr) function
  [x] height / width
  [x] file path
  [x] color for mark
  [x] color for annotation

### POLISH:
[x] Waypoint window automatically resizes when window resizes
[x] nicer colors / chars
  [x] nicer unicode table chars
  [x] nicer mark indicator chars
  [x] color the mark indicator chars
  [x] color the files
  [x] color the line numbers
[x] that weird scroll behavior I still can't figure out
[x] the bug when saving and loading
[x] the bug where marks at beginning/end of file don't have gaps
[x] support for other movement-like keys
  [x] H/M/L
  [x] gg/G
  [x] / and ?
  [x] <C-d> and <C-u>
[x] show A/B/C in footer of window
  [x] make footer background equal to window background
[x] limit horizontal scroll
[x] look into whether the status line height messes up my window calculations
[x] bug when navigated to from telescope
[x] fix toggle bug
[x] fix highlight when creating but not loading bug
[x] only allow waypoints in files (e.g. not in nvim-tree)
[x] remove annotations
[x] left pad the file numbers instead of right padding
[x] move cursor without triggering autocmd (excess draws)
[x] handle weird interaction of / and scroll now that I have ignore_next_autocmd
    have highlight in line, n, hhhhhh, n, l
[x] keep track of the cursor position and restore to it when you open the floating window
[x] fix bug where moving to bottom doesn't move view to bring bottom waypoint fully into view
[x] goddamnit, I just realized the source of the bug. it's because the table chars are unicode, and therefore multiple chars long
    nvim_win_get_cursor doesn't account for unicode.
    solution: get rid of all uses of nvim_win_get_cursor and replace with vim.fn.getcurpos()
[x] handle col vs curswant better so unicode doesn't confuse cursor state
[x] fix syntax highlighting for makefile
[x] don't allow growing then shrinking context to let the view go past the end of lines
[x] fix issues with highlighting files you haven't opened yet
[x] fix cursor jump bug when scrolling on window with short lines
[x] pad each waypoint to width of window
[x] add treesitter highlights
[x] increase performance of highlighting
[x] find out how TOhtml works with vanilla syntax and fix my vanilla syntax highlighter
[x] fix all the extra spacing I put in the lua lsp type annotations
[x] scope class declaration type annotations
[x] figure out why my method of loading other files at startup doesn't work for treesitter highlights but does for vanilla
    [x] figure out why some treesitter highlights aren't caught (e.g. headers in treesitter sometimes)
    [x] figure out why some treesitter highlights seem to flicker
    [x] figure out why some syntax highlights aren't caught (e.g. comments in zsh)
[x] g? shows an alternate informational buffer when pressed in the floating window
[x] allow numbers + motions
    [x] allow number + j/k to move up number waypoints
    [x] allow number + J/K to swap up number waypoints
    [x] allow number + <> to indent number of times
[x] keybind to swap waypoint to top of file
[x] keybind to swap waypoint to bottom of file
[ ] increase the performance of highlights and draw calls in general
[x] get rid of the mark char in the floating window, it's redundant with the number
[x] document common abbreviations in a comment somewhere
[x] remove index hungarian, use comments instead
[x] fix the bug where opening nvim-tree fucks up the window
[x] add ability to toggle context
[x] debug why buffers have line count 0 if you start a session made with mksession
[x] fix bug where vanilla highlights at end of line don't get applied
[x] make indentation saved by number of indents, not number of spaces
config
[ ] g? shows keybinds
[ ] add bookmarks.nvim-style config validation
[ ] think about persisting waypoints on every waypoint state change
[ ] take inspiration from harpoon and bookmarks about when the file gets saved and where
    https://github.com/nvim-lua/plenary.nvim/blob/master/lua/plenary/path.lua
    maybe use vim.schedule to do it async if worried about perf?
[ ] get rid of the optimization to vary the widths of the waypoint context if it hits eof or bof
    [ ] use the optimization afforded by that to only render waypoints + contexts currently on screen
[ ] highlight table separators with WinSeparator
[ ] take indentation into account when padding rows so they all have the same number of spaces
[ ] find out how nvim tree seems to dynamically adjust the brightness of the cursorline (NvimTreeCursorLine)
keybinds
[ ] add keybind to swap waypoint and all its subindented waypoints
[ ] add ability to move to next waypoint at the same indentation level
[ ] add ability to move to previous waypoint at one fewer indentation
[ ] add ability to move to previous waypoint at no indentation
bugs
[ ] fix bugs around closing buffers with waypoints in them
[ ] handle the case where the file doesn't exist when opening
[ ] handle the case where the file gets renamed while open
[ ] when you expand the context, keep the selected waypoint at the same point in the window rather than centering on it
features
[ ] add annotations back in
[ ] indicate whether context for a mark is limited by file length (eof/bof)
[ ] limit context size to the size of the window

### ADVANCED FEATURES:
[x] delete waypoint from floating window with dd
[x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[x] quickfixlist for waypoints
[x] telescope for waypoints
[x] add some features from harpoon
  [x] jump to currently selected waypoint while outside the float window
  [x] jump to first waypoint while outside the float window
  [x] jump to last waypoint while outside the float window
  [x] jump to and select next waypoint while outside the float window
  [x] jump to and select prev waypoint while outside the float window
[ ] add visual mode
