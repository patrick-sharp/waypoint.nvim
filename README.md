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
[ ] popup with keybind info when you press g?
[ ] that weird scroll behavior I still can't figure out
[x] the bug when saving and loading
[x] the bug where marks at beginning/end of file don't have gaps
[ ] support for other movement-like keys
  [x] H/M/L
  [x] gg/G
  [x] / and ?
  [ ] <C-d> and <C-u>
  [ ] (possible fix for all of these: keep track of which line is which waypoint, and set waypoint + draw when cursor moves)
      hmm, this is tough. maybe: on cursor move, just select the waypoint the cursor is over.
      on some actions (e.g. j/k), center the cursor on the waypoint marker itself.
      could there also be a better ux for expanding context? maybe A should put the waypoint at the top, B at the bottom?
[x] show A/B/C in footer of window
  [ ] make footer background equal to window background
[x] limit horizontal scroll
[x] look into whether the status line height messes up my window calculations
[x] bug when navigated to from telescope
[x] fix toggle bug
[x] fix highlight when creating but not loading bug
[x] only allow bookmarks in files (e.g. not in nvim-tree)
[ ] decide whether I want to keep annotations
  [ ] update annotations
[x] left pad the file numbers instead of right padding
[ ] indicate whether context for a mark is limited by file length (eof/bof)
[x] move cursor without triggering autocmd (excess draws)
[x] handle weird interaction of / and scroll now that I have ignore_next_autocmd
    have highlight in line, n, hhhhhh, n, l
[ ] keep track of the cursor position and restore to it when you open the floating window
[ ] fix bug where moving to bottom doesn't move view to bring bottom waypoint fully into view

### ADVANCED FEATURES:
[ ] delete waypoint from floating window with dd
[x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[ ] telescope for waypoints
[ ] quickfixlist for waypoints

how I want it to work
1. scroll_col, topline, col and leftcol should be saved
2. if you close and reopen, those are restored.
3. however, they aren't persisted if you close vim

should moving up and down put scroll back to beginning?
should scrolling move cursor all the way to the left of screen?

