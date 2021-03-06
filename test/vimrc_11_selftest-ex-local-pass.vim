" test/vimrc_11_selftest-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

call EVLibTest_Start( 'expression tests (should get 100%)' )
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'group 1' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 [eval()] (should throw)', 'evlib#modulenotfound#SomeFunction()', [ 'code.throws' ] ],
			\			{ 'test': 'test 3 [exec] (should throw)', 'exec': 'EVLib_NonExistingModule_Command', 'options': [ 'code.throws' ] },
			\			[ 'test 4 (true)', '1' ],
			\			[ 'test 5 (using an undefined variable throws)', 'g:mytest_selftest_myvar', [ 'code.throws' ] ],
			\			[ 'test 6 (exec in list: assign to variable)', ':let g:mytest_selftest_myvar = 1' ],
			\			[ 'test 7 (using the variable works)', 'g:mytest_selftest_myvar' ],
			\		]
			\	)
			" TODO: put these in a separate test:
			" \			[ 'test 5 (unexpected throw)', 'EVLib_NonExistingModule_Command' ],
			" \			[ 'test 6 [eval()] (should throw, but does not)', 'strlen( "" ) == 0', [ 'code.throws' ] ],
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
