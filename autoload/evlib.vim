" library initialisation functions

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_autoload_evlib_loaded' ) || ( exists( 'g:evlib_disable' ) && g:evlib_disable != 0 )
	finish
endif
let g:evlib_autoload_evlib_loaded = 1
" MAYBE: move somewhere else, maybe from 's:evlib_local_globalsetup_succeeded's value (below)
let g:evlib_loaded = 1
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

" support functions {{{
function s:DebugMessage( msg )
	return evlib#debug#DebugMessage( a:msg )
endfunction
" }}}

" internal setup {{{
function s:EVLibLocalSetup( src ) abort
	let l:success = !0 " true
	" internal initialisation: allows any other autoload module to be used
	let l:success = l:success && evlib#pvt#init#InternalInit()
	" get the path to the project root directory
	let l:success = l:success && evlib#pvt#lib#InitPre( fnamemodify( a:src, ':p:h:h' ) )
	return l:success
endfunction
let s:evlib_local_globalsetup_succeeded = s:EVLibLocalSetup( expand( '<sfile>' ) )
" the function above needs to be called only once -> delete it
delfunction s:EVLibLocalSetup
" }}}

" versioning support {{{
" NOTE: g:evlib_global_api_version_list moved to {root}/lib/evlib/c_main.vim
function evlib#SupportsAPIVersion( ver_major, ver_minor, ... ) abort
	let l:version_to_check = [ a:ver_major, a:ver_minor, ( ( a:0 > 0 ) ? a:1 : 0 ) ]
	return evlib#pvt#apiver#SupportsAPIVersion(
			\		l:version_to_check,
			\		g:evlib_global_api_version_list
			\	)
endfunction
" }}}

" note: we only need the 'eval' feature (already checked)
function evlib#IsInitialised()
	return ( exists( 'g:evlib_initialised' ) ? ( g:evlib_initialised != 0 ) : 0 )
endfunction

" TODO: also initialise the library from the 'plugin/*.vim' file, so that we
"  can support the user not caring about initialisation, as long as we are
"  accessible through the 'runtimepath' setting;
function evlib#Init() abort
	if ( ! evlib#IsInitialised() )
		let l:success = !0

		" first, make sure that the script-local setup has worked
		let l:success = l:success && exists( 's:evlib_local_globalsetup_succeeded' ) && ( s:evlib_local_globalsetup_succeeded )
		let l:success = l:success && ( v:version >= 700 )
		" TODO: check for all the features that we need in this library

		" now we can set up a few things
		if ( l:success )
			try
				" for now, we don't care if there were any files here or not
				call evlib#pvt#lib#SourceEVLibFiles( 'parts/init/*.vim' )
			catch
				" an exception has been thrown -> that is not good
				let l:success = 0
			endtry
		endif

		" lastly, we mark the library as initialised
		let g:evlib_initialised = l:success
	endif
	return evlib#IsInitialised()
endfunction

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'autoload/evlib.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
