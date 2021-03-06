" evlib_loader.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" NOTE: inclusion control is currently shared between
"   {root}/evlib_loader.vim
"   {root}/autoload/evlib.vim
"  but '{root}/evlib_loader.vim' does not set g:evlib_loaded
"  (it merely detects the existing value)
"
" inclusion control {{{
if exists( 'g:evlib_loaded' ) || ( exists( 'g:evlib_disable' ) && g:evlib_disable != 0 )
	finish
endif
" }}}

" top-level sanity checking {{{
if !( v:version >= 700 )
	" tried to load with an unsupported version of vim
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
function s:EnableEVLib( paths ) abort
	" for now, start small: copy reference to user's list
	let l:paths = a:paths

	let l:path_found = ''
	for l:path_now in l:paths
		let l:path_now = fnamemodify( expand( l:path_now ), ':p' )
		" debug: echo '[DEBUG] l:path_now = "' . l:path_now . '"'
		if ! isdirectory( l:path_now )
			continue
		endif
		" NOTE: as the path is now known to be a directory (and according to
		"  the documentation on ':p' under ':h filename-modifiers'), we have a
		"  pathname separator at the end
		let l:path_detect_now = l:path_now . 'autoload/evlib.vim'
		if filereadable( l:path_detect_now )
			let l:path_found = l:path_now
			break
		endif
	endfor
	if ( strlen( l:path_found ) > 0 )
		" TODO: abstract this condition (and operation?) in a function, so
		"  that we do not have to do this manually anymore
		" to_refactor {{{
		if ( strlen( l:path_found ) > 1 ) && ( stridx( '/\\', l:path_found[ -1: ] ) >= 0 )
			" get rid of the last pathname separator ('/', '\\')
			let l:path_found = l:path_found[ :-2 ]
		endif
		" }}} to_refactor
		" prev: fnameescape() not always available -- probably better to avoid
		"  it: exec 'set runtimepath+=' . fnameescape( l:path_found )
		let &runtimepath = l:path_found . ( ( strlen( &runtimepath ) > 0 ) ? ( ',' . &runtimepath ) : '' )
		" MAYBE: if evlib#Init() works, consider adding the 'after'
		"  path, too (should I use evlib#rtpath#ExtendRuntimePath(),
		"  or manually add the '/after' path here?)
		" NOTE: we have now the library root directory in
		"   g:evlib_global_lib_root_dir
		"   (set in 'autoload/evlib/pvt/lib.vim'), which
		"   is used in that module's functions
		"  IDEA: if needed, we could add the '/after' directory here (or
		"   somewhere else, maybe inside that module?)
		return evlib#Init()
	endif
	return 0
endfunction
" }}}

" determine the directory in which this file lives, and call the
"  initialisation function with it
if ! s:EnableEVLib( [ fnamemodify( expand( '<sfile>' ), ':p:h' ) ] )
	echoerr '[DEBUG] ' . expand( '<sfile>' ) . ': failed to find and initialise EVLib'
endif

" no need to keep this function in memory -> delete it
delfunction s:EnableEVLib

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

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
