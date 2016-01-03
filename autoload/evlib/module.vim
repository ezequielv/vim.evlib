" module support functions

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'module' ) )
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

" args:
"  * module_id : string denoting the file path inside the relevant directory
"     structure in the script/plugin directory tree
"     (tip: use a first "component" as a namespace, such as 'mypluginname_')
"  * condition : string describing a boolean expression to be evaluated, to
"     make sure that the module should be included (this can be seen as a term
"     of a number of boolean expressions "anded" ('&&') together);
"  * setvar_flag (optional): (default: true) if the module should be included,
"     set the "loaded" variable to "true";
"
" returns: query result:
"  * true: "yes, you should source this file";
"  * false: do a "finish" as soon as possible;
"
" example: if ! evlib#module#ShouldSourceThisModuleWithCondition( 'myplugin_rtpath', 'MyCheckFunction()' ) ... endif
" example: if ! evlib#module#ShouldSourceThisModuleWithCondition( 'myplugin_pvt_lib', 'MyCheckFunction()', 0 ) ... endif
function evlib#module#ShouldSourceThisModuleWithCondition( module_id, condition, ... ) abort
	return evlib#pvt#module#ShouldSourceThisModuleWithCondition(
				\		a:module_id,
				\		a:condition,
				\		[ function( 's:DebugMessage' ) ] + a:000
				\	)
endfunction

" args:
"  * module_id : string denoting the file path inside the relevant directory
"     structure in the script/plugin directory tree
"     (tip: use a first "component" as a namespace, such as 'mypluginname_')
"  * setvar_flag (optional): (default: true) if the module should be included,
"     set the "loaded" variable to "true";
"
" returns: query result:
"  * true: "yes, you should source this file";
"  * false: do a "finish" as soon as possible;
"
" example: if ! evlib#module#ShouldSourceThisModule( 'myplugin_rtpath' ) ... endif
" example: if ! evlib#module#ShouldSourceThisModule( 'myplugin_pvt_lib', 0 ) ... endif
function evlib#module#ShouldSourceThisModule( module_id, ... ) abort
	return evlib#module#ShouldSourceThisModuleWithCondition( a:module_id, '!0', a:000 )
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
echoerr "the script 'compat.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
