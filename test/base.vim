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

" support for writing the results to a file {{{
let s:evlib_test_common_global_outputtofile_flag = 0

function EVLibTest_Gen_IsRedirectingToAFile()
	return ( s:evlib_test_common_global_outputtofile_flag != 0 )
endfunction

" FIXME: make sure that the renamed function has an "end" function:
"   FIXME: make function also take filename(s) from vim variable (in addition
"    to environment variable)
"  EVLibTest_TestOutput_Reopen()
"  EVLibTest_TestOutput_Close()
"
" MAYBE: add (optional?) parameter: do_open_flag
function EVLibTest_TestOutput_InitAndOpen()
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
" }}}

" MAYBE: move function 'EVLibTest_Module_Load( module )' here

" MAYBE: make this include a "defs.vim" with just constants (useful for the
"  'foldexpr' and 'foldtext' implementing functions)
"  MAYBE: ... and move constants there! (which might need some refactoring,
"   too, in order to share just the literals on one hand, and then have
"   regexes for matching the produced lines, on the other);

" formatted output support {{{

let s:evlib_test_common_output_lineprefix_string = 'TEST: '

function EVLibTest_TestOutput_GetFormattedLinePrefix()
	return s:evlib_test_common_output_lineprefix_string
endfunction

function EVLibTest_Gen_OutputLine( msg )
	" fix: when redirecting to a file, make sure that we start each message on
	"  a new line (error messages sometimes have a '<CR>' at the end, which
	"  means that the next line will start at column > 1
	if EVLibTest_Gen_IsRedirectingToAFile()
		silent echomsg ' '
	endif
	execute ( EVLibTest_Gen_IsRedirectingToAFile() ? 'silent ' : '' )
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
