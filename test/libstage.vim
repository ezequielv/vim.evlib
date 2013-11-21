" test/libstage.vim

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if exists( 'g:evlib_test_libstage_loaded' )
	finish
endif
let g:evlib_test_libstage_loaded = 1
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
" }}}

" }}}

" library stages testing support {{{
" values: 'none', 'all', 'pre', 'post'
let s:evlib_test_common_libstages_throw_script_type = 'none'

" values: 'none', 'all', 'pre', 'post'
function EVLibTest_LibStages_UserScriptSetThrowingScriptType( script_type )
	if ( index( [ 'none', 'all', 'pre', 'post' ], a:script_type ) >= 0 )
		let s:evlib_test_common_libstages_throw_script_type = a:script_type
		return !0 " true
	endif
	call EVLibTest_Util_ThrowTestExceptionInternalError()
	return 0 " false -- just in case
endfunction

" * args:
"  * script_type: 'any', 'pre', 'post'
function EVLibTest_LibStages_UserScriptWouldThrow( script_type )
	let l:script_type = a:script_type
	if ( s:evlib_test_common_libstages_throw_script_type == 'none' )
		return 0
	elseif ( s:evlib_test_common_libstages_throw_script_type == 'all' ) || ( l:script_type == 'any' )
		return !0
	elseif ( s:evlib_test_common_libstages_throw_script_type == l:script_type )
		return !0
	else
		return 0
	endif
endfunction

function EVLibTest_LibStages_UserScriptConditionallyThrow( script_type )
	if EVLibTest_LibStages_UserScriptWouldThrow( a:script_type )
		call EVLibTest_Util_ThrowTestException_Custom( 'TestException' )
	endif
	return !0 " returns 'true' otherwise
endfunction

" returns a list that is to be used directly or added to user options.
" example:
"  [ 'test name', 'test_expression', [ _my_options_ ] +
"   EVLibTest_LibStages_GetDoBatchOptionForUserScriptThatCanThrow( 'any' ) ],
function EVLibTest_LibStages_GetDoBatchOptionForUserScriptThatCanThrow( script_type )
	return (
		\		( EVLibTest_LibStages_UserScriptWouldThrow( a:script_type ) )
		\		?	[ 'code.throws' ]
		\		:	[]
		\	)
endfunction

" IDEA: create a selftest to test evlib#pvt#apiver#SupportsAPIVersion()
function EVLibTest_LibStages_CheckAPIVersion()
	let l:version_v1 = 0
	let l:version_v2 = 1
	let l:version_v3 = 0

	return
				\	evlib#SupportsAPIVersion( l:version_v1, l:version_v2 )
				\	&&
				\	evlib#SupportsAPIVersion( l:version_v1, l:version_v2, l:version_v3 )
endfunction

let g:evlib_test_libstages_counter_to_check = 0
" EVLibTest_LibStages_CheckUpdateCounter( val_check [, val_true [, val_false ] ] )
function EVLibTest_LibStages_CheckUpdateCounter( val_check, ... )
	let l:success = ( g:evlib_test_libstages_counter_to_check == a:val_check )

	if ( ! l:success ) && 0 " [debug]: comment from '&&' onwards to enable this debug message
		call EVLibTest_Gen_InfoMsg( 'failed script counter check.'
			\		. ' expected value: ' . string( a:val_check )
			\		. ( ( a:0 > 0 ) ? ( '; value to be set if true: ' . string( a:1 ) ) : '' )
			\		. ( ( a:0 > 1 ) ? ( '; value to be set if false: ' . string( a:2 ) ) : '' )
			\		. '; actual value: ' . string( g:evlib_test_libstages_counter_to_check )
			\	)
	endif

	" conditionally update
	if l:success && ( a:0 > 0 )
		let g:evlib_test_libstages_counter_to_check = a:1
	endif
	if ( ! l:success ) && ( a:0 > 1 )
		let g:evlib_test_libstages_counter_to_check = a:2
	endif

	return l:success
endfunction

let g:evlib_test_libstages_testtree_libcheck01 = g:evlib_test_common_test_testtrees_rootdir . '/init.01'

let s:evlib_test_libstages_counter_check_test_flags_list = [ 'skiponfail.local' ]

let s:evlib_test_libstages_counter_data_from_scripttype_stageid_dict = {
		\		'none': {
		\				'postinit.1': [ 6, 7, 121 ],
		\				'epilog.1': [ 7, 8, 122 ],
		\				'after.1': [ 8, 10, 123 ],
		\			},
		\		'pre': {
		\				'postinit.1': [ 16, 5, 121 ],
		\				'epilog.1': [ 5, 6, 122 ],
		\				'after.1': [ 6, 10, 123 ],
		\			},
		\		'post': {
		\				'postinit.1': [ 5, 6, 121 ],
		\				'epilog.1': [ 6, 7, 122 ],
		\				'after.1': [ 7, 10, 123 ],
		\			},
		\		'all': {
		\				'postinit.1': [ 4, 5, 121 ],
		\				'epilog.1': [ 5, 6, 122 ],
		\				'after.1': [ 6, 10, 123 ],
		\			},
		\	}
