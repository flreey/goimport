goimport
========

ctrlp extension of import go package

add below to your vimrc

autocmd FileType go nnoremap <Leader>i :CtrlPGoimport<cr>
autocmd FileType go nnoremap <Leader>d :CtrlPGodrop<cr>

need pre install: https://github.com/jnwhiteh/vim-golang.git
