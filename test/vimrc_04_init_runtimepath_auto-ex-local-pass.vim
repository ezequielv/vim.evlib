" test/vimrc_04_init_runtimepath_auto-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
execute 'source ' . fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/common.vim' )
" }}}

call EVLibTest_Start( 'make library available by setting runtimepath, then initialising manually' )
call EVLibTest_GroupSet_LoadLibrary_Custom(
	\		[
	\			[ 'sanity check: common.vim set up correctly', 'exists( "g:evlib_test_common_rootdir" ) && isdirectory( g:evlib_test_common_rootdir )', [ 'skiponfail.all' ] ],
	\			[ 'set up runtimepath to include project root directory', ':let &runtimepath .= "," . g:evlib_test_common_rootdir', [ 'skiponfail.all' ] ],
	\			[ 'initialise the library (call evlib#Init())', ':call evlib#Init()', [ 'skiponfail.all' ] ],
	\		]
	\	)

call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
