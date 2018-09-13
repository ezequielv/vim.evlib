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

let s:typeid_string = type( '' )
let s:typeid_dict = type( {} )

" TODO: implement unit test
function evlib#buftagvar#HasTaggedVarsContainer( ... )
	return (
				\		( a:0 == 0 )
				\		?  exists( 'b:evlib_buftagvar_taggedvarscontainer' )
				\		: ( type( getbufvar( a:1, 'evlib_buftagvar_taggedvarscontainer' ) ) == s:typeid_dict )
				\	)
endfunction

"? let s:script_local_HasTaggedVarsContainer = function( 'evlib#buftagvar#HasTaggedVarsContainer' )

" TODO: implement unit test
function evlib#buftagvar#HasTaggedVar( var_key, ... )
	if ( a:0 == 0 )
		return ( evlib#buftagvar#HasTaggedVarsContainer()
					\		&& has_key( b:evlib_buftagvar_taggedvarscontainer, a:var_key )
					\	)
	endif
	return ( evlib#buftagvar#HasTaggedVarsContainer( a:1 )
				\		&& has_key( getbufvar( a:1, 'evlib_buftagvar_taggedvarscontainer' ), a:var_key )
				\	)
endfunction

let s:script_local_HasTaggedVar = function( 'evlib#buftagvar#HasTaggedVar' )

" TODO: implement unit test
function evlib#buftagvar#GetTaggedVar( var_key, ... )
	if ! call( s:script_local_HasTaggedVar, [ a:var_key ] + a:000 )
		" other idea: find a way to show which buffer this is about (possibly
		" passing a:000 as a positional argument).
		throw 'evlib#buftagvar#GetTaggedVar(): could not find a buffer tagged-variable for key ' . a:var_key
					\	. ( ( a:0 > 0 ) ? ( ' in buffer ' . string( a:1 ) ) : '' )
	endif
	if ( a:0 == 0 )
		return b:evlib_buftagvar_taggedvarscontainer[ a:var_key ]
	endif
	return getbufvar( a:1, 'evlib_buftagvar_taggedvarscontainer' )[ a:var_key ]
endfunction

" TODO: implement unit test
function evlib#buftagvar#SetTaggedVar( var_key, var_value, ... )
	if ( a:0 == 0 )
		if ! evlib#buftagvar#HasTaggedVarsContainer()
			let b:evlib_buftagvar_taggedvarscontainer = {}
		endif
		let b:evlib_buftagvar_taggedvarscontainer[ a:var_key ] = a:var_value
	else
		if evlib#buftagvar#HasTaggedVarsContainer( a:1 )
			let getbufvar( a:1, 'evlib_buftagvar_taggedvarscontainer' )[ a:var_key ] = a:var_value
		else
			call setbufvar( a:1, 'evlib_buftagvar_taggedvarscontainer', { a:var_key: a:var_value } )
		endif
	endif
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
