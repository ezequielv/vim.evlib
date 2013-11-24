" test/common.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_test_common_loaded' )
	finish
endif
let g:evlib_test_common_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" variables and functions {{{
" general variables {{{
let g:evlib_test_common_testdir = fnamemodify( expand( '<sfile>' ), ':p:h' )
let g:evlib_test_common_rootdir = fnamemodify( g:evlib_test_common_testdir, ':h' )
let g:evlib_test_common_test_testtrees_rootdir = g:evlib_test_common_testdir . '/test_trees'

let s:evlib_test_common_ignore_skipped_tests_completely = 0 " make non-zero to avoid reporting those as 'skipped'

let g:evlib_test_common_ntests = 0
let g:evlib_test_common_npass = 0
let s:evlib_test_common_global_skippingtests_flag = 0
" }}}

" test framework modules {{{
function EVLibTest_Module_Load( module )
	let l:filepath = g:evlib_test_common_testdir . '/' . a:module
	execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( l:filepath ) : l:filepath )
	return !0 " true
endfunction
" }}}

" global test support {{{
function EVLibTest_Start( suite_name )
	if s:evlib_test_common_in_group_flag || ( g:evlib_test_common_ntests > 0 )
		call EVLibTest_Finalise()
	endif
	" note: we could move this outside of this function, and store the result
	"  in a 's:'-scoped variable
	" {{{
	let l:source_name = ''
	if exists( 'g:evlib_test_common_main_source_file' ) && ( type( g:evlib_test_common_main_source_file ) == type( '' ) )
		let l:source_name = fnamemodify( g:evlib_test_common_main_source_file, ':p' )
		for l:replace_elem_now in [
					\		[ g:evlib_test_common_testdir, '{test}' ],
					\		[ g:evlib_test_common_rootdir, '{root}' ],
					\	]
			let l:source_name = fnamemodify( l:source_name, ':s?' . l:replace_elem_now[ 0 ] . '?' . l:replace_elem_now[ 1 ] . '?' )
		endfor
	endif
	" }}}
	call EVLibTest_Gen_OutputLine( 'SUITE: ' . a:suite_name . ( empty( l:source_name ) ? '' : ' [' . l:source_name . ']' ) )
	call EVLibTest_Gen_OutputLine( '' )
endfunction

function EVLibTest_Finalise( ... )
	" note: do not check results if the user did not provide a dictionary
	let l:src_results_user = ( ( a:0 > 0 ) ? ( a:1 ) : {} )

	if s:evlib_test_common_in_test_flag
		call EVLibTest_Test_EndUncertain()
	endif
	if s:evlib_test_common_in_group_flag
		call EVLibTest_Group_End()
	endif
	call EVLibTest_Gen_OutputTestStats( 'Total', g:evlib_test_common_ntests, g:evlib_test_common_npass, l:src_results_user )
	call EVLibTest_Gen_OutputLine( '' )
	let g:evlib_test_common_ntests = 0
	let g:evlib_test_common_npass = 0
	let s:evlib_test_common_global_skippingtests_flag = 0
endfunction

" support for writing the results to a file {{{
let s:evlib_test_common_global_outputtofile_flag = 0
function s:EVLibTest_Init_TestOutput()
	for l:var_now in [ '$EVLIB_VIM_TEST_OUTPUTFILE' ]
		if exists( l:var_now )
			let l:file_escaped = expand( l:var_now )
			if exists( '*fnameescape' )
				let l:file_escaped = fnameescape( l:file_escaped )
			endif
			" NOTE: alternative, use option 'verbosefile' instead
			"  (see ":h 'verbosefile'")
			execute 'redir >> ' . l:file_escaped
			let s:evlib_test_common_global_outputtofile_flag = 1
			" all done, stop trying
			break
		endif
	endfor
	" TODO: add an event handler before vim exits, to close the redirection
endfunction
call s:EVLibTest_Init_TestOutput()
" }}}

let s:evlib_test_common_output_lineprefix_string = 'TEST: '
function EVLibTest_Gen_OutputLine( msg )
	" fix: when redirecting to a file, make sure that we start each message on
	"  a new line (error messages sometimes have a '<CR>' at the end, which
	"  means that the next line will start at column > 1
	if s:evlib_test_common_global_outputtofile_flag
		echomsg ' '
	endif
	echomsg s:evlib_test_common_output_lineprefix_string . a:msg
endfunction

function EVLibTest_Gen_InfoMsg( msg )
	return EVLibTest_Gen_OutputLine( 'info: ' . a:msg )
endfunction

