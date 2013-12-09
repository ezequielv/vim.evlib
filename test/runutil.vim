" test/runutil.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_test_runutil_loaded' ) || ( exists( 'g:evlib_test_runutil_disable' ) && g:evlib_test_runutil_disable != 0 )
	finish
endif
let g:evlib_test_runutil_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" include our 'base' script (variables, functions) {{{
execute 'source ' . fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/' . 'base.vim'
" save object just created/returned into our own script variable
let s:evlib_test_base_object = g:evlib_test_base_object_last
" }}}

function! s:Local_DefineFunctionFromFuncRef( fname, funcref )
	for l:func_now in [ a:fname, 's:' . a:fname ]
		try
			execute 'delfunction ' . l:func_now
		catch
		endtry
	endfor

	execute 'unlet! ' . a:fname . ' s:' . a:fname
	execute 'let s:' . a:fname . ' = a:funcref'
endfunction

" create mappings as if they were the real functions (see ':h Funcref') {{{
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_OptionalGetRedirFilename', s:evlib_test_base_object.f_testoutput_optionalgetredirfilename )
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_InitAndOpen', s:evlib_test_base_object.f_testoutput_initandopen )
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_Close', s:evlib_test_base_object.f_testoutput_close )
" }}}

" note: this used to be the "front-end" function
function! s:EVLibTest_RunUtil_TestOutput_Process()
	" FIXME: implement properly, or leave all of this to our caller (as we'll
	"  probably need many variables in the context of our caller to determine
	"  which script is to be "sourced" exactly)
	call s:evlib_test_base_object.f_module_load( 'evtest/proc/evtstd/v0-1-0.vim' )
endfunction

function! s:EVLibTest_RunUtil_Util_JoinCmdArgs( args_list )
	return join( map( filter( copy( a:args_list ), '! empty( v:val )' ), 'escape( v:val, " \\" )' ), ' ' )
endfunction

