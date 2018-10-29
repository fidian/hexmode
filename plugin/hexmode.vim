"============================================================================
"File:        hexmode.vim
"Description: vim plugin for on hex editing
"Origin:      http://vim.wikia.com/wiki/Improved_hex_editing
"
"============================================================================

if exists("g:loaded_hexmode_plugin")
    finish
endif

let g:loaded_hexmode_plugin = 1

" auto hexmode file patterns, default none
let g:hexmode_patterns = get(g:, 'hexmode_patterns', '')

" auto hexmode xxd options, default none
let g:hexmode_xxd_options = get(g:, 'hexmode_xxd_options', '')

" ex command for toggling hex mode - define mapping if desired
command -bar Hexmode call ToggleHex()

" helper function to toggle hex mode
function ToggleHex()
    " hex mode should be considered a read-only operation
    " save values for modified and read-only for restoration later,
    " and clear the read-only flag for now
    let l:modified = &l:modified
    let l:oldreadonly = &l:readonly
    let l:oldmodifiable = &l:modifiable
    setlocal noreadonly
    setlocal modifiable
    if !exists("b:editHex") || !b:editHex
        " save old options
        let b:oldft = &l:ft
        let b:oldbin = &l:bin
        " set status
        let b:editHex=1
        " switch to hex editor
        silent exe "%!xxd " . g:hexmode_xxd_options
        " set new options
        let &l:bin=1 " make sure it overrides any textwidth, etc.
        let &l:ft="xxd"
    else
        " restore old options
        let &l:ft = b:oldft
        let &l:bin = b:oldbin
        " return to normal editing
        silent exe "%!xxd -r " . g:hexmode_xxd_options
        " set status
        let b:editHex=0
    endif

    " restore values for modified and read only state
    let &l:modified = l:modified
    let &l:readonly = l:oldreadonly
    let &l:modifiable = l:oldmodifiable
endfunction

" Detection of a binary buffer is difficult to do right.  This used to call
" `file -ibL` on the file being edited and inspect the results.
" Unfortunately, calling `system()` during BufReadPre and BufReadPost
" passes control to an external program temporarily.  This is bad because the
" terminal was sent codes asking for the current cursor position, among
" other things, and the terminal has a good chance of sending its response
" right when the external program is executing.  Sadly, vim does not get
" these escape sequences.  Want more details?  See fidian/hexmode#17.
function! s:IsHexmodeEditable()
    " Hexmode conflicts with the gzip plugin. Because we can't detect if
    " `vim -b` was used on the command line and because we can't disable
    " gzip, Hexmode must be disabled.
    " See https://github.com/fidian/hexmode/issues/27
    if expand('<afile>:p') =~ '\.\(bz2\|gz\|lzma\|xz\|Z\)$'
        return 0
    endif

    " Otherwise, vim -b file should always work.
    if &l:binary
        return 1
    endif

    " Probably not a binary file or else we don't want to flip into binary
    " editing mode. See issues #31 and #35.
    return 0
endfunction

" autocmds to automatically enter hex mode and handle file writes properly
if has("autocmd")
    " vim -b : edit binary using xxd-format!
    augroup Binary
        au!

        " Set binary option for all binary files before reading them.
        if !empty(g:hexmode_patterns)
            execute printf('au BufReadPre %s setlocal binary', g:hexmode_patterns)
        endif

        " If on a fresh read the buffer variable is already set, it's wrong.
        au BufReadPost *
            \ if exists('b:editHex') && b:editHex |
            \   let b:editHex = 0 |
            \ endif

        " Convert to hex on startup for binary files automatically.
        au BufReadPost *
            \ if s:IsHexmodeEditable() != 0 |
            \   Hexmode |
            \ endif

        " When the text is freed, the next time the buffer is made active it
        " will re-read the text and thus not match the correct mode, we will
        " need to convert it again if the buffer is again loaded.
        au BufUnload *
            \ if getbufvar(expand("<afile>"), 'editHex') == 1 |
            \   call setbufvar(expand("<afile>"), 'editHex', 0) |
            \ endif

        " before writing a file when editing in hex mode, convert back to non-hex
        au BufWritePre *
            \ if exists("b:editHex") && b:editHex |
            \  let b:oldview = winsaveview() |
            \  let b:oldro=&l:ro | let &l:ro=0 |
            \  let b:oldma=&l:ma | let &l:ma=1 |
            \  undojoin |
            \  silent exe "%!xxd -r " . g:hexmode_xxd_options |
            \  let &l:ma=b:oldma | let &l:ro=b:oldro |
            \  unlet b:oldma | unlet b:oldro |
            \  let &l:ul = &l:ul |
            \ endif

        " after writing a binary file, if we're in hex mode, restore hex mode
        au BufWritePost *
            \ if exists("b:editHex") && b:editHex |
            \  let b:oldro=&l:ro | let &l:ro=0 |
            \  let b:oldma=&l:ma | let &l:ma=1 |
            \  undojoin |
            \  silent exe "%!xxd " . g:hexmode_xxd_options |
            \  exe "setlocal nomod" |
            \  let &l:ma=b:oldma | let &l:ro=b:oldro |
            \  unlet b:oldma | unlet b:oldro |
            \  call winrestview(b:oldview) |
            \  let &l:ul = &l:ul |
            \ endif
    augroup END
endif

" vim: set et sts=4 sw=4:
