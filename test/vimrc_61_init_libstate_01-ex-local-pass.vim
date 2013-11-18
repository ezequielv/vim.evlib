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

" ref: function EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust( test_list_precheck, test_list_preinit, test_list_postinit, test_list_epilog )
call EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust(
		\		{
		\			'group_title': 'my group title',
		\			'precheck':
		\				[
		\					[ 'pre-check #1', '!0' ],
		\					[ 'check API version (inaccessible -> throws)', 'EVLibTest_Local_CheckAPIVersion()', [ 'code.throws' ] ],
		\				],
		\			'preinit':
		\				[
		\					[ 'pre-init #1', '!0' ],
		\					[ 'check API version (accessible -> "true")', 'EVLibTest_Local_CheckAPIVersion()' ],
		\					[ 'call function needing initialised lib (throws)', ':throw EVLibTest_Local_ExceptionTest', [ 'code.throws' ] ],
		\				],
		\			'postinit':
		\				[
		\					[ 'post-init #1', '!0' ],
		\				],
		\			'epilog':
		\				[
		\					[ 'epilog #1', '!0' ],
		\				],
		\		}
		\	)
call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

