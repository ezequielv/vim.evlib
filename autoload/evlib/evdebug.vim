" provide debugging capabilities

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evdebug_loaded' ) || ( exists( 'g:evdebug_disable' ) && g:evdebug_disable != 0 )
	finish
endif
let g:evdebug_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog


" debugging ( evlib#evdebug#DebugMessage() ) {{{
" not_needed: let s:debug_this_script=0
"let s:debug_this_script=1 " comment this line to disable debugging
"
" FIXME: change variable name (remove HDS)
if exists( '$HDS_VIM_DEBUG' )
	let s:debug_this_script = expand( '$HDS_VIM_DEBUG' )
endif

function evlib#evdebug#DebugMessage( msg )
	if exists( "s:debug_this_script" ) && s:debug_this_script
		let cmdpref_1 = ( exists( ':unsilent' ) ? ':unsilent ' : '' )
		" doc: see ':h :unsilent'
		exec cmdpref_1 . 'echomsg "[DEBUG]: " . a:msg'
	endif
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
echoerr "the script 'evdebug.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

