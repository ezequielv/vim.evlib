" test/evtest/proc/evtstd/v0-1-0.vim

" boiler plate -- prolog {{{

" FIXME: work on buffer variables, and even names that can't be mapped back to this file (something like 'b:current_syntax' is)

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" g:evlib_test_processor_operation {{{
if g:evlib_test_processor_operation == 'define_functions'
" g:evlib_test_processor_operation == 'define_functions' {{{

" include our 'base' script (variables, functions) {{{
execute 'source ' . fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/' . 'c-defs.vim'
" save object just created/returned into our own script variable
let b:evlib_test_evtest_evtstd_base_object = deepcopy( g:evlib_test_evtest_evtstd_base_object_last )
" }}}

function! b:EVLibTest_RunUtil_TestOutput_GetLine( lnum )
	" save previous search
	let l:saved_register_search = @/

	let l:line = substitute( getline( a:lnum ), b:evlib_test_evtest_evtstd_base_object.c_output_pref, '', '' )

	" recover previous search
	let @/ = l:saved_register_search

	return l:line
endfunction

" test presentation
let b:evlib_test_evtest_evtstd_base_object.c_output_pref = '^' . b:evlib_test_evtest_evtstd_base_object.c_output_lineprefix_string
let b:evlib_test_evtest_evtstd_base_object.c_output_pref_optional = '^\(' . b:evlib_test_evtest_evtstd_base_object.c_output_pref . '\)\?'
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_mid_pref = '\['
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref = '\['
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_suff = '\]\s*$'
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_mid = '[^\]]\+'
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_suff = b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_mid . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_suff
let b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end = b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_suff
let b:evlib_test_evtest_evtstd_base_object.c_results_pref = '^RESULTS ('
let b:evlib_test_evtest_evtstd_base_object.c_results_mid_any = '[^)]\+'
let b:evlib_test_evtest_evtstd_base_object.c_results_suff = '):'
" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
let b:evlib_test_evtest_evtstd_base_object.c_results_fail_suff = '\[FAIL\]\s*$'
let b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_pass = 'pass'
let b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_skipped = 'skipped'
let b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_failure_pref = 'failed\.'
let b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_custom_pref = 'custom\.'
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_pref = b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_mid_pref
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_mid_any = '[^\]]\+'
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_suff = '\]'
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_failure_all = b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_pref . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_failure_pref . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_mid_any . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_suff
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_custom_all  = b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_pref . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_custom_pref . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_mid_any . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_suff
let b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_other_all   = b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_pref . '\(\(' . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_failure_pref . '\)\|\(' . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_custom_pref . '\)\)\@!' . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_mid_any . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_suff
let b:evlib_test_evtest_evtstd_base_object.c_gen_tagged_any_failure_suff = b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref . '\(\(' . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_pass . '\)\|\(' . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_skipped . '\)\)\@!' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_suff
" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
let b:evlib_test_evtest_evtstd_base_object.c_results_group = b:evlib_test_evtest_evtstd_base_object.c_results_pref . 'group total' . b:evlib_test_evtest_evtstd_base_object.c_results_suff
" example: RESULTS (Total): tests: 14, pass: 3 -- [custom.results] [pass]
let b:evlib_test_evtest_evtstd_base_object.c_results_total = b:evlib_test_evtest_evtstd_base_object.c_results_pref . 'Total' . b:evlib_test_evtest_evtstd_base_object.c_results_suff
" example:    test 1 (true) . . . . . . . . . . . . . . . . . . . . . . . [pass]
" fix vim parser: {
let b:evlib_test_evtest_evtstd_base_object.c_testline_pref = '^ \{3,}'
let b:evlib_test_evtest_evtstd_base_object.c_testline = b:evlib_test_evtest_evtstd_base_object.c_testline_pref . '.*' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end
" example: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]
let b:evlib_test_evtest_evtstd_base_object.c_suite_begin = '^SUITE: '
let b:evlib_test_evtest_evtstd_base_object.c_suite_header = b:evlib_test_evtest_evtstd_base_object.c_suite_begin
" example: [group 1]
let b:evlib_test_evtest_evtstd_base_object.c_group_begin = '^\['
let b:evlib_test_evtest_evtstd_base_object.c_group_withcontent = b:evlib_test_evtest_evtstd_base_object.c_group_begin . '.*\]\(\(\s*$\)\|\( \[\)\)\@='
let b:evlib_test_evtest_evtstd_base_object.c_line_with_tagged_result_pref = '\(\(' . b:evlib_test_evtest_evtstd_base_object.c_testline_pref . '\)\|\(' . b:evlib_test_evtest_evtstd_base_object.c_results_pref . '\)\)'

