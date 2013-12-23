" test/testrun.vim

" boilerplate -- prolog {{{
if has('eval')
let s:evlib_test_testrun_main_source_file = expand( '<sfile>' )
let s:evlib_test_testrun_testdir = fnamemodify( s:evlib_test_testrun_main_source_file, ':p:h' )
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" support functions {{{
let s:evlib_test_testrunner_debug = ( ( exists( 'g:evlib_test_testrunner_debug' ) ) ? ( g:evlib_test_testrunner_debug ) : 0 )

function! s:IsDebuggingEnabled()
	return ( s:evlib_test_testrunner_debug != 0 )
endfunction

function! s:DebugMessage( msg )
	if s:IsDebuggingEnabled()
		echomsg '[debug] ' . a:msg
	endif
endfunction

function! s:DebugExceptionCaught()
	if ( ! s:IsDebuggingEnabled() ) | return | endif

	" (see ':h throw-variables')
	if v:exception != ''
		call s:DebugMessage( 'caught exception "'. v:exception . '" in ' . v:throwpoint )
	else
		call s:DebugMessage( 'nothing caught' )
	endif
endfunction
" }}}

" FIXME: refactor the code in runutil.vim so that some of those functions are
"  available to this module, too.
"  NOTE: in particular, the function
"   s:EVLibTest_RunUtil_Local_ProcessorDef_Invoke() (and its requirements)
"  NOTE: so that way we can generate certain informational messages, such as:
"   * test file could not be read/sourced;
"   * an exception was thrown when sourcing the test file;
"   ... in the format that the test file claimed to support.

" general functions {{{

function s:EVLibTest_Local_fnameescape( fname )
	if exists( '*fnameescape' )
		return fnameescape( a:fname )
	else
		" (see ':h escape()')
		return escape( a:fname, ' \' )
	endif
endfunction

" }}}

" include & process needed 'modules' {{{

" include our 'base' script (variables, functions) {{{
execute 'source ' . s:EVLibTest_Local_fnameescape( s:evlib_test_testrun_testdir . '/' . 'base.vim' )
" save object just created/returned into our own script variable
let s:evlib_test_base_object = g:evlib_test_base_object_last
" }}}

" }}}

" test "processor" functions {{{

let s:evlib_test_local_test_processor_info_contextlevel_base = ( exists( 'g:evlib_test_info_contextlevelbase' ) ? ( g:evlib_test_info_contextlevelbase ) : 1 )

function! s:EVLibTest_CurrentProcessor_GetInstance()
	if ( ! exists( 's:evlib_test_local_test_processor_defs_data' ) )
		" FIXME: get the processor from the 'g:' variable
		" note: this dictionary instance will be updated by the invoked
		"  function, below
		let s:evlib_test_local_test_processor_defs_data = {
					\		'processor_script': s:evlib_test_testrun_testdir . '/' . 'evtest/proc/evtstd/v0-1-0.vim',
					\	}
	endif
	return s:evlib_test_local_test_processor_defs_data
endfunction

" real documentation: see EVLibTest_ProcessorDef_Invoke() ('test/base.vim')
function! s:EVLibTest_CurrentProcessor_Invoke( function_name, function_args )
	" forward to the real function, passing our 'processor_defs_data'
	return s:evlib_test_base_object.f_processordef_invoke(
				\		s:EVLibTest_CurrentProcessor_GetInstance(),
				\		a:function_name,
				\		a:function_args
				\	)
endfunction

" real documentation: see EVLibTest_ProcessorDef_UserCall_WriteTestContextInfo() ('test/base.vim')
function! s:EVLibTest_CurrentProcessor_UserCall_WriteTestContextInfo( contextlevel_offset, infostring )
	" forward to the real function, passing our 'processor_defs_data'
	return s:evlib_test_base_object.f_processordef_usercall_writetestcontextinfo(
				\		s:EVLibTest_CurrentProcessor_GetInstance(),
				\		s:evlib_test_local_test_processor_info_contextlevel_base + a:contextlevel_offset,
				\		'[testrunning] ' . a:infostring
				\	)
endfunction

function! s:EVLibTest_CurrentProcessor_UserCall_WriteTestBlankLine()
	" forward to the real function, passing our 'processor_defs_data'
	return s:evlib_test_base_object.f_processordef_usercall_writetestcontextinfo(
				\		s:EVLibTest_CurrentProcessor_GetInstance(),
				\		s:evlib_test_local_test_processor_info_contextlevel_base,
				\		''
				\	)
endfunction

" }}}

" main functions {{{

function s:EVLibTest_TestRunner_RunTestAuto()
	let l:debug_message_prefix = 's:EVLibTest_TestRunner_RunTestAuto(): '

	let l:success = !0 " success
	call s:DebugMessage( l:debug_message_prefix . 'entered' )

	try
		if l:success
			let l:testscript = g:evlib_test_testrunner_testscript
			let l:testscript_escaped = s:EVLibTest_Local_fnameescape( l:testscript )
		endif
		if l:success
			if s:IsDebuggingEnabled()
				call s:DebugMessage( l:debug_message_prefix . 'about to "source" file "' . l:testscript . '" (readable: ' . string( filereadable( l:testscript ) ) . ', escaped: ' . l:testscript_escaped . ')' )
				call s:DebugMessage( l:debug_message_prefix . 'escaped: <' . l:testscript_escaped . '>' )
			endif
			call s:EVLibTest_CurrentProcessor_UserCall_WriteTestContextInfo( 0, 'about to source file: ' . string( l:testscript ) )

			" MAYBE: TODO: leave this blank line to each test (in our case,
			"  'common.vim') script to add, if desired.
			call s:EVLibTest_CurrentProcessor_UserCall_WriteTestBlankLine()
			execute 'source ' . l:testscript_escaped
		endif
	catch
		call s:DebugExceptionCaught()
		let l:success = 0 " false
	endtry

	call s:DebugMessage( l:debug_message_prefix . 'exiting' )
	return l:success
endfunction

" }}}

" 'exported' functions {{{

" }}}

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" NOTE: here, we have the 'compatibility' options as they were {{{

" exception handling block {{{
try
	" 'try' block {{{

	call s:evlib_test_base_object.f_testoutput_initandopen()

	call s:DebugMessage( 'testrun.vim: executing non-function code' )

	if exists( 'g:evlib_test_testrunner_debug' )
		call s:DebugMessage( 'g:evlib_test_testrunner_debug: ' . string( g:evlib_test_testrunner_debug ) )
	endif
	call s:DebugMessage( 'g:evlib_test_testrunner_testscript: ' . string( g:evlib_test_testrunner_testscript ) )
	if s:IsDebuggingEnabled()
		pwd
	endif
	call s:DebugMessage( 'g:evlib_test_outputfile: ' . string( g:evlib_test_outputfile ) )

	" 'source' the test script
	call s:EVLibTest_TestRunner_RunTestAuto()

	" }}}
finally
	if s:evlib_test_base_object.f_testoutput_isredirectingtoafile()
		" ignore rc for now
		call s:evlib_test_base_object.f_testoutput_close()
	endif
	" whatever happens, exit vim now
	quit
endtry
" }}}

" }}}

" boilerplate -- epilog {{{
finish
endif

echoerr 'testrun.vim needs the "eval" feature'
" }}}

" vim600: set filetype=vim fileformat=unix foldmethod=marker:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