function EVLibTest_Gen_InfoVarValue( varname, ... )
	let l:msgpref = ( ( a:0 > 0 ) ? ( a:1 . ': ' ) : '' )
	return EVLibTest_Gen_InfoMsg( l:msgpref . 'variable ' . a:varname . ': ' . string( eval( a:varname ) ) )
endfunction

function EVLibTest_Gen_GetTestStats()
	let l:ntests_adjustment = ( s:evlib_test_common_in_test_flag ? -1 : 0 )
	let l:result_dict = {
			\		'global': {
			\				'ntests': ( g:evlib_test_common_ntests + l:ntests_adjustment ),
			\				'npass': g:evlib_test_common_npass,
			\			},
			\		'group': {
			\				'active': s:evlib_test_common_in_group_flag,
			\				'ntests': ( s:evlib_test_common_in_group_flag ? ( g:evlib_test_common_group_ntests + l:ntests_adjustment ) : 0 ),
			\				'npass':  ( s:evlib_test_common_in_group_flag ? g:evlib_test_common_group_npass : 0 ),
			\			},
			\		'general': {
			\				'skipping': s:evlib_test_common_global_skippingtests_flag,
			\			},
			\	}
	return l:result_dict
endfunction

function s:EVLibTest_Gen_CheckTestStats_DoDict( src_results_user, src_results_actual )
	let l:success = !0 " true

	" make sure we have been given dictionaries as inputs
	let l:success = l:success && ( type( a:src_results_user ) == type( a:src_results_actual ) ) && ( type( a:src_results_user ) == type( {} ) )
	" (internal) sanity checking
	if ( ! l:success ) | call EVLibTest_Util_ThrowTestExceptionInternalError() | endif

	if l:success
		for l:results_user_dict_key_now in sort( keys( a:src_results_user ) )
			let l:success = l:success && has_key( a:src_results_actual, l:results_user_dict_key_now )
			if l:success
				let l:results_user_dict_entry_now   = a:src_results_user[   l:results_user_dict_key_now ]
				let l:results_actual_dict_entry_now = a:src_results_actual[ l:results_user_dict_key_now ]
				let l:success = l:success && ( type( l:results_user_dict_entry_now ) == type( l:results_actual_dict_entry_now ) )
				if ( type( l:results_user_dict_entry_now ) == type( {} ) )
					" call recursively to compare sub-dictionary
					let l:success = l:success && s:EVLibTest_Gen_CheckTestStats_DoDict( l:results_user_dict_entry_now, l:results_actual_dict_entry_now )
				else
					" compare as scalar values
					let l:success = l:success && ( l:results_user_dict_entry_now == l:results_actual_dict_entry_now )
					" TODO: report failure nicely (create new error reporing function)
				endif
			endif
			" abort the loop on error
			if ( ! l:success )
				break
			endif
		endfor
	endif

	return l:success
endfunction

" returns 'success'
"
" args: src_results_user [, src_results_actual ]
"
"  * src_results_actual: if unspecified, get values from
"     EVLibTest_Gen_GetTestStats();
"
function EVLibTest_Gen_CheckTestStats( src_results_user, ... )
	let l:success = !0 " true
	let l:src_results_actual = ( ( a:0 > 0 ) ? a:1 : EVLibTest_Gen_GetTestStats() )

	let l:success = l:success && s:EVLibTest_Gen_CheckTestStats_DoDict( a:src_results_user, l:src_results_actual )

	return l:success
endfunction

" args:
"  * if empty( src_results_user ), we do not check results;
"  * if !empty( src_results_user ), we will check results via
"    EVLibTest_Gen_CheckTestStats()
function EVLibTest_Gen_OutputTestStats( msg, ntests, npass, src_results_user )
	let l:flag_hasuserresults = ( ! empty( a:src_results_user ) )

	if l:flag_hasuserresults
		let l:results_success = EVLibTest_Gen_CheckTestStats( a:src_results_user )
	else
		let l:results_success = ( a:ntests == a:npass )
		" vim 7.0 does not have str2float() (or float support, for that matter)
		let l:pass_rate_strnum = ( a:npass * 10000 ) / ( a:ntests ? a:ntests : 1 )
		" pad with zeroes if the result is too small
		if ( strlen( l:pass_rate_strnum ) < 3 )
			let l:pass_rate_strnum = repeat( '0', 3 - strlen( l:pass_rate_strnum ) ) . l:pass_rate_strnum
		endif
		let l:pass_rate_msg = 'rate: ' . l:pass_rate_strnum[ -5:-3 ] . '.' . l:pass_rate_strnum[ -2: ] . '%'
	endif

	call EVLibTest_Gen_OutputLine(
			\		'RESULTS (' . a:msg . '): ' .
			\		'tests: ' . string( a:ntests ) .
			\		', pass: ' . string( a:npass ) .
			\		' --' .
			\		( 	l:flag_hasuserresults
			\			?	' [custom]'
			\			:	' ' . l:pass_rate_msg
			\		) .
			\		' [' . ( l:results_success ? 'pass' : 'FAIL' ) . ']' .
			\		''
			\	)
