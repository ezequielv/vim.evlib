" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'autoload_evlib_buftagvar' ) )
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

" TODO: implement unit test
function evlib#buftagvar#HasTaggedVarsContainer()
	return exists( 'b:evlib_buftagvar_taggedvarscontainer' )
endfunction

" TODO: implement unit test
function evlib#buftagvar#HasTaggedVar( var_key )
	return ( evlib#buftagvar#HasTaggedVarsContainer() &&
				\		has_key( b:evlib_buftagvar_taggedvarscontainer, a:var_key )
				\	)
endfunction

" TODO: implement unit test
function evlib#buftagvar#GetTaggedVar( var_key )
	if ! evlib#buftagvar#HasTaggedVar( a:var_key )
		throw 'evlib#buftagvar#GetTaggedVar(): could not find a buffer tagged-variable for key ' . a:var_key
	endif
	return b:evlib_buftagvar_taggedvarscontainer[ a:var_key ]
endfunction

" TODO: implement unit test
function evlib#buftagvar#SetTaggedVar( var_key, var_value )
	if ! evlib#buftagvar#HasTaggedVarsContainer()
		let b:evlib_buftagvar_taggedvarscontainer = {}
	endif
	let b:evlib_buftagvar_taggedvarscontainer[ a:var_key ] = a:var_value
	" [debug]: echo '[debug] value of b:evlib_buftagvar_taggedvarscontainer[] after setting tagged var with key ' . a:var_key . ': ' . string( b:evlib_buftagvar_taggedvarscontainer )
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
echoerr "the script 'buftagvar.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
