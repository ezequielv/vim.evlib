" extend the runtimepath

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'rtpath' ) )
	finish
endif
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" support functions {{{
function s:DebugMessage( msg )
	return evlib#debug#DebugMessage( a:msg )
endfunction
" }}}

" function evlib#rtpath#ExtendRuntimePath( path_or_paths [, flags ] ) {{{
"
" extend runtimepath with each path in the list
" 	each path is prepended to the current value of 'runtimepath' in the
" 	same order, and '{element}/after' appended after the current value of
" 	'runtimepath'.
"
" flags: one or more of the following
"
"  'd': force directory detection: only add existing directories;
"        (default is to add the entry without checking)
"  'l': leave entries as they are:
"        * do not expand vim and system environment variables
"           (expand() does not get called);
"  'a': make each directory an absolute path
"           (fnamemodify( {path}, ':p' ) gets called
"           for each {path} in the list);
"
" notes:
"
" 	* each item is expanded through 'expand()' prior to it being added;
"
" example:
" # on entry: runtimepath='path1,path2'
" :call evlib#rtpath#ExtendRuntimePath( [ 'added1', 'added2' ] )
" # on exit: runtimepath='added1,added2,path1,path2,added2/after,added1/after'
function evlib#rtpath#ExtendRuntimePath( path_or_paths, ... )
	let l:debug_message_prefix = 'evlib#rtpath#ExtendRuntimePath(): '

	if type( a:path_or_paths ) == type( '' )
		let l:paths = [ a:path_or_paths ]
	else
		if !( type( a:path_or_paths ) == type( [] ) )
			echoerr l:debug_message_prefix . 'type of argument path_or_paths is invalid. it should be either a list of strings or a string.'
		endif
		let l:paths = a:path_or_paths
	endif
	let l:flags = ( ( a:0 > 0 ) ? a:1 : '' )
	let l:flag_checkdirectory = ( stridx( l:flags, 'd' ) >= 0 )
	let l:flag_leavepathalone = ( stridx( l:flags, 'l' ) >= 0 )
	let l:flag_makeabsolute   = ( stridx( l:flags, 'a' ) >= 0 )

	" NOTE: order is the one you would expect, if this list were to be
	"  added at the beginning (of the runtimepath list)
	"
	" no need to use deepcopy(), as we will not modify the list elements
	" note: we need a copy because reverse() changes the list 'in place'
	for l:path_now in reverse( copy( l:paths ) )
		" apply transformations {{{
		if ! l:flag_leavepathalone
			" expand variables
			let l:path_now = expand( l:path_now )
		endif
		if l:flag_makeabsolute
			" make path absolute (see ':h filename-modifiers')
			let l:path_now = fnamemodify( l:path_now, ':p' )
		endif
		" get rid of the last '/', if there is one
		if ( len( l:path_now ) > 1 ) && ( l:path_now[ -1: ] == '/' )
			let l:path_now = l:path_now[ :-2 ]
		endif
		" }}}

		" pre-validation {{{
		if ( len( l:path_now ) == 0 )
			continue
		endif
		" }}}

		call s:DebugMessage( l:debug_message_prefix . ' processing directory entry: "' . l:path_now . '"' )

		" conditionally add directories to 'runtimepath' {{{
		for l:stage_elem_now in [
				\		[ '', '^' ],
				\		[ '/after', '+' ],
				\	]
			" manipulate entry
			let l:path_now = l:path_now . l:stage_elem_now[ 0 ]
			" see whether we should process this entry
			if !( ( !( l:flag_checkdirectory ) || isdirectory( l:path_now ) ) )
				continue
			endif
			let l:path_now_escaped = evlib#compat#fnameescape( l:path_now )
			" remove previous instances of this path from 'runtimepath' {{{
			for l:stage_path_remove in range( 1, 2 )
				let l:path_now_to_remove = ''
				" deal with the entry as it is
				if ( l:stage_path_remove == 1 )
					let l:path_now_to_remove = l:path_now
				elseif ( l:stage_path_remove == 2 )
					" deal with entries that do not have the trailing '/'
					if ( len( l:path_now ) > 1 ) && ( l:path_now[ -1: ] == '/' )
						" get rid of the last '/'
						let l:path_now_to_remove = l:path_now[ :-2 ]
					endif
				endif
				if ( len( l:path_now_to_remove ) > 0 )
					" remove it if it was present in the list already
					exec 'set runtimepath-=' . evlib#compat#fnameescape( l:path_now_to_remove )
				endif
			endfor
			" }}}
			" add it in the right place
			exec 'set runtimepath' . l:stage_elem_now[ 1 ]  . '=' . l:path_now_escaped
		endfor
		" }}}
	endfor