endfunction
" }}}

" utility functions {{{
function EVLibTest_Util_ThrowTestException_Custom( exception_suffix )
	throw 'EVLibTestException_' . a:exception_suffix
endfunction
function EVLibTest_Util_ThrowTestExceptionInternalError()
	return EVLibTest_Util_ThrowTestException_Custom( 'InternalError' )
endfunction
" }}}

" test group support {{{
let s:evlib_test_common_in_group_flag = 0
let g:evlib_test_common_group_ntests = 0
let g:evlib_test_common_group_npass = 0

function EVLibTest_Group_Begin( group_name )
	if s:evlib_test_common_in_group_flag
		call EVLibTest_Group_End()
	endif
	if s:evlib_test_common_ignore_skipped_tests_completely && s:evlib_test_common_global_skippingtests_flag
		return
	endif

	call EVLibTest_Gen_OutputLine( '[' . a:group_name . ']' )
	let s:evlib_test_common_in_group_flag = 1
endfunction

function EVLibTest_Group_End( ... )
	" note: do not check results if the user did not provide a dictionary
	let l:src_results_user = ( ( a:0 > 0 ) ? ( a:1 ) : {} )

	if s:evlib_test_common_in_group_flag
		" report group results
		call EVLibTest_Gen_OutputTestStats( 'group total', g:evlib_test_common_group_ntests, g:evlib_test_common_group_npass, l:src_results_user )
		call EVLibTest_Gen_OutputLine( '' )
	endif
	let s:evlib_test_common_in_group_flag = 0

	let g:evlib_test_common_group_ntests = 0
	let g:evlib_test_common_group_npass = 0
	" FIXME: [debug] remove: call EVLibTest_Gen_InfoVarValue( 's:evlib_test_common_global_skippingtests_all_flag', 'EVLibTest_Group_End()' ) " [debug] " FIXME: remove this line
	" only reset this flag conditionally
	if s:evlib_test_common_global_skippingtests_flag && ( ! s:evlib_test_common_global_skippingtests_all_flag )
		let s:evlib_test_common_global_skippingtests_flag = 0
	endif
endfunction
" }}}

" individual test support {{{
let s:evlib_test_common_in_test_flag = 0
" sets a few variables
" (we probably can't send output through 'echomsg', as that would mean that
" we'd have separate lines for the message and result)
function EVLibTest_Test_Begin( test_msg )
	if s:evlib_test_common_ignore_skipped_tests_completely && s:evlib_test_common_global_skippingtests_flag
		return
	endif
	if s:evlib_test_common_in_test_flag
		call EVLibTest_Test_EndUncertain()
	endif
	let g:evlib_test_common_ntests += 1
	if s:evlib_test_common_in_group_flag
		let g:evlib_test_common_group_ntests += 1
	endif
	let s:evlib_test_common_last_test_msg = a:test_msg
	let s:evlib_test_common_in_test_flag = 1
endfunction

" does variable cleanup, etc.
function EVLibTest_Test_EndCommon( msg_result )
	if s:evlib_test_common_in_test_flag
		" prev: call EVLibTest_Gen_OutputLine( ( s:evlib_test_common_in_group_flag ? '   ' : '' ) . s:evlib_test_common_last_test_msg . ': [' . a:msg_result . ']' )
		let l:message_start = ( s:evlib_test_common_in_group_flag ? '   ' : '' ) . s:evlib_test_common_last_test_msg . ' '
		let l:message_end_result = '[' . a:msg_result . ']'

		let l:filler_string_one = '. '
		let l:filler_string_one_len = strlen( l:filler_string_one )
		" make the result message suffix a fixed length (multiple of
		"  l:filler_string_one_len)
		let l:message_end_padding_len = ( strlen( l:message_end_result ) % l:filler_string_one_len )
		if ( l:message_end_padding_len != 0 )
			let l:message_end_result = repeat( ' ', l:message_end_padding_len ) . l:message_end_result
		endif

		let l:message_unpadded_len = strlen( s:evlib_test_common_output_lineprefix_string ) + strlen( l:message_start ) + strlen( l:message_end_result )
		" leave a small gap at the end -- just in case
		let l:columns = ( s:evlib_test_common_global_outputtofile_flag ? 76 : min( [ &columns, 100 ] ) ) - 1
		if ( l:message_unpadded_len < l:columns )
			let l:filler_len = ( l:columns - l:message_unpadded_len )
			let l:filler_string = repeat( ' ', ( l:filler_len % l:filler_string_one_len ) ) . repeat( l:filler_string_one, ( l:filler_len / l:filler_string_one_len ) )
		else
			let l:filler_string = ''
		endif
		call EVLibTest_Gen_OutputLine( l:message_start . l:filler_string . l:message_end_result )
	endif
	let s:evlib_test_common_in_test_flag = 0
