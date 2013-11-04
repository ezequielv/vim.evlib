" test/vimrc_00_selftest-local.vim

" boilerplate -- prolog {{{
if has('eval')
" load 'common' vim code
execute 'source ' . fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/common.vim' )
" }}}

if 0 " disabled for now
call EVLibTest_Start( 'skip local test (results near the end)' )
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'group 1' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (false)', '0' ],
			\			[ 'test 3 (has("eval"))', 'has("eval")' ],
			\			{ 'group': 'group 2' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (false)', '0' ],
			\			[ 'test 2 (false) (skip group) (one more that is "pass")', '0', [ 'skiponfail.local' ] ],
			\			[ 'test 3 (true)', '1' ],
			\			{ 'group': 'group 3' },
			\			[ 'results so far (n, pass): (3, 2), (3, 1): n == 6', 'EVLibTest_Gen_GetTestStats()[ "global" ][ "ntests" ] == 6' ],
			\			[ 'results so far (n, pass): (3, 2), (3, 1), (1, 1): pass == 4', 'EVLibTest_Gen_GetTestStats()[ "global" ][ "npass" ] == 4' ],
			\		]
			\	)
call EVLibTest_Finalise()
endif

call EVLibTest_Start( 'skip local and skip all test (results in separate test suite)' )
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'group 1' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (false)', '0' ],
			\			[ 'test 3 (false) (skip group) (one more that is "pass")', '0', [ 'skiponfail.local' ] ],
			\			[ 'test 4 (true)', '1' ],
			\			{ 'group': 'group 2' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (true)', '1' ],
			\			[ 'test 3 (false) (skip all: true and false, more groups)', '0', [ 'skiponfail.all' ] ],
			\			[ 'test 4 (true)', '1' ],
			\			{ 'group': 'group 3' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (false)', '0' ],
			\			{ 'group': 'group 4' },
			\			[ 'test 1 (true)', '1' ],
			\			[ 'test 2 (true)', '1' ],
			\		]
			\	)
						" group 1 - end: (3, 1)
						" group 2 - end: (3, 1) + (3, 2)
						" group 3 - end: skipped
						" group 4 - end: skipped
" save results so far
let g:test_skipall_results = EVLibTest_Gen_GetTestStats()
call EVLibTest_Finalise()

call EVLibTest_Start( 'skip local and skip all results (should get 100% pass here)' )
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'skip all results' },
			\			[ 'global.ntests == 6', 'g:test_skipall_results[ "global" ][ "ntests" ] == 6' ],
			\			[ 'global.npass == 3', 'g:test_skipall_results[ "global" ][ "npass" ] == 3' ],
			\			[ 'group.active (false)', '! g:test_skipall_results[ "group" ][ "active" ]' ],
			\			[ 'general.skipping (true)', 'g:test_skipall_results[ "general" ][ "skipping" ]' ],
			\		]
			\	)
			" prev: \			[ 'group.ntests == 3', 'g:test_skipall_results[ "group" ][ "ntests" ] == 3' ],
			" prev: \			[ 'group.npass == 2', 'g:test_skipall_results[ "group" ][ "npass" ] == 2' ],
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
