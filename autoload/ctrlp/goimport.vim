" To load this extension into ctrlp, add this to your vimrc:
"
"     let g:ctrlp_extensions = ['goimport']
"
" Load guard
if ( exists('g:loaded_ctrlp_goimport') && g:loaded_ctrlp_goimport )
    \ || v:version < 700 || &cp
    finish
endif
let g:loaded_ctrlp_goimport = 1

" Add this extension's settings to g:ctrlp_ext_vars
"
" Required:
"
" + init: the name of the input function including the brackets and any
"         arguments
"
" + accept: the name of the action function (only the name)
"
" + lname & sname: the long and short names to use for the statusline
"
" + type: the matching type
"   - line : match full line
"   - path : match full line like a file or a directory path
"   - tabs : match until first tab character
"   - tabe : match until last tab character
"
" Optional:
"
" + enter: the name of the function to be called before starting ctrlp
"
" + exit: the name of the function to be called after closing ctrlp
"
" + opts: the name of the option handling function called when initialize
"
" + sort: disable sorting (enabled by default when omitted)
"
" + specinput: enable special inputs '..' and '@cd' (disabled by default)
"
call add(g:ctrlp_ext_vars, {
    \ 'init': 'ctrlp#goimport#init()',
    \ 'accept': 'ctrlp#goimport#accept',
    \ 'lname': 'goimport',
    \ 'sname': '',
    \ 'type': 'line',
    \ 'enter': 'ctrlp#goimport#enter()',
    \ 'exit': 'ctrlp#goimport#exit()',
    \ 'opts': 'ctrlp#goimport#opts()',
    \ 'sort': 1,
    \ 'specinput': 0,
    \ })


let s:is_import = 1
let s:global_packages = []
let s:local_packages = []
" Provide a list of strings to search in
"
" Return: a Vim's List
"
function! ctrlp#goimport#init()
    if s:is_import
        if len(s:global_packages) == 0
            call ctrlp#goimport#global_packs()
        endif
        return s:global_packages
    else
        call ctrlp#goimport#local_packs()
        return s:local_packages
    endif
endfunction

function! ctrlp#goimport#global_packs()
python << EOF
import os
import vim
gopath = os.environ.get("GOPATH").split(":")
packages = set()

def recurse_find(root):
    for dirpath, dirnames, filenames in os.walk(root):
        for d in dirnames:
            if os.path.isdir(d):
                path = os.path.join(dirpath, d)
                if "src" in path:
                    recurse_find(path)
        if "src" in dirpath and not "/bin/" in dirpath:
            for f in filenames:
                pack = ""
                if  "/pkg/" in dirpath:
                    pack = dirpath.split("pkg/")[1]
                elif".go" in f:
                    pack = dirpath.split("src/")[1]
                packages.add(pack)

for path in gopath:
    recurse_find(path)

vim.command("let s:global_packages = " + str(list(packages)))
EOF
endfunction


function! ctrlp#goimport#local_packs()
python << EOF
import vim
import re
packages = []
found = False
for filename in range(1, int(vim.eval("bufnr('$')"))+1):
    for line in vim.eval("getbufline(%s, 0, '$')" % filename):
        if re.search("import\s+\(", line):
            found = True
            continue

        if found:
            matches = re.match(".*\"(.+)\"", line)
            if matches:
                packages.append(matches.group(1).strip())

            if ")" in line:
                found = False
            continue

        matches = re.match("var|const|type|func", line)
        if matches:
            break

        matches = re.match("import\s+\"(.+)\"", line)
        if matches:
            packages.append(matches.group(1).strip())

vim.command("let s:local_packages = " + str(list(packages)))
EOF
endfunction

" The action to perform on the selected string
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"           the values are 'e', 'v', 't' and 'h', respectively
"  a:str    the selected string
"
function! ctrlp#goimport#accept(mode, str)
    " For this example, just exit ctrlp and run help
    call ctrlp#exit()
    if s:is_import == 1
        exec "Import ".a:str
    else
        exec "Drop ".a:str
    endif
endfunction


" (optional) Do something before enterting ctrlp
function! ctrlp#goimport#enter()
endfunction


" (optional) Do something after exiting ctrlp
function! ctrlp#goimport#exit()
endfunction


" (optional) Set or check for user options specific to this extension
function! ctrlp#goimport#opts()
endfunction


" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

" Allow it to be called later
function! ctrlp#goimport#id()
    return s:id
endfunction

"import or drop
function! ctrlp#goimport#setimport(opt)
	let s:is_import = a:opt
	call ctrlp#init(ctrlp#goimport#id())
endfunction