endfunction

function EVLibTest_Test_EndUncertain()
	call EVLibTest_Test_EndCommon( 'ABORTED' )
endfunction

function EVLibTest_Test_Result( rc, ... )
	let l:debug_message_prefix = 'EVLibTest_Test_Result(): '

	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )
	let l:flag_skiprest_all = ( stridx( l:flags, 'S' ) >= 0 )
	let l:flag_skiprest = ( l:flag_skiprest_all || ( stridx( l:flags, 's' ) >= 0 ) )

	let l:result_test_executed = !0 " true, by default

	if type( a:rc ) == type( 0 )
		let l:result_is_pass = ( a:rc != 0 )
		let l:result_as_string = ( l:result_is_pass ? 'pass' : 'FAIL' )
	elseif type( a:rc ) == type( '' )
		let l:result_is_pass = 0
		let l:result_test_executed = ( a:rc != 'skipped' )
		let l:rc_string_to_result_mapping =
				\	{
				\		'exception': 'EXCEPTION',
				\		'didnotthrow': 'DIDNOTTHROW',
				\		'skipped': 'skipped',
				\	}
		if has_key( l:rc_string_to_result_mapping, a:rc )
			let l:result_as_string = l:rc_string_to_result_mapping[ a:rc ]
		else
			let l:result_as_string = 'INTERNAL_ERROR'
			echoerr l:debug_message_prefix . 'unrecognised value for rc (type: string). value: "' . a:rc . '"'
		endif
	endif
	call EVLibTest_Test_EndCommon( l:result_as_string )
	if l:result_test_executed
		if l:result_is_pass
			let g:evlib_test_common_npass += 1
			if s:evlib_test_common_in_group_flag
				let g:evlib_test_common_group_npass += 1
			endif
		elseif l:flag_skiprest
			" flag this situation
			let s:evlib_test_common_global_skippingtests_flag = 1
			let s:evlib_test_common_global_skippingtests_all_flag = l:flag_skiprest_all
			" FIXME: [debug] remove: call EVLibTest_Gen_InfoVarValue( 's:evlib_test_common_global_skippingtests_all_flag', 'EVLibTest_Test_Result()' ) " [debug] " FIXME: remove this line
		endif
	endif
	return a:rc
endfunction
" }}}

