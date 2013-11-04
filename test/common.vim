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

let g:evlib_test_common_ntests = 0
let g:evlib_test_common_npass = 0
let s:evlib_test_common_global_skippingtests_flag = 0
" }}}

" global test support {{{
function EVLibTest_Start( suite_name )
	if s:evlib_test_common_in_group_flag || ( g:evlib_test_common_ntests > 0 )
		call EVLibTest_Finalise()
	endif
	call EVLibTest_Gen_OutputLine( 'SUITE: ' . a:suite_name )
	call EVLibTest_Gen_OutputLine( '' )
endfunction

function EVLibTest_Finalise()
	if s:evlib_test_common_in_test_flag
		call EVLibTest_Test_EndUncertain()
	endif
	if s:evlib_test_common_in_group_flag
		call EVLibTest_Group_End()
	endif
	call EVLibTest_Gen_OutputTestStats( 'Total', g:evlib_test_common_ntests, g:evlib_test_common_npass )
	call EVLibTest_Gen_OutputLine( '' )
	let g:evlib_test_common_ntests = 0
	let g:evlib_test_common_npass = 0
	let s:evlib_test_common_global_skippingtests_flag = 0
endfunction

let s:evlib_test_common_output_lineprefix_string = 'TEST: '
function EVLibTest_Gen_OutputLine( msg )
	echomsg s:evlib_test_common_output_lineprefix_string . a:msg
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

function EVLibTest_Gen_OutputTestStats( msg, ntests, npass )
	call EVLibTest_Gen_OutputLine( 'RESULTS (' . a:msg . '): tests: ' . string( a:ntests ) . ', pass: ' . string( a:npass ) . ' -- rate: ' . string( round( ( ( str2float( a:npass ) / ( a:ntests ? str2float( a:ntests ) : 1.0 ) ) * 100 ) * 100 ) / 100 ) . '%' )
endfunction
"" }}}

" test group support {{{
let s:evlib_test_common_in_group_flag = 0
let g:evlib_test_common_group_ntests = 0
let g:evlib_test_common_group_npass = 0

function EVLibTest_Group_Begin( group_name )
	if s:evlib_test_common_in_group_flag
		call EVLibTest_Group_End()
	endif
	if s:evlib_test_common_global_skippingtests_flag
		return
	endif

	call EVLibTest_Gen_OutputLine( '[' . a:group_name . ']' )
	let s:evlib_test_common_in_group_flag = 1
endfunction

function EVLibTest_Group_End()
	if s:evlib_test_common_in_group_flag
		" report group results
		call EVLibTest_Gen_OutputTestStats( 'group total', g:evlib_test_common_group_ntests, g:evlib_test_common_group_npass )
		call EVLibTest_Gen_OutputLine( '' )
	endif
	let s:evlib_test_common_in_group_flag = 0

	let g:evlib_test_common_group_ntests = 0
	let g:evlib_test_common_group_npass = 0
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
	if s:evlib_test_common_global_skippingtests_flag
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
		let l:columns = min( [ &columns, 100 ] ) - 1
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

	if type( a:rc ) == type( 0 )
		let l:result_is_pass = ( a:rc != 0 )
		let l:result_as_string = ( l:result_is_pass ? 'pass' : 'FAIL' )
	elseif type( a:rc ) == type( '' )
		let l:result_is_pass = 0
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
	if l:result_is_pass
		let g:evlib_test_common_npass += 1
		if s:evlib_test_common_in_group_flag
			let g:evlib_test_common_group_npass += 1
		endif
	elseif l:flag_skiprest
		" flag this situation
		let s:evlib_test_common_global_skippingtests_flag = 1
		let s:evlib_test_common_global_skippingtests_all_flag = l:flag_skiprest_all
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
"
function EVLibTest_Do_Check( test_msg, expr, ... )
	let l:debug_message_prefix = 'EVLibTest_Do_Check(): '

	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )
	let l:flag_execute  = ( stridx( l:flags, 'e' ) >= 0 )
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
		if type( a:expr ) == type( function( 'EVLibTest_Group_Begin' ) )
			echoerr l:debug_message_prefix . 'Funcref objects still not supported. fix the code (common.vim) and try again'
		elseif type( a:expr ) == type( '' )
			unlet! l:rc
			unlet! l:rc_real
			let l:result_throws = 0
			try
				if l:flag_execute
					silent execute a:expr
					" successful execution is mapped to a rc != 0
					let l:rc_real = 1
				else
					silent let l:rc_real = eval( a:expr )
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
" }}}

