

if !has("nvim")
  echo "vim-godebug: vim is not yet supported, try it with neovim"
  finish
endif

if exists("g:godebug_loaded_install")
  finish
endif
let g:godebug_loaded_install = 1

"autocmd VimLeave * call godebug#deleteBreakpointsFile()
autocmd FileType go call godebug#init()

" Private functions
function! godebug#init()
    let g:godebug_breakpoints_file = getcwd() . "/debug"
    if !exists("g:godebug_breakpoints")
        let g:godebug_breakpoints = []
    endif
    
    if filereadable("g:godebug_breakpoints_file")
        let g:godebug_breakpoints = readfile(g:godebug_breakpoints_file)
    endif
endfunction


function! godebug#toggleBreakpoint(file, line, ...) abort
  " Compose the breakpoint for delve:
  " Example: break /home/user/path/to/go/file.go:23
  let breakpoint = "break " . a:file. ':' . a:line

  " Define the sign for the gutter
  exe "sign define gobreakpoint text=◉ texthl=Search"

  " If the line isn't already in the list, add it.
  " Otherwise remove it from the list.
  let i = index(g:godebug_breakpoints, breakpoint)
  if i == -1
    call add(g:godebug_breakpoints, breakpoint)
    exe "sign place ". a:line ." line=" . a:line . " name=gobreakpoint file=" . a:file
  else
    call remove(g:godebug_breakpoints, i)
    exe "sign unplace ". a:line ." file=" . a:file
  endif
  call godebug#writeBreakpointsFile()
endfunction

function! godebug#writeBreakpointsFile() abort
  call writefile(g:godebug_breakpoints + ["continue"], g:godebug_breakpoints_file)
endfunction

function! godebug#loadBreakpointsFile()
    if filereadable("g:godebug_breakpoints_file")
       let g:godebug_breakpoints = readfile(g:godebug_breakpoints_file)
       echo g:godebug_breakpoints
    else
	echo "No debug file was found"
	echo "Creating new debug file"
	call writefile(["continue"], g:godebug_breakpoints_file)
    endif
    call godebug#drawBreakpoints()
endfunction

function! godebug#drawBreakpoints()
    exe "sign define gobreakpoint text=◉ texthl=Search"
    for e in g:godebug_breakpoints
	if e !~ "continue"
	    exe "sign place ". str2nr(matchstr(e, '[0-9]\+'),10) ." line=" . str2nr(matchstr(e, '[0-9]\+'),10)  . " name=gobreakpoint file=" . expand('%:p')
	endif
    endfor
endfunction

function! godebug#deleteBreakpointsFile(...) abort
  if filereadable(g:godebug_breakpoints_file)
    call delete(g:godebug_breakpoints_file)
  endif
endfunction

function! godebug#debug(bang, ...) abort
  return go#term#new(a:bang, ["dlv", "debug", "--init=" . g:godebug_breakpoints_file], "%-G#\ %.%#")
endfunction

function! godebug#debugtest(bang, ...) abort
  return go#term#new(a:bang, ["dlv", "test", "--init=" . g:godebug_breakpoints_file], "%-G#\ %.%#")
endfunction

command! -nargs=* -bang GoToggleBreakpoint call godebug#toggleBreakpoint(expand('%:p'), line('.'), <f-args>)
command! -nargs=* -bang GoLoadBreakpoints call godebug#loadBreakpointsFile()
command! -nargs=* -bang GoDebug call godebug#debug(<bang>0, 0, <f-args>)
command! -nargs=* -bang GoDebugTest call godebug#debugtest(<bang>0, 0, <f-args)
