" test/base.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_test_base_loaded' )
	finish
endif
let g:evlib_test_base_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" FIXME: move this from common.vim: " support for writing the results to a file ...
"  FIXME: move s:EVLibTest_Init_TestOutput() (but rename the function first)
" FIXME: make sure that the renamed function has an "end" function:
"  EVLibTest_TestOutput_InitAndOpen( MAYBE_OPTIONAL_ARG_do_open_flag )
"   FIXME: make function also take filename(s) from vim variable (in addition
"    to environment variable)
"  EVLibTest_TestOutput_Reopen()
"  EVLibTest_TestOutput_Close()

" MAYBE: move function 'EVLibTest_Module_Load( module )' here

" MAYBE: make this include a "defs.vim" with just constants (useful for the
"  'foldexpr' and 'foldtext' implementing functions)
"  MAYBE: ... and move constants there! (which might need some refactoring,
"   too, in order to share just the literals on one hand, and then have
"   regexes for matching the produced lines, on the other);

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'test/base.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
