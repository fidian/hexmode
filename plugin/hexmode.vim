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

" ex command for toggling hex mode - define mapping if desired
command -bar Hexmode call ToggleHex()

" helper function to toggle hex mode
function ToggleHex()
	" hex mode should be considered a read-only operation
	" save values for modified and read-only for restoration later,
	" and clear the read-only flag for now
	let l:modified=&mod
	let l:oldreadonly=&readonly
	let &readonly=0
	let l:oldmodifiable=&modifiable
	let &modifiable=1
	if !exists("b:editHex") || !b:editHex
	" save old options
	let b:oldft=&ft
	let b:oldbin=&bin
	" set new options
	setlocal binary " make sure it overrides any textwidth, etc.
	let &ft="xxd"
	" set status
	let b:editHex=1
	" switch to hex editor
	silent %!xxd
	else
	" restore old options
	let &ft=b:oldft
	if !b:oldbin
	setlocal nobinary
	endif
	" set status
	let b:editHex=0
	" return to normal editing
	silent %!xxd -r
	endif
	" restore values for modified and read only state
	let &mod=l:modified
	let &readonly=l:oldreadonly
	let &modifiable=l:oldmodifiable
endfunction

" Exclude vim files from auto hexmode
function IsVimFile()
    let b:path = expand("%:p:h")

    " Loop through each directory in the runtime path
    for i in split(&rtp, ",")
        " See if this file resides somewhere in the runtime path
        if match(b:path, i) != -1
            return 1
        endif
    endfor

    " No match
    return 0
endfunction

" autocmds to automatically enter hex mode and handle file writes properly
if has("autocmd")
	" vim -b : edit binary using xxd-format!
	augroup Binary
		au!

		" set binary option for all binary files before reading them
		au BufReadPre *.bin,*.hex setlocal binary

		" if on a fresh read the buffer variable is already set, it's wrong
		au BufReadPost *
			\ if exists('b:editHex') && b:editHex |
			\   let b:editHex = 0 |
			\ endif

		" convert to hex on startup for binary files automatically
		au BufReadPost *
			\ if &binary && !IsVimFile() | Hexmode | endif

		" When the text is freed, the next time the buffer is made active it will
		" re-read the text and thus not match the correct mode, we will need to
		" convert it again if the buffer is again loaded.
		au BufUnload *
			\ if getbufvar(expand("<afile>"), 'editHex') == 1 |
			\   call setbufvar(expand("<afile>"), 'editHex', 0) |
			\ endif

		" before writing a file when editing in hex mode, convert back to non-hex
		au BufWritePre *
			\ if exists("b:editHex") && b:editHex && &binary |
			\  let oldview = winsaveview() |
			\  let oldro=&ro | let &ro=0 |
			\  let oldma=&ma | let &ma=1 |
			\  undojoin |
			\  silent exe "%!xxd -r" |
			\  let &ma=oldma | let &ro=oldro |
			\  unlet oldma | unlet oldro |
			\ endif

		" after writing a binary file, if we're in hex mode, restore hex mode
		au BufWritePost *
			\ if exists("b:editHex") && b:editHex && &binary |
			\  let oldro=&ro | let &ro=0 |
			\  let oldma=&ma | let &ma=1 |
			\  undojoin |
			\  silent exe "%!xxd" |
			\  exe "set nomod" |
			\  let &ma=oldma | let &ro=oldro |
			\  unlet oldma | unlet oldro |
			\  call winrestview(oldview) |
			\ endif
	augroup END
endif

" vim: set et sts=4 sw=4:
