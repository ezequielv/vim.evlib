" test/vimrc_01_init_source-local.vim

" boilerplate -- prolog {{{
if has('eval')
" load 'common' vim code
execute 'source ' . fnameescape( fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/common.vim' )
" }}}

call EVLibTest_Start( 'load library using "source {path}/evlib_loader.vim"' )
call EVLibTest_GroupSet_LoadLibrary_Method_Source()
call EVLibTest_GroupSet_TestLibrary()
call EVLibTest_Finalise()

" boilerplate -- epilog {{{
finish
endif

echoerr 'test need the "eval" feature'
" }}}
