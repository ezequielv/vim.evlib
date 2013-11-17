" delegate to user code
" TODO: use the variable directly (the invocation in ??-run_pre_init.vim
"  should leave the variable defined)
if evlib#eval#GetVariableValueDefault( 'g:evlib_cfg_init_userscripts_enable', 1 )
	call evlib#pvt#lib#SourceExternalFiles( 'init/post/*.vim' )
endif