endfunction
" }}}

" syntax: evlib#rtpath#CheckVimVersion( vim_version, [ vim_patchlevel [, vim_features ] ] )
" returns:
"  == 0: false;
"  != 0: true;
function evlib#rtpath#CheckVimVersion( vim_version, ... )
	let l:debug_message_prefix = 'evlib#rtpath#CheckVimVersion(): '

	let l:vim_patchlevel = 0
	let l:vim_features = []
	if ( a:0 >= 1 )
		" debug: call s:DebugMessage( l:debug_message_prefix . ' a:1: ' . string( a:1 ) )
		let l:vim_patchlevel = a:1
	endif
	if ( a:0 >= 2 )
		" debug: call s:DebugMessage( l:debug_message_prefix . ' a:2: ' . string( a:2 ) )
		let l:vim_features = a:2
	endif

	if !( v:version >= a:vim_version )
		return 0
	endif
	" note: patch level is only meaningful when the major+minor matches the
	"  currently running vim
	if ( l:vim_patchlevel > 0 ) && ( v:version == a:vim_version )
		if !( has( 'patch' . l:vim_patchlevel ) )
			return 0
		endif
	endif
	for l:feature_now in l:vim_features
		if !( has( l:feature_now ) )
			return 0
		endif
	endfor
	return 1
endfunction

function s:ExtendVersionedRuntimePath_FilterElement( elem )
	return evlib#rtpath#CheckVimVersion( a:elem['ver_main'], a:elem['ver_patch'], a:elem['features'] )
endfunction

function s:ExtendVersionedRuntimePath_CompareElements( v1, v2 )
	" for now, we order later versions first
	let l:compare_result = -( a:v1['version'] - a:v2['version'] )
	if l:compare_result == 0
		let l:compare_result = a:v1['rootdir_order'] - a:v2['rootdir_order']
	endif
	if l:compare_result == 0
		" TODO: implement a user order (for example, through a '_{user_order}', just after the optional patch level),
		"  and compare it here
	endif
	return l:compare_result
endfunction

