# waypoint.nvim

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
[x] Bookmarks window automatically resizes when window resizes
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
[x] only allow bookmarks in files (e.g. not in nvim-tree)
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
[ ] fix bugs around closing buffers with waypoints in them
[ ] indent after the waypoint number (this will be a pain)
[ ] think about persisting waypoints on every waypoint state change
[ ] indicate whether context for a mark is limited by file length (eof/bof)
[ ] fix all the extra spacing I put in the lua lsp type annotations
[ ] scope class declaration type annotations
[ ] figure out why my method of loading other files at startup doesn't work for treesitter highlights but does for vanilla
[ ] add bookmarks.nvim-style config validation
[ ] popup with keybind info when you press g?
[ ] take inspiration from harpoon and bookmarks about when the file gets saved and where
[ ] add keybind to swap waypoint and all its subindented waypoints
[ ] allow numbers + motions
    [ ] allow number + j/k to move up number waypoints
    [ ] allow number + J/K to swap up number waypoints
[ ] keybind to swap waypoint to top of file
[ ] cache the highlights for each line to increase performance
[x] get rid of the mark char in the floating window, it's redundant with the number
[ ] get rid of the optimization to vary the widths of the waypoint context if it hits eof or bof
    [ ] use the optimization afforded by that to only render waypoints + contexts currently on screen
[ ] add annotations back in
[ ] highlight table separators with WinSeparator
[ ] document abbreviations
    wp
    linenr
    bufnr
    winnr
[ ] remove index hungarian, use comments instead


### ADVANCED FEATURES:
[x] delete waypoint from floating window with dd
[x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[x] quickfixlist for waypoints
[x] telescope for waypoints
[ ] add some features from harpoon
  [ ] jump to currently selected waypoint while outside the float window
  [ ] jump to first waypoint while outside the float window
  [ ] jump to last waypoint while outside the float window
  [ ] jump to and select next waypoint while outside the float window
  [ ] jump to and select prev waypoint while outside the float window
[ ] add visual mode

local self = TSHighlighter.active[buf]
there's nothing active.
I need to find out where the active highlighter gets set.

