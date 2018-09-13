" provide debugging capabilities

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'autoload_evlib_debug' ) )
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

" debugging ( evlib#debug#DebugMessage() ) {{{
let s:debug_this_script = 0
if exists( 'g:evlib_debug_enable' )
	let s:debug_this_script = g:evlib_debug_enable
elseif exists( '$EVLIB_VIM_DEBUG' )
	let s:debug_this_script = expand( '$EVLIB_VIM_DEBUG' )
endif
" deal with an empty variable value
"  (note: empty() also returns != 0 for the input number == 0)
if ( empty( s:debug_this_script ) )
	let s:debug_this_script = 0
endif
" normalise: any value that is not the string '0' gets transformed into 1,
"  so that the comparisons done by this script can be done quickly and
"  safely
if ( s:debug_this_script != '0' )
	let s:debug_this_script = 1
endif

if s:debug_this_script

	function evlib#debug#IsDebugEnabled()
		return !0
	endfunction

	function evlib#debug#DebugMessage( msg )
		let cmdpref_1 = ( exists( ':unsilent' ) ? ':unsilent ' : '' )
		let l:msgpref = ( ( exists( '*strftime' ) ) ? ( ' ' . strftime( '[%Y.%m.%d %H:%M:%S]' ) ) : '' )
		execute cmdpref_1 . 'echomsg "[DEBUG]" . l:msgpref . ": " . a:msg'
	endfunction

else

	function evlib#debug#IsDebugEnabled()
		return 0
	endfunction

	function evlib#debug#DebugMessage( msg )
	endfunction

endif
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
echoerr "the script 'debug.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
