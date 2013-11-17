" compatibility functions

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'compat' ) )
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

let s:evlib_compat_has_fnameescape = exists( '*fnameescape' )
function evlib#compat#fnameescape( fname )
	" from documentation: it escapes: " \t\n*?[{`$\\%#'\"|!<"
	"  plus, depending on 'isfname', other characters.
	return ( s:evlib_compat_has_fnameescape ? fnameescape( a:fname ) : escape( a:fname, " \t\n*?[{`$\\%#'\"|!<" ) )
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


