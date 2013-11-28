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
	" save previous search
	let l:saved_register_search = @/

	let l:line = substitute( getline( a:lnum ), s:regex_output_pref, '', '' )

	" recover previous search
	let @/ = l:saved_register_search

	return l:line
endfunction

" test presentation
let s:regex_output_pref = '^TEST: \?'
let s:regex_output_pref_optional = '^\(' . s:regex_output_pref . '\)\?'
let s:regex_squarebrackets_mid_pref = '\['  " prev: '\(\s\)\['
let s:regex_squarebrackets_end_pref = '\['
let s:regex_squarebrackets_end_suff = '\]\s*$'
let s:regex_squarebrackets_end_any_mid = '[^\]]\+'
let s:regex_squarebrackets_end_any_suff = s:regex_squarebrackets_end_any_mid . s:regex_squarebrackets_end_suff
let s:regex_squarebrackets_end = s:regex_squarebrackets_end_pref . s:regex_squarebrackets_end_any_suff
let s:regex_results_pref = '^RESULTS ('
let s:regex_results_mid_any = '[^)]\+'
let s:regex_results_suff = '):'
" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
let s:regex_results_fail_suff = '\[FAIL\]\s*$'
let s:regex_keyword_tagged_pass = 'pass'
let s:regex_keyword_tagged_skipped = 'skipped'
let s:regex_keyword_tagged_failure_pref = 'failed\.'
let s:regex_keyword_tagged_custom_pref = 'custom\.'
let s:regex_tagged_mid_pref = s:regex_squarebrackets_mid_pref
let s:regex_tagged_mid_mid_any = '[^\]]\+'
let s:regex_tagged_mid_suff = '\]'
let s:regex_tagged_mid_failure_all = s:regex_tagged_mid_pref . s:regex_keyword_tagged_failure_pref . s:regex_tagged_mid_mid_any . s:regex_tagged_mid_suff
let s:regex_tagged_mid_custom_all  = s:regex_tagged_mid_pref . s:regex_keyword_tagged_custom_pref . s:regex_tagged_mid_mid_any . s:regex_tagged_mid_suff
let s:regex_tagged_mid_other_all   = s:regex_tagged_mid_pref . '\(\(' . s:regex_keyword_tagged_failure_pref . '\)\|\(' . s:regex_keyword_tagged_custom_pref . '\)\)\@!' . s:regex_tagged_mid_mid_any . s:regex_tagged_mid_suff
let s:regex_gen_tagged_any_failure_suff = s:regex_squarebrackets_end_pref . '\(\(' . s:regex_keyword_tagged_pass . '\)\|\(' . s:regex_keyword_tagged_skipped . '\)\)\@!' . s:regex_squarebrackets_end_any_suff
" example: RESULTS (group total): tests: 4, pass: 1 -- rate: 25.00% [failed.results] [FAIL]
let s:regex_results_group = s:regex_results_pref . 'group total' . s:regex_results_suff
" example: RESULTS (Total): tests: 14, pass: 3 -- [custom.results] [pass]
let s:regex_results_total = s:regex_results_pref . 'Total' . s:regex_results_suff
" example:    test 1 (true) . . . . . . . . . . . . . . . . . . . . . . . [pass]
let s:regex_testline_pref = '^ \{3,}'
let s:regex_testline = s:regex_testline_pref . '.*' . s:regex_squarebrackets_end
" example: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]
let s:regex_suite_begin = '^SUITE: '
let s:regex_suite_header = s:regex_suite_begin
" example: [group 1]
let s:regex_group_begin = '^\['
let s:regex_group_withcontent = s:regex_group_begin . '.*\]\(\(\s*$\)\|\( \[\)\)\@='
let s:regex_line_with_tagged_result_pref = '\(\(' . s:regex_testline_pref . '\)\|\(' . s:regex_results_pref . '\)\)'

