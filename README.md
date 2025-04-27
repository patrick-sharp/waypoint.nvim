# waypoint.nvim

## TODO:

### MVP:
[x] autosave
[x] autoload
[x] syntax highlighting for file text with vanilla vim syntax
[ ] syntax highlighting for file text with treesitter
[x] user configuration
  [ ] keybinds
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
[ ] fix bugs around closing buffers with waypoints in them
[x] add treesitter highlights
[x] increase performance of highlighting
[ ] indent after the waypoint number (this will be a pain)
[ ] think about persisting waypoints on every waypoint state change
[ ] indicate whether context for a mark is limited by file length (eof/bof)
[ ] fix all the extra spacing I put in the lua lsp type annotations
[ ] scope class declaration type annotations
[x] find out how TOhtml works with vanilla syntax and fix my vanilla syntax highlighter
[ ] figure out why my method of loading other files at startup doesn't work for treesitter highlights but does for vanilla


### ADVANCED FEATURES:
[x] delete waypoint from floating window with dd
[x] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[x] quickfixlist for waypoints
[x] telescope for waypoints
[ ] add some features from harpoon
  [ ] jump to first waypoint while outside the float window
  [ ] jump to currently selected waypoint while outside the float window
  [ ] jump to and select next waypoint while outside the float window
  [ ] jump to and select prev waypoint while outside the float window


last capture group has priority
if it doesn't make sense to apply it, then don't

have code for getting leaves, but they don't map to highlight groups in the way I was expecting

:TSHighlightCapturesUnderCursor

~/.local/share/nvim/site/pack/packer/start/nvim-treesitter/queries/


MarkdownCode
String
@string.regexp xxx guifg=#ce9178
@character     xxx guifg=#ce9178
@lsp.type.regexp
Character
markdownLinkText

unfortunately, the slow part about the vanilla syntax highlighting is
actually getting the synstack.
I'm not sure what to do about this.
maybe open small other windows with the file open instead of actually pasting text into the buffer 
    that sounds insane.
maybe re-implementing the syntax highlighter?
    that also sounds insane.


:syn sync fromstart  " Ensure syntax is fully parsed
:redir @a           " Redirect output to register 'a'
:syntax list        " List all syntax groups
:redir END          " Stop redirection
:put a              " Paste the list

 function DumpSyntax()
    local lines = {}
    for i = 1, vim.fn.line('$') do
        local line = vim.fn.getline(i)
        for j = 1, #line do
            local stack = vim.fn.synstack(i, j)
            if #stack > 0 then
                local syn = vim.fn.synIDattr(stack[#stack], 'name')
                table.insert(lines, string.format("Line %d, Col %d: %s", i, j, syn))
            end
        end
    end
    vim.fn.writefile(lines, 'syntax_dump.txt')
    print("Syntax dump saved to syntax_dump.txt")
end

:TOhtml

