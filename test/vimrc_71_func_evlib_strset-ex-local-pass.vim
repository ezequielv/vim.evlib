" test/vimrc_71_func_evlib_strset-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

function Test_CreatedSetMatches( elements )
	return ( sort( copy( a:elements ) ) == sort( evlib#strset#AsList( evlib#strset#Create( a:elements ) ) ) )
endfunction

function Test_CreatedIsSameObj( a_set )
	return a:a_set is evlib#strset#Create( a:a_set, 'o' )
endfunction

call EVLibTest_Start( 'load library using "source {path}/evlib_loader.vim"' )
call EVLibTest_GroupSet_LoadLibrary_Method_Source()
"? call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

call EVLibTest_Start( 'evlib#strset module' )
" TODO: put these ones on the 'dtset' module (when it's created)
"			\			[ 'evlib#strset#Create(): simple (integer numbers)', 'Test_CreatedSetMatches( [1, 3, 2, -4] )' ],
"			\			[ 'evlib#strset#Create(): simple (w/float numbers)', 'Test_CreatedSetMatches( [1, 3, 2, -4, 5.0, -6.1] )' ],
" TODO: add support in the library code to reject empty string value elements
"-			\			[ 'evlib#strset#Create(): empty, normal', 'Test_CreatedSetMatches( ["one", ""] )' ],
call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'evlib#strset#Create() (independent)', 'options': [ 'verbose' ] },
			\			[ 'evlib#strset#Create(): simple', 'Test_CreatedSetMatches( ["one", "two", "three"] )' ],
			\			[ 'evlib#strset#Create(): quotes, normal', 'Test_CreatedSetMatches( ["\"quoted\" value", "normal value", "value in '."'".'single apostrophes'."'".'"] )' ],
			\			[ 'evlib#strset#Create(): return same obj if already strset', 'Test_CreatedIsSameObj( evlib#strset#Create( ["one", "two"] ) )' ],
			\			{ 'group': 'evlib#strset#UnionNew() (independent)' },
			\			[ 'evlib#strset#UnionNew(): simple', 'sort( evlib#strset#AsList( evlib#strset#UnionNew( ["one", "two"], ["three", "four", "one"] ) ) ) == sort( [ "one", "two", "three", "four" ] )' ],
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
