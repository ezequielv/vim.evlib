" test/vimrc_01_init_source-local.vim

" boilerplate -- prolog {{{
if has('eval')
" load 'common' vim code
execute 'source ' . fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/common.vim' )
" }}}

call EVLibTest_Start( 'load library using "source {path}/evlib_loader.vim"' )
" TODO: put this in new function:
"  EVLibTest_GroupSet_LoadLibrary_Method_Source(), to be called from the
"  function EVLibTest_GroupSet_LoadLibrary_Default() (to be used from other
"  test suites)
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'library initialisation' },
			\			[ 'library not intialised yet (safe check)', '! exists( "*evlib#IsInitialised()" )' ],
			\			{ 'test': 'load library by sourcing "evlib_loader.vim"', 'exec': 'source ' . g:evlib_test_common_rootdir . '/evlib_loader.vim' },
			\			[ 'library now intialised', 'exists( "*evlib#IsInitialised" ) && evlib#IsInitialised()', [ 'skiponfail.all' ] ],
			\		]
			\	)
call EVLibTest_GroupSet_TestLibrary()

call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
