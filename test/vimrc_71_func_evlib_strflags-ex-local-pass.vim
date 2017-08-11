" test/vimrc_71_func_evlib_strflags-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

let g:test_gfv_allowed_01 = 'abcd'

call EVLibTest_Start( 'load library using "source {path}/evlib_loader.vim"' )
call EVLibTest_GroupSet_LoadLibrary_Method_Source()
"? call EVLibTest_GroupSet_TestLibrary()
" TODO: test invalid inputs: use numbers instead of strings, etc.
" TODO: test with "regex"-y characters, like '[', ']', '\'.
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'evlib#strflags#GetFlagValues() (independent)' },
			\			[ 'evlib#strflags#GetFlagValues(): simple', 'evlib#strflags#GetFlagValues( "c", g:test_gfv_allowed_01 ) == "c"' ],
			\			[ 'evlib#strflags#GetFlagValues(): ret default (in: empty)', 'evlib#strflags#GetFlagValues( "", g:test_gfv_allowed_01, "", "_" ) == "_"' ],
			\			[ 'evlib#strflags#GetFlagValues(): ret default (in: others)', 'evlib#strflags#GetFlagValues( "1232", g:test_gfv_allowed_01, "", "_" ) == "_"' ],
			\			[ 'evlib#strflags#GetFlagValues(): ret empty def (in: empty)', 'evlib#strflags#GetFlagValues( "", g:test_gfv_allowed_01 ) == ""' ],
			\			[ 'evlib#strflags#GetFlagValues(): ret empty def (in: others)', 'evlib#strflags#GetFlagValues( "1232", g:test_gfv_allowed_01 ) == ""' ],
			\			[ 'evlib#strflags#GetFlagValues(): return others', 'evlib#strflags#GetFlagValues( "1b232", g:test_gfv_allowed_01, "O" ) == "1232"' ],
			\			[ 'evlib#strflags#GetFlagValues(): multiple in single group', 'evlib#strflags#GetFlagValues( "cb", g:test_gfv_allowed_01, "m" ) == "cb"' ],
			\			[ 'evlib#strflags#GetFlagValues(): multiple (in: w/others)', 'evlib#strflags#GetFlagValues( "1c2b34", g:test_gfv_allowed_01, "m" ) == "cb"' ],
			\			[ 'evlib#strflags#GetFlagValues(): exclusive (in: valid)', 'evlib#strflags#GetFlagValues( "c", g:test_gfv_allowed_01, "x" ) == "c"' ],
			\			[ 'evlib#strflags#GetFlagValues(): exclusive (in: multiple)', 'evlib#strflags#GetFlagValues( "ca", g:test_gfv_allowed_01, "x", "_", "!" ) == "!"' ],
			\			[ 'evlib#strflags#GetFlagValues(): ret empty err (excl.err)', 'evlib#strflags#GetFlagValues( "ba", g:test_gfv_allowed_01, "x", "_" ) == ""' ],
			\			[ 'evlib#strflags#GetFlagValues(): excl (in: multiple) (exc)', 'evlib#strflags#GetFlagValues( "ca", g:test_gfv_allowed_01, "xt", "_", "!" )', [ 'code.throws' ] ],
			\			[ 'evlib#strflags#GetFlagValues(): exclusive (in: w/others)', 'evlib#strflags#GetFlagValues( "12d34", g:test_gfv_allowed_01, "x", "_", "!" ) == "!"' ],
			\			[ 'evlib#strflags#GetFlagValues(): excl+mult (in: multiple)', 'evlib#strflags#GetFlagValues( "db", g:test_gfv_allowed_01, "xm", "_", "!" ) == "db"' ],
			\			[ 'evlib#strflags#GetFlagValues(): excl+mult (in: w/others)', 'evlib#strflags#GetFlagValues( "1d2b3", g:test_gfv_allowed_01, "xm", "_", "!" ) == "!"' ],
			\		]
			\	)
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
