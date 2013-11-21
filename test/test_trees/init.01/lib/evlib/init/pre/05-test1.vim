" [debug]: call EVLibTest_Gen_InfoMsg( 'hello from 05-test1.vim - before throwing' ) " [debug]
call EVLibTest_LibStages_UserScriptConditionallyThrow( 'pre' )
" [debug]: call EVLibTest_Gen_InfoMsg( 'hello from 05-test1.vim - after throwing' ) " [debug]
call EVLibTest_LibStages_CheckUpdateCounter( 4, 5, 211 )

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