function! EVLibTest_RunUtil_Command_RunTests( ... )
	let l:process_flag = !0 " true
	let l:do_help_flag = 0 " false

	" process command (function) options (arguments) {{{
	if l:process_flag
		let l:test_files = []
		let l:programs_list = []
		let l:options_definitions = [
				\		[	[ '?', '-?' ], 0,
				\				[ 'display help' ]
				\		],
				\		[	[ '-p', '--program', '--programs' ], 1,
				\				[	'PROGRAMS',
				\					[
				\						'specify a list (comma-separated) of programs to run the tests',
				\					]
				\				]
				\		],
				\	]
		let l:options_def_cached = { }
		let l:help_message_options_list = []
		for l:options_def_elem_index_now in range( 0, len( l:options_definitions ) - 1 )
			let l:options_def_elem_now = l:options_definitions[ l:options_def_elem_index_now ]
			let l:options_def_elem_mainoption = ''
			let l:options_def_elem_flagvalue = l:options_def_elem_now[ 1 ]
			let l:options_def_elem_help_list = l:options_def_elem_now[ 2 ]
			let l:options_def_elem_help_use_flag = ( ! empty( l:options_def_elem_help_list ) )
			for l:options_def_elem_inner_now in l:options_def_elem_now[ 0 ]
				if empty( l:options_def_elem_mainoption )
					let l:options_def_elem_mainoption = l:options_def_elem_inner_now
				endif
				let l:options_def_cached[ l:options_def_elem_inner_now ] = {
						\		'mainoption': l:options_def_elem_mainoption,
						\		'arrayindex': l:options_def_elem_index_now,
						\		'hasvalue': l:options_def_elem_flagvalue,
						\		'helplist': l:options_def_elem_help_list
						\	}
				let l:options_def_elem_inner_help_option_now = l:options_def_elem_inner_now
				if l:options_def_elem_flagvalue
					let l:options_def_elem_inner_help_option_now .= ' ' . l:options_def_elem_help_list[ 0 ]
				endif
				if l:options_def_elem_help_use_flag
					let l:help_message_options_list += [ l:options_def_elem_inner_help_option_now ]
				endif
			endfor
			if l:options_def_elem_help_use_flag
				unlet! l:options_def_elem_help_list_lines
				let l:options_def_elem_help_list_lines = l:options_def_elem_help_list[ -1 ]
				" TODO: see if we actually need the copy() call, as the list
				"  addition might result in a separate list object -> no need
				"  to copy that
				let l:help_message_options_list += 
						\	map(
						\			copy( ( ( type( l:options_def_elem_help_list_lines ) == type( '' ) ) ? [ l:options_def_elem_help_list_lines ] : l:options_def_elem_help_list_lines ) + [ '' ] ),
						\			'"   " . v:val'
						\		)
			endif
		endfor
	endif
	if l:process_flag && ( a:0 == 0 )
		let l:do_help_flag = !0 " true
		let l:process_flag = 0 " false
	endif
	if l:process_flag
		let l:arg_is_option_flag = 0 " false
		let l:option_hasvalue_next = 0 " false
		for l:arg_now in a:000
			" standard option processing {{{
			if ( l:option_hasvalue_next )
				let l:arg_is_option_flag = !0 " true
				let l:option_hasvalue_next = 0 " false
			elseif ( has_key( l:options_def_cached, l:arg_now ) )
				let l:arg_is_option_flag = !0 " true
				let l:options_def_cached_now = l:options_def_cached[ l:arg_now ]
				let l:option_main_now = l:options_def_cached_now[ 'mainoption' ]
				let l:option_hasvalue_next = ( l:options_def_cached_now[ 'hasvalue' ] )
				if l:option_hasvalue_next
					" process next option (hopefully the value)
					continue
				endif
			else
				let l:arg_is_option_flag = 0 " false
				let l:option_hasvalue_next = 0 " false
			endif
			" }}}

			if l:arg_is_option_flag
				if	( l:option_main_now == '?' )
					let l:do_help_flag = !0 " true
					let l:process_flag = 0 " false
					break
				elseif	( l:option_main_now == '-p' )
					let l:programs_list += split( l:arg_now, ',', 0 )
				endif
			else
				" treat it as a file (we could do further validation here)
				let l:test_files += sort( split( glob( l:arg_now ), '\n', 0 ) )
			endif
		endfor
	endif
	" default values {{{
	if l:process_flag
		if ( empty( l:programs_list ) )
			let l:programs_list = [ v:progname ]
		endif
	endif
	if l:do_help_flag
		for l:help_line_now in [
				\		'EVTestRunFiles [options] TESTFILES...',
				\		'',
				\		'runs unit tests in TESTFILES, and produces a report with the results',
				\		'',
				\		'options:',
				\		'',
				\	]
				\	+ l:help_message_options_list
				\	+ [
				\	]
			" note: this is needed in ':echo', apparently, so that empty
			"  expressions are not skipped (we want the empty lines)
			echo ( ( ! empty( l:help_line_now ) ) ? l:help_line_now : ' ' )
		endfor
		" no_need_now: return 0
	endif
	" }}}
	" }}}

	" pre-test run initialisations {{{
	" FIXME: load variables for: editor executable, parameters, etc.
	" }}}
	" FIXME: create an outer loop to iterate through elements of this type:
	"  { 'test_files': LIST_TEST_FILES, 'proc': PROCESSOR_SCRIPT }
	"   (NOTE: we could add more elements)
	" FIXME: but be careful with externally-specified "redir file"
	"  (l:test_output_file): maybe just use it for the first of these groups
	"  (which would work nicely when there is a single group)
	" run tests, process output {{{
	if l:process_flag
		let l:test_output_file = ''
		let l:test_output_file_temp_flag = 0 " false
		let l:test_output_redirecting_flag = 0 " false
		try
			let l:test_output_init_flag = 0 " false
			let l:test_output_redir_active_flag = 0 " false
			" run all tests for each (vim) program {{{
			for l:program_now in l:programs_list
				" one-time initialisations {{{
				if ( ! l:test_output_init_flag )
					let l:test_output_file = s:EVLibTest_TestOutput_OptionalGetRedirFilename()
					if ( empty( l:test_output_file ) )
						" create a temporary file
						let l:test_output_file = tempname()
						let l:test_output_file_temp_flag = !0 " true
					endif
					let g:evlib_test_runtest_id = ( exists( 'g:evlib_test_runtest_id' ) ? ( g:evlib_test_runtest_id ) : 0 ) + 1
					if ( ! s:EVLibTest_TestOutput_InitAndOpen( 0 ) )
						" FIXME: report the error in a way that would be
						"  picked up by our caller (exception?)
						break " FIXME: see comment above
					endif
					let l:test_output_init_flag = !0 " true
				endif
				" }}}

				" per-program initialisation {{{
				" FIXME: start the program directly, not through 'env'
				"  FIXME: add support for specifying a variable *before* our vimrc gets
				"   loaded
				"  FIXME: maybe load it through something else (not '-u'): '-c "let VAR | source TESTFILE"'
				let l:progoptions_pref_list = [
						\		'env',
						\		'EVLIB_VIM_TEST_OUTPUTFILE=' . l:test_output_file,
						\		l:program_now, '-f',
						\		'-e',
						\		'--noplugin',
						\		'-U', 'NONE',
						\		'-u',
						\	]
				" NOTE: option for specifying script to run: '-u "${l_getresults_file_now}"'
				" NOTE: executing vim/gvim uses stdout/stderr, and it can
				"  be quite slow (especially under the GUI)
				"  FIXME: do this per-platform, etc.
				"  FIXME: these redirections made vim pop up a message box
				"   (even more disruptive)
				"-?		\		'>' , '/dev/null',
				"-?		\		'2>' , '/dev/null',
				let l:progoptions_suff_list = [
						\		'+q',
						\	]
				let l:progoptions_pref_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_pref_list )
				let l:progoptions_suff_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_suff_list )
				" }}}

				" FIXME: write information about the (vim) program currently being used

				" run all tests {{{
				for l:test_file_now in l:test_files
					" validate current file {{{
					if ( ! filereadable( l:test_file_now ) )
						" FIXME: report the error in l:test_output_file in a way that
						"  will be picked up by s:EVLibTest_RunUtil_TestOutput_Process()

						" do not process this file
						continue
					endif
					" }}}
					" run vim with the right parameters {{{
					try
						" FIXME: write information about the test to be run here

						" FIXME: stop redirection here

						" FIXME: execute the commands silently (':h :silent'),
						"  and display "friendly" messages instead
						execute '! '
								\	.	l:progoptions_pref_string
								\	.	' '
								\	.	s:EVLibTest_RunUtil_Util_JoinCmdArgs( [ l:test_file_now ] )
								\	.	' '
								\	.	l:progoptions_suff_string
						execute '! ls -l ' . l:test_output_file
					catch " all exceptions
						" FIXME: record an error string if the test failed (do it in a way
						"  that will be shown to the user appropriately
					finally
						" FIXME: re-enable redirection here
					endtry
					" }}}
				endfor
				" }}}
			endfor
			" }}}
			" process the temporary file {{{
			if filereadable( l:test_output_file )
				" split/create tab, set new buffer attributes
				execute 'tab sview ' . l:test_output_file
				setlocal buftype=nofile noswapfile
				" done: make this better (or use a timestamp, etc.)
				" IDEA: put all the filenames that the test had at the beginning,
				"  for example (with one of those 'INFO:' lines?)
				"  FIXME: and make that a folding group ("test info", etc.)
				execute 'file ' . '{test-output-' . printf( '%04d', g:evlib_test_runtest_id ) . '}'
				call s:EVLibTest_RunUtil_TestOutput_Process()
			else
				" FIXME: report that no test output was produced?
			endif
			" }}}
		" IDEA: to avoid doing the 'catch': just set a flag at the end of the
		"  'good' code block, and detect that in the 'finally' block, below
		" LATER catch " all exceptions
			" FIXME: optionally enable redirection (maybe looking at
			"  l:test_output_redirecting_flag); display error message;
			" FIXME: re-throw the exception
		finally
			if l:test_output_redirecting_flag
				call s:EVLibTest_TestOutput_Close()
				let l:test_output_redirecting_flag = 0 " false
			endif
			if l:test_output_file_temp_flag && ( ! empty( l:test_output_file ) )
				call delete ( l:test_output_file ) " ignore rc for now
			endif
		endtry
	endif
	" }}}
	" [debug]: echo '[debug] ' . string( l:options_def_cached )
endfunction

" define custom command(s)
command! -bar -nargs=* -complete=file EVTestRunFiles
			\	call EVLibTest_RunUtil_Command_RunTests(<f-args>)

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'test/runutil.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
