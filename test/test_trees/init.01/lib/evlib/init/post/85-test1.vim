" [debug]: call EVLibTest_Gen_InfoMsg( 'hello from 85-test1.vim - before throwing' ) " [debug]
call EVLibTest_LibStages_UserScriptConditionallyThrow( 'post' )
" [debug]: call EVLibTest_Gen_InfoMsg( 'hello from 85-test1.vim - after throwing' ) " [debug]

" values to check against and set (true, false) are dependant on whether the
"  'pre' script has thrown an exception (before checking/updating the counter)
if EVLibTest_LibStages_UserScriptWouldThrow( 'pre' )
	call EVLibTest_LibStages_CheckUpdateCounter( 4, 16, 221 )
else
	call EVLibTest_LibStages_CheckUpdateCounter( 5, 6, 222 )
endif

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