function! EVLibTest_RunUtil_TestOutput_FoldingFun( lnum )
	"let l:line_prev    = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum - 1 )
	let l:line_current = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum )
	"let l:line_next    = s:EVLibTest_RunUtil_TestOutput_GetLine( a:lnum + 1 )

	" example: SUITE: suite #10.1: skip local/all test [custom] [{test}/vimrc_10_selftest-ex-local-pass.vim]
	if l:line_current =~ s:regex_suite_begin
		return '>1'
	" example: [group 1]
	elseif l:line_current =~ s:regex_group_begin
		return '>2'
	" example:    test 1 (true) . . . . . . . . . . . . . . . . . . . . . . . [pass]
	elseif l:line_current =~ s:regex_testline
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

" syntax: EVLibTest_RunUtil_TestOutput_FoldTextFun( [ USE_DEFAULT_FOLDING_FUNCTION ] )
"
" args:
"
"  * USE_DEFAULT_FOLDING_FUNCTION (default: use it, if available):
"     whether to use foldtext() or use the internal implementation (which is "tweakable");
"
function! EVLibTest_RunUtil_TestOutput_FoldTextFun( ... )
	let l:regex_results_now = ( ( v:foldlevel == 1 ) ? s:regex_results_total : s:regex_results_group )

	let l:use_default_foldtext = ( ( a:0 > 0 ) ? a:1 : ( !0 ) )
	let l:use_default_foldtext = l:use_default_foldtext && ( exists( '*foldtext' ) )

	let l:line_fold_suffix = ''

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

function! EVLibTest_RunUtil_TestOutput_Search_Generic( search_expr, search_forward_flag, no_more_matches_msg )
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

function! EVLibTest_RunUtil_TestOutput_SearchSuiteFail( search_forward_flag )
	call EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		s:regex_results_total . '.*' . s:regex_results_fail_suff,
				\		a:search_forward_flag,
				\		'no more suite (total) failures'
				\	)
endfunction

function! EVLibTest_RunUtil_TestOutput_SearchGroupFail( search_forward_flag )
	call EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		s:regex_results_group . '.*' . s:regex_results_fail_suff,
				\		a:search_forward_flag,
				\		'no more group failures'
				\	)
endfunction

function! EVLibTest_RunUtil_TestOutput_SearchTestFail( search_forward_flag )
	call EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		s:regex_testline_pref . '.*' . s:regex_gen_tagged_any_failure_suff,
				\		a:search_forward_flag,
				\		'no more test failures'
				\	)
endfunction

function! EVLibTest_RunUtil_TestOutput_SearchAnyFail( search_forward_flag )
	call EVLibTest_RunUtil_TestOutput_Search_Generic(
				\		s:regex_line_with_tagged_result_pref . '.*' . s:regex_gen_tagged_any_failure_suff,
				\		a:search_forward_flag,
				\		'no more failures of any kind'
				\	)
endfunction

function! s:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( expr )
	let l:rc = !0
	try
		execute 'silent ' . a:expr
	catch
		let l:rc = 0
	endtry
	return l:rc
endfunction

function! EVLibTest_RunUtil_TestOutput_Sanitise()
	" save previous search
	let l:saved_register_search = @/

	call s:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( '%g/^\s*$/d' )
	call s:EVLibTest_RunUtil_ExecuteSilentlyNoErrors( '%s/^TEST: \?//' )
	silent 1

	" recover previous search
	let @/ = l:saved_register_search
endfunction

function! s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( regex )
	return s:regex_output_pref_optional . substitute( a:regex, '\^', '', 'g' )
endfunction

