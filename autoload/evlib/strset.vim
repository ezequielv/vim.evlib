" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'autoload_evlib_strset' ) )
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

" TODO: rename module to strset, as dictionary keys seem to be implicitly converted to strings.
"  (and maybe create a slower version that allows arbitrary types)

let s:dict_set_element_dummy_value = 1

function evlib#strset#IsStrSet( a_set, ... )
	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )
	" (optional flags: 'q': quick, 't': thorough)
	let l:flag_check_thorough = ( evlib#strflags#GetFlagValues( l:flags, 'qt', '1', 'q' ) == 't' )
	" TODO: replace with a better check (see comments about evlib#type#HighLevelType())
	let l:result = ( type( a:a_set ) == type( {} ) )

	if l:flag_check_thorough
		" TODO: implement this...
	endif

	return l:result
endfunction

function s:validate_is_set( a_set )
	if ( ! evlib#strset#IsStrSet( a:a_set ) )
		" TODO: make a function to throw exceptions from evlib
		echoerr printf( 'evlib#strset#IsStrSet() returned false. object=%s', string( a:a_set ) )
	endif
endfunction

" TODO: implement unit test
" NOTE: [api] new in v0.3.0
function evlib#strset#NumElements( a_set )
	call s:validate_is_set( a:a_set )
	return len( a:a_set )
endfunction

" TODO: implement unit test
" NOTE: [api] new in v0.3.0
function evlib#strset#IsEmpty( a_set )
	call s:validate_is_set( a:a_set )
	return empty( a:a_set )
endfunction

" TODO: implement unit test
"
" args: 
function evlib#strset#Create(...)
	"? if ( a:0 == 0 )
	"? 	return {}
	"? endif
	let l:result = {}

	if ( a:0 >= 1 )
		let l:flags = ( ( a:0 >= 2 ) ? a:2 : '' )
		" get the flags from the option string
		let l:flag_copy_src = ( evlib#strflags#GetFlagValues( l:flags, 'co', '1', 'c' ) == 'c' )
		" TODO: perform a copy if l:flag_copy_src && evlib#strset#IsStrSet(a:1)
		if ( ! l:flag_copy_src ) && evlib#strset#IsStrSet( a:1 )
			" optimised: do not copy: return the original object instead.
			let l:result = a:1
		else
			call evlib#strset#Add( l:result, a:1, l:flags ) " ignore return value
		endif
	endif
	return l:result
endfunction

" TODO: implement unit test
function evlib#strset#Add( a_set, string_or_list, ... )
	let l:result = a:a_set
	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )

	" MAYBE: use extend() to extend dictionaries? (but how?)
	for l:elem_now in evlib#stdtype#AsTopLevelList( a:string_or_list )
		let a:a_set[ l:elem_now ] = s:dict_set_element_dummy_value
	endfor

	return l:result
endfunction

" TODO: implement unit test
function evlib#strset#Clear( a_set )
	let l:result = a:a_set

	" taken from the ':h filter()' documentation entry.
	call filter( a:a_set, 0 )

	return l:result
endfunction

" TODO: implement unit test
function evlib#strset#HasElement( a_set, element )
	return has_key( a:a_set, a:element )
endfunction

" TODO: implement unit test
function evlib#strset#AsList( a_set )
	return keys( a:a_set )
endfunction

" TODO: implement unit test
function evlib#strset#Copy( a_set )
	return copy( a:a_set )
endfunction

" TODO: allow all functions taking "another set" ('a_other') to receive either a list or one of our "strset" objects -- create a function to create a shallow copy of the src, so we can use its values without worrying about performance (ie., avoid creating an object if the original source was already an object).

" TODO: implement unit test
function evlib#strset#UnionUpdate( a_set, a_other )
	" TODO: validate that 'a_other' is a strset.
	" get the set version of a:a_other, if it isn't a strset already.
	let l:other = evlib#strset#Create( a:a_other, 'o' )
	call extend( a:a_set, l:other )
	return a:a_set
endfunction

" TODO: implement unit test
function evlib#strset#UnionNew( a_set, a_other )
	return evlib#strset#UnionUpdate( evlib#strset#Create( a:a_set ), a:a_other )
endfunction

" TODO: implement intersection functions (no "native" function (as extend() is) to build upon, though)

" TODO: create an "evlib" version of type(), so these custom types can all be checked for their "custom" type: for example:
"  * evlib#type#ClassType(a_obj) -> string
"  * evlib#type#IsClassType(a_obj) -> boolean
"  * evlib#type#HighLevelType(a_obj) -> string (either a value like type([]), type(1), etc., or the string from evlib#type#ClassType())
" MAYBE: TODO: (optionally?) validate (the "quick" way?) that each 'a_set' is of the right type.

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'strset.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
