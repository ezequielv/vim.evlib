" test/runutil.vim
"
" needs/includes:
"  * 'source test/base.vim'
"
" output:
"  * overwrites previous functions ('s:'-scoped);
"  * defines the ex command 'EVTestRunFiles';
"
" side effects:
"  * "normal" inclusion control global variables (get/set);
"  * because it includes '.../test/base.vim' (see above), it overwrites the
"     previous value (if it exists) of g:evlib_test_base_object_last
"     (and see in that file which others get affected, too)
"  * TODO: fill this section
"

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

" include our 'base' script (variables, functions) {{{
execute 'source ' . fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/' . 'base.vim'
" save object just created/returned into our own script variable
let s:evlib_test_base_object = g:evlib_test_base_object_last
" }}}

" support functions {{{
let s:evlib_test_runutil_debug = ( ( exists( 'g:evlib_test_runutil_debug' ) ) ? ( g:evlib_test_runutil_debug ) : 0 )

function! s:IsDebuggingEnabled()
	return ( s:evlib_test_runutil_debug != 0 )
endfunction

function! s:DebugMessage( msg )
	if s:IsDebuggingEnabled()
		echomsg '[debug] ' . a:msg
	endif
endfunction

" args:
"  * message_custom: if non-empty, it's appended to the automatically
"     generated 'exception caught' message (separators, if any, are added by
"     this function);
function! s:GetExceptionCaughtMessage( ... )
	let l:message_custom = ( ( a:0 > 0 ) ? ( a:1 ) : '' )

	" (see ':h throw-variables')
	let l:message_exception = ''
	if v:exception != ''
		let l:message_exception = ( 'caught exception "'. v:exception . '" in ' . v:throwpoint )
	else
		let l:message_exception = ( 'nothing caught' )
	endif
	return (
				\		l:message_custom
				\			.
				\			( ( ( ! empty( l:message_exception ) ) && ( ! empty( l:message_custom ) ) ) ? ' -- ' : '' )
				\			.
				\			l:message_exception
				\	)
endfunction

" args:
"  * message_custom: if non-empty, it's appended to the automatically
"     generated 'exception caught' message (separators, if any, are added by
"     this function)
"     (see s:GetExceptionCaughtMessage());
function! s:DebugExceptionCaught( ... )
	if ( ! s:IsDebuggingEnabled() ) | return | endif

	let l:message_custom = ( ( a:0 > 0 ) ? ( a:1 ) : '' )
	return s:DebugMessage( s:GetExceptionCaughtMessage( l:message_custom ) )
endfunction
" }}}

" script-local variables {{{
" for now, runutil.vim lives in the test directory
" TODO: modify this when this file gets moved to another directory
let s:evlib_test_runutil_testdir_evlib_rootdir = fnamemodify( expand( '<sfile>' ), ':p:h' )
" }}}

