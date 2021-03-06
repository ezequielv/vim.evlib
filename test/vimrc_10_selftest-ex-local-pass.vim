" test/vimrc_10_selftest-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

" suite #10.1 {{{
call EVLibTest_Start( 'suite #10.1: skip local/all test [custom]' )
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
			\			[ 'test 5 (false)', '0' ],
			\			[ 'test 6 (true)', '1' ],
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
let g:mytest_results_10_1 = EVLibTest_Gen_GetTestStats()
call EVLibTest_Finalise(
			\		{
			\			'global': {
			\					'ntests': 14,
			\					'npass': 3,
			\				},
			\			'group': {
			\					'active': 0,
			\				},
			\			'general': {
			\					'skipping': 1,
			\				},
			\		}
			\	)

call EVLibTest_Start( 'validate expected test results (suite #10.1)' )
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'skip all results' },
			\			[ 'global.ntests == 14', 'g:mytest_results_10_1[ "global" ][ "ntests" ] == 14' ],
			\			[ 'global.npass == 3', 'g:mytest_results_10_1[ "global" ][ "npass" ] == 3' ],
			\			[ 'group.active (false)', '! g:mytest_results_10_1[ "group" ][ "active" ]' ],
			\			[ 'general.skipping (true)', 'g:mytest_results_10_1[ "general" ][ "skipping" ]' ],
			\		]
			\	)
call EVLibTest_Finalise()
" }}}

