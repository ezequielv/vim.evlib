" delegate to user code
" TODO: add flags in call to evlib#eval#GetVariableValueDefault()
"  (specify 's', to leave the variable set after checking for its value)
if evlib#eval#GetVariableValueDefault( 'g:evlib_cfg_init_userscripts_enable', 1 )
	call evlib#pvt#lib#SourceExternalFiles( 'init/pre/*.vim' )
endif
