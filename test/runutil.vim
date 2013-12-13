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

" include our 'base' script (variables, functions) {{{
execute 'source ' . fnamemodify( expand( '<sfile>' ), ':p:h' ) . '/' . 'base.vim'
" save object just created/returned into our own script variable
let s:evlib_test_base_object = g:evlib_test_base_object_last
" }}}

function! s:Local_DefineFunctionFromFuncRef( fname, funcref )
	for l:func_now in [ a:fname, 's:' . a:fname ]
		try
			execute 'delfunction ' . l:func_now
		catch
		endtry
	endfor

	execute 'unlet! ' . a:fname . ' s:' . a:fname
	execute 'let s:' . a:fname . ' = a:funcref'
endfunction

" create mappings as if they were the real functions (see ':h Funcref') {{{
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_OptionalGetRedirFilename', s:evlib_test_base_object.f_testoutput_optionalgetredirfilename )
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_InitAndOpen', s:evlib_test_base_object.f_testoutput_initandopen )
call s:Local_DefineFunctionFromFuncRef( 'EVLibTest_TestOutput_Close', s:evlib_test_base_object.f_testoutput_close )
" }}}

" note: this used to be the "front-end" function
function! s:EVLibTest_RunUtil_TestOutput_Process()
	" FIXME: implement properly, or leave all of this to our caller (as we'll
	"  probably need many variables in the context of our caller to determine
	"  which script is to be "sourced" exactly)
	call s:evlib_test_base_object.f_module_load( 'evtest/proc/evtstd/v0-1-0.vim' )
endfunction

function! s:EVLibTest_RunUtil_Util_JoinCmdArgs( args_list )
	return join( map( filter( copy( a:args_list ), '! empty( v:val )' ), 'escape( v:val, " \\" )' ), ' ' )
endfunction

function! s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( list, list_len_adjust )
	let l:list_len = len( a:list )
	let l:ret_list = ( ( l:list_len < a:list_len_adjust ) ? ( copy( a:list ) + repeat( [ 0 ], ( a:list_len_adjust - l:list_len ) ) ) : a:list )
	return l:ret_list
endfunction

function! s:EVLibTest_RunUtil_Local_ProcGroupsAddElem( test_processors_groups_list, test_processors_groups_list_elem_commit )
	" only consider a:test_processors_groups_list_elem_commit non-empty
	"  when it has a non-empty files list
	if ( has_key( a:test_processors_groups_list_elem_commit, 'files' ) ) && ( ! ( empty( a:test_processors_groups_list_elem_commit.files ) ) )
		call add( a:test_processors_groups_list, deepcopy( a:test_processors_groups_list_elem_commit ) )
	endif

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
endfunction

function! s:EVLibTest_RunUtil_Local_VersionListSortFun( l1, l2 )
	let l:l1_len = len( a:l1 )
	let l:l2_len = len( a:l2 )
	let l:list_len_max = max( l1_len, l2_len )
	let l:l1 = s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( a:l1, l:list_len_max )
	let l:l2 = s:EVLibTest_RunUtil_Local_ListAdjustLenMaybeCopy( a:l2, l:list_len_max )
	for l:index_now in range( l:list_len_max ) " 0 .. len() - 1
		let l:comp_result = l:l1[ l:index_now ] - l:l2[ l:index_now ]
		if l:comp_result != 0
			return l:comp_result
		endif
	endfor
	" they are equal if we never managed to find a difference
	return 0
endfunction

function! s:EVLibTest_RunUtil_Local_ProcessorsToFilesMapDict_Versioned_SortFun( v1, v2 )
	return s:EVLibTest_RunUtil_Local_VersionListSortFun( v1.version, v2.version )
endfunction

function! s:EVLibTest_RunUtil_Local_SortFun_NormaliseCompResult( comp_result )
	return ( ( a:comp_result == 0 ) ? 0 : ( ( a:comp_result > 0 ) ? 1 : -1 ) )
