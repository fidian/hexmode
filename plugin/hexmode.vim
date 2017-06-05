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

" default auto hexmode file patterns
let g:hexmode_patterns = get(g:, 'hexmode_patterns', '*.bin,*.exe,*.so,*.jpg,*.jpeg,*.gif,*.png,*.pdf,*.tiff')

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
        silent %!xxd
        " set new options
        let &l:bin=1 " make sure it overrides any textwidth, etc.
        let &l:ft="xxd"
    else
        " set status
        let b:editHex=0
        " return to normal editing
        silent %!xxd -r
        " restore old options
        let &l:ft = b:oldft
        let &l:bin = b:oldbin
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
function! s:IsBinary()
    if &l:binary
        " vim -b file should always work.
        return 1
    endif
    " This match looks for characters that are not whitespace of various
    " sorts, printable ASCII, extended ASCII, and not Unicode.  Not great,
    " but fairly fast and fairly acceptable.
    return !!search('[\x00-\x08\x0e-\x1f\x7f]', 'wn')
endfunction

" autocmds to automatically enter hex mode and handle file writes properly
if has("autocmd")
    " vim -b : edit binary using xxd-format!
    augroup Binary
        au!

        " Set binary option for all binary files before reading them.
        execute printf('au BufReadPre %s setlocal binary', g:hexmode_patterns)

        au BufReadPost * let &l:binary = s:IsBinary() | let b:allow_hexmode = 1

        " Gzipped help files show up as binary in (and only in) BufReadPost.
        execute printf('au BufReadPre {%s}/doc/*.txt.gz let b:allow_hexmode = 0',
            \ escape(&rtp, ' '))

        " If on a fresh read the buffer variable is already set, it's wrong.
        au BufReadPost *
            \ if exists('b:editHex') && b:editHex |
            \   let b:editHex = 0 |
            \ endif

        " Convert to hex on startup for binary files automatically.
        au BufReadPost *
            \ if &l:binary && b:allow_hexmode |
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
            \ if exists("b:editHex") && b:editHex && &l:binary |
            \  let b:oldview = winsaveview() |
            \  let b:oldro=&l:ro | let &l:ro=0 |
            \  let b:oldma=&l:ma | let &l:ma=1 |
            \  undojoin |
            \  silent exe "%!xxd -r" |
            \  let &l:ma=b:oldma | let &l:ro=b:oldro |
            \  unlet b:oldma | unlet b:oldro |
            \  let &l:ul = &l:ul |
            \ endif

        " after writing a binary file, if we're in hex mode, restore hex mode
        au BufWritePost *
            \ if exists("b:editHex") && b:editHex && &l:binary |
            \  let b:oldro=&l:ro | let &l:ro=0 |
            \  let b:oldma=&l:ma | let &l:ma=1 |
            \  undojoin |
            \  silent exe "%!xxd" |
            \  exe "setlocal nomod" |
            \  let &l:ma=b:oldma | let &l:ro=b:oldro |
            \  unlet b:oldma | unlet b:oldro |
            \  call winrestview(b:oldview) |
            \  let &l:ul = &l:ul |
            \ endif
    augroup END
endif

" vim: set et sts=4 sw=4:
