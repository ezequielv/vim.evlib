" test/vimrc_64_init_libstate_04-ex-local-pass.vim

" boilerplate -- prolog {{{
if has('eval')
let g:evlib_test_common_main_source_file = expand( '<sfile>' )
" load 'common' vim code
let s:evlib_test_common_common_source_file = fnamemodify( g:evlib_test_common_main_source_file, ':p:h' ) . '/common.vim'
execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( s:evlib_test_common_common_source_file ) : s:evlib_test_common_common_source_file )
" }}}

call EVLibTest_Module_Load( 'libstage.vim' )
call EVLibTest_LibStages_FullSuite_UserScriptThrow( 'initialisation - library state checks (all user scripts throw)', 'all' )

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}

