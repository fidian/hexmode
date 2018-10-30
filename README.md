Hexmode - Hex editing in Vim
============================

Ever need a hex editor?  Tired of installing `ncurses-hexedit`, `hexedit`, or
maybe even using an `od` script to format some binary file as hex just so you
can see if there are null characters at the end of the file?  Fret no longer!

Thankfully, there is a wonderful [wiki page][wiki] that illustrated not only how
to use `xxd` to filter files to/from hex, but it also provided a great function,
called ToggleHex.  On top of that, there are buffer reading and writing hooks so
using vim to edit a binary file will automatically edit it as hex.

Also, on that wiki page, it mentions how to avoid getting the "Press ENTER or
type command to continue" message that would normally show up.  By adding
`silent` in a couple places, the ToggleHex function now operates quietly.
Fantastic!

So now I put out this repository so others can easily grab the plugin as just
a single file instead of copying and pasting the bits from the webpage and also
figuring out where to put this magical `silent` command.


Installation
------------

First, install the [Pathogen][pathogen] plugin if you don't already have it.
Adding other plugins by using Pathogen makes things much easier.  Careful: the
second command is quite long.

1. `mkdir -p ~/.vim/autoload ~/.vim/bundle`
2. `curl -so ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim`
3. `echo 'call pathogen#infect()' >> ~/.vimrc`

Now we can clone this repository into your `~/.vim/bundle` directory.

1. `cd ~/.vim/bundle`
2. `git clone https://github.com/fidian/hexmode.git`


Usage
-----

Simply editing a file in binary mode, e.g.,

    vim -b some_file.jpg

will open it in hex mode.

Also, you can use `:Hexmode` to switch between hex editing and normal editing.

Use the `g:hexmode_patterns` flag to automatically open specific file patterns
in hex mode. E.g.,

    let g:hexmode_patterns = '*.bin,*.exe,*.dat,*.o'


Use the `g:hexmode_xxd_options` flag to pass options to xxd. E.g.,

    let g:hexmode_xxd_options = '-g 1'


Credits and License
-------------------

Tyler Akins (the "fidian" guy at GitHub) did *not* write this.  Mad props go out
to Fritzophrenic for fulfilling this need so completely.  Also, look at the
commit log for other contributions that were received after the plugin was
released on GitHub.

The plugin is under a [Creative Commons Attribution-Share Alike License 3.0
(Unported)][cc-by-sa] because the original post was under that license.  Make
sure that all code contributions are also under this license.  Officially, here
is the notice:

> This vim plugin uses material from the ["Improved hex editing"][wiki] article
> on the [Vim Tips Wiki][vimwiki] at [Wikia][wikia] and is licensed under the
> [Creative Commons Attribution-Share Alike License][cc-by-sa].


Alternatives and Enhancements
-----------------------------

You might want to look at [hexman.vim][hexman] for additional functionality.
Also, I'd be happy to accept pull requests if there are some improvements that
you would be willing to submit to the project.


[cc-by-sa]: http://creativecommons.org/licenses/by-sa/3.0/
[hexman]: http://www.vim.org/scripts/script.php?script_id=666
[pathogen]: https://github.com/tpope/vim-pathogen/
[vimwiki]: http://vim.wikia.com/
[wiki]: http://vim.wikia.com/wiki/Improved_hex_editing
[wikia]: http://www.wikia.com/