function! b:EVLibTest_RunUtil_TestOutput_FoldingFun( lnum )
	if ( ! exists( 'b:evlib_test_runtest_folding_stddata_level_offset' ) )
		" FIXME: determine this value from the presence of our custom data
		let b:evlib_test_runtest_folding_stddata_level_offset = 0
		let b:evlib_test_runtest_folding_suite_level = b:evlib_test_runtest_folding_stddata_level_offset + 1
		let b:evlib_test_runtest_folding_group_level = b:evlib_test_runtest_folding_suite_level + 1
	endif

	"let l:line_prev    = b:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum - 1 )
	let l:line_current = b:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum )
	"let l:line_next    = b:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum + 1 )

	" example: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]
	if l:line_current =~ b:evlib_test_evtest_evtstd_base_object.c_suite_begin
		return '>' . b:evlib_test_runtest_folding_suite_level
	" example: [group 1]
	elseif l:line_current =~ b:evlib_test_evtest_evtstd_base_object.c_group_begin
		return '>' . b:evlib_test_runtest_folding_group_level
	" example:    test 1 (true) . . . . . . . . . . . . . . . . . . . . . . . [pass]
	elseif l:line_current =~ b:evlib_test_evtest_evtstd_base_object.c_testline
		return '='
	" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
	elseif l:line_current =~ b:evlib_test_evtest_evtstd_base_object.c_results_group
		return b:evlib_test_runtest_folding_group_level
	" example: RESULTS (Total): tests: 14, pass: 3 -- [custom.results] [pass]
	elseif l:line_current =~ b:evlib_test_evtest_evtstd_base_object.c_results_total
		return b:evlib_test_runtest_folding_suite_level
	endif
	return '='
endfunction

" syntax: b:EVLibTest_RunUtil_TestOutput_FoldTextFun( [ USE_DEFAULT_FOLDING_FUNCTION ] )
"
" args:
"
"  * USE_DEFAULT_FOLDING_FUNCTION (default: use it, if available):
"     whether to use foldtext() or use the internal implementation (which is "tweakable");
"
function! b:EVLibTest_RunUtil_TestOutput_FoldTextFun( ... )
	let l:foldlevel_current = v:foldlevel
	" NOTE: use variables defined in b:EVLibTest_RunUtil_TestOutput_FoldingFun()
	if l:foldlevel_current == b:evlib_test_runtest_folding_suite_level
		let l:regex_results_now = b:evlib_test_evtest_evtstd_base_object.c_results_total
	elseif l:foldlevel_current == b:evlib_test_runtest_folding_group_level
		let l:regex_results_now = b:evlib_test_evtest_evtstd_base_object.c_results_group
	else
		" don't do matching (use default)
		let l:regex_results_now = ''
	endif

	let l:use_default_foldtext = ( ( a:0 > 0 ) ? a:1 : ( !0 ) )
	let l:use_default_foldtext = l:use_default_foldtext && ( exists( '*foldtext' ) )

	let l:line_fold_suffix = ''

	if ( ! empty( l:regex_results_now ) )
		" add the last square-bracket-enclosed expression from the results
		"  line that matches l:regex_results_now
		let l:lines_fold = getline( v:foldstart, v:foldend )
		let l:line_result_index = match( l:lines_fold, l:regex_results_now )
		if ( l:line_result_index >= 0 )
			let l:regex_squarebrackets_last_extract = '\v^.*(\[[^\]]+\])\s*$'
			let l:line_result = l:lines_fold[ l:line_result_index ]
			" get the last bit in square brackets
			if ( match( l:line_result, l:regex_squarebrackets_last_extract ) >= 0 )
				let l:line_fold_suffix .= ' ' . substitute( l:line_result, l:regex_squarebrackets_last_extract, '\1', '' )
			endif
		endif
	endif

	if l:use_default_foldtext
		let l:line_fold_result = foldtext()
	else
		" note: at the moment, we are trying to mirror the default setting
		" default: +-- 30 lines: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]---
		let l:line_fold_result = (
			\		'+-' .
			\		v:folddashes .
			\		' ' .
			\		( printf( '%2d lines: ', ( v:foldend - v:foldstart + 1 ) ) ) .
			\		getline( v:foldstart ) .
			\		''
			\	)
	endif

	return ( l:line_fold_result . l:line_fold_suffix )