" function EVLibTest_Do_Check( test_msg, expr [, flags ] )
"
" evaluates {expr}, and reports result:
"  ==0 (false): [fail]
"  !=0 (true): [pass]
" expr:
"  * string: expression to be evaluated/executed;
"     default is to evaluate the string through 'eval()';
"  * function object: gets 'call'-ed -- should return a value convertible to a
"     number (and be evaluated implicitly (false, true));
"
" flags:
"  'e': use 'execute', rather than 'eval()'uate (which is the default);
"        (invalid for Funcref objects)
"  's': skip rest of tests until the end of the group
"        (or the end of all tests, if a group is not active);
"        (default is to carry on);
"  'S': skip tests until the end of the suite;
"        (default is to carry on);
"  't': "expected to throw": the expression/code should throw an exception.
"        test will only pass if such a thing happens;
"  'q': "quiet" mode: force the expression to be quietly executed;
"  'v': "verbose" mode: force the expression to be executed in 'non-silent'
"        mode;
"
function EVLibTest_Do_Check( test_msg, expr, ... )
	let l:debug_message_prefix = 'EVLibTest_Do_Check(): '

	" NOTE: this default could come from a global "config" variable
	let l:flag_silent = !0 " for now, we start in 'quiet' mode

	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )
	let l:flag_execute = ( stridx( l:flags, 'e' ) >= 0 )
	if ( stridx( l:flags, 'v' ) >= 0 )
		let l:flag_silent = 0
	elseif ( stridx( l:flags, 'q' ) >= 0 )
		let l:flag_silent = !0
	endif
	" LATER: remove these local variables, as we have no use for them
	"  IDEA: and use a string/list of flag values to propagate to
	"   l:test_result_flags
	let l:flag_skiprest_all = ( stridx( l:flags, 'S' ) >= 0 )
	let l:flag_skiprest = ( l:flag_skiprest_all || ( stridx( l:flags, 's' ) >= 0 ) )
	let l:flag_shouldthrow = ( stridx( l:flags, 't' ) >= 0 )

	let l:test_result_flags = ''
	for l:test_result_flags_mapping_elem_now in
			\	[
			\		[ l:flag_skiprest, 's' ],
			\		[ l:flag_skiprest_all, 'S' ],
			\	]
		if ( l:test_result_flags_mapping_elem_now[ 0 ] )
			let l:test_result_flags = l:test_result_flags . l:test_result_flags_mapping_elem_now[ 1 ]
		endif
	endfor

	call EVLibTest_Test_Begin( a:test_msg )
	if s:evlib_test_common_global_skippingtests_flag
		let l:rc = 'skipped'
	else
		" FIXME: [debug] remove: let l:flag_silent = 0 " [debug] force non-silent mode " FIXME: remove this line
		let l:cmd_pref_silent = ( l:flag_silent ? 'silent ' : '' )

		if type( a:expr ) == type( function( 'EVLibTest_Group_Begin' ) )
			echoerr l:debug_message_prefix . 'Funcref objects still not supported. fix the code (common.vim) and try again'
		elseif type( a:expr ) == type( '' )
			unlet! l:rc
			unlet! l:rc_real
			let l:result_throws = 0
			try
				" FIXME: [debug] remove: call EVLibTest_Gen_InfoMsg( '[debug] flags: "' . l:flags . '"; about to execute/eval: ' . l:cmd_pref_silent . a:expr ) " FIXME: remove this line
				if l:flag_execute
					execute l:cmd_pref_silent . 'execute a:expr'
					" successful execution is mapped to a rc != 0
					let l:rc_real = 1
				else
					execute l:cmd_pref_silent . 'let l:rc_real = eval( a:expr )'
					" for now, we map every non-numeric value to 'false'
					if type( l:rc_real ) != type( 0 )
						unlet l:rc_real
						let l:rc_real = 0
					endif
				endif
			catch
				let l:rc_real = 'exception'
				let l:result_throws = 1
			endtry
			" map test result to what we actually want
			if l:flag_shouldthrow
				if l:result_throws
					let l:rc = 1
				else
					let l:rc = 'didnotthrow'
				endif
			else
				let l:rc = l:rc_real
			endif
		else
			echoerr l:debug_message_prefix . 'invalid type for expr. type: ' . string( type( a:expr ) )
		endif
	endif
	call EVLibTest_Test_Result( l:rc, l:test_result_flags )
endfunction

" returns test flags after being manipulated according to specified subset of
"  supported options (src_supported_options) and the user-specified options
"  (src_options_list);
"
function EVLibTest_Internal_TestFlagsUpdate( src_flags, src_supported_options_list, src_options_list )
	let l:debug_message_prefix = 'EVLibTest_Internal_TestFlagsUpdate(): '

	let l:success = !0 " true
	let l:result_flags = a:src_flags

	" first-run initialisation only
	if ! exists( 's:evlib_test_common_testflagsupdate_options_mapping' )
		let l:options_remove_skiponfail = 'Ss'
		let l:options_remove_verbose = 'qv'

		let s:evlib_test_common_testflagsupdate_options_mapping =
				\	{
				\		'skiponfail.local': [ l:options_remove_skiponfail, 's' ],
				\		'skiponfail.all':   [ l:options_remove_skiponfail, 'S' ],
				\		'skiponfail.cont':  [ l:options_remove_skiponfail, '' ],
				\		'silent':           [ l:options_remove_verbose, 'q' ],
				\		'verbose':          [ l:options_remove_verbose, 'v' ],
				\		'code.throws':      [ '', 't' ],
				\	}
	endif

	if l:success
		for l:option_elem_now in a:src_options_list
			if ( ! empty( a:src_supported_options_list ) )
				" make sure the user-specified option is supported
				let l:success = l:success && ( index( a:src_supported_options_list, l:option_elem_now ) >= 0 )
			endif
			" make sure the option is in our map (dictionary)
			let l:success = l:success && has_key( s:evlib_test_common_testflagsupdate_options_mapping, l:option_elem_now )
			if l:success
				let l:dict_elem_now = s:evlib_test_common_testflagsupdate_options_mapping[ l:option_elem_now ]

				" conditionally remove options
				if ( ! empty( l:dict_elem_now[ 0 ] ) )
					let l:result_flags = substitute( l:result_flags, '[' . l:dict_elem_now[ 0 ] . ']', '', 'g' )
				endif
				" conditionally add option(s)
				if ( ! empty( l:dict_elem_now[ 1 ] ) )
					let l:result_flags .= l:dict_elem_now[ 1 ]
				endif
			endif

			if ! l:success
				break
			endif
		endfor
	endif

	" (internal) sanity checking
	if ( ! l:success ) | call EVLibTest_Util_ThrowTestExceptionInternalError() | endif

	return l:result_flags
