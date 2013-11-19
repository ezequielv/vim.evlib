" test/vimrc_61_init_libstate_01-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

call EVLibTest_Start( 'initialisation - library state checks' )

" IDEA: create a selftest to test evlib#pvt#apiver#SupportsAPIVersion()
function EVLibTest_Local_CheckAPIVersion()
	let l:version_v1 = 0
	let l:version_v2 = 1
	let l:version_v3 = 0

	return
				\	evlib#SupportsAPIVersion( l:version_v1, l:version_v2 )
				\	&&
				\	evlib#SupportsAPIVersion( l:version_v1, l:version_v2, l:version_v3 )
endfunction

let g:evlib_test_local_counter_to_check = 0
" EVLibTest_Local_CheckUpdateCounter( val_check [, val_true [, val_false ] ] )
function EVLibTest_Local_CheckUpdateCounter( val_check, ... )
	let l:success = ( g:evlib_test_local_counter_to_check == a:val_check )

	" conditionally update
	if l:success && ( a:0 > 0 )
		let g:evlib_test_local_counter_to_check = a:1
	endif
	if ( ! l:success ) && ( a:0 > 1 )
		let g:evlib_test_local_counter_to_check = a:2
	endif

	return l:success
endfunction

let g:evlib_test_local_testtree_libcheck01 = g:evlib_test_common_test_testtrees_rootdir . '/init.01'

let s:evlib_test_local_counter_check_test_flags_list = [ 'skiponfail.local' ]

call EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust(
		\		{
		\			'group_title': 'test initialisation stages',
		\			'precheck':
		\				[
		\					[ 'pre-check #1', '!0' ],
		\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
		\					[ 'check API version (inaccessible -> throws)', 'EVLibTest_Local_CheckAPIVersion()', [ 'code.throws' ] ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 0', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (check only)', 'EVLibTest_Local_CheckUpdateCounter( 0 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 0', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 0, 1 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 1', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (check and set) ("false")', '! EVLibTest_Local_CheckUpdateCounter( 0, 1, 2 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 2', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (check and set) ("false")', '! EVLibTest_Local_CheckUpdateCounter( 0, 1, 5 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 5', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 5, 1, 10 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 1', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
		\				],
		\			'preinit':
		\				[
		\					[ 'pre-init #1', '!0' ],
		\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 1, 2 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check API version (accessible -> "true")', 'EVLibTest_Local_CheckAPIVersion()' ],
		\					[ 'call function needing initialised lib (throws)', ':throw EVLibTest_Local_ExceptionTest', [ 'code.throws' ] ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 2, 3 )', s:evlib_test_local_counter_check_test_flags_list ],
		\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
		\					[ 'add our test tree to the runtimepath', ':set runtimepath+=' . ( exists( '*fnameescape' ) ? fnameescape( g:evlib_test_local_testtree_libcheck01 ) : g:evlib_test_local_testtree_libcheck01 ), [ 'skiponfail.all' ] ],
		\					[ 'check that our test tree is now accessible', 'evlib#test#init01#HasAccessToThisTest()', [ 'skiponfail.local' ] ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 3, 4 )', s:evlib_test_local_counter_check_test_flags_list ],
		\				],
		\			'postinit':
		\				[
		\					[ 'post-init #1', '!0' ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 6, 7 )', s:evlib_test_local_counter_check_test_flags_list ],
		\				],
		\			'epilog':
		\				[
		\					[ 'epilog #1', '!0' ],
		\					[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 7, 8 )', s:evlib_test_local_counter_check_test_flags_list ],
		\				],
		\		}
		\	)

call EVLibTest_Do_Batch(
		\		[
		\			{ 'group': 'post-lib initialisation checks' },
		\			[ 'check test counter (check and set)', 'EVLibTest_Local_CheckUpdateCounter( 8, 9 )', s:evlib_test_local_counter_check_test_flags_list ],
		\			[ 'check test counter (manual)', 'g:evlib_test_local_counter_to_check == 9', s:evlib_test_local_counter_check_test_flags_list ],
		\		]
		\	)

call EVLibTest_GroupSet_TestLibrary()

call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

