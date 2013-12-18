" test/base.vim
"
" needs/includes:
"  * call s:EVLibTest_Module_Load( 'evtest/proc/evtstd/c-defs.vim' );
"
" output:
"  * instanciates a new variable g:evlib_test_base_object_last;
"
" side effects:
"  * other than the global variable that is set on output, it should have no
"     other side effects of its own;
"  * because it includes '.../evtstd/c-defs.vim' (see above), it overwrites
"     the previous value (if it exists) of
"     g:evlib_test_evtest_evtstd_base_object_last
"

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control -- start {{{
if ( ! exists( 's:evlib_test_base_loaded' ) ) || ( exists( 'g:evlib_test_base_forceload' ) && ( g:evlib_test_base_forceload != 0 ) )
let s:evlib_test_base_loaded = 1
unlet! g:evlib_test_base_forceload
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" everything in this file will be part of: s:evlib_test_base_object

" variables and functions {{{
" general variables {{{
let s:evlib_test_base_testdir = fnamemodify( expand( '<sfile>' ), ':p:h' )
let s:evlib_test_base_rootdir = fnamemodify( s:evlib_test_base_testdir, ':h' )
let s:evlib_test_base_test_testtrees_rootdir = s:evlib_test_base_testdir . '/test_trees'
" }}}

" test framework modules {{{
function! s:EVLibTest_Module_Load( module )
	let l:filepath = s:evlib_test_base_testdir . '/' . a:module
	execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( l:filepath ) : l:filepath )
	return !0 " true
endfunction
" }}}
" }}}

" include our 'base' script (variables, functions) {{{
call s:EVLibTest_Module_Load( 'evtest/proc/evtstd/c-defs.vim' )
" save object just created/returned into our own script variable
let s:evlib_test_evtest_evtstd_base_object = g:evlib_test_evtest_evtstd_base_object_last
" }}}

" support for writing the results to a file {{{
let s:evlib_test_base_global_outputtofile_flag = 0
let s:evlib_test_base_global_outputtofile_lastfile_escaped = ''

function! s:EVLibTest_TestOutput_IsRedirectingToAFile()
	return ( s:evlib_test_base_global_outputtofile_flag != 0 )
endfunction

" args:
" * file_escaped
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
function! s:EVLibTest_TestOutput_Do_Redir( file_escaped, ... )
	let l:success = !0 " true
	let l:redir_overwrite_flag = ( ( a:0 > 0 ) ? a:1 : ( 0 ) )

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingToAFile() )
	let l:success = l:success && ( ! empty( a:file_escaped ) )

	if l:success
		" NOTE: alternative, use option 'verbosefile' instead
		"  (see ":h 'verbosefile'")
		let l:redir_ex_command_prefix = ( l:redir_overwrite_flag ? 'redir! >' : 'redir >>' )
		execute l:redir_ex_command_prefix . ' ' . a:file_escaped
		let s:evlib_test_base_global_outputtofile_flag = 1
	endif
	return l:success
endfunction

" args: [ redir_filename ]
"  * redir_filename: (ignored if empty)
"
" returns: file name to use in redirection, if one was found
"  (the empty string if one was not found)
function! s:EVLibTest_TestOutput_OptionalGetRedirFilename( ... )
	let l:success = !0 " true
	let l:redir_filename = ''

	if l:success
		let l:stage = 1
		while ( l:success ) && ( empty( l:redir_filename ) )
			let l:stage_finished = !0 " true (by default)
			let l:stage_is_last = 0 " false
			let l:filename_now = ''

			" note: if ( ! l:success ) the while condition will stop the loop
			if l:success
				if l:stage == 1
					" process optional argument
					let l:filename_now = ( ( a:0 > 0 ) ? ( a:1 ) : '' )
				elseif l:stage == 2
					let l:stage_is_last = !0 " true

					if ( ! exists( 'l:variables_list' ) )
						let l:variables_list = [ '$EVLIB_VIM_TEST_OUTPUTFILE' ]
					endif
					" remove the first element from the list, and store it in
					"  l:var_now
					" note: we know that the list is always non-empty at this point
					let l:var_now = remove( l:variables_list, 0 )

					if l:success && exists( l:var_now )
						let l:filename_now = expand( l:var_now )
					endif

					let l:stage_finished = empty( l:variables_list )
				endif
			endif
			if l:success && ( ! empty( l:filename_now ) )
				let l:redir_filename = l:filename_now
			endif

			if l:stage_finished
				if l:stage_is_last
					break
				else
					let l:stage += 1
				endif
			endif
		endwhile
	endif

	return ( l:success ? l:redir_filename : '' )
endfunction

" args: [ do_redir_now_flag [, redir_filename [, redir_overwrite_flag ] ] ]
" * do_redir_now_flag (default: TRUE);
" * redir_filename: empty or unspecified to use automatic name detection;
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
"
" returns: success state
function! s:EVLibTest_TestOutput_InitAndOpen( ... )
	let l:success = !0 " true
	let l:do_redir_now_flag = ( ( a:0 > 0 ) ? ( a:1 ) : ( !0 ) )
	let l:redir_filename_user = ( ( a:0 > 1 ) ? ( a:2 ) : '' )
	let l:redir_overwrite_flag = ( ( a:0 > 2 ) ? ( a:3 ) : ( 0 ) )

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingToAFile() )

	if l:success
		let l:file_escaped = s:EVLibTest_TestOutput_OptionalGetRedirFilename( l:redir_filename_user )
	endif
	if l:success && ( ! empty( l:file_escaped ) )
		if exists( '*fnameescape' )
			let l:file_escaped = fnameescape( l:file_escaped )
		endif
		if l:do_redir_now_flag
			let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( l:file_escaped, l:redir_overwrite_flag )
		endif
		" note: purposedly writing these other (globally/script
		"  scoped) variables
		if l:success
			let s:evlib_test_base_global_outputtofile_lastfile_escaped = l:file_escaped
		endif
	endif

	return l:success
