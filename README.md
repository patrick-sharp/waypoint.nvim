# waypoint.nvim

## TODO:

### MVP:
[x] autosave
[x] autoload
[ ] syntax highlighting for file text
[x] user configuration
  [ ] keybinds
  [x] height / width
  [x] file path
  [x] color for mark
  [x] color for annotation

### POLISH:
[x] Bookmarks window automatically resizes when window resizes
[ ] nicer colors / chars
  [x] nicer unicode table chars
  [ ] nicer mark indicator chars
  [ ] color the mark indicator chars
  [ ] color the table chars differently than text
  [ ] color the files
  [ ] color the line numbers
  [ ] color the mark numbers (or get rid of them)
[ ] popup with keybind info when you press g?
[x] that weird scroll behavior I still can't figure out
[x] the bug when saving and loading
[x] the bug where marks at beginning/end of file don't have gaps
[x] support for other movement-like keys
  [x] H/M/L
  [x] gg/G
  [x] / and ?
  [x] <C-d> and <C-u>
[x] show A/B/C in footer of window
  [ ] make footer background equal to window background
[x] limit horizontal scroll
[x] look into whether the status line height messes up my window calculations
[x] bug when navigated to from telescope
[x] fix toggle bug
[x] fix highlight when creating but not loading bug
[x] only allow bookmarks in files (e.g. not in nvim-tree)
[ ] remove annotations
[x] left pad the file numbers instead of right padding
[ ] indicate whether context for a mark is limited by file length (eof/bof)
[x] move cursor without triggering autocmd (excess draws)
[x] handle weird interaction of / and scroll now that I have ignore_next_autocmd
    have highlight in line, n, hhhhhh, n, l
[x] keep track of the cursor position and restore to it when you open the floating window
[x] fix bug where moving to bottom doesn't move view to bring bottom waypoint fully into view
[x] goddamnit, I just realized the source of the bug. it's because the table chars are unicode, and therefore multiple chars long
    nvim_win_get_cursor doesn't account for unicode.
    solution: get rid of all uses of nvim_win_get_cursor and replace with vim.fn.getcurpos()
[x] handle col vs curswant better so unicode doesn't confuse cursor state
[ ] fix syntax highlighting for makefile
[ ] increase performance of highlighting


### ADVANCED FEATURES:
[x] delete waypoint from floating window with dd
[x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[x] quickfixlist for waypoints
[ ] telescope for waypoints
[ ] add some features from harpoon
  [ ] jump to first waypoint while outside the float window
  [ ] jump to currently selected waypoint while outside the float window
  [ ] jump to and select next waypoint while outside the float window
  [ ] jump to and select prev waypoint while outside the float window

how I want it to work
1. scroll_col, topline, col and leftcol should be saved
2. if you close and reopen, those are restored.
3. however, they aren't persisted if you close vim

syntax file location
/opt/homebrew/Cellar/neovim/0.10.3/share/nvim/runtime/syntax


man section on syntax
:h syn
6. Defining a syntax					*:syn-define* *E410*