endfunction

function! b:EVLibTest_RunUtil_TestOutput_Search_Generic( search_expr, search_forward_flag, no_more_matches_msg )
	" save previous search
	let l:saved_register_search = @/
	let l:saved_wrapscan = &wrapscan

	try
		set nowrapscan
		" perform the forward search
		execute ( a:search_forward_flag ? '/' : '?' ) . a:search_expr
		" this only executes when the search has worked
		normal zx
	catch
		if ( ! empty( a:no_more_matches_msg ) )
			echo a:no_more_matches_msg
		endif
	finally
		" no_need?: nohlsearch
		" recover previous search
		let @/ = l:saved_register_search
		let &wrapscan = l:saved_wrapscan
	endtry
endfunction

function! b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail( search_forward_flag )
	call b:EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		b:evlib_test_evtest_evtstd_base_object.c_results_total . '.*' . b:evlib_test_evtest_evtstd_base_object.c_results_fail_suff,
				\		a:search_forward_flag,
				\		'no more suite (total) failures'
				\	)
endfunction

function! b:EVLibTest_RunUtil_TestOutput_SearchGroupFail( search_forward_flag )
	call b:EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		b:evlib_test_evtest_evtstd_base_object.c_results_group . '.*' . b:evlib_test_evtest_evtstd_base_object.c_results_fail_suff,
				\		a:search_forward_flag,
				\		'no more group failures'
				\	)
endfunction

function! b:EVLibTest_RunUtil_TestOutput_SearchTestFail( search_forward_flag )
	call b:EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		b:evlib_test_evtest_evtstd_base_object.c_testline_pref . '.*' . b:evlib_test_evtest_evtstd_base_object.c_gen_tagged_any_failure_suff,
				\		a:search_forward_flag,
				\		'no more test failures'
				\	)
endfunction

function! b:EVLibTest_RunUtil_TestOutput_SearchAnyFail( search_forward_flag )
	call b:EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		b:evlib_test_evtest_evtstd_base_object.c_line_with_tagged_result_pref . '.*' . b:evlib_test_evtest_evtstd_base_object.c_gen_tagged_any_failure_suff,
				\		a:search_forward_flag,
				\		'no more failures of any kind'
				\	)
endfunction

function! b:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( expr )
	let l:rc = !0
	try
		execute 'silent ' . a:expr
	catch
		let l:rc = 0
	endtry
	return l:rc
endfunction

function! b:EVLibTest_RunUtil_TestOutput_Sanitise()
	" save previous search
	let l:saved_register_search = @/

	call b:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( '%g/^\s*$/d' )
	call b:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( '%s/^TEST: \?//' )
	silent 1

	" recover previous search
	let @/ = l:saved_register_search
endfunction

function! b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( regex )
	return b:evlib_test_evtest_evtstd_base_object.c_output_pref_optional . substitute( a:regex, '\^', '', 'g' )
endfunction

