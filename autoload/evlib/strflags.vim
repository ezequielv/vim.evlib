" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'autoload_evlib_strflags' ) )
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

" args: input, allowed [, own_flags [, default_value [, error_value]]]
" own_flags:
"  'x': exclusive values: do not allow any value in 'input' that isn't in 'allowed';
"		default: allow other values in 'input';
"  'm': allow multiple values in 'allowed' to be present in 'input';
"  '1': allow only one of the values in 'allowed' to be present in 'input' (this is the default);
"  't': throw an exception from this function in the case of an error;
"  'O': return the "other" values (instead of the "allowed" values found in 'input', which is the default);
function evlib#strflags#GetFlagValues( input, allowed, ... )
	let l:flags_local = ( ( a:0 > 0 ) ? a:1 : '' )
	let l:default_value = ( ( a:0 > 1 ) ? a:2 : '' )
	let l:error_value = ( ( a:0 > 2 ) ? a:3 : '' )

	" TODO: validate argument types
	let l:flag_local_exclusive = 	( stridx( l:flags_local, 'x' ) >= 0 )
	let l:flag_local_multiple = 	( stridx( l:flags_local, 'm' ) >= 0 )
	let l:flag_local_retother = 	( stridx( l:flags_local, 'O' ) >= 0 )
	let l:flag_local_errthrow = 	( stridx( l:flags_local, 't' ) >= 0 )

	" only the single-character regex tokens that have special meaning with "very nomagic" are escaped.
	let l:regex_term_allowed_inner_block = escape( a:allowed, ']^$\' )
	let l:regex_allowed = '\V\(\[' . l:regex_term_allowed_inner_block . ']\)'
	let l:regex_rest = '\V\(\[^' . l:regex_term_allowed_inner_block . ']\)'

	" TODO: de-duplicate each result string (and update unit tests)
	"-? let l:result_rest = substitute( a:input, l:regex_rest, '\1', 'g' )
	let l:result_rest = substitute( a:input, l:regex_allowed, '', 'g' )
	let l:result_allowed = substitute( a:input, l:regex_rest, '', 'g' )
	let l:success = !0 " true

	if l:success && ( len( l:result_allowed ) > 1 ) && ( ! l:flag_local_multiple )
		let l:success = 0 " false
	endif
	if l:success && ( ! empty( l:result_rest ) ) && l:flag_local_exclusive
		let l:success = 0 " false
	endif
	if l:success && empty( l:result_allowed )
		let l:result_allowed = l:default_value
	endif

	" handle return value
	let l:result = ( l:flag_local_retother ? l:result_rest : l:result_allowed )
	if ( ! l:success )
		if l:flag_local_errthrow
			" TODO: register the exact error when it's detected, so we can report that instead.
			throw 'evlib#strflags#GetFlagValues(): validation failed'
		endif
		let l:result = l:error_value
	endif
	return l:result
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
echoerr "the script 'strflags.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