" TODO: MAYBE: share all these 'fnameescape() wrappers' in a file (maybe put it in 'base.vim', and access it from here)
function! s:EVLibTest_Local_fnameescape( fname )
	if exists( '*fnameescape' )
		return fnameescape( a:fname )
	else
		" (see ':h escape()')
		return escape( a:fname, ' \' )
	endif
endfunction

" TODO: remove function, as I'm not sure it works 100% of the time
"  (seems to /sometimes/ work, so it's probably hitting a vim bug or working
"  those times for the wrong reasons)
function! s:Local_DefineFunctionFromFuncRef( fname, funcref )
	let l:debug_message_prefix = 's:Local_DefineFunctionFromFuncRef(): '

	if ( ! ( type( a:funcref ) == type( function( 's:Local_DefineFunctionFromFuncRef' ) ) ) )
		call s:DebugMessage( l:debug_message_prefix . 'invalid type for a:funcref: ' . string( type( a:funcref ) ) )
	endif
	for l:func_now in [ a:fname, 's:' . a:fname ]
		try
			execute 'delfunction ' . l:func_now
		catch
		endtry
	endfor

	execute 'unlet! ' . a:fname . ' s:' . a:fname
	execute 'let s:' . a:fname . ' = a:funcref'
endfunction

" global/script-local variables {{{
let s:evlib_test_local_evtest_main_subdir_name = 'evtest'
" }}}

" support for message writing to the "current output buffer" {{{

let s:evlib_test_runutil_hasoutputbuffer_flag = 0 " false

" args:
"  processor_defs_data: can be empty;
"  message: string to either send through ':echomsg', 'call append(...)';
"
" returns:
"  != 0 (true): situation has been handled, return immediately;
"  == 0 (false): nothing was done -- carry on as normal;
function! s:EVLibTest_RunUtil_Local_OutputAuto_WriteMessage_Handle_Pre( processor_defs_data, message )
	" TODO: think about this prefix -- do I need it? or should I leave my
	"  caller to format the entire line?
	let l:message_no_processor = 'MESSAGE: ' . ( empty( a:message ) ? '(empty)' : a:message )

	if ( ! s:evlib_test_runutil_hasoutputbuffer_flag )
		echomsg l:message_no_processor
		return !0 " true: handled
	elseif ( empty( a:processor_defs_data ) )
		call append( line( '$' ), l:message_no_processor )
		return !0 " true: handled
	endif
	return 0 " false: carry on
endfunction

" }}}

" high-level (script-local) test output functions {{{

function! s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_Start()
	let l:redirecting_flag = s:evlib_test_base_object.f_testoutput_isredirectingoutput()
	let l:startdict = {
				\		'saved': {
				\				'redir_active': l:redirecting_flag,
				\			},
				\	}
	" enable redirection (if not enabled before)
	if ( ! l:redirecting_flag )
		" FIXME: improve error handling (possibly recording the result of the
		"  f_testoutput_reopen() call, rather than 'redir_active' entry,
		"  above)
		call s:evlib_test_base_object.f_testoutput_reopen()
	endif

	return l:startdict
endfunction

function! s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_End( startdict )
	if ( ! a:startdict.saved.redir_active )
		call s:evlib_test_base_object.f_testoutput_close()
	endif
endfunction

" args:
"  * processor_defs_data: can be empty (handled by
"     s:EVLibTest_RunUtil_Local_OutputAuto_WriteMessage_Handle_Pre());
function! s:EVLibTest_RunUtil_Local_TestOutput_WriteTestContextInfo( processor_defs_data, contextlevel, infostring )
	if s:EVLibTest_RunUtil_Local_OutputAuto_WriteMessage_Handle_Pre( a:processor_defs_data, 'INFO: ' . a:infostring )
		return !0 " handled (in some way)
	endif

	let l:startdict = s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_Start()

	" call user-level 'exported' function
	let l:retvalue = s:evlib_test_base_object.f_processordef_usercall_writetestcontextinfo( a:processor_defs_data, a:contextlevel, a:infostring )

	call s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_End( l:startdict )
	return l:retvalue
endfunction

" args:
"  * processor_defs_data: can be empty (handled by
"     s:EVLibTest_RunUtil_Local_OutputAuto_WriteMessage_Handle_Pre());
function! s:EVLibTest_RunUtil_Local_TestOutput_WriteErrorMessage( processor_defs_data, errormessage )
	if s:EVLibTest_RunUtil_Local_OutputAuto_WriteMessage_Handle_Pre( a:processor_defs_data, 'ERROR: ' . a:errormessage )
		return !0 " handled (in some way)
	endif

	let l:startdict = s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_Start()

	" call user-level 'exported' function
	let l:retvalue = s:evlib_test_base_object.f_processordef_usercall_writeerrormessage( a:processor_defs_data, a:errormessage )

	call s:EVLibTest_RunUtil_Local_TestOutput_InvokeWithRedir_End( l:startdict )
	return l:retvalue
endfunction

" high-level error reporting support {{{

" syntax:
"  s:EVLibTest_RunUtil_Local_TestOutput_ReportExceptionCaught( processor_defs_data [, message_custom ] )
"
" args:
"  * processor_defs_data: can be empty (handled by
"     s:EVLibTest_RunUtil_Local_TestOutput_WriteErrorMessage());
"  * message_custom: if non-empty, it's appended to the automatically
"     generated 'exception caught' message (separators, if any, are added by
"     this function)
"     (see s:GetExceptionCaughtMessage());
function! s:EVLibTest_RunUtil_Local_TestOutput_ReportExceptionCaught( processor_defs_data, ... )
	let l:message_custom = ( ( a:0 > 0 ) ? ( a:1 ) : '' )

	" also produce a debug message (just in case)
	call s:DebugExceptionCaught( l:message_custom )

	return s:EVLibTest_RunUtil_Local_TestOutput_WriteErrorMessage(
				\		a:processor_defs_data,
				\		s:GetExceptionCaughtMessage( l:message_custom )
				\	)
endfunction

" }}}

function! s:EVLibTest_RunUtil_Local_TestOutput_FlushVarToCurrentBuffer()
	if exists( 'g:evlib_test_runutil_testoutput_content' )
		let l:redirecting_flag = s:evlib_test_base_object.f_testoutput_isredirectingoutput()
		" flush redirected output into variable
		if l:redirecting_flag
			call s:evlib_test_base_object.f_testoutput_close()
		endif

		" transform the string into a list made of line elements,
		"  then append each element in that list as a line under
		"  the last line in the current buffer
		call append( line( '$' ), split( g:evlib_test_runutil_testoutput_content, '\n' ) )

		" conditionally re-enable redirection (overwriting previous content)
		if l:redirecting_flag
			call s:evlib_test_base_object.f_testoutput_reopen( !0 )
		else
			" we are not redirecting, so we have to clear up this variable
			"  manually
			let g:evlib_test_runutil_testoutput_content = ''
		endif
	endif
endfunction

" }}}

function! s:EVLibTest_RunUtil_Util_JoinCmdArgs( args_list )
	return join( map( filter( copy( a:args_list ), '! empty( v:val )' ), 'escape( v:val, " \\\"" )' ), ' ' )
endfunction

function! s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( list, list_len_adjust )
	let l:list_len = len( a:list )
	let l:ret_list = ( ( l:list_len < a:list_len_adjust ) ? ( copy( a:list ) + repeat( [ 0 ], ( a:list_len_adjust - l:list_len ) ) ) : a:list )
	return l:ret_list
endfunction

" args:
"  * procflag_find:
"   * if it's a list, we will return true if all the elements have been found;
"   * if it's a string, we will treat it as a list with only one element;
function! s:EVLibTest_RunUtil_Local_ProcessorFlagsHas( procflags_list, procflag_find )
	let l:procflag_find_list = ( ( type( a:procflag_find ) == type( '' ) ) ? [ a:procflag_find ] : a:procflag_find )
	let l:found_all = !0 " true
	for l:procflag_find_now in l:procflag_find_list
		let l:found_all = l:found_all && ( index( a:procflags_list, l:procflag_find_now ) >= 0 )
		if ( ! l:found_all )
			break
		endif
	endfor

	return l:found_all
endfunction

function! s:EVLibTest_RunUtil_Local_SortFun_NormaliseCompResult( comp_result )
	return ( ( a:comp_result == 0 ) ? 0 : ( ( a:comp_result > 0 ) ? 1 : -1 ) )
endfunction

function! s:EVLibTest_RunUtil_Local_VersionValues_Compare( l1, l2 )
	let l:l1_len = len( a:l1 )
	let l:l2_len = len( a:l2 )
	let l:list_len_max = max( [ l1_len, l2_len ] )
	let l:l1 = s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( a:l1, l:list_len_max )
	let l:l2 = s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( a:l2, l:list_len_max )
	for l:index_now in range( l:list_len_max ) " 0 .. len() - 1
		let l:comp_result = l:l1[ l:index_now ] - l:l2[ l:index_now ]
		if l:comp_result != 0
			return s:EVLibTest_RunUtil_Local_SortFun_NormaliseCompResult( l:comp_result )
		endif
	endfor
	" they are equal if we never managed to find a difference
	return 0
endfunction

function! s:EVLibTest_RunUtil_Local_VersionRange_ContainsValue( version_range, version_value )
	return (
			\		( s:EVLibTest_RunUtil_Local_VersionValues_Compare( a:version_range[ 0 ], a:version_value ) <= 0 )
			\		&&
			\		( s:EVLibTest_RunUtil_Local_VersionValues_Compare( a:version_value, a:version_range[ 1 ] ) <= 0 )
			\	)
endfunction

function! s:EVLibTest_RunUtil_Local_Gen_RangesIntersect( range1, range2, function_compare, function_contains_value )
	let l:query_result = 0 " false
	if ( ! l:query_result )
		for l:stage in range( 1, 2 )
			if l:stage == 1
				" check if the maximum of the two 'range start' values is
				"  contained in the other range
				if ( a:function_compare( a:range1[ 0 ], a:range2[ 0 ] ) < 0 )
					let l:range_check_value = a:range2[ 0 ]
					let l:range_check_check = a:range1
				else
					let l:range_check_value = a:range1[ 0 ]
					let l:range_check_check = a:range2
				endif
			elseif l:stage == 2
				" check if the minimum of the two 'range end' values is
				"  contained in the other range
				if ( a:function_compare( a:range1[ 1 ], a:range2[ 1 ] ) < 0 )
					let l:range_check_value = a:range1[ 1 ]
					let l:range_check_check = a:range2
				else
					let l:range_check_value = a:range2[ 1 ]
					let l:range_check_check = a:range1
				endif
			endif

			let l:query_result = a:function_contains_value( l:range_check_check, l:range_check_value )

			if ( l:query_result )
				break
			endif
		endif
	endif

	return l:query_result
endfunction

" returns:
"  < 0 : range1 contains range2 (for now, this is also reported when the ranges are equal);
"  > 0 : range2 contains range1;
"  == 0 : no containment;
function! s:EVLibTest_RunUtil_Local_Gen_ReportRangeContainment( range1, range2, function_contains_value )
	let l:query_result = 0 " no containment by default
	if ( l:query_result == 0 )
		for l:stage in range( 1, 2 )
			if l:stage == 1
				let l:range_check_contained = a:range2
				let l:range_check_container = a:range1
				let l:result_if_contained = -1
			elseif l:stage == 2
				let l:range_check_contained = a:range1
				let l:range_check_container = a:range2
				let l:result_if_contained = 1
			endif

			if	(
					\		( a:function_contains_value( l:range_check_container, l:range_check_contained[ 0 ] ) )
					\		&&
					\		( a:function_contains_value( l:range_check_container, l:range_check_contained[ 1 ] ) )
					\	)
				let l:query_result = l:result_if_contained
				break
			endif
		endif
	endif

	return l:query_result
endfunction

function! s:EVLibTest_RunUtil_Local_VersionRange_Intersect( version_range1, version_range2 )
	return s:EVLibTest_RunUtil_Local_Gen_RangesIntersect(
				\		a:version_range1,
				\		a:version_range2,
				\		function( 's:EVLibTest_RunUtil_Local_VersionValues_Compare' ),
				\		function( 's:EVLibTest_RunUtil_Local_VersionRange_ContainsValue' )
				\	)
endfunction

" return value: see s:EVLibTest_RunUtil_Local_Gen_ReportRangeContainment()
function! s:EVLibTest_RunUtil_Local_VersionRange_ReportContainment( version_range1, version_range2 )
	return s:EVLibTest_RunUtil_Local_Gen_ReportRangeContainment(
				\		a:version_range1,
				\		a:version_range2,
				\		function( 's:EVLibTest_RunUtil_Local_VersionRange_ContainsValue' )
				\	)
endfunction

" args: 
"  * test_processors_groups_list
"  * test_processors_groups_list_elem_commit
function! s:EVLibTest_RunUtil_Local_ProcGroupsAddElem( test_processors_groups_list, test_processors_groups_list_elem_commit )
	let l:success = !0 " true

	" only consider a:test_processors_groups_list_elem_commit non-empty
	"  when it has a non-empty files list
	if ( l:success ) && ( has_key( a:test_processors_groups_list_elem_commit, 'files' ) ) && ( ! ( empty( a:test_processors_groups_list_elem_commit.files ) ) )
		let l:processor_id = a:test_processors_groups_list_elem_commit.processor_id
		if ( s:EVLibTest_RunUtil_Local_ProcessorFlagsHas( a:test_processors_groups_list_elem_commit.procflags, 'file' ) )
			if ( ! has_key( a:test_processors_groups_list_elem_commit, 'processor_defs_data' ) )
				let a:test_processors_groups_list_elem_commit.processor_defs_data = {}
			endif
			" copy the 'file' as the 'processor_script'
			let a:test_processors_groups_list_elem_commit.processor_defs_data.processor_script = l:processor_id
		endif
		if ( !( has_key( a:test_processors_groups_list_elem_commit, 'processor_defs_data' ) ) )
			" FIXME: throw an error: this should never happen
			let l:success = 0 " false
		endif
		if l:success
			call add( a:test_processors_groups_list, deepcopy( a:test_processors_groups_list_elem_commit ) )
		endif
	endif

	" clear/init a:test_processors_groups_list_elem_commit {{{
	if l:success
		" remove all entries in the user's dictionary
		call filter( a:test_processors_groups_list_elem_commit, '0' )
		" extend() it with our entries
		call extend(
				\		a:test_processors_groups_list_elem_commit,
				\		deepcopy(
				\				{
				\					'categtype': 'unknown',
				\					'sort_index': 9999,
				\					'files': [],
				\				},
				\			)
				\	)
	endif
	" }}}

	return l:success
endfunction

" args: 
"  * test_processors_groups_list_elem_commit
"  * test_processors_to_files_map_key_now
"  * test_processors_to_files_map_elem_now
"  * test_processors_to_files_map_elem_categkey_now
"  * (if test_processors_to_files_map_elem_categkey_now == 'versioned') [ test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now ]
function! s:EVLibTest_RunUtil_Local_ProcGroupsElemSetup_Common( test_processors_groups_list_elem_commit, test_processors_to_files_map_key_now, test_processors_to_files_map_elem_now, test_processors_to_files_map_elem_categkey_now, ... )
	let l:success = !0 " true

	let l:test_processors_groups_list_elem_commit = a:test_processors_groups_list_elem_commit
	let l:test_processors_to_files_map_key_now = a:test_processors_to_files_map_key_now
	let l:test_processors_to_files_map_elem_now = a:test_processors_to_files_map_elem_now
	let l:test_processors_to_files_map_elem_categkey_now = a:test_processors_to_files_map_elem_categkey_now
	if ( a:0 > 0 )
		let l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now = a:1
	endif

	" clear/init l:test_processors_groups_list_elem_commit {{{
	if ( l:success )
		let l:process_flag = !0 " true

		let l:test_processors_groups_list_elem_commit.processor_id = l:test_processors_to_files_map_key_now

		if ( l:process_flag )
			for l:dict_key_now in [
						\		'sort_index',
						\		'procflags',
						\	]
				let l:test_processors_groups_list_elem_commit[ l:dict_key_now ] = l:test_processors_to_files_map_elem_now[ l:dict_key_now ]
			endfor
		endif

		if ( l:process_flag )
			let l:test_processors_groups_list_elem_commit.categtype = l:test_processors_to_files_map_elem_categkey_now
			let l:process_flag = l:process_flag && ( has_key( s:evlib_test_local_processors_defs_dict, l:test_processors_groups_list_elem_commit.processor_id ) )
			if ( l:process_flag )
				" find a processor entry in s:evlib_test_local_processors_defs_dict,
				let l:processors_defs_dict_entry_main_now = s:evlib_test_local_processors_defs_dict[ l:test_processors_groups_list_elem_commit.processor_id ]
				let l:process_flag = l:process_flag && ( l:test_processors_to_files_map_elem_categkey_now == l:processors_defs_dict_entry_main_now.categtype )
				let l:processors_defs_dict_entry_leafentries_ref = {}
			endif

			if ( l:process_flag ) && ( l:test_processors_to_files_map_elem_categkey_now == 'versioned' )
				" find the right (processor) version element for the
				"  current entry being processed
				for l:processors_defs_dict_entry_versionlist_entry_now in l:processors_defs_dict_entry_main_now.version_list
					call s:DebugMessage( 'l:processors_defs_dict_entry_versionlist_entry_now loop. l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now: ' . string( l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now ) )
					if s:EVLibTest_RunUtil_Local_VersionRange_ContainsValue(
								\		l:processors_defs_dict_entry_versionlist_entry_now.version_range,
								\		l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version
								\	)
						let l:processors_defs_dict_entry_leafentries_ref = l:processors_defs_dict_entry_versionlist_entry_now
						break
					endif
				endfor
			elseif ( l:process_flag ) && ( l:test_processors_to_files_map_elem_categkey_now == 'plain' )
				let l:processors_defs_dict_entry_leafentries_ref = l:processors_defs_dict_entry_main_now
			endif
			let l:process_flag = l:process_flag && ( ! empty( l:processors_defs_dict_entry_leafentries_ref ) )

			if ( l:process_flag )
				for l:dict_key_now in [
							\		'processor_defs_data',
							\	]
					let l:test_processors_groups_list_elem_commit[ l:dict_key_now ] = l:processors_defs_dict_entry_leafentries_ref[ l:dict_key_now ]
				endfor
			endif
		endif
		" now, we will only report a success if we could "process" this
		"  source entry successfully
		let l:success = l:success && l:process_flag
	endif
	" }}}

	return l:success
endfunction

function! s:EVLibTest_RunUtil_Local_VersionListSortFun( l1, l2 )
	return s:EVLibTest_RunUtil_Local_VersionValues_Compare( a:l1, a:l2 )
endfunction

function! s:EVLibTest_RunUtil_Local_ProcessorsToFilesMapDict_Versioned_SortFun( v1, v2 )
	return s:EVLibTest_RunUtil_Local_VersionListSortFun( v1.version, v2.version )
endfunction

function! s:EVLibTest_RunUtil_Local_ProcessorsGroupsList_SortFun( v1, v2 )
	return s:EVLibTest_RunUtil_Local_SortFun_NormaliseCompResult( ( v1.sort_index - v2.sort_index ) )
endfunction

" data structures:
" 	s:evlib_test_local_processors_defs_dict = {
" 			'evtstd': {
"					'categtype': 'versioned',
"					'version_list': [
"							{
"								'version_range': [ [ 0, 1, 0 ], [ 0, 2, 0 ] ],
"								'processor_defs_data': {
"										'processor_script': 'evtest/proc/evtstd/v0-1-0.vim',
"									},
"							},
"							{
"								'version_range': [ [ 1, 0, 0 ], [ 1, 4, 20 ] ],
"								'processor_defs_data': {
"										'processor_script': 'evtest/proc/evtstd/v1-4-20.vim',
"									},
"							},
"						],
" 				},
" 			'userplain01': {
" 					'categtype': 'plain',
"					'processor_defs_data': {
" 							'processor_script': 'userplain01_out.vim',
" 						},
" 				},
" 			'user01': {
" 					'categtype': 'plain',
"					'processor_defs_data': {
" 							'processor_script': 'user01_out.vim',
" 						},
" 				},
" 		}

" s:EVLibTest_RunUtil_Local_ProcessorDef_Add():
"  * function to udpate s:evlib_test_local_processors_defs_dict from a source dict entry;
"  * syntax: call s:EVLibTest_RunUtil_Local_ProcessorDef_Add( defs_dict_dst, defs_entry_data )
"
"  where a:defs_entry_data = {
"  		'processor_id': ...,
"  		'version_range': ...,
"  		'processor_defs_data': ...,
"  	}
"  or a:defs_entry_data = {
"  		'processor_id': ...,
"  		" no 'version_range' means 'plain' in this context
"  		'processor_defs_data': ...,
"  	}
"  	so the function will:
"  	 * create parent dictionary entries (like a:defs_dict_dst.version_list);
"  	 * validate that an entry is not simultaneously 'versioned' and 'plain';
function! s:EVLibTest_RunUtil_Local_ProcessorDef_Add( defs_dict_dst, defs_entry_data )
	let l:process_flag = !0 " true

	let l:process_flag = l:process_flag && ( has_key( a:defs_entry_data, 'processor_id' ) )
	call s:DebugMessage( 'l:process_flag: ' . string( l:process_flag ) )
	call s:DebugMessage( 'a:defs_dict_dst: ' . string( a:defs_dict_dst ) )
	if l:process_flag
		let l:processor_id = a:defs_entry_data.processor_id
		let l:src_entry_is_versioned = ( has_key( a:defs_entry_data, 'version_range' ) )
		let l:src_categtype = ( l:src_entry_is_versioned ? 'versioned' : 'plain' )
		let l:dst_entry_main_exists_flag = has_key( a:defs_dict_dst, l:processor_id )
		let l:write_entry_flag = ( ! l:dst_entry_main_exists_flag )

		if ( l:dst_entry_main_exists_flag )
			let l:defs_dict_entry_now = a:defs_dict_dst[ l:processor_id ]
		else
			let a:defs_dict_dst[ l:processor_id ] = {
						\		'categtype': l:src_categtype,
						\	}
			let l:defs_dict_entry_now = a:defs_dict_dst[ l:processor_id ]
			if ( l:src_entry_is_versioned )
				call extend( l:defs_dict_entry_now, {
						\			'version_list': [],
						\		}
						\	)
			endif
		endif

		" FIXME: validate that an entry is not simultaneously 'versioned' and 'plain';

		if ( l:src_entry_is_versioned )
			let l:processed_versioned_list = 0 " false
			let l:src_versioned_version_range = a:defs_entry_data.version_range
			let l:src_versioned_entry = {
						\		'version_range': copy( l:src_versioned_version_range ),
						\	}
			for l:version_range_now in l:defs_dict_entry_now.version_list
				" if there is an intersection with an existing one,
				if ( s:EVLibTest_RunUtil_Local_VersionRange_Intersect( l:version_range_now.version_range, l:src_versioned_version_range ) )
					" choose the best fit (only one per non-intersecting ranges)
					let l:version_containment_now = ( s:EVLibTest_RunUtil_Local_VersionRange_ReportContainment( l:version_range_now.version_range, l:src_versioned_version_range ) )
					" if the existing entry contains the range from the 'src' entry,
					if ( l:version_containment_now < 0 )
						" we do nothing: we will stop trying and also mark
						"  that we will not write a dictionary entry
						let l:write_entry_flag = 0 " false
						" mark the versioned list element as processed,
						"  so that we don't add an element for this range
						let l:processed_versioned_list = !0 " true
						break
					" if the 'src' entry range contains the existing one,
					elseif ( l:version_containment_now > 0 )
						" we will replace the existing entry with the 'src' one.
						" first, we will make the dictionary empty
						call filter( l:version_range_now, '0' )
						" then, we will extend the dictionary from our 'src' one
						call extend( l:version_range_now, l:src_versioned_entry )
						" we mark this entry as the one to be written to
						let l:dst_entry_for_leaf_keys = l:version_range_now
						" we make sure we will write to the above dictionary entry
						let l:write_entry_flag = !0 " true
						" mark the versioned list element as processed,
						"  so that we don't add an element for this range
						let l:processed_versioned_list = !0 " true
						break
					" if there is no containment,
					else
						" for now, we keep going
						" (there will be intersecting entries then, but no
						" containment)
					endif
				endif
			endfor
			" if no intersecting entries were found,
			if ( ! l:processed_versioned_list )
				" add this entry as the best fit (to the end)
				call add( l:defs_dict_entry_now.version_list, l:src_versioned_entry )
				" we will write to the element we've just added (at the end)
				let l:dst_entry_for_leaf_keys = l:defs_dict_entry_now.version_list[ -1 ]
				let l:write_entry_flag = !0 " true
			endif
		else
			let l:dst_entry_for_leaf_keys = l:defs_dict_entry_now
		endif

		" write the "leaf" key values
		if ( l:write_entry_flag )
			for l:dict_key_now in [
						\		'processor_defs_data',
						\	]
				let l:dst_entry_for_leaf_keys[ l:dict_key_now ] = deepcopy( a:defs_entry_data[ l:dict_key_now ] )
			endfor
		endif
	endif

	return l:process_flag
endfunction

function! s:EVLibTest_RunUtil_Local_PopulateProcessorDefs( test_files )
	unlet! s:evlib_test_local_processors_defs_dict
	let s:evlib_test_local_processors_defs_dict = {}

	" key: dir (path)
	let l:test_dirs_data = {}

	" take all the files (a:test_files) and extract directory names,
	"  then build a comprehensive list of 'directories'/'parent directories'
	"  to find 'processors' in
	let l:test_dirs = []
	" add default entry(/ies)
	call add( l:test_dirs, s:evlib_test_base_object.c_testdir )
	" add entries from test files
	for l:test_file_now in a:test_files
		let l:test_dir_now = fnamemodify( l:test_file_now, ':p:h' )
		call add( l:test_dirs, l:test_dir_now )
	endfor

	call s:DebugMessage( 'l:test_dirs: ' . string( l:test_dirs ) )
	for l:test_dir_now in l:test_dirs
		if ( ! has_key( l:test_dirs_data, l:test_dir_now ) )
			" for now, we mark the directory as 'processed' early
			let l:test_dirs_data[ l:test_dir_now ] = !0 " true
			" process directory
			for l:scan_dir_parent1 in [
						\		s:evlib_test_local_evtest_main_subdir_name . '/proc'
						\	]
				for l:scanned_dir_now in filter( split( glob( l:test_dir_now . '/' . l:scan_dir_parent1 . '/[a-zA-Z]*' ) ), 'isdirectory(v:val)' )
					call s:DebugMessage( 'processing directory: ' . string( l:scanned_dir_now ) )
					" now we've got a directory name under a semantically
					"  meaningful parent. the 'leaf' is the processor_id
					let l:processor_id = fnamemodify( l:scanned_dir_now, ':t' )
					"? let l:processor_dir_now = fnamemodify( l:scanned_dir_now, ':h' )
					for l:stage in range( 1, 2 )
						if l:stage == 1
							for l:processor_file_now in filter( split( glob( l:scanned_dir_now . '/v[0-9]*.vim' ) ), 'filereadable(v:val)' )
								try
									call s:DebugMessage( ' processing file: ' . string( l:processor_file_now ) )
									let l:version_from_file_string = fnamemodify( l:processor_file_now, ':t:r' )
									let l:regex_processor_file_versioned_vnumber_extractnumber = '\v^v([0-9]-[0-9][0-9-]*)$'

									" validate that the name matches a regex
									"  (to avoid generating invalid version
									"  values)
									if ( !( match( l:version_from_file_string, l:regex_processor_file_versioned_vnumber_extractnumber ) >= 0 ) )
										" file name did not match
										continue
									endif
									" extract only the parts we're interested
									"  in (remove the initial 'v', etc)
									let l:version_from_file_string = substitute( l:version_from_file_string, l:regex_processor_file_versioned_vnumber_extractnumber, '\1', '' )

									let l:version_from_file_list = split( l:version_from_file_string, '[-_]' )

									" if, for whatever reason, we could not
									"  find a proper version, skip this
									"  file
									if ( !( len( l:version_from_file_list ) > 1 ) )
										continue
									endif

									" transform each component into a number
									" TODO: put this into a function, so other
									"  conversions/transformations can do
									"  this, too
									let l:version_from_file_list = map( l:version_from_file_list, 'v:val + 0' )

									" make the start version one with the same
									"  major version, but from the first
									"  available minor version for that major
									"  version ('x.0.0')
									let l:version_range_start = [ l:version_from_file_list[ 0 ], 0, 0 ]

									call s:DebugMessage( '  about to add processor_defs element with version: ' . string( l:version_from_file_list ) )
									call s:EVLibTest_RunUtil_Local_ProcessorDef_Add(
												\		s:evlib_test_local_processors_defs_dict,
												\		{	'processor_id': l:processor_id,
												\			'version_range': [ l:version_range_start, l:version_from_file_list ],
												\			'processor_defs_data': {
												\					'processor_script': l:processor_file_now,
												\				},
												\		}
												\	)
								" LATER: catch " catch all exceptions
									" MAYBE: report the dodgy filename to the user
								endtry
							endfor
						elseif l:stage == 2
						endif
					endfor
				endfor
				" FIXME: also find 'plain' processors directly under l:scan_dir_parent1
			endfor
		endif
	endfor
	unlet l:test_dirs

endfunction

function! EVLibTest_RunUtil_Command_RunTests( ... )
	let l:debug_message_prefix = 'EVLibTest_RunUtil_Command_RunTests(): '

	let l:process_flag = !0 " true
	let l:verbose_flag = 0 " false
	let l:do_help_flag = 0 " false
	" no processor yet (but used in error reporting functions)
	let l:processor_defs_data = {}
	let s:evlib_test_runutil_hasoutputbuffer_flag = 0 " false

	try

		" process command (function) options (arguments) {{{
		if l:process_flag
			let l:test_files = []
			let l:programs_list = []
			let l:options_definitions = [
					\		[	[ '?', '-?' ], 0,
					\				[ 'display help' ]
					\		],
					\		[	[ '-p', '--program', '--programs' ], 1,
					\				[	'PROGRAMS',
					\					[
					\						'specify a list (comma-separated) of programs to run the tests',
					\					]
					\				]
					\		],
					\		[	[ '-v', '--verbose' ], 0,
					\				[
					\					'be more verbose (show commands)',
					\				]
					\		],
					\	]
			let l:options_def_cached = { }
			let l:help_message_options_list = []
			for l:options_def_elem_index_now in range( 0, len( l:options_definitions ) - 1 )
				let l:options_def_elem_now = l:options_definitions[ l:options_def_elem_index_now ]
				let l:options_def_elem_mainoption = ''
				let l:options_def_elem_flagvalue = l:options_def_elem_now[ 1 ]
				let l:options_def_elem_help_list = l:options_def_elem_now[ 2 ]
				let l:options_def_elem_help_use_flag = ( ! empty( l:options_def_elem_help_list ) )
				for l:options_def_elem_inner_now in l:options_def_elem_now[ 0 ]
					if empty( l:options_def_elem_mainoption )
						let l:options_def_elem_mainoption = l:options_def_elem_inner_now
					endif
					let l:options_def_cached[ l:options_def_elem_inner_now ] = {
							\		'mainoption': l:options_def_elem_mainoption,
							\		'arrayindex': l:options_def_elem_index_now,
							\		'hasvalue': l:options_def_elem_flagvalue,
							\		'helplist': l:options_def_elem_help_list
							\	}
					let l:options_def_elem_inner_help_option_now = l:options_def_elem_inner_now
					if l:options_def_elem_flagvalue
						let l:options_def_elem_inner_help_option_now .= ' ' . l:options_def_elem_help_list[ 0 ]
					endif
					if l:options_def_elem_help_use_flag
						let l:help_message_options_list += [ l:options_def_elem_inner_help_option_now ]
					endif
				endfor
				if l:options_def_elem_help_use_flag
					unlet! l:options_def_elem_help_list_lines
					let l:options_def_elem_help_list_lines = l:options_def_elem_help_list[ -1 ]
					" TODO: see if we actually need the copy() call, as the list
					"  addition might result in a separate list object -> no need
					"  to copy that
					let l:help_message_options_list += 
							\	map(
							\			copy( ( ( type( l:options_def_elem_help_list_lines ) == type( '' ) ) ? [ l:options_def_elem_help_list_lines ] : l:options_def_elem_help_list_lines ) + [ '' ] ),
							\			'"   " . v:val'
							\		)
				endif
			endfor
		endif
		if l:process_flag && ( a:0 == 0 )
			let l:do_help_flag = !0 " true
			let l:process_flag = 0 " false
		endif
		if l:process_flag
			let l:arg_is_option_flag = 0 " false
			let l:option_hasvalue_next = 0 " false
			for l:arg_now in a:000
				" standard option processing {{{
				if ( l:option_hasvalue_next )
					let l:arg_is_option_flag = !0 " true
					let l:option_hasvalue_next = 0 " false
				elseif ( has_key( l:options_def_cached, l:arg_now ) )
					let l:arg_is_option_flag = !0 " true
					let l:options_def_cached_now = l:options_def_cached[ l:arg_now ]
					let l:option_main_now = l:options_def_cached_now[ 'mainoption' ]
					let l:option_hasvalue_next = ( l:options_def_cached_now[ 'hasvalue' ] )
					if l:option_hasvalue_next
						" process next option (hopefully the value)
						continue
					endif
				else
					let l:arg_is_option_flag = 0 " false
					let l:option_hasvalue_next = 0 " false
				endif
				" }}}

				if l:arg_is_option_flag
					if	( l:option_main_now == '?' )
						let l:do_help_flag = !0 " true
						let l:process_flag = 0 " false
						break
					elseif	( l:option_main_now == '-p' )
						let l:programs_list += split( l:arg_now, ',', 0 )
					elseif	( l:option_main_now == '-v' )
						let l:verbose_flag = !0 " true
					endif
				else
					" treat it as a file (we could do further validation here)
					let l:test_files += sort( split( glob( l:arg_now ), '\n', 0 ) )
				endif
			endfor
		endif
		" default values {{{
		if l:process_flag
			if ( empty( l:programs_list ) )
				let l:programs_list = [ v:progname ]
			endif
		endif
		" debug information {{{
		if s:IsDebuggingEnabled() && exists( 'l:options_def_cached' )
			" [debug]: call s:DebugMessage( string( l:options_def_cached ) )
		endif
		" }}}
		if l:do_help_flag
			for l:help_line_now in [
					\		'EVTestRunFiles [options] TESTFILES...',
					\		'',
					\		'runs unit tests in TESTFILES, and produces a report with the results',
					\		'',
					\		'options:',
					\		'',
					\	]
					\	+ l:help_message_options_list
					\	+ [
					\	]
				" note: this is needed in ':echo', apparently, so that empty
				"  expressions are not skipped (we want the empty lines)
				echo ( ( ! empty( l:help_line_now ) ) ? l:help_line_now : ' ' )
			endfor
		endif
		" }}}
		" }}}

		" bail out now if there is nothing more for this function to do at this point {{{
		if ! l:process_flag
			return 0
		endif
		" }}}

		" organise the test files (l:test_files) into groups {{{
		let l:test_processors_to_files_map = {}
		let l:test_file_norder_now = 0
		for l:test_file_now in l:test_files
			unlet! l:test_file_defs
			let l:test_file_norder_now += 1
			for l:stage_id_now in range( 1, 5 )
				let l:test_file_defs = {}
				" NOTE: other example values for l:test_file_defs :
				" 	{
				" 		'processor': {
				" 				'file': '/home/user/devel/scripts/vim/evtest/proc/myprocessor.vim',
				" 			},
				" 	}
				"
				" 	{
				" 		'processor': {
				" 				" note: starting with './' will get the same dir
				" 				"  as the file from which this definition was read
				" 				"  from (possible to be stored in a local
				" 				"  variable, to make processing of such entries
				" 				"  more generic)
				" 				'file': './proc/myprocessor.vim',
				" 			},
				" 	}
				"
				" for tests in our "test" directory (note the "keep going" flag):
				" ( 'defs.continue' )
				"
				" 	in a test file:
				" 	{
				" 		'vimmode': 'ex', " other values: 'visual', 'gui'
				" 		'flags': [ 'defs.continue' ],
				" 	}
				"
				" 	then in our test directory:
				" 	{
				" 		'processor': {
				" 				'name': 'evtstd',
				"				" note: alternatively, take the version from
				"				"  another file, which would define the version
				"				"  for which the processor has been coded
				"				'version': [ 0, 1, 0 ],
				" 			},
				" 		" no 'flags' entry -> assume it empty ->
				" 		"	assume 'defs.continue' is not set ->
				" 		"   	stop the 'populate l:test_file_defs' algorithm
				" 	}
				"
				if l:stage_id_now == 1
					" FIXME: "source" the file in a special mode (g:evlib_test_testfile_source_mode == 'getdefs') to get the value to be ultimately stored in l:test_file_defs
					" FIXME: heuristic: calculate from file name (strong match)
					" FIXME: heuristic: calculate from dir names leading to file name (strong match)
				elseif l:stage_id_now == 2
					" FIXME: "definition" file based on the name of the test file
					"  (look in a series of directories)
				elseif l:stage_id_now == 3
					" FIXME: "definition" file *not* based on the name of the test
					"  file (look in a series of directories) -- this is
					"   "cacheable" (as other files in the same dir would have the
					"   exact same output at this stage)
				elseif l:stage_id_now == 4
					" FIXME: heuristic: calculate from file name (weak match)
					" FIXME: heuristic: calculate from dir names leading to file name (weak match)
				elseif l:stage_id_now == 5
					" force our internal "definition" file
					" FIXME: get processor version (and name?) from somewhere else ('c-defs.vim'?)
					" FIXME: (see 'TODO' file): also add a 'Funcref' (or more than
					"  one) to output test information before actually executing
					"  each test
					"  MAYBE: leave that task (define those functions) to another
					"   file, so we keep the "defs" file clean (and only having
					"   "defs"), and also decoupling test definition with actual
					"   script code (as it's currently the case)
					let l:test_file_defs = {
							\		'processor': {
							\				'name': 'evtstd',
							\				'version': [ 0, 1, 0 ],
							\			},
							\	}
				endif
				" FIXME: react to variables set per stage:
				"  FIXME: find definition in specified dir
				" FIXME: do more checks (maybe looking for some required
				"  dictionary keys)
				if ( ! empty( l:test_file_defs ) )
					break
				endif
			endfor
			if ( ! empty( l:test_file_defs ) )
				" NOTE: data structures:
				"  example:
				"   l:test_processors_to_files_map = {
				"			'evtstd': {
				"					'versioned': [
				"							{	'version': [ 0, 1, 0 ],
				"								'files': [ 'file1.vim', 'file2.vim' ],
				"							},
				"							{	'version': [ 0, 2, 0 ],
				"								'files': [ 'file3.vim' ]
				"							},
				"						],
				" 					'sort_index': 1,
				"					'procflags': [],
				"				},
				"			'userplain01': {
				"					'plain': [ 'file_p1.vim', 'file_p2.vim' ],
				" 					'sort_index': 2,
				"					'procflags': [],
				"				},
				"			" note how there is a flag to denote the processor as
				"			"  'resolved' file:
				"			'/home/user/devel/scripts/vim/evtest/proc/myprocessor.vim': {
				"					'plain': [ 'file_f1.vim', 'file_f2.vim' ],
				" 					'sort_index': 3,
				"					'procflags': [ 'file' ],
				"				},
				"			'user01': {
				"					'plain': [ 'file_u1.vim', 'file_u2.vim' ],
				" 					'sort_index': 4,
				"					'procflags': [],
				"				},
				"		}
				"
				" IDEA:
				"  * do not group the files under the same version -> just have a
				"     list of elements like this:
				"     [ VERSION_ELEMENT, FILE ]
				"   * pros/cons:
				"    [=] the existing l:test_processors_to_files_map elements have
				"         got to be iterated anyway, so we don't lose performance;
				"    [+] constant-time insertion time (no lookups, no searches);
				"
				" IDEA:
				"  * make all dictionary entries ('versioned' already is, but
				"     'plain' is not) dictionaries themselves, then add
				"     'sort_index' with the lowest number in the set (':h min()'),
				"     so that we can sort the processor-based groups based on the
				"     "earliest" file for each one (so the group for the first
				"     user-specified file will be processed first, then the group
				"     for the next file that isn't in the same group, and so on)
				"
				" NOTE:
				"  * in the 'version' list, items are sorted (maybe after all
				"     insertions were done?);
				"  * maybe we need an intermediate structure before we are in a
				"     position to populate l:test_processors_to_files_map
				"     efficiently
				"  * processing can then iterate through each processor, and
				"     within each one, each version group and then the 'plain'
				"     one (should not happen normally, but I don't want to dictate
				"     what users can do with this);
				"
				" IDEA: intermediate structure/list:
				" 	l:test_files_processor_data_list = [
				"			[ [ 'file1.vim', 'file2.vim' ], file_defs_01 ],
				"			[ [ 'file3.vim' ], file_defs_02 ],
				"			[ [ 'file_p1.vim', 'file_p2.vim' ], file_defs_03 ],
				"			[ [ 'file_u1.vim', 'file_u2.vim' ], file_defs_04 ],
				"		]
				"	NOTES:
				"	 * constant insertion speed (at the end) when processing
				"	    elements in the l:test_files list;
				"	 * first list element could be a string, rather than a list,
				"	    if that's easier (it probably is);
				"
				call s:DebugMessage( 'l:test_file_defs: ' . string( l:test_file_defs ) )
				let l:test_file_defs_processor_dict = l:test_file_defs.processor
				let l:test_file_defs_processor_hasversion_flag = ( has_key( l:test_file_defs_processor_dict, 'version' ) )
				let l:test_file_defs_processor_isfile_flag = ( has_key( l:test_file_defs_processor_dict, 'file' ) )
				if l:test_file_defs_processor_hasversion_flag && l:test_file_defs_processor_isfile_flag
					" FIXME: report the error: we should not (for now?) have a file with "version" support
				endif
				if ( l:test_file_defs_processor_isfile_flag )
					" FIXME: in the case of a file, we'll want to use a resolved name,
					"  not the literal value specified by our 'source' defs dictionary
					"  entry
					let l:test_processors_to_files_map_key_now = l:test_file_defs_processor_dict.file
				else
					let l:test_processors_to_files_map_key_now = l:test_file_defs_processor_dict.name
				endif
				" create first (empty) element if it does not exist
				if ( ! has_key( l:test_processors_to_files_map, l:test_processors_to_files_map_key_now ) )
					let l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ] = {
								\		'sort_index': l:test_file_norder_now,
								\		'procflags': [],
								\	}
					if l:test_file_defs_processor_hasversion_flag
						let l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ].versioned = []
					else
						let l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ].plain = []
					endif
					if l:test_file_defs_processor_isfile_flag
						call add( l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ].procflags, 'file' )
					endif
				endif
				let l:test_processors_to_files_map_entry_now = l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ]
				if ( l:test_file_defs_processor_hasversion_flag )
					" find an element with 'version' matching the current one
					let l:test_processors_to_files_map_entry_now_versioned_elem_found = {}
					"
					" MAYBE: make this bit more efficient, if necessary
					" NOTE: this 'for' loop could be avoided if we used another
					"  data structure with "references" to existing dictionaries.
					"  something like:
					"   {
					"   	" string_representation_of_version_array: dictionary reference
					"   	'[0, 1, 0]': dict_entry_01,
					"   	'(none)': dict_entry_02,
					"   }
					"   * then, we just use 'has_key()' to detect whether we have
					"      an element matching the version (or the 'plain'
					"      element);
					"   * we can easily create this string representation
					"      ('string(expression)');
					for l:test_processors_to_files_map_entry_now_versioned_elem_now in l:test_processors_to_files_map_entry_now.versioned
						if ( l:test_processors_to_files_map_entry_now_versioned_elem_now.version == l:test_file_defs_processor_dict.version )
							" add element and store its reference in a variable
							let l:test_processors_to_files_map_entry_now_versioned_elem_found = l:test_processors_to_files_map_entry_now_versioned_elem_now
							break
						endif
					endfor
					" if no elements with a matching version were found,
					if empty( l:test_processors_to_files_map_entry_now_versioned_elem_found )
						" we will use the clean (and so far, empty) instance, and
						"  add a few values
						let l:test_processors_to_files_map_entry_now_versioned_elem_found.version = l:test_file_defs_processor_dict.version
						let l:test_processors_to_files_map_entry_now_versioned_elem_found.files = []
						" add a reference to this new dictionary object instance
						"  at the end of the appropriate list
						call add( l:test_processors_to_files_map_entry_now.versioned, l:test_processors_to_files_map_entry_now_versioned_elem_found )
					endif
					let l:test_processors_to_files_map_entry_now_common_files_list = l:test_processors_to_files_map_entry_now_versioned_elem_found.files
					" common processing (existing elements for previous files, or
					"  new element for this file)
				else
					let l:test_processors_to_files_map_entry_now_common_files_list = l:test_processors_to_files_map_entry_now.plain
				endif
				" add the directory(/file) that has lead us to this group
				"  (NOTE: this is so that when trying to find the "processor" for this
				"  group, we can look files up in the right directories)
				call add( l:test_processors_to_files_map_entry_now_common_files_list, l:test_file_now )
			else
				" FIXME: deal with the error -- would this be considered "unexpected"?
				" IDEA: add each one of these to a group without a "processor", so
				"  that they can be run together, but without output processing
				"  (we can write our "test preamble" messages before running each
				"  test, but then each test will create its own output (possible
				"  with each chunk looking different from the previous one)
			endif
		endfor
		call s:DebugMessage( 'l:test_processors_to_files_map: ' . string( l:test_processors_to_files_map ) )
		" }}}

		" populate the list of "processors" accessible/related to the test files being considered {{{
		" note: sets s:evlib_test_local_processors_defs_dict
		call s:EVLibTest_RunUtil_Local_PopulateProcessorDefs( l:test_files )
		" }}}

		" for each group, find its "processor" and other related data {{{
		" data structures:
		" 	l:test_processors_groups_list = [
		" 			{
		" 				'processor_id': 'evtstd',
		" 				'categtype': 'versioned',
		"				'procflags': [],
		" 				"-? 'version_range': [ [ 0, 1, 0 ], [ 0, 2, 0 ] ],
		" 				'sort_index': 1,
		" 				'files': [ 'file1.vim', 'file2.vim', 'file3.vim' ]
		" 				'processor_defs_data': {
		" 						"-? 'process_script_pre': 'evtest/proc/evtstd/p0-1-0.vim',
		" 						'processor_script': 'evtest/proc/evtstd/v0-1-0.vim',
		" 					},
		" 			},
		" 			{
		" 				'processor_id': 'userplain01',
		" 				'categtype': 'plain',
		"				'procflags': [],
		" 				'sort_index': 2,
		" 				'files': [ 'file_p1.vim', 'file_p2.vim' ]
		" 				'processor_defs_data': {
		" 						"-? 'process_script_pre': 'userplain01_pre.vim',
		" 						'processor_script': 'userplain01_out.vim',
		" 					},
		" 			},
		" 			{
		" 				'processor_id': '/home/user/devel/scripts/vim/evtest/proc/myprocessor.vim',
		" 				'categtype': 'plain',
		"				'procflags': [ 'file' ],
		" 				'sort_index': 3,
		" 				'files': [ 'file_f1.vim', 'file_f2.vim' ]
		" 				'processor_defs_data': {
		" 						'processor_script': '/home/user/devel/scripts/vim/evtest/proc/myprocessor.vim',
		" 					},
		" 			},
		" 			{
		" 				'processor_id': 'user01',
		" 				'categtype': 'plain',
		"				'procflags': [],
		" 				'sort_index': 4,
		" 				'files': [ 'file_u1.vim', 'file_u2.vim' ]
		" 				'processor_defs_data': {
		" 						"-? 'process_script_pre': 'user01_pre.vim',
		" 						'processor_script': 'user01_out.vim',
		" 					},
		" 			},
		" 		]
		let l:test_processors_groups_list = []
		"? let l:test_processors_to_files_map_key_last = ''
		" NOTE: the division is entirely based on which processor will take it:
		"  if the processor entry is different than the one used for previous
		"  entries, then we will do this 'add + initialise next' bit
		for l:test_processors_to_files_map_key_now in keys( l:test_processors_to_files_map )
			let l:test_processors_groups_list_elem_commit = {} " empty by default (empty() will be used to detect pending commits)
			let l:test_processors_to_files_map_elem_now = l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ]
			let l:processor_id_now = l:test_processors_to_files_map_key_now
			for l:test_processors_to_files_map_elem_categkey_now in [ 'versioned', 'plain' ]
				" conditionally add pending "groups list" element
				call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem(
							\		l:test_processors_groups_list,
							\		l:test_processors_groups_list_elem_commit
							\	)

				" skip non-existing dictionary entries
				if ( ! has_key( l:test_processors_to_files_map_elem_now, l:test_processors_to_files_map_elem_categkey_now ) )
					continue
				endif

				let l:test_processors_to_files_map_elem_categ_elem_now = l:test_processors_to_files_map_elem_now[ l:test_processors_to_files_map_elem_categkey_now ]

				" skip empty dictionary entries
				if ( empty( l:test_processors_to_files_map_elem_categ_elem_now ) )
					continue
				endif

				if l:test_processors_to_files_map_elem_categkey_now == 'versioned'
					" sort the elements in the 'versioned' list (custom sort order)
					call sort( l:test_processors_to_files_map_elem_categ_elem_now, function( 's:EVLibTest_RunUtil_Local_ProcessorsToFilesMapDict_Versioned_SortFun' ) )
					let l:processors_defs_dict_entry_versionlist_entry_version_range_current = []

					for l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now in l:test_processors_to_files_map_elem_categ_elem_now
						let l:process_create_new_elem_flag = ( empty( l:processors_defs_dict_entry_versionlist_entry_version_range_current ) )
						" if we have not decided to create a new element yet,
						if ( ! l:process_create_new_elem_flag )
							" check whether the current element can be processed
							"  by the processor that is associated to the list
							"  element to be committed
							"  (whose range is cached in
							"  l:processors_defs_dict_entry_versionlist_entry_version_range_current)
							if s:EVLibTest_RunUtil_Local_VersionRange_ContainsValue(
										\		l:processors_defs_dict_entry_versionlist_entry_version_range_current,
										\		l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version
										\	)
								" we will not do anything here, as we will
								"  add the files to the element that will be committed
								"  below
							else
								" set flag so that we add a new element
								let l:process_create_new_elem_flag = !0 " true
							endif
						endif
						if ( l:process_create_new_elem_flag )
							" add the pending element, if there was one
							call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem(
										\		l:test_processors_groups_list,
										\		l:test_processors_groups_list_elem_commit
										\	)

							" find the right version element for the current entry
							"  being processed
							call s:DebugMessage( 's:evlib_test_local_processors_defs_dict: ' . string( s:evlib_test_local_processors_defs_dict ) )
							call s:DebugMessage( 'l:processor_id_now: ' . string( l:processor_id_now ) )
							let l:processors_defs_dict_entry_main_now = s:evlib_test_local_processors_defs_dict[ l:processor_id_now ]

							"- let l:processors_defs_dict_entry_leafentries_ref = {}
							let l:process_found_processors_defs_dict_entry_for_this_version_flag = 0 " false
							for l:processors_defs_dict_entry_versionlist_entry_now in l:processors_defs_dict_entry_main_now.version_list
								if s:EVLibTest_RunUtil_Local_VersionRange_ContainsValue(
											\		l:processors_defs_dict_entry_versionlist_entry_now.version_range,
											\		l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version
											\	)
									"- let l:processors_defs_dict_entry_leafentries_ref = l:processors_defs_dict_entry_versionlist_entry_now
									let l:process_found_processors_defs_dict_entry_for_this_version_flag = !0 " true
									" cache the range associated to our 'processor'
									let l:processors_defs_dict_entry_versionlist_entry_version_range_current = l:processors_defs_dict_entry_versionlist_entry_now.version_range
									break
								endif
							endfor
							if ( l:process_found_processors_defs_dict_entry_for_this_version_flag )
								call s:EVLibTest_RunUtil_Local_ProcGroupsElemSetup_Common(
											\		l:test_processors_groups_list_elem_commit,
											\		l:test_processors_to_files_map_key_now,
											\		l:test_processors_to_files_map_elem_now,
											\		l:test_processors_to_files_map_elem_categkey_now,
											\		l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now
											\	)
							else
								" FIXME: error: we could not find a processor for
								"  this version value
							endif
						endif

						" TODO: CHECK_AND_MAYBEDO: add the current element data to our l:test_processors_groups_list_elem_commit variable
						"  ref: l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version -> 'version_range'
						" add the files to the element that will be committed
						call extend( l:test_processors_groups_list_elem_commit.files, l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.files )
					endfor
					" FIXME: process each element in the 'version' dictionary entry (list)
					" FIXME: when an incompatible version transition has been
					"  found, call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem()
				elseif l:test_processors_to_files_map_elem_categkey_now == 'plain'
					call s:EVLibTest_RunUtil_Local_ProcGroupsElemSetup_Common(
								\		l:test_processors_groups_list_elem_commit,
								\		l:test_processors_to_files_map_key_now,
								\		l:test_processors_to_files_map_elem_now,
								\		l:test_processors_to_files_map_elem_categkey_now
								\	)

					" add the files from 'plain' to our '.files'
					call extend( l:test_processors_groups_list_elem_commit.files, l:test_processors_to_files_map_elem_categ_elem_now )

					" leave to code outside this loop (or next iteration inside
					"  this loop) to actually add this element
					call s:DebugMessage( 'added plain files' )
				else
					" FIXME: handle error (this would be an internal error)
				endif
			endfor
			" conditionally add pending "groups list" element
			call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem(
						\		l:test_processors_groups_list,
						\		l:test_processors_groups_list_elem_commit
						\	)
		endfor
		call sort( l:test_processors_groups_list, function( 's:EVLibTest_RunUtil_Local_ProcessorsGroupsList_SortFun' ) )
		call s:DebugMessage( 'l:test_processors_groups_list: ' . string( l:test_processors_groups_list ) )
		unlet l:test_processors_to_files_map
		" }}}

		" pre-test run initialisations {{{
		" FIXME: load variables for: editor executable, parameters, etc.
		" }}}
		" FIXME: but be careful with externally-specified "redir file"
		"  (l:test_output_file): maybe just use it for the first of these groups
		"  (which would work nicely when there is a single group)
		" run tests, process output {{{
		if l:process_flag
			let l:test_output_file = ''
			let l:test_output_file_temp_flag = 0 " false
			let l:test_output_redirecting_flag = 0 " false
			let l:test_ex_command_pref = ( l:verbose_flag ? '' : 'silent ' )
			try
				" scoped variable(s) initialisation {{{
				let l:test_output_init_flag = 0 " false
				let l:test_output_redir_active_flag = 0 " false
				let l:test_processing_use_tabs = !0 " true
				" }}}
				" process all "grouped" test files {{{
				for l:test_processors_groups_elem_now in l:test_processors_groups_list
					" scoped variable(s) initialisation {{{
					let s:evlib_test_runutil_hasoutputbuffer_flag = 0 " disable until properly initialised
					let l:processor_defs_data = l:test_processors_groups_elem_now.processor_defs_data
					let l:test_processing_createdbuffer_flag = 0 " false

					let l:test_processing_current_savedstate = {}
					if l:test_processing_use_tabs
						call extend( l:test_processing_current_savedstate,
									\		{
									\			'prevtabpage': tabpagenr(),
									\		}
									\	)
					endif
					" }}}
					try
						" one-time initialisations {{{
						if ( ! l:test_output_init_flag )
							let l:test_output_file = s:evlib_test_base_object.f_testoutput_optionalgetredirexpression()
							if ( empty( l:test_output_file ) )
								" create a temporary file
								let l:test_output_file = tempname()
								let l:test_output_file_temp_flag = !0 " true
							endif
							" we don't have to use the same output file, so we'll
							"  make it optional for now (and possibly make it
							"  forcibly use a variable later)
							let l:test_output_runutil_redir_use_variable = !0
							"+ let l:test_output_runutil_redir_use_variable = 0
							" note: splitting the dictionary definition into
							"  several lines triggers E685 in vim-7.0
							" note: ... as does doing that splitting into a
							"  '( expr ? expr1 : expr2 )' construct
							if l:test_output_runutil_redir_use_variable
								let l:test_output_runutil_redir_expression = { 'redir_type': 'var', 'varname': 'g:evlib_test_runutil_testoutput_content', }
							else
								let l:test_output_runutil_redir_expression = l:test_output_file
							endif
							if ( ! s:evlib_test_base_object.f_testoutput_initandopen( 0, l:test_output_runutil_redir_expression ) )
								" FIXME: report the error in a way that would be
								"  picked up by our caller (exception?)
								break " FIXME: see comment above
							endif
							let l:test_output_init_flag = !0 " true
						endif
						" }}}

						" per-processor initialisation {{{
						" initialise the "output" buffer {{{
						if l:test_processing_use_tabs
							" create new tab (with new buffer)
							silent tabedit
						else
							" create new window (with new buffer)
							silent new
						endif
						let l:test_processing_createdbuffer_flag = !0 " true
						setlocal buftype=nofile noswapfile
						let g:evlib_test_runtest_id = ( exists( 'g:evlib_test_runtest_id' ) ? ( g:evlib_test_runtest_id ) : 0 ) + 1
						" done: make this better (or use a timestamp, etc.)
						" IDEA: put all the filenames that the test had at the beginning,
						"  for example (with one of those 'INFO:' lines?)
						"  FIXME: and make that a folding group ("test info", etc.)
						execute l:test_ex_command_pref . 'file ' . '{test-output-' . printf( '%04d', g:evlib_test_runtest_id ) . '}'
						let s:evlib_test_runutil_hasoutputbuffer_flag = !0 " true
						" }}}

						" truncate the file/variable/register before starting to
						"  process this test file group
						call s:evlib_test_base_object.f_testoutput_reopen( !0 )
						call s:evlib_test_base_object.f_testoutput_close()
						" }}}

						" MAYBE: we could initialise 'processor'-related
						"  variables/state here

						" run all tests for each (vim) program {{{
						for l:program_now in l:programs_list
							" per-program initialisation {{{
							"
							" FIXME: invoke vim using a temporary (another
							"  temporary file, possibly *not* user-overrideable)
							"  vim script, so we don't need OS support for long
							"  commands, we don't suffer with OS-specific escaping
							"  (for non-filenames), etc.
							"
							"  NOTE: some arguments should remain arguments
							"   ('-u NONE', '-e', etc.), but the '-c {expr}' are
							"   obvious candidates to go in the vim script file.
							"
							"  NOTE: use writefile() (see ':h writefile()')
							"
							let l:progoptions_pref_list = [
									\		l:program_now, '-f',
									\		'-e',
									\		'--noplugin',
									\		'-U', 'NONE',
									\		'-u', 'NONE',
									\		'-c', ''
									\			. 'let g:evlib_test_outputfile="' . l:test_output_file . '"'
									\			,
									\		'-c', ''
									\			. 'let g:evlib_test_outputfile_truncate=' . l:test_output_runutil_redir_use_variable
									\			,
									\		'-c', ''
									\			. 'let g:evlib_test_info_contextlevelbase=' . 3
									\			,
									\	]
							if s:evlib_test_runutil_debug
								let l:progoptions_pref_list += [
										\		'-c', ''
										\			. 'let g:evlib_test_testrunner_debug=1'
										\			,
										\	]
							endif
							" NOTE: executing vim/gvim uses stdout/stderr, and it can
							"  be quite slow (especially under the GUI)
							"  FIXME: do this per-platform, etc.
							"  FIXME: these redirections made vim pop up a message box
							"   (even more disruptive)
							"-?		\		'>' , '/dev/null',
							"-?		\		'2>' , '/dev/null',
							" NOTE: I don't think I need to call
							"  s:EVLibTest_Local_fnameescape() to escape the
							"  filename here, as
							"  s:EVLibTest_RunUtil_Util_JoinCmdArgs() escapes all
							"  args equally
							let l:progoptions_suff_list = [
									\		'-S', ''
									\			. s:evlib_test_runutil_testdir_evlib_rootdir . '/' . 'testrun.vim'
									\			,
									\	]
							let l:progoptions_pref_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_pref_list )
							let l:progoptions_suff_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_suff_list )
							" }}}

							" write information about the (vim) program currently being used
							call s:EVLibTest_RunUtil_Local_TestOutput_WriteTestContextInfo(
									\		l:processor_defs_data,
									\		1,
									\		'vim program: ' . string( l:program_now )
									\	)

							" run all tests {{{
							for l:test_file_now in l:test_processors_groups_elem_now.files
								" validate current file {{{
								if ( ! filereadable( l:test_file_now ) )
									call s:EVLibTest_RunUtil_Local_TestOutput_WriteErrorMessage(
											\		l:processor_defs_data,
											\		( 'could not find test (script) file ' . string( l:test_file_now ) . ', or file is not readable' )
											\	)

									" do not process this file
									continue
								endif
								" }}}
								" run vim with the right parameters {{{
								try
									" FIXME: write information about the test to be run here
									call s:EVLibTest_RunUtil_Local_TestOutput_WriteTestContextInfo(
											\		l:processor_defs_data,
											\		2,
											\		'about to execute test file: ' . string( l:test_file_now )
											\	)

									if ! l:test_output_runutil_redir_use_variable
										" FIXME: stop redirection here (check l:test_output_redirecting_flag first)
									endif

									let l:progoptions_test_list = [
											\		'-c', ''
											\			. 'let g:evlib_test_testrunner_testscript="' . l:test_file_now . '"'
											\			,
											\	]
									execute l:test_ex_command_pref
											\	.	'! '
											\	.		l:progoptions_pref_string
											\	.		' '
											\	.		s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_test_list )
											\	.		' '
											\	.		l:progoptions_suff_string
									if l:verbose_flag
										execute l:test_ex_command_pref
												\	.	'! ls -l ' . s:EVLibTest_Local_fnameescape( l:test_output_file )
									endif
								catch " all exceptions
									call s:EVLibTest_RunUtil_Local_TestOutput_ReportExceptionCaught(
											\		l:processor_defs_data,
											\		'vim exception thrown executing nested vim instance'
											\	)
								finally
									" FIXME: re-enable redirection here
								endtry
								" }}}
								" append the in-memory redirected output to the current
								"  "test output" buffer {{{
								if l:test_output_runutil_redir_use_variable
									call s:EVLibTest_RunUtil_Local_TestOutput_FlushVarToCurrentBuffer()

									if filereadable( l:test_output_file )
										" add the test produced file to the end of
										"  the current buffer (test output)
										execute l:test_ex_command_pref . '$r ' . s:EVLibTest_Local_fnameescape( l:test_output_file )
										" note: no need to delete the file, as
										"  every test execution will truncate the
										"  file, if it exists
										"  (and there is a 'delete()' in the right
										"  place, below)
									endif
								endif
								" }}}
								" [debug]: throw 'oops'
							endfor
							" }}}
						endfor
						" }}}
						" process the temporary file {{{
						if filereadable( l:test_output_file )
							if ! l:test_output_runutil_redir_use_variable
								" split/create tab, set new buffer attributes
								execute l:test_ex_command_pref . '0r ' . s:EVLibTest_Local_fnameescape( l:test_output_file )
								" remove the last line (which should be empty), which
								"  should belong to the original "clean" buffer
								silent $d
							endif
							" if we have to (temporary file: always, user file:
							"  when?), truncate/delete the file, or make sure that the
							"  next invocation/use will overwrite the file, as opposed
							"  to append to it
							if l:test_output_file_temp_flag && ( ! empty( l:test_output_file ) )
								call delete( l:test_output_file ) " ignore rc for now
							endif
							" FIXME: do proper error handling (do not discard return value)
							call s:evlib_test_base_object.f_processordef_invoke(
										\		l:processor_defs_data,
										\		'f_process_output',
										\		{}
										\	)
						else
							" FIXME: report that no test output was produced?
						endif
						" }}}
					catch " all exceptions
						call s:EVLibTest_RunUtil_Local_TestOutput_ReportExceptionCaught(
									\		l:processor_defs_data,
									\		l:debug_message_prefix .
									\			'running the tests and/or processing the test output has thrown an exception'
									\	)

						let l:test_processing_restore_previous_state_flag = 0 " false

						" TODO: put this in a function (and possibly remove the
						"  dependency on '+byte_offset')
						if has( 'byte_offset' )
							" this needs the '+byte_offset' feature (see ':h line2byte()')
							let l:output_buffer_is_empty = ( byte2line( line('$') + 1 ) <= 1 )
						else
							let l:output_buffer_is_empty = ( ( line('$') == 1 ) && ( match( getline( line('$') ), '^\s*$' ) >= 0 ) )
						endif

						" for now, if the output buffer is empty, we will restore
						"  the previous state
						let l:test_processing_restore_previous_state_flag = l:test_processing_restore_previous_state_flag || ( l:output_buffer_is_empty )
						if l:test_processing_restore_previous_state_flag
							if l:output_buffer_is_empty
								bdelete " remove current buffer
								let s:evlib_test_runutil_hasoutputbuffer_flag = 0 " false (no more output buffer)
							endif
							" restore previous tab page when it makes sense to do
							"  so
							if ( has_key( l:test_processing_current_savedstate, 'prevtabpage' ) )
										\	&& ( tabpagenr() != l:test_processing_current_savedstate.prevtabpage )
								execute 'tabnext ' . l:test_processing_current_savedstate.prevtabpage
							endif
						endif
					endtry
				endfor
				" }}}
			" IDEA: to avoid doing the 'catch': just set a flag at the end of the
			"  'good' code block, and detect that in the 'finally' block, below
			" LATER catch " all exceptions
				" FIXME: optionally enable redirection (maybe looking at
				"  l:test_output_redirecting_flag); display error message;
				" FIXME: re-throw the exception
			finally
				if l:test_output_redirecting_flag
					call s:evlib_test_base_object.f_testoutput_close()
					let l:test_output_redirecting_flag = 0 " false
				endif
				if l:test_output_file_temp_flag && ( ! empty( l:test_output_file ) )
					call delete( l:test_output_file ) " ignore rc for now
				endif
			endtry
		endif
		" }}}

	catch " all exceptions
		call s:EVLibTest_RunUtil_Local_TestOutput_ReportExceptionCaught( l:processor_defs_data )
		" NOTE: we are not re-throwing at the moment (although we probably should)
		"  (NOTE: see ':h rethrow')

	finally
		" to be put in an "outer" 'try..catch..finally' {{{
		let s:evlib_test_runutil_hasoutputbuffer_flag = 0 " false
		" }}}
	endtry
endfunction

" define custom command(s)
command! -bar -nargs=* -complete=file EVTestRunFiles
			\	call EVLibTest_RunUtil_Command_RunTests(<f-args>)

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
