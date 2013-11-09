" test/vimrc_03_init_vundle-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

" make sure that 'vundle' is supported {{{
" LATER: put the right version check here
"  (see ':h v:version', and 'has("patch123")')
if !( exists( '*fnameescape' ) && ( v:version >= 700 ) )
	call EVLibTest_Gen_InfoMsg( 'test file: ' . string( fnamemodify( g:evlib_test_common_main_source_file, ':p:t' ) ) . ' requires "vundle", but it is not supported by the vim instance being run' )
	call EVLibTest_Gen_OutputLine( '' )
	finish
endif
" }}}

let g:mytest_mytesttree_rootdir = g:evlib_test_common_test_testtrees_rootdir . '/vundle.01'
let g:mytest_mytesttree_bundledir = g:mytest_mytesttree_rootdir . '/bundle'
let g:mytest_mytesttree_vundledir = g:mytest_mytesttree_bundledir . '/vundle'

function EVLibTest_Util_VundleInitialised()
	return exists( 'g:bundles' )
endfunction

" set up as 'vundle' requires {{{
set nocompatible               " be iMproved
filetype off                   " required!
" }}}

"+ call EVLibTest_Gen_InfoVarValue( "g:mytest_mytesttree_rootdir" )
"+ call EVLibTest_Gen_InfoVarValue( "g:mytest_mytesttree_bundledir" )
"+ call EVLibTest_Gen_InfoVarValue( "g:mytest_mytesttree_vundledir" )
"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )
"+ exec 'set runtimepath+=' . ( exists( '*fnameescape' ) ? fnameescape( g:mytest_mytesttree_vundledir ) : g:mytest_mytesttree_vundledir )
"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )

call EVLibTest_Start( 'load library using "vundle"' )
call EVLibTest_Do_Batch( [
	\			{ 'group': 'sanity checks' },
	\			[ 'library not intialised yet (safe check)', '! exists( "*evlib#IsInitialised" )', [ 'skiponfail.all' ] ],
	\			[ 'vundle not initialised yet', '! EVLibTest_Util_VundleInitialised()', [ 'skiponfail.all' ] ],
	\			[ '"vundle" package directory available', 'filereadable( g:mytest_mytesttree_vundledir . "/README.md" )', [ 'skiponfail.all' ] ],
	\			{ 'group': 'vundle initialisation' },
	\			[ 'set up runtimepath to include "vundle"', ':set runtimepath+=' . ( exists( '*fnameescape' ) ? fnameescape( g:mytest_mytesttree_vundledir ) : g:mytest_mytesttree_vundledir ), [ 'skiponfail.all' ] ],
	\			[ 'make sure vundle#rc() is available', ':call function("vundle#rc")', [ 'skiponfail.all' ] ],
	\			[ 'initialise vundle (call vundle#rc())', ':call vundle#rc( g:mytest_mytesttree_bundledir )', [ 'skiponfail.all' ] ],
	\			[ 'vundle initialised', 'EVLibTest_Util_VundleInitialised()', [ 'skiponfail.all' ] ],
	\			[ 'add "vundle" package (required by vundle)', ':Bundle "gmarik/vundle"', [ 'skiponfail.all' ] ],
	\			{ 'group': 'vim.evlib library initialisation' },
	\			[ 'add "vim.evlib" package (this one)', ':Bundle "ezequielv/vim.evlib"', [ 'skiponfail.all' ] ],
	\			[ 'finalise plugin setup (required by vundle)', ':filetype plugin indent on', [ 'skiponfail.all' ] ],
	\			[ 'force execution of "vim.evlib" plugin now', ':runtime plugin/evlib_fwd.vim', [ 'skiponfail.all' ] ],
	\	] )

"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )

call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