endfunction

function! s:EVLibTest_RunUtil_Local_ProcessorsGroupsList_SortFun( v1, v2 )
	return s:EVLibTest_RunUtil_Local_SortFun_NormaliseCompResult( ( v1.sort_index - v2.sort_index ) )
endfunction

function! EVLibTest_RunUtil_Command_RunTests( ... )
	let l:process_flag = !0 " true
	let l:do_help_flag = 0 " false

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
		" no_need_now: return 0
	endif
	" }}}
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
			echomsg '[debug] l:test_file_defs: ' . string( l:test_file_defs )
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
	echomsg '[debug] l:test_processors_to_files_map: ' . string( l:test_processors_to_files_map )
	" }}}

	" for each group, find its "processor" and other related data {{{
	" data structures:
	" 	l:test_processors_groups_list = [
	" 			{
	" 				'name': 'evtstd',
	" 				'categtype': 'versioned',
	"				'procflags': [],
	" 				'version_range': [ [ 0, 1, 0 ], [ 0, 2, 0 ] ],
	" 				'sort_index': 1,
	" 				'process_script_pre': 'evtest/proc/evtstd/p0-1-0.vim',
	" 				'files': [ 'file1.vim', 'file2.vim', 'file3.vim' ]
	" 				'process_script_out': 'evtest/proc/evtstd/v0-1-0.vim',
	" 			},
	" 			{
	" 				'name': 'userplain01',
	" 				'categtype': 'plain',
	"				'procflags': [],
	" 				'sort_index': 2,
	" 				'process_script_pre': 'userplain01_pre.vim',
	" 				'files': [ 'file_p1.vim', 'file_p2.vim' ]
	" 				'process_script_out': 'userplain01_out.vim',
	" 			},
	" 			{
	" 				'name': '/home/user/devel/scripts/vim/evtest/proc/myprocessor.vim',
	" 				'categtype': 'plain',
	"				'procflags': [ 'file' ],
	" 				'sort_index': 3,
	" 				'files': [ 'file_f1.vim', 'file_f2.vim' ]
	" 			},
	" 			{
	" 				'name': 'user01',
	" 				'categtype': 'plain',
	"				'procflags': [],
	" 				'sort_index': 4,
	" 				'process_script_pre': 'user01_pre.vim',
	" 				'files': [ 'file_u1.vim', 'file_u2.vim' ]
	" 				'process_script_out': 'user01_out.vim',
	" 			},
	" 		]
	let l:test_processors_groups_list = []
	"? let l:test_processors_to_files_map_key_last = ''
	for l:test_processors_to_files_map_key_now in keys( l:test_processors_to_files_map )
		let l:test_processors_groups_list_elem_commit = {} " empty by default (empty() will be used to detect pending commits)
		let l:test_processors_to_files_map_elem_now = l:test_processors_to_files_map[ l:test_processors_to_files_map_key_now ]
		let l:test_processors_to_files_map_elem_sortindex_now = l:test_processors_to_files_map_elem_now.sort_index
		let l:test_processors_to_files_map_elem_procflags_now = l:test_processors_to_files_map_elem_now.procflags
		for l:test_processors_to_files_map_elem_categkey_now in [ 'versioned', 'plain' ]
			" conditionally add pending "groups list" element
			call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem( l:test_processors_groups_list, l:test_processors_groups_list_elem_commit )
			let l:test_processors_groups_list_elem_commit.name = l:test_processors_to_files_map_key_now
			let l:test_processors_groups_list_elem_commit.categtype = l:test_processors_to_files_map_elem_categkey_now
			let l:test_processors_groups_list_elem_commit.sort_index = l:test_processors_to_files_map_elem_sortindex_now
			let l:test_processors_groups_list_elem_commit.procflags = l:test_processors_to_files_map_elem_procflags_now

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
				let l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_last_version_list = [ 0, 0 ]
				for l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now in l:test_processors_to_files_map_elem_categ_elem_now
					if l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version[ 0 ] != l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_last_version_list[ 0 ]
						call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem( l:test_processors_groups_list, l:test_processors_groups_list_elem_commit )
						let l:test_processors_groups_list_elem_commit.name = l:test_processors_to_files_map_key_now
						let l:test_processors_groups_list_elem_commit.categtype = l:test_processors_to_files_map_elem_categkey_now
						let l:test_processors_groups_list_elem_commit.sort_index = l:test_processors_to_files_map_elem_sortindex_now
						let l:test_processors_groups_list_elem_commit.procflags = l:test_processors_to_files_map_elem_procflags_now
						" NOTE: done in invoked function: let l:test_processors_groups_list_elem_commit.files = []
						echomsg '[debug] detected major version change. added versioned files up to this point.'
					endif

					" FIXME: add the current element data to our l:test_processors_groups_list_elem_commit variable
					"  ref: l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version -> 'version_range'
					call extend( l:test_processors_groups_list_elem_commit.files, l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.files )

					" save our "last" version list for next iteration's
					"  comparison
					let l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_last_version_list = l:test_processors_to_files_map_elem_categ_elem_now_versioned_elem_now.version
				endfor
				" FIXME: process each element in the 'version' dictionary entry (list)
				" FIXME: when an incompatible version transition has been
				"  found, call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem()
			elseif l:test_processors_to_files_map_elem_categkey_now == 'plain'
				call extend( l:test_processors_groups_list_elem_commit.files, l:test_processors_to_files_map_elem_categ_elem_now )
				" leave to code outside this loop (or next iteration inside
				"  this loop) to actually add this element
				echomsg '[debug] added plain files'
			else
				" FIXME: handle error (this would be an internal error)
			endif
		endfor
		" conditionally add pending "groups list" element
		call s:EVLibTest_RunUtil_Local_ProcGroupsAddElem( l:test_processors_groups_list, l:test_processors_groups_list_elem_commit )
	endfor
	call sort( l:test_processors_groups_list, function( 's:EVLibTest_RunUtil_Local_ProcessorsGroupsList_SortFun' ) )
	echomsg '[debug] l:test_processors_groups_list: ' . string( l:test_processors_groups_list )
	" }}}

	" pre-test run initialisations {{{
	" FIXME: load variables for: editor executable, parameters, etc.
	" }}}
	" FIXME: create an outer loop to iterate through elements of this type:
	"  { 'test_files': LIST_TEST_FILES, 'proc': PROCESSOR_SCRIPT }
	"   (NOTE: we could add more elements)
	" FIXME: but be careful with externally-specified "redir file"
	"  (l:test_output_file): maybe just use it for the first of these groups
	"  (which would work nicely when there is a single group)
	" run tests, process output {{{
	if l:process_flag
		let l:test_output_file = ''
		let l:test_output_file_temp_flag = 0 " false
		let l:test_output_redirecting_flag = 0 " false
		try
			let l:test_output_init_flag = 0 " false
			let l:test_output_redir_active_flag = 0 " false
			" run all tests for each (vim) program {{{
			for l:program_now in l:programs_list
				" one-time initialisations {{{
				if ( ! l:test_output_init_flag )
					let l:test_output_file = s:EVLibTest_TestOutput_OptionalGetRedirFilename()
					if ( empty( l:test_output_file ) )
						" create a temporary file
						let l:test_output_file = tempname()
						let l:test_output_file_temp_flag = !0 " true
					endif
					let g:evlib_test_runtest_id = ( exists( 'g:evlib_test_runtest_id' ) ? ( g:evlib_test_runtest_id ) : 0 ) + 1
					if ( ! s:EVLibTest_TestOutput_InitAndOpen( 0 ) )
						" FIXME: report the error in a way that would be
						"  picked up by our caller (exception?)
						break " FIXME: see comment above
					endif
					let l:test_output_init_flag = !0 " true
				endif
				" }}}

				" per-program initialisation {{{
				" FIXME: start the program directly, not through 'env'
				"  FIXME: add support for specifying a variable *before* our vimrc gets
				"   loaded
				"  FIXME: maybe load it through something else (not '-u'): '-c "let VAR | source TESTFILE"'
				let l:progoptions_pref_list = [
						\		'env',
						\		'EVLIB_VIM_TEST_OUTPUTFILE=' . l:test_output_file,
						\		l:program_now, '-f',
						\		'-e',
						\		'--noplugin',
						\		'-U', 'NONE',
						\		'-u',
						\	]
				" NOTE: option for specifying script to run: '-u "${l_getresults_file_now}"'
				" NOTE: executing vim/gvim uses stdout/stderr, and it can
				"  be quite slow (especially under the GUI)
				"  FIXME: do this per-platform, etc.
				"  FIXME: these redirections made vim pop up a message box
				"   (even more disruptive)
				"-?		\		'>' , '/dev/null',
				"-?		\		'2>' , '/dev/null',
				let l:progoptions_suff_list = [
						\		'+q',
						\	]
				let l:progoptions_pref_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_pref_list )
				let l:progoptions_suff_string = s:EVLibTest_RunUtil_Util_JoinCmdArgs( l:progoptions_suff_list )
				" }}}

				" FIXME: write information about the (vim) program currently being used

				" run all tests {{{
				for l:test_file_now in l:test_files
					" validate current file {{{
					if ( ! filereadable( l:test_file_now ) )
						" FIXME: report the error in l:test_output_file in a way that
						"  will be picked up by s:EVLibTest_RunUtil_TestOutput_Process()

						" do not process this file
						continue
					endif
					" }}}
					" run vim with the right parameters {{{
					try
						" FIXME: write information about the test to be run here

						" FIXME: stop redirection here

						" FIXME: execute the commands silently (':h :silent'),
						"  and display "friendly" messages instead
						execute '! '
								\	.	l:progoptions_pref_string
								\	.	' '
								\	.	s:EVLibTest_RunUtil_Util_JoinCmdArgs( [ l:test_file_now ] )
								\	.	' '
								\	.	l:progoptions_suff_string
						execute '! ls -l ' . l:test_output_file
					catch " all exceptions
						" FIXME: record an error string if the test failed (do it in a way
						"  that will be shown to the user appropriately
					finally
						" FIXME: re-enable redirection here
					endtry
					" }}}
				endfor
				" }}}
			endfor
			" }}}
			" process the temporary file {{{
			if filereadable( l:test_output_file )
				" split/create tab, set new buffer attributes
				execute 'tab sview ' . l:test_output_file
				setlocal buftype=nofile noswapfile
				" done: make this better (or use a timestamp, etc.)
				" IDEA: put all the filenames that the test had at the beginning,
				"  for example (with one of those 'INFO:' lines?)
				"  FIXME: and make that a folding group ("test info", etc.)
				execute 'file ' . '{test-output-' . printf( '%04d', g:evlib_test_runtest_id ) . '}'
				call s:EVLibTest_RunUtil_TestOutput_Process()
			else
				" FIXME: report that no test output was produced?
			endif
			" }}}
		" IDEA: to avoid doing the 'catch': just set a flag at the end of the
		"  'good' code block, and detect that in the 'finally' block, below
		" LATER catch " all exceptions
			" FIXME: optionally enable redirection (maybe looking at
			"  l:test_output_redirecting_flag); display error message;
			" FIXME: re-throw the exception
		finally
			if l:test_output_redirecting_flag
				call s:EVLibTest_TestOutput_Close()
				let l:test_output_redirecting_flag = 0 " false
			endif
			if l:test_output_file_temp_flag && ( ! empty( l:test_output_file ) )
				call delete ( l:test_output_file ) " ignore rc for now
			endif
		endtry
	endif
	" }}}
	" [debug]: echo '[debug] ' . string( l:options_def_cached )
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
