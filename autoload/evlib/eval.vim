" viml language - general-purpose functions

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'eval' ) )
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

" returns the value of the variable whose name is 'varname' if it exists,
"  or the value {def} if it does not
"
" TODO: add optional "flags" parameter to do:
"  t: type check: treat the variable as non-existing if the current value does
"      not match the type for {def};
"  s: set: if the variable did not exist, create it and set it to {def};
"
" TODO: update callers to use flags, when those are implemented
function evlib#eval#GetVariableValueDefault( varname, def ) abort
	if exists( a:varname )
		return eval( a:varname )
	endif
	return a:def
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
echoerr "the script 'eval.vim' needs support for the following: eval"

" }}} boiler plate -- epilog