" suite #10.2 {{{
function EVLibTest_Local_Test_10_2()

	let l:group_results_list_empty = [ [], [], [], [], [], [], [], ]

	let l:group_results_list_all =
				\	[
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 3,
				\								'npass': 1,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 7,
				\								'npass': 4,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 4,
				\								'npass': 3,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 0,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 4,
				\								'npass': 2,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 6,
				\								'npass': 3,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 6,
				\								'npass': 3,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\		[
				\			{ 'groupend': 0,
				\				'results':
				\					{
				\						'global': {
				\							},
				\						'group': {
				\								'ntests': 3,
				\								'npass': 0,
				\								'active': 1,
				\							},
				\						'general': {
				\								'skipping': 1,
				\							},
				\					},
				\			},
				\		],
				\	]

	let l:suite_results_dict_empty = {}

	let l:suite_results_dict_all =
				\	{
				\		'global': {
				\				'ntests': 33,
				\				'npass': 16,
				\			},
				\		'group': {
				\				'active': 0,
				\			},
				\		'general': {
				\				'skipping': 1,
				\			},
				\	}

	for l:stage in range( 1, 3 )

		unlet! g:mytest_results_10_2_1
		unlet! g:mytest_results_10_2_2
		unlet! g:mytest_results_10_2_3
		unlet! g:mytest_results_10_2_4
		unlet! g:mytest_results_10_2_5
		unlet! g:mytest_results_10_2_last

		let l:suite_id = '#10.2.' . string( l:stage )

		if l:stage == 1
			let l:suite_suffix = '(no custom group results, custom suite results)'
			let l:group_results_list = l:group_results_list_empty
			let l:suite_results_dict = l:suite_results_dict_all
		elseif l:stage == 2
			let l:suite_suffix = '(custom group results, no custom suite results)'
			let l:group_results_list = l:group_results_list_all
			let l:suite_results_dict = l:suite_results_dict_empty
		elseif l:stage == 3
			let l:suite_suffix = '(custom group results, custom suite results)'
			let l:group_results_list = l:group_results_list_all
			let l:suite_results_dict = l:suite_results_dict_all
		else
			call EVLibTest_Util_ThrowTestExceptionInternalError()
		endif

		call EVLibTest_Start( 'suite ' . l:suite_id . ': group options ' . l:suite_suffix )
		call EVLibTest_Do_Batch(
					\		[
					\			{ 'group': 'group 1 (skip group)', 'options': [ 'skiponfail.local' ] },
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (false) (one more that is "pass")', '0' ],
					\			[ 'test 3 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 0 ]
					\		+
					\		[
					\			{ 'group': 'group 2 (skip group, local overrides)', 'options': [ 'skiponfail.local' ] },
					\			[ 'test 0 (save partial results (-group 1)', ':let g:mytest_results_10_2_1 = EVLibTest_Gen_GetTestStats()' ],
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (true)', '1' ],
					\			[ 'test 3 (false) (continue: true and false, more groups)', '0', [ 'skiponfail.cont' ] ],
					\			[ 'test 4 (true)', '1' ],
					\			[ 'test 5 (false) (should skip group (group options))', '0' ],
					\			[ 'test 6 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 1 ]
					\		+
					\		[
					\			{ 'group': 'group 3 (continue (default))', 'options': [ 'skiponfail.cont' ] },
					\			[ 'test 0 (save partial results (-group 2)', ':let g:mytest_results_10_2_2 = EVLibTest_Gen_GetTestStats()' ],
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (false)', '0' ],
					\			[ 'test 3 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 2 ]
					\		+
					\		[
					\			{ 'group': 'group 4 (continue (default), local overrides)', 'options': [ 'skiponfail.cont' ] },
					\			[ 'test 0 (save partial results (-group 3)', ':let g:mytest_results_10_2_3 = EVLibTest_Gen_GetTestStats()' ],
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (false) (skip group, more groups, more tests)', '0', [ 'skiponfail.local' ] ],
					\			[ 'test 3 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 3 ]
					\		+
					\		[
					\			{ 'group': 'group 5 (skip all, local overrides)', 'options': [ 'skiponfail.all' ] },
					\			[ 'test 0 (save partial results (-group 4)', ':let g:mytest_results_10_2_4 = EVLibTest_Gen_GetTestStats()' ],
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (false) (should continue, more groups, more tests)', '0', [ 'skiponfail.cont' ] ],
					\			[ 'test 3 (true)', '1' ],
					\			[ 'test 4 (false) (skip group, more groups, more tests)', '0', [ 'skiponfail.local' ] ],
					\			[ 'test 5 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 4 ]
					\		+
					\		[
					\			{ 'group': 'group 6 (skip all, local overrides)', 'options': [ 'skiponfail.all' ] },
					\			[ 'test 0 (save partial results (-group 5)', ':let g:mytest_results_10_2_5 = EVLibTest_Gen_GetTestStats()' ],
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (false) (should continue, more groups, more tests)', '0', [ 'skiponfail.cont' ] ],
					\			[ 'test 3 (true)', '1' ],
					\			[ 'test 4 (false) (skip all, more groups, more tests)', '0' ],
					\			[ 'test 5 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 5 ]
					\		+
					\		[
					\			{ 'group': 'group 90 (should be skipped)' },
					\			[ 'test 1 (true)', '1' ],
					\			[ 'test 2 (true)', '1' ],
					\			[ 'test 3 (true)', '1' ],
					\		]
					\		+
					\		l:group_results_list[ 6 ]
					\		+
					\		[
					\		]
					\	)
					" group 1  - end: (1, 2)
					" group 2  - end: (1, 2) + (1, 0) + (3, 3)
					" group 3  - end: (1, 2) + (1, 0) + (3, 3) + (1, 0) + (2, 1)
					" group 4  - end: (1, 2) + (1, 0) + (3, 3) + (1, 0) + (2, 1) + (1, 0) + (1, 2)
					" group 5  - end: (1, 2) + (1, 0) + (3, 3) + (1, 0) + (2, 1) + (1, 0) + (1, 2) + (1, 0) + (2, 3)
					" group 6  - end: (1, 2) + (1, 0) + (3, 3) + (1, 0) + (2, 1) + (1, 0) + (1, 2) + (1, 0) + (2, 3) + (1, 0) + (2, 3)
					" group 90 - end: (1, 2) + (1, 0) + (3, 3) + (1, 0) + (2, 1) + (1, 0) + (1, 2) + (1, 0) + (2, 3) + (1, 0) + (2, 3) + (0, 3)

		" save results so far
		let g:mytest_results_10_2_last = EVLibTest_Gen_GetTestStats()
		call EVLibTest_Finalise( l:suite_results_dict )

		call EVLibTest_Start( 'validate expected test results (suite ' . l:suite_id . ')' )
		call EVLibTest_Do_Batch(
					\		[
					\			{ 'group': 'suite #10.1 - group 1 - results' },
					\			[ 'global.ntests == 3', 'g:mytest_results_10_2_1[ "global" ][ "ntests" ] == 3' ],
					\			[ 'global.npass == 1', 'g:mytest_results_10_2_1[ "global" ][ "npass" ] == 1' ],
					\			[ 'group.active (true) (read from group)', 'g:mytest_results_10_2_1[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (false) (read from group)', '! g:mytest_results_10_2_1[ "general" ][ "skipping" ]' ],
					\			{ 'group': 'suite #10.1 - group 2 - results' },
					\			[ 'global.ntests == 10', 'g:mytest_results_10_2_2[ "global" ][ "ntests" ] == 10' ],
					\			[ 'global.npass == 5', 'g:mytest_results_10_2_2[ "global" ][ "npass" ] == 5' ],
					\			[ 'group.active (true) (read from group)', 'g:mytest_results_10_2_2[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (false) (read from group)', '! g:mytest_results_10_2_2[ "general" ][ "skipping" ]' ],
					\			{ 'group': 'suite #10.1 - group 3 - results' },
					\			[ 'global.ntests == 14', 'g:mytest_results_10_2_3[ "global" ][ "ntests" ] == 14' ],
					\			[ 'global.npass == 8', 'g:mytest_results_10_2_3[ "global" ][ "npass" ] == 8' ],
					\			[ 'group.active (true) (read from group)', 'g:mytest_results_10_2_3[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (false) (read from group)', '! g:mytest_results_10_2_3[ "general" ][ "skipping" ]' ],
					\			{ 'group': 'suite #10.1 - group 4 - results' },
					\			[ 'global.ntests == 18', 'g:mytest_results_10_2_4[ "global" ][ "ntests" ] == 18' ],
					\			[ 'global.npass == 10', 'g:mytest_results_10_2_4[ "global" ][ "npass" ] == 10' ],
					\			[ 'group.active (true) (read from group)', 'g:mytest_results_10_2_4[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (false) (read from group)', '! g:mytest_results_10_2_4[ "general" ][ "skipping" ]' ],
					\			{ 'group': 'suite #10.1 - group 5 - results' },
					\			[ 'global.ntests == 24', 'g:mytest_results_10_2_5[ "global" ][ "ntests" ] == 24' ],
					\			[ 'global.npass == 13', 'g:mytest_results_10_2_5[ "global" ][ "npass" ] == 13' ],
					\			[ 'group.active (true) (read from group)', 'g:mytest_results_10_2_5[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (false) (read from group)', '! g:mytest_results_10_2_5[ "general" ][ "skipping" ]' ],
					\			{ 'group': 'suite #10.1 - group 6 - results' },
					\			[ 'global.ntests == 33', 'g:mytest_results_10_2_last[ "global" ][ "ntests" ] == 33' ],
					\			[ 'global.npass == 16', 'g:mytest_results_10_2_last[ "global" ][ "npass" ] == 16' ],
					\			[ 'group.active (false) (read at global scope)', '! g:mytest_results_10_2_last[ "group" ][ "active" ]' ],
					\			[ 'general.skipping (true) (read at global scope)', 'g:mytest_results_10_2_last[ "general" ][ "skipping" ]' ],
					\		]
					\	)
		call EVLibTest_Finalise()
	endfor
endfunction

call EVLibTest_Local_Test_10_2()
" }}}


" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