" args:
"  * path_paths_or_elements: either:
"   * string: single path (see element being a string);
"   * list: each element:
"    * string: interpret element as "[ element_value, 'all' ]";
"    * element: a tuple: "[ element_value, inclusion_method ]";
"     * inclusion method:
"      * 'all': all the subdirectories that match the version criteria;
"      * 'one': the most "advanced" (the one referring to the latest version) of the version checks;
"
" examples:
"  * evlib#rtpath#ExtendVersionedRuntimePath( [ '~/mydir', 'all' ] )
"     equivalent to: evlib#rtpath#ExtendVersionedRuntimePath( [ '~/mydir' ] )
"     equivalent to: evlib#rtpath#ExtendVersionedRuntimePath( '~/mydir' )
"
" version matching criteria:
"  for each versioned directory, the format is the following:
"   {major_minor_in_v:version_format}[.{patch_level}][-{features_list}]
"  with each feature separated by '.'.
"
"  so, for a subdirectory with plugins for vim version 7.3.240 and later,
"   for unix, and with the features 'visual' and 'windows', your subdirectory
"   name should be:
"    703.240-unix.visual.windows
"
"  * for plugins for vim 7.0 and later (all platforms): '700';
"  * for plugins for vim 6.3 and later (unix): '603-unix';
"
function evlib#rtpath#ExtendVersionedRuntimePath( path_paths_or_elements )
	let l:debug_message_prefix = 'evlib#rtpath#ExtendVersionedRuntimePath(): '

	if type( a:path_paths_or_elements ) == type( '' )
		let l:paths = [ a:path_paths_or_elements ]
	else
		" this does reference copy on lists
		let l:paths = a:path_paths_or_elements
	endif
	if !( type( l:paths ) == type( [] ) )
		echoerr l:debug_message_prefix . 'type of argument path_paths_or_elements is invalid. check this function documentation.'
	endif
	" l:version_list: elements are dictionaries of the following form
	" ('key': value):
	"  'version': numeric id representing version (sortable as a number);
	"    (example: for a directory: '701.3' -> 701.0003 or 7010003)
	"  'path': path to be considered if adding this element to vim's
	"   runtime (and others?) -- to call evlib#rtpath#ExtendRuntimePath()
	"   with;
	"  'ver_main': the "main" part of the version (corresponds to
	"   v:version);
	"    (example: for a directory '701.3' -> 701)
	"  'ver_patch': the "patch" part of the version (corresponds to
	"   the "patch version" in vim (see ':h has-patch');
	"    (example: for a directory '701.3' -> 3)
	"  'features': (list) features to be checked for. you'd expect
	"   the 'eval' expression 'has({feature})' to be non-zero for
	"   every feature that is present in the current version of vim.
	"  'rootdir_order': (number) position of items in this list with
	"   respect to others with the same value for 'version'.
	"
	let l:version_list = []
	let l:rootdir_order_now = 0

	" process all elements in the list in the right versioned order, even
	"  accross elements
	for l:paths_element_now in l:paths
		let l:rootdir_order_now += 1

		" process 'default' list elements
		if type( l:paths_element_now ) == type( '' )
			let l:paths_element_now_prev = l:paths_element_now
			unlet l:paths_element_now
			let l:paths_element_now = [ l:paths_element_now_prev, 'all' ]
			unlet l:paths_element_now_prev
		endif
		if !( ( type( l:paths_element_now ) == type( [] ) ) && ( len( l:paths_element_now ) >= 2 ) )
			echoerr l:debug_message_prefix . 'list element ' . l:rootdir_order_now . ' is invalid. skipping.'
			continue
		endif
		call s:DebugMessage( l:debug_message_prefix . ' processing directory entry: "' . string( l:paths_element_now ) . '"' )
		" expand variables here, so that the debug message is useful
		let l:paths_element_now[ 0 ] = expand( l:paths_element_now[ 0 ] )
		call s:DebugMessage( l:debug_message_prefix . '  expanded directory: "' . l:paths_element_now[ 0 ] . '"' )

		" initialise the list for this l:paths_element_now
		let l:version_list_now = []

		" process directories of the right "form" under the given
		"  "root" directory
		" TODO: make sure we did not mean to split at '\n' (it's using the
		"  default (white space separator))
		for l:paths_element_now_subdir in sort( split( glob( fnamemodify( l:paths_element_now[ 0 ], ':p' ) . '[0-9][0-9][0-9]*' ) ) )
			if !( isdirectory( l:paths_element_now_subdir ) )
				call s:DebugMessage( l:debug_message_prefix . '  skipping non-directory entry "' . l:paths_element_now_subdir . '"' )
				continue
			endif

			" create the dictionary element
			let l:version_list_elem = { }

			let l:version_list_elem['path'] = l:paths_element_now_subdir
			let l:version_list_elem['rootdir_order'] = l:rootdir_order_now

			" decompose subdirectory name into parts
			let l:path_value_toparse = fnamemodify( l:paths_element_now_subdir, ':t' )

			" vim version (key: 'ver_main') {{{
			let l:path_value_matchindex = match( l:path_value_toparse, '^[0-9]\+' )
			if !( l:path_value_matchindex >= 0 )
				call s:DebugMessage( l:debug_message_prefix . '  skipping malformed subdir component (vim version): "' . l:path_value_toparse . '"' )
				continue
			endif
			" note: match() returns '-1' if there is no match
			" example: "echo 'hello'[2:-1]" -> "llo"
			let l:path_value_matchindex = match( l:path_value_toparse, '[^0-9]' )
			" note: (see ':h octal') adding '+0' to force conversion to number
			let l:version_list_elem['ver_main'] = l:path_value_toparse[ 0 : ( ( l:path_value_matchindex >= 0 ) ? ( l:path_value_matchindex - 1 ) : l:path_value_matchindex ) ] + 0
			let l:path_value_toparse = ( ( l:path_value_matchindex >= 0 ) ? l:path_value_toparse[ l:path_value_matchindex : ] : '' )
			" }}}
			" patch level (key: 'ver_patch') {{{
			let l:path_value_matchindex = match( l:path_value_toparse, '\.[0-9]' )
			unlet! l:path_value_component
			let l:path_value_component = 0 " default
			if ( l:path_value_matchindex == 0 )
				let l:path_value_toparse = l:path_value_toparse[ 1: ] " skip separator
				let l:path_value_matchindex = match( l:path_value_toparse, '[^0-9]' )
				let l:path_value_component = l:path_value_toparse[ 0 : ( ( l:path_value_matchindex >= 0 ) ? ( l:path_value_matchindex - 1 ) : l:path_value_matchindex ) ] + 0
				let l:path_value_toparse = ( ( l:path_value_matchindex >= 0 ) ? l:path_value_toparse[ l:path_value_matchindex : ] : '' )
			endif
			let l:version_list_elem['ver_patch'] = l:path_value_component
			" }}}
			" version as a number (key: 'version') {{{
			"  now using
			"   l:version_list_elem[ 'ver_main' ] and
			"   l:version_list_elem[ 'ver_patch' ]
			let l:version_list_elem['version'] = ( l:version_list_elem['ver_main'] * 10000 ) + l:version_list_elem['ver_patch']
			" }}}
			" features (key: 'features') {{{
			let l:path_value_matchindex = match( l:path_value_toparse, '-' )
			unlet! l:path_value_component
			let l:path_value_component = [] " default
			if ( l:path_value_matchindex == 0 )
				let l:path_value_toparse = l:path_value_toparse[ 1: ] " skip separator
				let l:path_value_component = split( l:path_value_toparse, '\.' )
				let l:path_value_toparse = ''
			endif
			" borrow the newly created list reference (store it in the
			"  dictionary element)
			let l:version_list_elem['features'] = l:path_value_component
			" }}}
			" validation {{{
			if ( len( l:path_value_toparse ) > 0 )
				call s:DebugMessage( l:debug_message_prefix . '  found remaining elements in the subdirectory name. value remaining: "' . l:path_value_toparse . '". dictionary element so far: ' . string( l:version_list_elem )  )
				continue
			endif
			" }}}
			" add the dictionary to the end of the list {{{
			" filter the array elements, by seeing which ones are matched by the
			"  currently running vim
			if s:ExtendVersionedRuntimePath_FilterElement( l:version_list_elem )
				let l:version_list_now += [ l:version_list_elem ]
				let l:debug_message_now = '[added]'
			else
				let l:debug_message_now = '[failed_checks]'
			endif
			call s:DebugMessage( l:debug_message_prefix . '  dictionary element: ' . string( l:version_list_elem ) . ' ' . l:debug_message_now )
			" }}}
		endfor

		" now, depending on the inclusion method, we will either:
		"  * ('all'): add all the dictionary elements;
		"  * ('one'): find best match, and add only that one;
		let l:paths_element_now_incmethod = l:paths_element_now[ 1 ]
		if l:paths_element_now_incmethod == 'all'
			" nothing extra to do
		elseif l:paths_element_now_incmethod == 'one'
			" sort the elements by numeric version then by ... ?
			" note: see why I've done an assignment (search for 'sort(', below (')'))
			let l:version_list_now = sort( l:version_list_now, 's:ExtendVersionedRuntimePath_CompareElements' )

			" filter elements: leave the best match
			"  (note: should be the first one in the list)
			" note: this notation does not error if the element index does
			"  not exist.
			"  example: "echo [][ 1:1 ]" -> "[]"
			let l:version_list_now = l:version_list_now[ 1:1 ]
		else
			echoerr l:debug_message_prefix . 'invalid inclusion method: "' . l:paths_element_now_incmethod . '"'
		endif

		if ( len( l:version_list_now ) > 0 )
			call s:DebugMessage( l:debug_message_prefix . ' root directory #' . l:rootdir_order_now . ': about to add entries: ' . string( l:version_list_now ) )
		else
			call s:DebugMessage( l:debug_message_prefix . '  (directory not found, no valid subdirectories found, or valid subdirectories did not pass version checking)' )
		endif
		" append the list for the current "root directory" to the overall one
		let l:version_list += l:version_list_now
	endfor

	if ( len( l:version_list ) > 0 )
		" now make sure we've got all the list elements sorted in the right order
		" for the runtimepath operations we're going to perform
		"
		" note: the sorting is supposed to be in-place, but without the
		"  assignment, it didn't work properly
		let l:version_list = sort( l:version_list, 's:ExtendVersionedRuntimePath_CompareElements' )
		" TODO: remove: call s:DebugMessage( l:debug_message_prefix . 'INFO: sorted list of dictionary entries: ' . string( l:version_list ) )

		" get the list to use in the call to evlib#rtpath#ExtendRuntimePath() {{{
		unlet! l:version_list_now
		unlet! l:paths_runtimedirs
		let l:paths_runtimedirs = []
		for l:version_list_now in l:version_list
			let l:paths_runtimedirs += [ l:version_list_now['path'] ]
		endfor
		" }}}

		call s:DebugMessage( l:debug_message_prefix . 'about to add the following directories to "runtimepath": ' . string( l:paths_runtimedirs ) )
		call evlib#rtpath#ExtendRuntimePath( l:paths_runtimedirs )
	else
		call s:DebugMessage( l:debug_message_prefix . 'no remaining directories are to be added to "runtimepath"' )
	endif
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
echoerr "the script 'rtpath.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
