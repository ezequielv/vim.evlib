" evlib_loader.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_loaded' ) || ( exists( 'g:evlib_disable' ) && g:evlib_disable != 0 )
	finish
endif
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" enable vim.evlib {{{
"
" function s:EnableEVLib( paths )
"
" args:
"  paths: list of directories (strings), one element per directory;
"
" returns:
"  0: failure (and/or not found the vim module/plugin);
"  !=0: success (evlib#Init() has been run successfully);
function s:EnableEVLib( paths )
	" for now, start small: copy reference to user's list
	let l:paths = a:paths

	let l:path_found = ''
	for l:path_now in l:paths
		let l:path_now = fnamemodify( expand( l:path_now ), ':p' )
		" debug: echo '[DEBUG] l:path_now = "' . l:path_now . '"'
		if ! isdirectory( l:path_now )
			continue
		endif
		let l:path_detect_now = l:path_now . 'autoload/evlib.vim'
		if filereadable( l:path_detect_now )
			let l:path_found = l:path_now
			break
		endif
	endfor
	if ( len( l:path_found ) > 0 )
		if ( len( l:path_found ) > 1 ) && ( l:path_found[ -1: ] == '/' )
			" get rid of the last '/'
			let l:path_found = l:path_found[ :-2 ]
		endif
		exec 'set runtimepath+=' . fnameescape( l:path_found )
		" FIXME: if evlib#Init() works, consider adding the 'after'
		"  path, too (should I use evlib#rtpath#ExtendRuntimePath(),
		"  or manually add the '/after' path here?)
		" IDEA: or have 'evlib#Init()' discover its own path (or is it
		"  in '<sfile>'?), and add the '/after' to the runpath itself
		return evlib#Init()
	endif
	return 0
endfunction
" }}}

" determine the directory in which this file lives, and call the
"  initialisation function with it
if ! s:EnableEVLib( [ fnamemodify( expand( '<sfile>' ), ':p:h' ) ] )
	echoerr '[DEBUG] ' . fnameescape( expand( '<sfile>' ) ) . ': failed to find and initialise EVLib'
endif

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'evlib_loader.vim' needs support for the following: eval"

" }}} boiler plate -- epilog