" high-level test support {{{
" test_list: elements:
"  { dictionary }
"  [ test_msg, expr [, options ] ]
"  * dictionary:
"   * group start: { 'group': GROUP_NAME }
"   * test entry: { 'test': TEST_MSG, 'expr': TEST_EXPRESSION [, 'options': OPTIONS ] }
"    * use 'eval()';
"   * test entry: { 'test': TEST_MSG, 'exec': EX_COMMAND_STRING [, 'options': OPTIONS ] }
"    * use 'execute';
"  * list: self-explanatory
"  * OPTIONS: a list of strings specifying "options":
"     * 'skiponfail.local': if this test fails, skip the test until the end of
"         the group (or the end of all tests, if there is no active group);
"     * 'skiponfail.all': if this test fails, skip the test until the end of
"         all tests (even if there is an active group at the time of failure);
"     * 'code.throws': (see EVLibTest_Do_Check() flag 't')
"        code is expected to throw an exception (test will only pass
"        if the code/expression throws);
"
" for each element in ths list, EVLibTest_Do_Check() is called, so:
"  * expr: same format and constraints as that function;
function EVLibTest_Do_Batch( test_list )
	let l:debug_message_prefix = 'EVLibTest_Do_Batch(): '

	" first-run initialisation only
	if ! exists( 's:evlib_test_common_dobatch_options_mapping' )
		let s:evlib_test_common_dobatch_options_mapping =
				\	{
				\		'skiponfail.local': 's',
				\		'skiponfail.all': 'S',
				\		'code.throws': 't',
				\	}
	endif

	let l:in_group_flag = 0
	for l:test_element_now_orig in a:test_list
		if type( l:test_element_now_orig ) == type( {} )
			let l:test_element_now = l:test_element_now_orig
		elseif type( l:test_element_now_orig ) == type( [] )
			let l:test_element_now = { 'test': l:test_element_now_orig[ 0 ], 'expr': l:test_element_now_orig[ 1 ] }
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
		elseif has_key( l:test_element_now, 'test' )
			let l:option_flags_now = ''
			if has_key( l:test_element_now, 'options' )
				" process string and lists, and create the low-level
				"  flags here (have the user use high level ones for now)
				for l:option_elem_now in l:test_element_now[ 'options' ]
					if ( strlen( l:option_elem_now ) == 0 )
						continue
					endif
					let l:option_flag_now = ''
					if has_key( s:evlib_test_common_dobatch_options_mapping, l:option_elem_now )
						let l:option_flag_now = s:evlib_test_common_dobatch_options_mapping[ l:option_elem_now ]
					else
						echoerr l:debug_message_prefix . 'invalid option. value: ' . string( l:option_elem_now )
					endif
					if ( strlen( l:option_flag_now ) > 0 )
						let l:option_flags_now = l:option_flags_now . l:option_flag_now
					endif
				endfor
			endif
			if has_key( l:test_element_now, 'expr' )
				call EVLibTest_Do_Check( l:test_element_now['test'], l:test_element_now['expr'], l:option_flags_now )
				let l:flag_handled = 1
			elseif has_key( l:test_element_now, 'exec' )
				call EVLibTest_Do_Check( l:test_element_now['test'], l:test_element_now['exec'], 'e' . l:option_flags_now )
				let l:flag_handled = 1
			endif
		endif
		if ! l:flag_handled
			echoerr l:debug_message_prefix . 'invalid test_list element. value: ' . string( l:test_element_now )
		endif
	endfor
	if l:in_group_flag
		call EVLibTest_Group_End()
	endif
endfunction
" }}}

" high-level test groups {{{
function EVLibTest_GroupSet_TestLibrary()
	return EVLibTest_Do_Batch(
		\		[
		\			{ 'group': 'library high-level sanity check' },
		\			[ 'library is intialised', 'exists( "*evlib#IsInitialised" ) && evlib#IsInitialised()', [ 'skiponfail.local' ] ],
		\			{ 'test': 'can call evlib#debug#DebugMessage()', 'exec': 'call evlib#debug#DebugMessage( "test message" )' },
		\		]
		\	)
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
