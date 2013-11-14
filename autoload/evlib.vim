" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_loaded' ) || ( exists( 'g:evlib_disable' ) && g:evlib_disable != 0 )
	finish
endif
let g:evlib_loaded = 1
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

" note: we only need the 'eval' feature (already checked)
function evlib#IsInitialised()
	return ( exists( 'g:evlib_initialised' ) ? ( g:evlib_initialised != 0 ) : 0 )
endfunction

" TODO: also initialise the library from the 'plugin/*.vim' file, so that we
"  can support the user not caring about initialisation, as long as we are
"  accessible through the 'runtimepath' setting;
function evlib#Init() abort
	if ! evlib#IsInitialised()
		" TODO: check for all the features that we need in this library

		" now we can set up a few things
		" FIXME: create a directory from the root:
		"  {root}/evlib
		"  to which this "glob" gets added and expanded:
		"  {root}/evlib/impl/init/:
		"   20-test_cmd.vim
		"    this will install commands such as:
		"    (TODO: validate from vim's help (see ':h usr_41.txt', then search
		"    for '<Plug>TypecorrAdd  -> '...)
		"     g:evlib_cfg_cmd_prefix . 'TestRun'
		"      which would run:
		"     <SID>CommandTestRun ...
		"      which would then run:
		"     :call <SID>TestRun( ... )<CR>
		"
		" FIXME: have autoload/evlib/internal.vim set the directory root,
		"  knowing its own relative location (fnamemodify());
		"
		" FIXME: use glob()
		"
		" LATER: call evlib#internal#SourceEVLibFiles( 'impl/init/*.vim' )

		" lastly, we mark the library as initialised
		let g:evlib_initialised = 1
	endif
	return evlib#IsInitialised()
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
echoerr "the script 'autoload/evlib.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