function EVLibTest_LibStages_CheckUpdateCounter_FromStageId( stage_id )
	let l:success = !0 " true

	" not_anymore: " normalise the script type (throwing in 'all' means we are going to throw
	" not_anymore: "  in 'pre' (it should not make 'post' in terms of counter updating)
	" not_anymore: let l:script_type = ( ( s:evlib_test_common_libstages_throw_script_type == 'all' ) ? 'pre' : s:evlib_test_common_libstages_throw_script_type )
	let l:script_type = s:evlib_test_common_libstages_throw_script_type

	let l:success = l:success && has_key( s:evlib_test_libstages_counter_data_from_scripttype_stageid_dict, l:script_type )
	" NOTE: if we leave the 'current script throwing type' as a 'global scope'
	"  variable, we could cache what is stored in l:dict_elem_main, to avoid
	"  an unnecessary hash lookup on every function invocation
	if l:success
		let l:dict_elem_main = s:evlib_test_libstages_counter_data_from_scripttype_stageid_dict[ l:script_type ]
		let l:success = l:success && has_key( l:dict_elem_main, a:stage_id )
	endif
	if l:success
		let l:dict_elem = l:dict_elem_main[ a:stage_id ]
		let l:dict_elem_len = len( l:dict_elem )
		if l:dict_elem_len > 2
			let l:counter_set_value_false = l:dict_elem[ 2 ]
		endif
		if l:dict_elem_len > 1
			let l:counter_set_value_true = l:dict_elem[ 1 ]
		endif
		if l:dict_elem_len > 0
			let l:counter_check_value = l:dict_elem[ 0 ]
		endif
	endif
	if l:success
		if exists( 'l:counter_set_value_false' )
			let l:retval = EVLibTest_LibStages_CheckUpdateCounter( l:counter_check_value, l:counter_set_value_true, l:counter_set_value_false )
		elseif exists( 'l:counter_set_value_true' )
			let l:retval = EVLibTest_LibStages_CheckUpdateCounter( l:counter_check_value, l:counter_set_value_true )
		elseif exists( 'l:counter_check_value' )
			let l:retval = EVLibTest_LibStages_CheckUpdateCounter( l:counter_check_value )
		else
			let l:success = 0 " false
		endif
		" [debug]: call EVLibTest_Gen_InfoMsg( 'hello from libstage - EVLibTest_LibStages_CheckUpdateCounter_FromStageId(). check: ' . string( l:counter_check_value ) . '; set: ' . string( l:counter_set_value_true ) . '; result: ' . string( l:retval ) )
	endif

	if ( ! l:success ) | call EVLibTest_Util_ThrowTestExceptionInternalError() | endif

	return l:retval
endfunction

function EVLibTest_LibStages_GroupSet_UserScriptThrow( throwing_script_type )

	" TODO: we could add a check to make sure that no "user scripts" are
	"  accessible before setting our &runtimepath
	"  (so that we know it is only the "user scripts" under our test tree the
	"  ones that are going to be run)
	"
	"  IDEA: put this into a function (returning "success"), then call that
	"   from here
	"
	call EVLibTest_GroupSet_LoadLibrary_Method_RuntimePathAdjust(
			\		{
			\			'group_title': 'test initialisation stages',
			\			'precheck':
			\				[
			\					[ 'pre-check #1', '!0' ],
			\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
			\					[ 'set user scripts throwing policy', 'EVLibTest_LibStages_UserScriptSetThrowingScriptType( "' . a:throwing_script_type . '" )' ],
			\					[ 'check API version (inaccessible -> throws)', 'EVLibTest_LibStages_CheckAPIVersion()', [ 'code.throws' ] ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 0', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (check only)', 'EVLibTest_LibStages_CheckUpdateCounter( 0 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 0', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter( 0, 1 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 1', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (check and set) ("false")', '! EVLibTest_LibStages_CheckUpdateCounter( 0, 1, 2 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 2', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (check and set) ("false")', '! EVLibTest_LibStages_CheckUpdateCounter( 0, 1, 5 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 5', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter( 5, 1, 10 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 1', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
			\				],
			\			'preinit':
			\				[
			\					[ 'pre-init #1', '!0' ],
			\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter( 1, 2, 101 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check API version (accessible -> "true")', 'EVLibTest_LibStages_CheckAPIVersion()' ],
			\					[ 'call function needing initialised lib (throws)', ':throw EVLibTest_LibStages_ExceptionTest', [ 'code.throws' ] ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter( 2, 3, 102 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\					[ 'check that our test tree is not accessible yet', 'evlib#test#init01#HasAccessToThisTest()', [ 'code.throws' ] ],
			\					[ 'add our test tree to the runtimepath', ':set runtimepath+=' . ( exists( '*fnameescape' ) ? fnameescape( g:evlib_test_libstages_testtree_libcheck01 ) : g:evlib_test_libstages_testtree_libcheck01 ), [ 'skiponfail.all' ] ],
			\					[ 'check that our test tree is now accessible', 'evlib#test#init01#HasAccessToThisTest()', [ 'skiponfail.local' ] ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter( 3, 4, 103 )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\				],
			\			'postinit':
			\				[
			\					[ 'post-init #1', '!0' ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter_FromStageId( "postinit.1" )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\				],
			\			'epilog':
			\				[
			\					[ 'epilog #1', '!0' ],
			\					[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter_FromStageId( "epilog.1" )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\				],
			\		}
			\	)

	call EVLibTest_Do_Batch(
			\		[
			\			{ 'group': 'post-lib initialisation checks' },
			\			[ 'check test counter (check and set)', 'EVLibTest_LibStages_CheckUpdateCounter_FromStageId( "after.1" )', s:evlib_test_libstages_counter_check_test_flags_list ],
			\			[ 'check test counter (manual)', 'g:evlib_test_libstages_counter_to_check == 10', s:evlib_test_libstages_counter_check_test_flags_list ],
			\		]
			\	)

	call EVLibTest_GroupSet_TestLibrary()
endfunction

function EVLibTest_LibStages_FullSuite_UserScriptThrow( suite_title, throwing_script_type )
	call EVLibTest_Start( a:suite_title )

	call EVLibTest_LibStages_GroupSet_UserScriptThrow( a:throwing_script_type )

	call EVLibTest_Finalise()
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
echoerr "the script 'test/libstage.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
