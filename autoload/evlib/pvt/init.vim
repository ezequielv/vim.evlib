" private (internal) - internal library initialisation

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
" note: we can't use evlib#pvt#init#ShouldSourceThisModule(), as it will be
"  defined in this module! (and this module is "special")
if exists( 'g:evlib_pvt_init_loaded' ) || ( exists( 'g:evlib_pvt_init_disable' ) && g:evlib_disable != 0 )
	finish
endif
let g:evlib_pvt_init_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" internal initialisation support {{{

let s:evlib_local_pvt_init_initialised = 0

function evlib#pvt#init#CanLoadLibraryModules() abort
	return s:evlib_local_pvt_init_initialised
endfunction

" args:
"  * module_id : string denoting the file path inside the 'autoload' directory
"     structure (or use your own prefix to signify another "main" directory);
"  * setvar_flag (optional): (default: true) if the module should be included,
"     set the "loaded" variable to "true";
"
" returns: query result:
"  * true: "yes, you should source this file";
"  * false: do a "finish" as soon as possible;
"
" example: if ! evlib#pvt#init#ShouldSourceThisModule( 'rtpath' ) ... endif
" example: if ! evlib#pvt#init#ShouldSourceThisModule( 'pvt_lib' ) ... endif
function evlib#pvt#init#ShouldSourceThisModule( module_id, ... ) abort
	let l:setvar_flag = ( ( a:0 > 0 ) ? ( a:1 ) : ( !0 ) )
	let l:var_pref = 'evlib_' . a:module_id . '_'
	let l:var_loaded = l:var_pref . 'loaded'
	let l:var_disable = l:var_pref . 'disable'

	if	( ! evlib#pvt#init#CanLoadLibraryModules() )
				\	|| ( exists( l:var_loaded ) )
				\	|| ( exists( l:var_disable ) && ( eval( l:var_disable ) != 0 ) )
		return 0 " false
	endif
	" we should load this module
	if l:setvar_flag
		execute 'let ' . l:var_loaded . ' = 1'
	endif
	return !0 " true
endfunction

" returns "success"
function evlib#pvt#init#InternalInit() abort
	" for now, no additional validation
	let s:evlib_local_pvt_init_initialised = !0 " true
	return s:evlib_local_pvt_init_initialised
endfunction

" }}}

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'autoload/evlib/pvt/init.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

