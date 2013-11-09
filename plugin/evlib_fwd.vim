" evlib_fwd.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_loaded' ) || ( exists( 'g:evlib_disable' ) && g:evlib_disable != 0 )
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

function s:evlib_local_fnameescape( fname )
	" for now, we do not do any escaping if it isn't supported
	return ( exists( '*fnameescape' ) ? fnameescape( a:fname ) : a:fname )
endfunction

" forward to the script that knows how to load this library
execute 'source ' . s:evlib_local_fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h:h' ) . '/evlib_loader.vim' )

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'evlib_fwd.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