endfunction

" }}}

" high-level test support {{{
" test_list: elements:
"  { dictionary }
"  [ test_msg, expr [, options ] ]
"  * dictionary:
"   * group start: { 'group': GROUP_NAME [, 'options': OPTIONS ] }
"   * test entry: { 'test': TEST_MSG, 'expr': TEST_EXPRESSION [, 'options': OPTIONS ] }
"    * use 'eval()';
"   * test entry: { 'test': TEST_MSG, 'exec': EX_COMMAND_STRING [, 'options': OPTIONS ] }
"    * use 'execute';
"  * list: [ test_description, expr_or_command, OPTIONS ]
"     (the 'options' element is optional)
"     expr_or_command:
"      * if it starts with ':', it's considered a command ('execute');
"      * otherwise, it's treated as an expression ('eval()');
"  * OPTIONS: a list of strings specifying "options":
"     * 'skiponfail.local': if this test fails, skip the test until the end of
"         the group (or the end of all tests, if there is no active group);
"     * 'skiponfail.all': if this test fails, skip the test until the end of
"         all tests (even if there is an active group at the time of failure);
"     * 'skiponfail.cont': if this test fails, continue with the next test
"         (this is the default);
"     * 'code.throws': (see EVLibTest_Do_Check() flag 't')
"        code is expected to throw an exception (test will only pass
"        if the code/expression throws);
"        * note: this option is not valid for group entries;
"     * 'silent': execute the command/expression silently;
"     * 'verbose': execute the command/expression verbosely (non-silently);
"
" for each element in ths list, EVLibTest_Do_Check() is called, so:
"  * expr: same format and constraints as that function;
function EVLibTest_Do_Batch( test_list )
	let l:debug_message_prefix = 'EVLibTest_Do_Batch(): '

	" NOTE: this default could come from a global "config" variable
	let l:option_flags_default = 'q' " start in 'quiet' mode
	let l:option_flags_group = '' " unknown -> do not assume anything

	let l:in_group_flag = 0
	for l:test_element_now_orig in a:test_list
		if type( l:test_element_now_orig ) == type( {} )
			let l:test_element_now = l:test_element_now_orig
		elseif type( l:test_element_now_orig ) == type( [] )
			let l:test_element_now = { 'test': l:test_element_now_orig[ 0 ] }
			let l:test_element_now_expr_key = ( ( l:test_element_now_orig[ 1 ][ 0 ] == ':' ) ? 'exec' : 'expr' )
			let l:test_element_now[ l:test_element_now_expr_key ] = l:test_element_now_orig[ 1 ]
			if ( len( l:test_element_now_orig ) > 2 )
				let l:test_element_now[ 'options' ] = l:test_element_now_orig[ 2 ]
			endif
		else
			echoerr l:debug_message_prefix . 'invalid type for test_list. type: ' . string( type( l:test_element_now_orig ) )
		endif
		" makes sure that next iteration won't give us 'E706: Variable type mismatch for: l:test_element_now_orig'
		unlet l:test_element_now_orig

		let l:flag_handled = 0
		if has_key( l:test_element_now, 'group' )
			call EVLibTest_Group_Begin( l:test_element_now['group'] )
			let l:in_group_flag = 1
			let l:flag_handled = 1

			if has_key( l:test_element_now, 'options' )
				let l:option_flags_group = EVLibTest_Internal_TestFlagsUpdate(
						\		l:option_flags_default, 
						\		[
						\			'skiponfail.local',
						\			'skiponfail.all',
						\			'skiponfail.cont',
						\			'silent',
						\			'verbose',
						\		],
						\		l:test_element_now[ 'options' ]
						\	)
			else
				let l:option_flags_group = l:option_flags_default
			endif
		elseif has_key( l:test_element_now, 'test' )
			if has_key( l:test_element_now, 'options' )
				" process string and lists, and create the low-level
				"  flags here (have the user use high level ones for now)
				let l:option_flags_test = EVLibTest_Internal_TestFlagsUpdate(
						\		l:option_flags_group, 
						\		[],
						\		l:test_element_now[ 'options' ]
						\	)
			else
				let l:option_flags_test = l:option_flags_group
			endif
			if has_key( l:test_element_now, 'expr' )
				call EVLibTest_Do_Check( l:test_element_now['test'], l:test_element_now['expr'], l:option_flags_test )
				let l:flag_handled = 1
			elseif has_key( l:test_element_now, 'exec' )
				call EVLibTest_Do_Check( l:test_element_now['test'], l:test_element_now['exec'], 'e' . l:option_flags_test )
				let l:flag_handled = 1
			endif
		endif
		if ! l:flag_handled
			echoerr l:debug_message_prefix . 'invalid test_list element. value: ' . string( l:test_element_now )
			call EVLibTest_Util_ThrowTestExceptionInternalError()
		endif
	endfor
	if l:in_group_flag
		call EVLibTest_Group_End()
	endif
	return !0 " true
