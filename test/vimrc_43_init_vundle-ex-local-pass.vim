" test/vimrc_43_init_vundle-ex-local-pass.vim

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
if !( ( v:version >= 700 ) )
	call EVLibTest_Gen_InfoMsg( 'test file: ' . string( fnamemodify( g:evlib_test_common_main_source_file, ':p:t' ) ) . ' requires "vundle", but it is not supported by the vim instance being run' )
	call EVLibTest_TestOutput_OutputLine( '' )
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
	\			{ 'group': 'sanity checks', 'options': [ 'skiponfail.all' ] },
	\			[ 'library not intialised yet (safe check)', '! exists( "*evlib#IsInitialised" )' ],
	\			[ 'attempting to load of "vim.evlib" plugin, if accessible', ':runtime! plugin/evlib_fwd.vim' ],
	\			[ 'library still not intialised (safe check)', '! exists( "*evlib#IsInitialised" )' ],
	\			[ 'vundle not initialised yet', '! EVLibTest_Util_VundleInitialised()' ],
	\			[ '"vundle" package directory available', 'filereadable( g:mytest_mytesttree_vundledir . "/README.md" )' ],
	\			{ 'group': 'vundle initialisation', 'options': [ 'skiponfail.all' ] },
	\			[ 'set up runtimepath to include "vundle"', ':set runtimepath+=' . ( exists( '*fnameescape' ) ? fnameescape( g:mytest_mytesttree_vundledir ) : g:mytest_mytesttree_vundledir ) ],
	\			[ 'make sure vundle#*() functions are available', '!empty( globpath( &runtimepath, "autoload/vundle.vim" ) )' ],
	\			[ 'initialise vundle (call vundle#rc())', ':call vundle#rc( g:mytest_mytesttree_bundledir )' ],
	\			[ 'vundle initialised', 'EVLibTest_Util_VundleInitialised()' ],
	\			[ 'add "vundle" package (required by vundle)', ':Bundle "gmarik/vundle"' ],
	\			{ 'group': 'vim.evlib library initialisation', 'options': [ 'skiponfail.all' ] },
	\			[ 'add "vim.evlib" package (this one)', ':Bundle "ezequielv/vim.evlib"' ],
	\			[ 'finalise plugin setup (required by vundle)', ':filetype plugin indent on' ],
	\			[ 'force execution of "vim.evlib" plugin now', ':runtime! plugin/evlib_fwd.vim' ],
	\	] )

"+ call EVLibTest_Gen_InfoVarValue( '&runtimepath' )

call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
