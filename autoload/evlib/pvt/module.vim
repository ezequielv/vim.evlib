" private (internal) - module support

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
" note: we can't use evlib#pvt#init#ShouldSourceThisModule(), as it will be
"  defined in this module! (and this module is "special")
if exists( 'g:evlib_autoload_evlib_pvt_module_loaded' ) || ( exists( 'g:evlib_autoload_evlib_pvt_module_disable' ) && g:evlib_autoload_evlib_pvt_module_disable != 0 )
	finish
endif
let g:evlib_autoload_evlib_pvt_module_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" internal initialisation support {{{

function s:EVLib_pvt_module_NullDebugFunction( msg )
endfunction

let s:evlib_pvt_module_nulldebugfunction = function( 's:EVLib_pvt_module_NullDebugFunction' )

" args:
"  * module_id : string denoting the file path inside the relevant directory
"     structure in the script/plugin directory tree
"     (tip: use a first "component" as a namespace, such as 'mypluginname_')
"  * condition : string describing a boolean expression to be evaluated, to
"     make sure that the module should be included (this can be seen as a term
"     of a number of boolean expressions "anded" ('&&') together);
"  * a_000 : usually, the value for 'a:000' on the caller.
"     this can be the empty list (default values are assumed for the missing
"     elements);
"     [ 0 ]: (optional) Funcref for a "debugging" function. this function is
"             called with one parameter only, which is a string;
"             default: do not produce debug information.
"             hint: specify this list element as a non-Funcref and the
"             debugging functionality will not be enabled for the duration of
"             that call.
"     [ 1 ]: (optional) 'setvar_flag' (default: '!0' ("true"));
"             if the module should be included,
"             set the "loaded" variable to "true";
"
" returns: query result:
"  * true: "yes, you should source this file";
"  * false: do a "finish" as soon as possible;
"
" example: if ! evlib#pvt#module#ShouldSourceThisModuleWithCondition( 'myproject_mymodule', 'MyCheckFunction()', a:000 ) ... endif
" example: if ! evlib#pvt#module#ShouldSourceThisModuleWithCondition( 'myproject_mymodule', 'MyCheckFunction()', [] ) ... endif
" example: if ! evlib#pvt#module#ShouldSourceThisModuleWithCondition( 'myproject_mymodule', 'MyCheckFunction()', [ !0 ] ) ... endif
function evlib#pvt#module#ShouldSourceThisModuleWithCondition( module_id, condition, a_000 ) abort
	let l:EVLib_pvt_module_shouldsourcethismodule_debug_function_orig = ( ( len( a:a_000 ) > 0 ) ? ( a:a_000[ 0 ] ) : 0 )
	let l:EVLib_pvt_module_shouldsourcethismodule_debug_function = ( ( type( l:EVLib_pvt_module_shouldsourcethismodule_debug_function_orig ) == type( s:evlib_pvt_module_nulldebugfunction ) ) ? l:EVLib_pvt_module_shouldsourcethismodule_debug_function_orig : s:evlib_pvt_module_nulldebugfunction )
	let l:setvar_flag = ( ( len( a:a_000 ) > 1 ) ? ( a:a_000[ 1 ] ) : ( !0 ) )
	let l:var_pref = 'g:' . a:module_id . '_'
	let l:var_loaded = l:var_pref . 'loaded'
	let l:var_disable = l:var_pref . 'disable'
	" note: alternative: use a literal
	"  (but see ':h <sfile>', as that expands to the "nested" function name)
	let l:debug_message_pref = expand( '<sfile>' )

	try
		if ( exists( l:var_loaded ) )
			call l:EVLib_pvt_module_shouldsourcethismodule_debug_function( l:debug_message_pref . 'the variable "' . l:var_loaded . '" already exists. returning 0.' )
			return 0 " false
		endif
		if ( exists( l:var_disable ) && ( eval( l:var_disable ) != 0 ) )
			call l:EVLib_pvt_module_shouldsourcethismodule_debug_function( l:debug_message_pref . 'the variable "' . l:var_disable . '" exists and it is different than 0. returning 0.' )
			return 0 " false
		endif
		if ( ! eval( a:condition ) )
			call l:EVLib_pvt_module_shouldsourcethismodule_debug_function( l:debug_message_pref . 'the expression "' . a:condition . '" has evaluated to false. returning 0.' )
			return 0 " false
		endif
	catch " catch all
		" an exception has been caught
		call l:EVLib_pvt_module_shouldsourcethismodule_debug_function( l:debug_message_pref . 'warning: caught exception when trying to evaluate boolean expressions. returning 0.' )
		return 0 " false
	endtry
	" we should load this module
	if l:setvar_flag
		execute 'let ' . l:var_loaded . ' = 1'
	endif
	call l:EVLib_pvt_module_shouldsourcethismodule_debug_function( l:debug_message_pref . 'module ' . a:module_id . ' needs to be processed. returning !0.' )
	return !0 " true
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
echoerr "the script 'autoload/evlib/pvt/module.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
