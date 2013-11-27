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

function! s:EVLibTest_RunUtil_TestOutput_GetLine( lnum )
	let l:line = substitute( getline( a:lnum ), '^TEST: \?', '', '' )
	return l:line
endfunction

" test presentation
let s:regex_squarebrackets_end = '\[[^\]]\]\s*$'
let s:regex_results_pref = '^RESULTS ('
let s:regex_results_suff = ')'
" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
let s:regex_results_group = s:regex_results_pref . 'group total' . s:regex_results_suff
" example: RESULTS (Total): tests: 14, pass: 3 -- [custom.results] [pass]
let s:regex_results_total = s:regex_results_pref . 'Total' . s:regex_results_suff
let s:regex_testline = '^ \{3,}.*' . s:regex_squarebrackets_end

function! EVLibTest_RunUtil_TestOutput_FoldingFun( lnum )
	"let l:line_prev    = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum - 1 )
	let l:line_current = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum )
	"let l:line_next    = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum + 1 )

	" example: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]
	if l:line_current =~ '^SUITE: '
		return '>1'
	" example: [group 1]
	elseif l:line_current =~ '^\['
		return '>2'
	" example:    test 1 (true) . . . . . . . . . . . . . . . . . . . . . . . [pass]
	elseif l:line_current =~ '^ \{3,}.*\[[^\]]\]\s*$'
		return '='
	" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
	elseif l:line_current =~ s:regex_results_group
		return 2
	" example: RESULTS (Total): tests: 14, pass: 3 -- [custom.results] [pass]
	elseif l:line_current =~ s:regex_results_total
		return 1
	endif
	return '='
endfunction

" FIXME: implement folding function (see ':h fold-expr')

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