endfunction

" args:
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
function! s:EVLibTest_TestOutput_Reopen( ... )
	let l:success = !0 " true
	let l:redir_overwrite_flag = ( ( a:0 > 0 ) ? a:1 : ( 0 ) )

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingToAFile() )
	let l:success = l:success && exists( 's:evlib_test_base_global_outputtofile_lastfile_escaped' ) && ( ! empty( s:evlib_test_base_global_outputtofile_lastfile_escaped ) )

	" do it {{{
	let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( s:evlib_test_base_global_outputtofile_lastfile_escaped, l:redir_overwrite_flag )
	" }}}

	return l:success
endfunction

function! s:EVLibTest_TestOutput_Close()
	let l:success = !0 " success

	let l:success = l:success && s:EVLibTest_TestOutput_IsRedirectingToAFile()
	if l:success
		" end redirection (see ':h :redir')
		redir END
		let s:evlib_test_base_global_outputtofile_flag = 0
	endif
	return l:success
endfunction

" }}}

" TODO: make this include a "defs.vim" (done) with just constants (useful for
"  the 'foldexpr' and 'foldtext' implementing functions)
"
"  MAYBE: ... and move constants there! (which might need some refactoring,
"   too, in order to share just the literals on one hand, and then have
"   regexes for matching the produced lines, on the other);

" formatted output support {{{

let s:evlib_test_base_output_lineprefix_string = s:evlib_test_evtest_evtstd_base_object.c_output_lineprefix_string

function! s:EVLibTest_TestOutput_GetFormattedLinePrefix()
	return s:evlib_test_base_output_lineprefix_string
endfunction

function! s:EVLibTest_TestOutput_OutputLine( msg )
	" fix: when redirecting to a file, make sure that we start each message on
	"  a new line (error messages sometimes have a '<CR>' at the end, which
	"  means that the next line will start at column > 1
	if s:EVLibTest_TestOutput_IsRedirectingToAFile()
		silent echomsg ' '
	endif
	execute ( s:EVLibTest_TestOutput_IsRedirectingToAFile() ? 'silent ' : '' )
		\	. 'echomsg s:evlib_test_base_output_lineprefix_string . a:msg'
endfunction

" }}}

" everything in this file will be part of: s:evlib_test_base_object {{{
" TODO: define the functions directly in the dictionary object, to avoid this ugly hack
" from ':h <SID>' {{{
function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
" }}}
let s:funpref = '<SNR>' . s:SID() . '_'
" NOTE: values are copied (no references), so this is only a good method to
"  expose constants ('c_' prefix)
let s:evlib_test_base_object = {
		\		'c_testdir':				s:evlib_test_base_testdir,
		\		'c_rootdir':				s:evlib_test_base_rootdir,
		\		'c_testtrees_rootdir':		s:evlib_test_base_test_testtrees_rootdir,
		\
		\		'f_testoutput_outputline':					function( s:funpref . 'EVLibTest_TestOutput_OutputLine' ),
		\		'f_testoutput_getformattedlineprefix':		function( s:funpref . 'EVLibTest_TestOutput_GetFormattedLinePrefix' ),
		\		'f_testoutput_close':						function( s:funpref . 'EVLibTest_TestOutput_Close' ),
		\		'f_testoutput_reopen':						function( s:funpref . 'EVLibTest_TestOutput_Reopen' ),
		\		'f_testoutput_initandopen':					function( s:funpref . 'EVLibTest_TestOutput_InitAndOpen' ),
		\		'f_testoutput_optionalgetredirfilename':	function( s:funpref . 'EVLibTest_TestOutput_OptionalGetRedirFilename' ),
		\		'f_testoutput_redir':						function( s:funpref . 'EVLibTest_TestOutput_Do_Redir' ),
		\		'f_testoutput_isredirectingtoafile':		function( s:funpref . 'EVLibTest_TestOutput_IsRedirectingToAFile' ),
		\
		\		'f_module_load':							function( s:funpref . 'EVLibTest_Module_Load' ),
		\	}
" }}}

" inclusion control -- end {{{
endif " ... s:evlib_test_base_loaded ...
" }}}

" preserve the script object(s) as global {{{
unlet! g:evlib_test_base_object_last
let g:evlib_test_base_object_last = s:evlib_test_base_object
" }}}

" boiler plate -- epilog (customised) {{{

" restore old "compatibility" options {{{
if exists( 's:cpo_save' )
	let &cpo = s:cpo_save
	unlet s:cpo_save
endif
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'test/base.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
