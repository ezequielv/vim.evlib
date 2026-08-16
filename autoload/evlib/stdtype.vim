" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'autoload_evlib_stdtype' ) )
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
function! s:DebugMessage( msg )
	return evlib#debug#DebugMessage( a:msg )
endfunction
" }}}

" TODO: unit test
" NOTE: [api] new in v0.3.0
function! evlib#stdtype#StrTrim( src )
	return substitute( a:src, '\v%(%(^\s+)|%(\s+$))', '', 'g' )
endfunction

" TODO: unit test
function! evlib#stdtype#AsTopLevelList( val )
	return (
				\		( type( a:val ) == type( [] ) )
				\		?	a:val
				\		:	[ a:val ]
				\	)
endfunction

" TODO: unit test
" optional args:
"  * defval: if provided, this object will be returned when the container_list
"    is itself empty (there were no "source" containers to inspect).
"  * extend_xarg : additional ('{expr3}' in the vim documentation) arg to be
"    specified to 'extend()'.
function! evlib#stdtype#ExtendInOrderOrGetRef( container_list, ... ) abort
	if empty( a:container_list )
		if a:0 >= 1
			return a:1
		endif
		throw "evlib#stdtype#ExtendInOrderOrGetRef(): a:container_list empty and optional arg a:defval not specified"
	endif

	"+? prev: v1: let l:extend_xarg_list = ( a:0 >= 2 ) ? [a:2] : []
	" NOTE: the first two elements are placeholders
	"+? prev: v1: let l:extend_args_list = [ 0, 0 ] + l:extend_xarg_list
	let l:extend_args_list = [ 0, 0 ] + a:000[ 1:1 ]
	let l:Funcref_extend = function( 'extend' )

	for l:container_now in a:container_list
		if exists( 'l:container_out' )
			if l:type_container_out != type( l:container_now )
				throw printf(
							\		"evlib#stdtype#ExtendInOrderOrGetRef(): "
							\			. "one or more elements in a:container_list have different types."
							\			. " type_element=%d;"
							\			. " type_expected=%d;"
							\		, type( l:container_now )
							\		, l:type_container_out
							\	)
			endif
			" silently skip subsequent "src" empty containers
			if ! empty( l:container_now )
				" first create a copy of the output object if it matches a
				" source one (the first "used" one, which is equivalent in
				" this case).
				if l:container_out is l:container_firstout_ref
					" optimisation: if l:container_out is empty, there is no
					" need to duplicate it anyway: we will use this 2nd
					" (non-empty in this case) object as the "first" one.
					if empty( l:container_out )
						let l:container_out = l:container_now
						let l:container_firstout_ref = l:container_out
					else
						let l:container_out = copy( l:container_firstout_ref )
					endif
					let l:extend_args_list[ 0 ] = l:container_out
				endif
				if l:container_out isnot l:container_now
					let l:extend_args_list[ 1 ] = l:container_now
					call call( l:Funcref_extend, l:extend_args_list )
				endif
			endif
		else
			let l:container_out = l:container_now
			let l:extend_args_list[ 0 ] = l:container_out
			let l:container_firstout_ref = l:container_out
			let l:type_container_out = type( l:container_out )
			if ( a:0 >= 1 ) && ( type( a:1 ) != l:type_container_out )
				throw printf(
							\		"evlib#stdtype#ExtendInOrderOrGetRef(): "
							\			. "the type for the specified default container value does not match the type for one or more of the elements in a:container_list."
							\			. " type_defval=%d;"
							\			. " type_expected=%d;"
							\		, type( a:1 )
							\		, l:type_container_out
							\	)
			endif
		endif

		unlet l:container_now
	endfor

	return l:container_out
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
echoerr "the script 'stdtype.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
