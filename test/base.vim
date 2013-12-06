" test/base.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_test_base_loaded' )
	finish
endif
let g:evlib_test_base_loaded = 1
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" FIXME: rename all variables: s:evlib_test_common_* -> s:evlib_test_base_*

" variables and functions {{{
" general variables {{{
let g:evlib_test_common_testdir = fnamemodify( expand( '<sfile>' ), ':p:h' )
let g:evlib_test_common_rootdir = fnamemodify( g:evlib_test_common_testdir, ':h' )
let g:evlib_test_common_test_testtrees_rootdir = g:evlib_test_common_testdir . '/test_trees'
" }}}

" test framework modules {{{
function! EVLibTest_Module_Load( module )
	let l:filepath = g:evlib_test_common_testdir . '/' . a:module
	execute 'source ' . ( exists( '*fnameescape' ) ? fnameescape( l:filepath ) : l:filepath )
	return !0 " true
endfunction
" }}}
" }}}

" support for writing the results to a file {{{
let s:evlib_test_common_global_outputtofile_flag = 0
let s:evlib_test_common_global_outputtofile_lastfile_escaped = ''

function! EVLibTest_TestOutput_IsRedirectingToAFile()
	return ( s:evlib_test_common_global_outputtofile_flag != 0 )
endfunction

function! s:EVLibTest_TestOutput_Do_Redir( file_escaped )
	let l:success = !0 " true

	let l:success = l:success && ( ! EVLibTest_TestOutput_IsRedirectingToAFile() )
	let l:success = l:success && ( ! empty( a:file_escaped ) )

	if l:success
		" NOTE: alternative, use option 'verbosefile' instead
		"  (see ":h 'verbosefile'")
		execute 'redir >> ' . a:file_escaped
		let s:evlib_test_common_global_outputtofile_flag = 1
	endif
	return l:success
endfunction

" args: [ redir_filename ]
"  * redir_filename: (ignored if empty)
"
" returns: file name to use in redirection, if one was found
"  (the empty string if one was not found)
function! EVLibTest_TestOutput_OptionalGetRedirFilename( ... )
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

" args: [ do_redir_now_flag, [ redir_filename ] ]
" * do_redir_now_flag (default: TRUE);
"
" returns: success state
function! EVLibTest_TestOutput_InitAndOpen( ... )
	let l:success = !0 " true
	let l:do_redir_now_flag = ( ( a:0 > 0 ) ? ( a:1 ) : ( !0 ) )
	let l:redir_filename_user = ( ( a:0 > 1 ) ? ( a:2 ) : '' )

	let l:success = l:success && ( ! EVLibTest_TestOutput_IsRedirectingToAFile() )

	if l:success
		let l:file_escaped = EVLibTest_TestOutput_OptionalGetRedirFilename( l:redir_filename_user )
	endif
	if l:success && ( ! empty( l:file_escaped ) )
		if exists( '*fnameescape' )
			let l:file_escaped = fnameescape( l:file_escaped )
		endif
		if l:do_redir_now_flag
			let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( l:file_escaped )
		endif
		" note: purposedly writing these other (globally/script
		"  scoped) variables
		if l:success
			let s:evlib_test_common_global_outputtofile_lastfile_escaped = l:file_escaped
		endif
	endif

	return l:success
endfunction

function! EVLibTest_TestOutput_Reopen()
	let l:success = !0 " true

	let l:success = l:success && ( ! EVLibTest_TestOutput_IsRedirectingToAFile() )
	let l:success = l:success && exists( 's:evlib_test_common_global_outputtofile_lastfile_escaped' ) && ( ! empty( s:evlib_test_common_global_outputtofile_lastfile_escaped ) )

	" do it {{{
	let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( s:evlib_test_common_global_outputtofile_lastfile_escaped )
	" }}}

	return l:success
endfunction

function! EVLibTest_TestOutput_Close()
	let l:success = !0 " success

	let l:success = l:success && EVLibTest_TestOutput_IsRedirectingToAFile()
	if l:success
		" end redirection (see ':h :redir')
		redir END
		let s:evlib_test_common_global_outputtofile_flag = 0
	endif
	return l:success
endfunction

" }}}

" MAYBE: move function 'EVLibTest_Module_Load( module )' here

" MAYBE: make this include a "defs.vim" with just constants (useful for the
"  'foldexpr' and 'foldtext' implementing functions)
"  MAYBE: ... and move constants there! (which might need some refactoring,
"   too, in order to share just the literals on one hand, and then have
"   regexes for matching the produced lines, on the other);

" formatted output support {{{

let s:evlib_test_common_output_lineprefix_string = 'TEST: '

function! EVLibTest_TestOutput_GetFormattedLinePrefix()
	return s:evlib_test_common_output_lineprefix_string
endfunction

function! EVLibTest_TestOutput_OutputLine( msg )
	" fix: when redirecting to a file, make sure that we start each message on
	"  a new line (error messages sometimes have a '<CR>' at the end, which
	"  means that the next line will start at column > 1
	if EVLibTest_TestOutput_IsRedirectingToAFile()
		silent echomsg ' '
	endif
	execute ( EVLibTest_TestOutput_IsRedirectingToAFile() ? 'silent ' : '' )
		\	. 'echomsg s:evlib_test_common_output_lineprefix_string . a:msg'
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
echoerr "the script 'test/base.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
