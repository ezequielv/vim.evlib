" test/vimrc_22_selftest_init_runtimepath_01-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

" note: if changing this value, amend calls to
"  EVLibTest_Local_CounterCheckAndExec() in the test code
let g:evlib_test_local_counter_to_check = 1

" returns: "success"
function EVLibTest_Local_CounterCheckAndExec( val_check, expr )
	let l:success = ( g:evlib_test_local_counter_to_check == a:val_check )
	" purposedly not running through try..endtry, as we know this function
	"  will be executed by EVLibTest_Do_Check()
	if l:success && ( strlen( a:expr ) > 0 )
		execute a:expr
	endif
	return l:success
endfunction

call EVLibTest_Start( 'initialisation - library state checks (around initialisation)' )

call EVLibTest_Do_Batch(
		\		[
		\			{ 'group': 'EVLibTest_Local_CounterCheckAndExec() internal checks' },
		\			[ 'test-local counter check (manual)', 'g:evlib_test_local_counter_to_check == 1' ],
		\			[ 'test-local counter check function: check only', 'EVLibTest_Local_CounterCheckAndExec( 1, "" )' ],
		\			[ 'checking test-local counter has not changed', 'g:evlib_test_local_counter_to_check == 1' ],
		\			[ 'test-local counter check function: check and set', 'EVLibTest_Local_CounterCheckAndExec( 1, "let g:evlib_test_local_counter_to_check = g:evlib_test_local_counter_to_check + 2" )' ],
		\			[ 'test-local counter check (manual)', 'g:evlib_test_local_counter_to_check == 3' ],
		\			[ 'test-local counter check function: check only', 'EVLibTest_Local_CounterCheckAndExec( 3, "" )' ],
		\			[ 'checking test-local counter has not changed', 'g:evlib_test_local_counter_to_check == 3' ],
		\			[ 'setting test-local counter to initial value', ':let g:evlib_test_local_counter_to_check = 1' ],
		\		]
		\	)
call EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust(
		\		{
		\			'group_title': 'library initialisation with customised steps',
		\			'precheck':
		\				[
		\					[ 'pre-check #1', '!0' ],
		\					[ 'pre-check #2: checking test-local counter', 'EVLibTest_Local_CounterCheckAndExec( 1, "let g:evlib_test_local_counter_to_check = g:evlib_test_local_counter_to_check * 2" )' ]
		\				],
		\			'preinit':
		\				[
		\					[ 'pre-init #1', '!0' ],
		\					[ 'pre-init #2: checking test-local counter', 'EVLibTest_Local_CounterCheckAndExec( 2, "let g:evlib_test_local_counter_to_check = g:evlib_test_local_counter_to_check + 3" )' ]
		\				],
		\			'postinit':
		\				[
		\					[ 'post-init #1', '!0' ],
		\					[ 'post-init #2: checking test-local counter', 'EVLibTest_Local_CounterCheckAndExec( 5, "let g:evlib_test_local_counter_to_check = g:evlib_test_local_counter_to_check * 4" )' ]
		\				],
		\			'epilog':
		\				[
		\					[ 'epilog #1', '!0' ],
		\					[ 'epilog #2: checking test-local counter', 'EVLibTest_Local_CounterCheckAndExec( 20, "let g:evlib_test_local_counter_to_check = g:evlib_test_local_counter_to_check + 5" )' ]
		\				],
		\		}
		\	)
call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Do_Batch(
		\		[
		\			{ 'group': 'EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust() overall results' },
		\			[ 'test-local counter check (manual)', 'g:evlib_test_local_counter_to_check == 25' ],
		\			[ 'checking test-local counter (function)', 'EVLibTest_Local_CounterCheckAndExec( 25, "" )' ],
		\			[ 'checking test-local counter has not changed', 'g:evlib_test_local_counter_to_check == 25' ],
		\		]
		\	)

call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

