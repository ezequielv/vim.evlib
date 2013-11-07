" test/vimrc_01_init_source-local.vim

" boilerplate -- prolog {{{
if has('eval')
" load 'common' vim code
execute 'source ' . fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/common.vim' )
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
"+ exec 'set runtimepath+=' . fnameescape( g:mytest_mytesttree_vundledir )
"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )

call EVLibTest_Start( 'load library using "vundle"' )
call EVLibTest_Do_Batch( [
	\			{ 'group': 'sanity checks' },
	\			[ 'library not intialised yet (safe check)', '! exists( "*evlib#IsInitialised" )', [ 'skiponfail.all' ] ],
	\			[ 'vundle not initialised yet', '! EVLibTest_Util_VundleInitialised()', [ 'skiponfail.all' ] ],
	\			[ '"vundle" package directory available', 'filereadable( g:mytest_mytesttree_vundledir . "/README.md" )', [ 'skiponfail.all' ] ],
	\			{ 'group': 'vundle initialisation' },
	\			{ 'test': 'set up runtimepath to include "vundle"', 'exec': 'set runtimepath+=' . fnameescape( g:mytest_mytesttree_vundledir ), 'options': [ 'skiponfail.all' ] },
	\			{ 'test': 'make sure vundle#rc() is available', 'exec': 'call function("vundle#rc")', 'options': [ 'skiponfail.all' ] },
	\			{ 'test': 'initialise vundle (call vundle#rc())', 'exec': 'call vundle#rc( g:mytest_mytesttree_bundledir )', 'options': [ 'skiponfail.all' ] },
	\			[ 'vundle initialised', 'EVLibTest_Util_VundleInitialised()', [ 'skiponfail.all' ] ],
	\			{ 'test': 'add "vundle" package (required by vundle)', 'exec': 'Bundle "gmarik/vundle"', 'options': [ 'skiponfail.all' ] },
	\			{ 'group': 'vim.evlib library initialisation' },
	\			{ 'test': 'add "vim.evlib" package (this one)', 'exec': 'Bundle "ezequielv/vim.evlib"', 'options': [ 'skiponfail.all' ] },
	\			{ 'test': 'finalise plugin setup (required by vundle)', 'exec': 'filetype plugin indent on', 'options': [ 'skiponfail.all' ] },
	\			{ 'test': 'force execution of "vim.evlib" plugin now', 'exec': 'runtime plugin/evlib_fwd.vim', 'options': [ 'skiponfail.all' ] },
	\	] )
"

"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )

call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