endfunction
" }}}

" high-level test groups {{{

" utility functions {{{

let s:evlib_test_common_type_dict = type( {} )
let s:evlib_test_common_dict_empty_readonly = {}

function s:EVLibTest_GroupSet_GetDictEntryFromDict( args_dict, dict_key, val_default )
	let l:args_dict = ( ( type( a:args_dict ) == s:evlib_test_common_type_dict ) ? a:args_dict : s:evlib_test_common_dict_empty_readonly )
	if has_key( l:args_dict, a:dict_key ) && ( ! empty( l:args_dict[ a:dict_key ] ) )
		return l:args_dict[ a:dict_key ]
	endif
	return a:val_default
endfunction

" the returned dictionary is read-only. use deepcopy() to modify.
function s:EVLibTest_GroupSet_GetDictFromParsList( a_000 )
	return (
		\		( ( len( a:a_000 ) > 0 ) && ( type( a:a_000[ 0 ] ) == s:evlib_test_common_type_dict ) )
		\		?	( a:a_000[ 0 ] )
		\		:	( {} )
		\	)
endfunction

function s:EVLibTest_GroupSet_GetDictEntryFromParsList( a_000, dict_key, val_default )
	return s:EVLibTest_GroupSet_GetDictEntryFromDict(
		\		s:EVLibTest_GroupSet_GetDictFromParsList( a:a_000 ),
		\		a:dict_key, a:val_default
		\	)
endfunction

" returns new (possibly copied) dictionary, which could be written to without
"  a further copy()/deepcopy().
function s:EVLibTest_GroupSet_PopulateDictionaryCopy( args_dict )
	let l:args_dict = ( ( type( a:args_dict ) == s:evlib_test_common_type_dict ) ? deepcopy( a:args_dict ) : {} )
	for l:elem_now in [
				\		[
				\			[
				\				'precheck', 'preinit', 'postinit', 'epilog',
				\			],
				\			[]
				\		],
				\		[
				\			[ 'group_title', ],
				\			''
				\		]
				\	]
		let l:default_value_now = l:elem_now[ 1 ]
		for l:dict_key in l:elem_now[ 0 ]
			if ( ! has_key( l:args_dict, l:dict_key ) )
				let l:args_dict[ l:dict_key ] = l:default_value_now
			endif
		endfor
		unlet! l:default_value_now
	endfor
	return l:args_dict
endfunction

" returns "success"
function s:EVLibTest_GroupSet_SetDictionaryEntrySafe( args_dict, dict_key, value )
	if ( has_key( a:args_dict, a:dict_key ) && ( ! empty( a:args_dict[ a:dict_key ] ) ) )
		" dictionary has already got a non-empty value for this key
		return 0 " false
	endif
	" set the value
	let a:args_dict[ a:dict_key ] = a:value
	return !0 " true
endfunction

" }}}

function EVLibTest_GroupSet_TestLibrary()
	return EVLibTest_Do_Batch(
		\		[
		\			{ 'group': 'library high-level sanity check' },
		\			[ 'library is intialised', 'exists( "*evlib#IsInitialised" ) && evlib#IsInitialised()', [ 'skiponfail.local' ] ],
		\			[ 'can call evlib#debug#DebugMessage()', ':call evlib#debug#DebugMessage( "test message" )' ],
		\		]
		\	)
endfunction

let s:evlib_test_common_global_groupset_loadlibrary_start =
		\		[
		\			[ 'library not intialised yet (safe check)', '! exists( "*evlib#IsInitialised" )', [ 'skiponfail.all' ] ],
		\			[ 'does not have access to evlib functions yet', ':call evlib#IsInitialised()', [ 'code.throws', 'skiponfail.all' ] ],
		\		]

let s:evlib_test_common_global_groupset_loadlibrary_end =
		\		[
		\			[ 'library now intialised', 'exists( "*evlib#IsInitialised" ) && evlib#IsInitialised()', [ 'skiponfail.all' ] ],
		\		]