function! b:EVLibTest_RunUtil_TestOutput_Process( processor_function_args )
	call b:EVLibTest_RunUtil_TestOutput_Sanitise()
	setl readonly nomodifiable noswapfile

	setl foldexpr=b:EVLibTest_RunUtil_TestOutput_FoldingFun(v:lnum)
	setl foldtext=b:EVLibTest_RunUtil_TestOutput_FoldTextFun()
	setl foldmethod=expr

	" syntax {{{
	" see ':h usr_44.txt'
	"? syntax clear
	let b:current_syntax = "vimevtest"

	"+ execute 'syntax match evtSuiteBegin /' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_suite_begin ) . '/'
	execute 'syntax match evtSuiteBeginBegin /' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_suite_begin ) . '/'
	execute 'syntax match evtDataContentVimScript /' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_any_mid . '\.vim' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_suff . '/'
	execute 'syntax region evtSuiteBeginLine start=/' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_suite_begin ) . '/ end=/$/ contains=evtSuiteBeginBegin,evtDataContentVimScript oneline keepend'

	execute 'syntax match evtGroupBegin /' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_group_withcontent ) . '/'

	execute 'syntax match evtTagLastAny /' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end . '/' . ' contained'

	execute 'syntax match evtTagLastPass /' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_pass . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_suff . '/' . ' contained'
	execute 'syntax match evtTagLastSkipped /' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_pref . b:evlib_test_evtest_evtstd_base_object.c_keyword_tagged_skipped . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end_suff . '/' . ' contained'
	syntax cluster evtTagLastAll contains=evtTagLastAny,evtTagLastPass,evtTagLastSkipped

	"+execute 'syntax match evtTagMidCustom /' . '\[custom\.[^\]]\+\]' . '/' . ' contained'
	execute 'syntax match evtTagMidCustom /' . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_custom_all . '/' . ' contained'
	execute 'syntax match evtTagMidFailure /' . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_failure_all . '/' . ' contained'
	"? execute 'syntax match evtTagMidOther /' . b:evlib_test_evtest_evtstd_base_object.c_tagged_mid_other_all . '/' . ' contained'
	syntax cluster evtTagMidAll contains=evtTagMidCustom,evtTagMidFailure,evtTagMidOther

	execute 'syntax match evtResultHeaderSuite /' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_results_total ) . '/' . ' contained'
	execute 'syntax match evtResultHeaderGroup /' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_results_group ) . '/' . ' contained'
	syntax cluster evtResultHeaderAll contains=evtResultHeaderSuite,evtResultHeaderGroup

	" fix vim parser: {
	execute 'syntax match evtResultResultDataDetail /' . 'tests:\s*[[:digit:]]\+.\{,4}pass:\s*[[:digit:]]\+' . '/' . ' contained'
	execute 'syntax match evtResultResultDataSummary /' . '\(\(\[custom\.results\]\)\|\(rate:\s*[[:digit:]\.%]\+\)\)' . '/' . ' contained'
	syntax cluster evtResultResultDataAll contains=evtResultResultDataSummary,evtResultResultDataDetail

	execute 'syntax match evtDataLineFiller /' . '\( \.\)\+\s*' . '\(' . b:evlib_test_evtest_evtstd_base_object.c_squarebrackets_end . '\)\@=' . '/' . ' contained'

	execute 'syntax region evtTestLine start=/' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_testline_pref ) . '/ end=/$/ contains=@evtTagLastAll,evtDataLineFiller oneline keepend'
	execute 'syntax region evtResultsAll start=/' . b:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( b:evlib_test_evtest_evtstd_base_object.c_results_pref ) . b:evlib_test_evtest_evtstd_base_object.c_results_mid_any . b:evlib_test_evtest_evtstd_base_object.c_results_suff . '\s*' . '/ end=/$/ contains=@evtTagMidAll,@evtTagLastAll,@evtResultResultDataAll,@evtResultHeaderAll oneline keepend'

	" syntax_highlighting {{{
	" calculate which keys (from the ones available below)
	"  we are going to use

	let l:highlight_hasguirunning_flag = has( 'gui_running' )
	let l:highlight_use_standardtypes_flag = 0 " FIXME: parameterise/get from global variable

	if l:highlight_use_standardtypes_flag
		let l:highlight_keys_allowed = [ 'link' ]
	else
		let l:highlight_keys_allowed = [ 'term', 'cterm' ] + ( l:highlight_hasguirunning_flag ? [ 'gui' ] : [] )
		if ( &background == 'light' )
			let l:highlight_keys_allowed += [ 'cterm-light' ] + ( l:highlight_hasguirunning_flag ? [ 'gui-light' ] : [] )
		else
			let l:highlight_keys_allowed += [ 'cterm-dark' ] + ( l:highlight_hasguirunning_flag ? [ 'gui-dark' ] : [] )
		endif
	endif

	let l:highlight_colordict_saved_values = { }
	" elements (see ':h :colorscheme')
	"  [ {group-name}, DICTIONARY_COLORS ]
	"
	"  DICTIONARY_COLORS: entries:
	"   'term': EXPR_FOR_term,
	"   'cterm-dark': EXPR_FOR_cterm_darkback,
	"   'cterm-light': EXPR_FOR_cterm_lightback,
	"   'gui-dark': EXPR_FOR_gui_darkback,
	"   'gui-light': EXPR_FOR_gui_lightback
	"
	"  for each value (attr/expr), you can use:
	"   * '' to avoid setting that;
	"   * '=' to replicate the same value as the previous array element;
	for l:highlight_elem_now in [
			\		[	'evtSuiteBeginBegin', {
			\				'link':			'Identifier',
			\				'term':			'term=bold',
			\				'cterm':		'',
			\				'cterm-dark':	'ctermfg=Cyan',
			\				'cterm-light':	'ctermfg=DarkCyan',
			\				'gui':			'',
			\				'gui-dark':		'guifg=DarkCyan',
			\				'gui-light':	'guifg=DarkCyan',
			\			}
			\		],
			\		[	'evtSuiteBegin', '='
			\		],
			\		[	'evtResultHeaderSuite', '='
			\		],
			\		[	'evtGroupBegin', {
			\				'link':			'Function',
			\				'term':			'term=underline',
			\				'cterm':		'',
			\				'cterm-dark':	'ctermfg=LightBlue',
			\				'cterm-light':	'ctermfg=DarkBlue',
			\				'gui':			'',
			\				'gui-dark':		'guifg=SeaGreen',
			\				'gui-light':	'guifg=Blue',
			\			}
			\		],
			\		[	'evtResultHeaderGroup', '='
			\		],
			\		[	'evtResultResultDataDetail', {
			\				'link':			'Statement',
			\				'term':			'term=bold',
			\				'cterm':		'',
			\				'cterm-dark':	'ctermfg=LightYellow',
			\				'cterm-light':	'ctermfg=DarkYellow',
			\				'gui':			'',
			\				'gui-dark':		'guifg=Yellow',
			\				'gui-light':	'guifg=DarkMagenta',
			\			}
			\		],
			\		[	'evtResultResultDataSummary', '='
			\		],
			\		[	'evtDataContentVimScript', '='
			\		],
			\		[	'evtTagLastAny', {
			\				'link':			'Todo',
			\				'term':			'term=bold,reverse',
			\				'cterm':		'cterm=bold',
			\				'cterm-dark':	'ctermfg=Red',
			\				'cterm-light':	'ctermfg=DarkRed',
			\				'gui':			'gui=bold',
			\				'gui-dark':		'guifg=Red',
			\				'gui-light':	'guifg=DarkRed gui=reverse',
			\			}
			\		],
			\		[	'evtTagMidFailure', '='
			\		],
			\		[	'evtTagLastPass', {
			\				'link':			'String',
			\				'term':			'term=bold',
			\				'cterm':		'cterm=bold',
			\				'cterm-dark':	'ctermfg=Green',
			\				'cterm-light':	'ctermfg=DarkGreen',
			\				'gui':			'',
			\				'gui-dark':		'guifg=Green',
			\				'gui-light':	'guifg=SeaGreen',
			\			}
			\		],
			\		[	'evtTagLastSkipped', {
			\				'link':			'Comment',
			\				'term':			'term=underline',
			\				'cterm':		'',
			\				'cterm-dark':	'ctermfg=Magenta',
			\				'cterm-light':	'ctermfg=DarkMagenta',
			\				'gui':			'gui=bold',
			\				'gui-dark':		'guifg=DarkCyan',
			\				'gui-light':	'guifg=DarkYellow',
			\			}
			\		],
			\		[	'evtTagMidCustom', '='
			\		],
			\		[	'evtDataLineFiller', {
			\				'link':			'Comment',
			\				'term':			'',
			\				'cterm':		'',
			\				'cterm-dark':	'ctermfg=Brown',
			\				'cterm-light':	'ctermfg=Brown',
			\				'gui':			'',
			\				'gui-dark':		'guifg=DarkGreen',
			\				'gui-light':	'guifg=DarkGreen',
			\			}
			\		],
			\	]
		unlet! l:highlight_colordict_now_orig

		let l:highlight_groupname_now = l:highlight_elem_now[ 0 ]
		let l:highlight_colordict_now_orig = l:highlight_elem_now[ 1 ]

		execute 'highlight clear '	. l:highlight_groupname_now
		execute 'highlight link '	. l:highlight_groupname_now . ' NONE'

		if type( l:highlight_colordict_now_orig ) == type( '' )
			if ( l:highlight_colordict_now_orig == '' )
				" skip this entry
				continue
			elseif ( l:highlight_colordict_now_orig == '=' )
				let l:highlight_colordict_now = {
						\			'link':			'=',
						\			'term':			'=',
						\			'cterm':		'=',
						\			'cterm-dark':	'=',
						\			'cterm-light':	'=',
						\			'gui':			'=',
						\			'gui-dark':		'=',
						\			'gui-light':	'=',
						\		}
			endif
		else
			let l:highlight_colordict_now = l:highlight_colordict_now_orig
		endif

		let l:highlight_expr_now = ''
		let l:highlight_colordict_sentence_now = ''
		for l:highlight_colordict_key_now in l:highlight_keys_allowed
			if has_key( l:highlight_colordict_now, l:highlight_colordict_key_now )
				let l:highlight_colordict_expr_now = l:highlight_colordict_now[ l:highlight_colordict_key_now ]
				let l:highlight_colordict_sentence_now_save_flag = !0 " true
				if l:highlight_colordict_expr_now == '='
					" get from saved value
					let l:highlight_colordict_expr_now = ( has_key( l:highlight_colordict_saved_values, l:highlight_colordict_key_now ) ? ( l:highlight_colordict_saved_values[ l:highlight_colordict_key_now ] ) : '' )
					let l:highlight_colordict_sentence_now_save_flag = 0 " false
				endif
				if ( l:highlight_colordict_key_now == 'link' ) && ( ! empty( l:highlight_colordict_expr_now ) )
					let l:highlight_colordict_sentence_now = 'link ' . l:highlight_groupname_now . ' ' . l:highlight_colordict_expr_now
				endif
				if l:highlight_colordict_sentence_now_save_flag
					" save the value (could be empty, and that's fine) for
					"  the next element to use
					let l:highlight_colordict_saved_values[ l:highlight_colordict_key_now ] = l:highlight_colordict_expr_now
				endif
				if ( ! empty( l:highlight_colordict_sentence_now ) )
					break
				endif
				" only process the non-empty values
				if ( ! empty( l:highlight_colordict_expr_now ) )
					let l:highlight_expr_now .= l:highlight_colordict_expr_now . ' '
				endif
			endif
		endfor
		if ( empty( l:highlight_colordict_sentence_now ) )
			let l:highlight_colordict_sentence_now = l:highlight_groupname_now . ' ' . l:highlight_expr_now
		endif
		if ( ! empty( l:highlight_colordict_sentence_now ) )
			execute 'highlight ' . l:highlight_colordict_sentence_now
		endif
	endfor
	" }}}
	" }}}

	for l:map_elem_now in [
				\		[ 'tf', ':call b:EVLibTest_RunUtil_TestOutput_SearchTestFail(1)<CR>' ],
				\		[ 'tF', ':call b:EVLibTest_RunUtil_TestOutput_SearchTestFail(0)<CR>' ],
				\		[ 'gf', ':call b:EVLibTest_RunUtil_TestOutput_SearchGroupFail(1)<CR>' ],
				\		[ 'gF', ':call b:EVLibTest_RunUtil_TestOutput_SearchGroupFail(0)<CR>' ],
				\		[ 'sf', ':call b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)<CR>' ],
				\		[ 'sF', ':call b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail(0)<CR>' ],
				\		[ 'af', ':call b:EVLibTest_RunUtil_TestOutput_SearchAnyFail(1)<CR>' ],
				\		[ 'aF', ':call b:EVLibTest_RunUtil_TestOutput_SearchAnyFail(0)<CR>' ],
				\
				\		[ 'tt', ':call b:EVLibTest_RunUtil_TestOutput_SearchTestFail(1)<CR>' ],
				\		[ 'TT', ':call b:EVLibTest_RunUtil_TestOutput_SearchTestFail(0)<CR>' ],
				\		[ 'gg', ':call b:EVLibTest_RunUtil_TestOutput_SearchGroupFail(1)<CR>' ],
				\		[ 'GG', ':call b:EVLibTest_RunUtil_TestOutput_SearchGroupFail(0)<CR>' ],
				\		[ 'ss', ':call b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)<CR>' ],
				\		[ 'SS', ':call b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail(0)<CR>' ],
				\		[ 'ff', ':call b:EVLibTest_RunUtil_TestOutput_SearchAnyFail(1)<CR>' ],
				\		[ 'FF', ':call b:EVLibTest_RunUtil_TestOutput_SearchAnyFail(0)<CR>' ],
				\
				\	]
		execute 'nmap <silent> <buffer> <Leader>' . l:map_elem_now[ 0 ] . ' ' . l:map_elem_now[ 1 ]
	endfor

	" for now, automatically find the first 'suite' failure
	silent 1 | call b:EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)

	" [debug] echo "done"
endfunction

" set output variable
let g:evlib_test_processor_output = {
			\		'functions': {
			\				'f_process_output': function( 'b:EVLibTest_RunUtil_TestOutput_Process' ),
			\			},
			\	}

" }}} g:evlib_test_processor_operation == 'define_functions'
endif
" }}} g:evlib_test_processor_operation

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