" for now, this is the frontend function
" test case:
"  * from a buffer with an output produced by:
"   ~/data/apps/vim/all/init.plugins/ev.vim.evlib$ ( for p in vim-7.0 ; do echo "program: ${p:-default}" && test/bin/run-tests.sh ${p:+-p "$p"} -F /tmp/vim.evlib-test-output-01-vim-7.0.out -c test/vimrc_*-local-*.vim ; done ) 2>&1 | less +G
"   (for example:
"    $ ( cd ~/data/apps/vim/all/init.plugins/ev.vim.evlib/ && vim-7.0 -R /tmp/vim.evlib-test-output-01-vim-7.0.out '+colo default' )
"   )
"  * :tabedit | setl buftype=nofile noswapfile | silent 0r # | $d | 1 | unlet! g:evlib_test_runutil_loaded | source test/runutil.vim | call EVLibTest_RunUtil_TestOutput_Process()
function! EVLibTest_RunUtil_TestOutput_Process()
	call EVLibTest_RunUtil_TestOutput_Sanitise()
	setl readonly nomodifiable noswapfile

	setl foldexpr=EVLibTest_RunUtil_TestOutput_FoldingFun(v:lnum)
	setl foldtext=EVLibTest_RunUtil_TestOutput_FoldTextFun()
	setl foldmethod=expr

	" syntax {{{
	" see ':h usr_44.txt'
	"? syntax clear
	let b:current_syntax = "vimevtest"

	"+ execute 'syntax match evtSuiteBegin /' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_suite_begin ) . '/'
	execute 'syntax match evtSuiteBeginBegin /' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_suite_begin ) . '/'
	execute 'syntax match evtDataContentVimScript /' . s:regex_squarebrackets_end_pref . s:regex_squarebrackets_end_any_mid . '\.vim' . s:regex_squarebrackets_end_suff . '/'
	execute 'syntax region evtSuiteBeginLine start=/' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_suite_begin ) . '/ end=/$/ contains=evtSuiteBeginBegin,evtDataContentVimScript oneline keepend'

	execute 'syntax match evtGroupBegin /' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_group_withcontent ) . '/'

	execute 'syntax match evtTagLastAny /' . s:regex_squarebrackets_end . '/' . ' contained'

	execute 'syntax match evtTagLastPass /' . s:regex_squarebrackets_end_pref . s:regex_keyword_tagged_pass . s:regex_squarebrackets_end_suff . '/' . ' contained'
	execute 'syntax match evtTagLastSkipped /' . s:regex_squarebrackets_end_pref . s:regex_keyword_tagged_skipped . s:regex_squarebrackets_end_suff . '/' . ' contained'
	syntax cluster evtTagLastAll contains=evtTagLastAny,evtTagLastPass,evtTagLastSkipped

	"+execute 'syntax match evtTagMidCustom /' . '\[custom\.[^\]]\+\]' . '/' . ' contained'
	execute 'syntax match evtTagMidCustom /' . s:regex_tagged_mid_custom_all . '/' . ' contained'
	execute 'syntax match evtTagMidFailure /' . s:regex_tagged_mid_failure_all . '/' . ' contained'
	"? execute 'syntax match evtTagMidOther /' . s:regex_tagged_mid_other_all . '/' . ' contained'
	syntax cluster evtTagMidAll contains=evtTagMidCustom,evtTagMidFailure,evtTagMidOther

	execute 'syntax match evtResultHeaderSuite /' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_results_total ) . '/' . ' contained'
	execute 'syntax match evtResultHeaderGroup /' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_results_group ) . '/' . ' contained'
	syntax cluster evtResultHeaderAll contains=evtResultHeaderSuite,evtResultHeaderGroup

	execute 'syntax match evtResultResultDataDetail /' . 'tests:\s*[[:digit:]]\+.\{,4}pass:\s*[[:digit:]]\+' . '/' . ' contained'
	execute 'syntax match evtResultResultDataSummary /' . '\(\(\[custom\.results\]\)\|\(rate:\s*[[:digit:]\.%]\+\)\)' . '/' . ' contained'
	syntax cluster evtResultResultDataAll contains=evtResultResultDataSummary,evtResultResultDataDetail

	execute 'syntax match evtDataLineFiller /' . '\( \.\)\+\s*' . '\(' . s:regex_squarebrackets_end . '\)\@=' . '/' . ' contained'

	execute 'syntax region evtTestLine start=/' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_testline_pref ) . '/ end=/$/ contains=@evtTagLastAll,evtDataLineFiller oneline keepend'
	execute 'syntax region evtResultsAll start=/' . s:EVLibTest_RunUtil_TestOutput_SynMakeRegexAtBeginningOfLine( s:regex_results_pref ) . s:regex_results_mid_any . s:regex_results_suff . '\s*' . '/ end=/$/ contains=@evtTagMidAll,@evtTagLastAll,@evtResultResultDataAll,@evtResultHeaderAll oneline keepend'

	" syntax_highlighting {{{
	if 0
		" TODO: remove from final code? {{{
		highlight clear
		for l:highlight_group_now in [
					\		'evtSuiteBegin',
					\		'evtGroupBegin',
					\		'evtResultHeaderSuite',
					\		'evtResultHeaderGroup',
					\		'evtResultResultDataDetail',
					\		'evtResultResultDataSummary',
					\		'evtResultResultDataAll',
					\		'evtResultsAll',
					\		'evtTagLastAny',
					\		'evtTagLastPass',
					\		'evtTagLastSkipped',
					\	]
			execute 'highlight clear ' . l:highlight_group_now
			execute 'highlight link ' . l:highlight_group_now . ' NONE'
		endfor
		" }}}

		" note: old code: highlight default ...
		highlight link evtSuiteBegin Identifier
		highlight link evtResultHeaderSuite Identifier

		highlight link evtGroupBegin Function
		highlight link evtResultHeaderGroup Function

		highlight link evtResultResultDataDetail Statement
		highlight link evtResultResultDataSummary Statement

		highlight link evtTagLastAny Todo
		highlight link evtTagLastPass String
		highlight link evtTagLastSkipped Comment
	else

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

	endif
	" }}}

	for l:map_elem_now in [
				\		[ 'tf', ':call EVLibTest_RunUtil_TestOutput_SearchTestFail(1)<CR>' ],
				\		[ 'tF', ':call EVLibTest_RunUtil_TestOutput_SearchTestFail(0)<CR>' ],
				\		[ 'gf', ':call EVLibTest_RunUtil_TestOutput_SearchGroupFail(1)<CR>' ],
				\		[ 'gF', ':call EVLibTest_RunUtil_TestOutput_SearchGroupFail(0)<CR>' ],
				\		[ 'sf', ':call EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)<CR>' ],
				\		[ 'sF', ':call EVLibTest_RunUtil_TestOutput_SearchSuiteFail(0)<CR>' ],
				\		[ 'af', ':call EVLibTest_RunUtil_TestOutput_SearchAnyFail(1)<CR>' ],
				\		[ 'aF', ':call EVLibTest_RunUtil_TestOutput_SearchAnyFail(0)<CR>' ],
				\
				\		[ 'tt', ':call EVLibTest_RunUtil_TestOutput_SearchTestFail(1)<CR>' ],
				\		[ 'TT', ':call EVLibTest_RunUtil_TestOutput_SearchTestFail(0)<CR>' ],
				\		[ 'gg', ':call EVLibTest_RunUtil_TestOutput_SearchGroupFail(1)<CR>' ],
				\		[ 'GG', ':call EVLibTest_RunUtil_TestOutput_SearchGroupFail(0)<CR>' ],
				\		[ 'ss', ':call EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)<CR>' ],
				\		[ 'SS', ':call EVLibTest_RunUtil_TestOutput_SearchSuiteFail(0)<CR>' ],
				\		[ 'ff', ':call EVLibTest_RunUtil_TestOutput_SearchAnyFail(1)<CR>' ],
				\		[ 'FF', ':call EVLibTest_RunUtil_TestOutput_SearchAnyFail(0)<CR>' ],
				\
				\	]
		execute 'nmap <silent> <buffer> <Leader>' . l:map_elem_now[ 0 ] . ' ' . l:map_elem_now[ 1 ]
	endfor

	" for now, automatically find the first 'suite' failure
	silent 1 | call EVLibTest_RunUtil_TestOutput_SearchSuiteFail(1)

	" [debug] echo "done"
endfunction

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