function EVLibTest_GroupSet_LoadLibrary_Custom( ... )
	let l:args_dict = s:EVLibTest_GroupSet_GetDictFromParsList( a:000 )
	return EVLibTest_Do_Batch(
				\		[
				\			{ 'group': s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'group_title', 'library initialisation' ) },
				\		]
				\		+
				\		s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'precheck', [] )
				\		+
				\		s:evlib_test_common_global_groupset_loadlibrary_start
				\		+
				\		s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'preinit', [] )
				\		+
				\		s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'libinit', [] )
				\		+
				\		s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'postinit', [] )
				\		+
				\		s:evlib_test_common_global_groupset_loadlibrary_end
				\		+
				\		s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'epilog', [] )
				\	)
endfunction

function EVLibTest_GroupSet_LoadLibrary_Method_Source( ... )
	let l:args_dict = s:EVLibTest_GroupSet_PopulateDictionaryCopy( s:EVLibTest_GroupSet_GetDictFromParsList( a:000 ) )
	let l:success = !0 " true

	let l:success = l:success && s:EVLibTest_GroupSet_SetDictionaryEntrySafe( l:args_dict, 'libinit',
				\		[
				\			[ 'load library by sourcing "evlib_loader.vim"', ':source ' . g:evlib_test_common_rootdir . '/evlib_loader.vim' ],
				\		]
				\	)
	let l:success = l:success && EVLibTest_GroupSet_LoadLibrary_Custom( l:args_dict )
	" (internal) sanity checking
	if ( ! l:success ) | call EVLibTest_Util_ThrowTestExceptionInternalError() | endif

	return l:success
endfunction

" * does pre-loading validation (uses EVLibTest_GroupSet_LoadLibrary_Custom());
" * makes the library available in the 'runtimepath';
" * adds test_list_preinit;
" * initialises the library manually;
" * adds test_list_postinit;
" * does post-loading validation (uses EVLibTest_GroupSet_LoadLibrary_Custom());
"
" DONE: change all these EVLibTest_GroupSet_LoadLibrary_*() functions:
"  . make them take a dictionary instead of several lists:
"     'precheck', 'preinit', 'postinit', 'epilog'
"  . then we could add support for a custom group 'group'/'group_title';
"  . change the functions so all take '( ... )', and resolve the dictionary
"     entries like this:
"     let l:list_preinit = s:EVLibTest_GroupSet_GetDictEntryFromPars( a:000, 'preinit', [] )
"     let l:list_preinit = s:EVLibTest_GroupSet_GetDictEntryFromPars( a:000, 'group_title', 'default title' )
"     let l:dictionary_to_change = s:EVLibTest_GroupSet_PopulateDictionaryFromPars( a:000 )
"      " this returns a dictionary with certain guaranteed entries (so that we
"      "  don't have to do has_key() calls for those);
"      " customisations...
"  . change the functions that take one of the list members to use the
"     dictionary entry instead ('fun(list_par) -> fun(...)'), and
"     use EVLibTest_GroupSet_PopulateDictionaryFromPars() to retrieve the
"     dictionary from the "extra args";
"   . todo: think how we're going to avoid overwriting user settings without
"      noticing (so we could have a setting somewhere to set a new value, only
"      when empty() returns true for the current (default) value);
function EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust( ... )
	let l:args_dict = s:EVLibTest_GroupSet_PopulateDictionaryCopy( s:EVLibTest_GroupSet_GetDictFromParsList( a:000 ) )
	let l:success = !0 " true

	" add our elements to the beginning of 'preinit'
	if l:success
		let l:args_dict[ 'preinit' ] =
				\	[
				\		[ 'sanity check: common.vim set up correctly', 'exists( "g:evlib_test_common_rootdir" ) && isdirectory( g:evlib_test_common_rootdir )', [ 'skiponfail.all' ] ],
				\		[ 'set up runtimepath to include project root directory', ':let &runtimepath .= "," . g:evlib_test_common_rootdir', [ 'skiponfail.all' ] ],
				\	]
				\	+ deepcopy( s:EVLibTest_GroupSet_GetDictEntryFromDict( l:args_dict, 'preinit', [] ) )
	endif

	let l:success = l:success && s:EVLibTest_GroupSet_SetDictionaryEntrySafe( l:args_dict, 'libinit',
			\		[
			\			[ 'initialise the library (call evlib#Init())', 'evlib#Init()', [ 'skiponfail.all' ] ],
			\		]
			\	)

	let l:success = l:success && EVLibTest_GroupSet_LoadLibrary_Custom( l:args_dict )
	" (internal) sanity checking
	if ( ! l:success ) | call EVLibTest_Util_ThrowTestExceptionInternalError() | endif

	return l:success
endfunction

function EVLibTest_GroupSet_LoadLibrary_Default( ... )
	return EVLibTest_GroupSet_LoadLibrary_Method_Source( s:EVLibTest_GroupSet_GetDictFromParsList( a:000 ) )
endfunction

" }}}

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'test/common.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
