" private (internal) - library management/control/utilities

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'pvt_lib' ) )
	finish
endif
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" exception support {{{

let s:evlib_local_exception_name_prefix = 'EVLibExc'

" example: call evlib#pvt#lib#ThrowEVLibException( 'NotImplemented' )
function evlib#pvt#lib#ThrowEVLibException( exception_string )
	throw s:evlib_local_exception_name_prefix . exception_string
endfunction

" }}}

" save/restore options support {{{
let s:evlib_local_savedoptions_names_default = [ '&cpoptions' ]
" args:
"
"  * dict_saved_options: a dictionary (passed by reference) to be filled by
"     this function. it should be created with:
"      let {varname} = {}
"     * note: the dictionary is not wiped -> options are *added*/replaced,
"        and options that aren't specified aren't modified;
"
"  * list_option_names (optional): strings denoting each option name (with
"     the '&' preceeding each one);
"     * default is to use s:evlib_local_savedoptions_names_default
"
function evlib#pvt#lib#InternalScriptSaveOptions( dict_saved_options, ... ) abort
	let l:option_keys = ( ( a:0 > 0 ) ? ( a:1 ) : s:evlib_local_savedoptions_names_default )
	for l:opt_now in l:option_keys
		" conditionally save the option
		if exists( l:opt_now )
			" add/update dictionary entry
			let a:dict_saved_options[ l:opt_now ] = eval( l:opt_now )
		endif
	endfor
	return !0 " true
endfunction

" restores all options stored in the dictionary
function evlib#pvt#lib#InternalScriptRestoreOptions( dict_saved_options ) abort
	" for now, all keys are options/variables to restore
	let l:option_keys = keys( a:dict_saved_options )
	" MAYBE: we could filter the options here...

	for l:opt_now in l:option_keys
		let l:opt_value_now = a:dict_saved_options[ l:opt_now ]

		" conditionally restore the option value
		if ( eval( l:opt_now ) != l:opt_value_now )
			" TODO: see if we could use variable dereferencing instead of
			"  'execute' (for performance reasons)
			execute 'let ' . l:opt_now . ' = l:opt_value_now'
		endif

		" avoid errors regarding the type change for this local variable
		unlet! l:opt_value_now
	endfor
	return !0 " true
endfunction
" }}}

" call external scripts support {{{

" purpose: restore options, force the right 'compatible' mode
" returns "success" flag
function evlib#pvt#lib#SourceExternalFilesDoRestore( saved_options ) abort
	let l:success = !0 " true

	" IDEA: restore options like '&history' only when the 'set nocompatible'
	"  is being executed
	"  -> have a list of options to restore only when 'set nocompatible' is
	"   executed
	"   (this could be "script local")
	if l:success
		" force 'nocompatible' option value (but leave it alone if it wasn't
		"  set);
		if &cp | set nocp | endif
	endif
	let l:success = l:success && evlib#pvt#lib#InternalScriptRestoreOptions( a:saved_options )
	return l:success
endfunction

let s:evlib_local_external_source_base_relative_dir = 'lib/evlib'

" returns "success" flag
" NOTE: all paths are relative to s:evlib_local_external_source_base_relative_dir
function evlib#pvt#lib#SourceExternalFiles( src_srcs ) abort
	let l:success = !0 " true
	let l:saved_options = {}

	let l:success = l:success && evlib#pvt#lib#InternalScriptSaveOptions( l:saved_options )

	if l:success
		let l:needs_restoring_options_flag = 0
		try
			for l:src_now in ( ( type( a:src_srcs ) == type( '' ) ) ? [ a:src_srcs ] : a:src_srcs )
				let l:needs_restoring_options_flag = 1

				execute 'runtime! ' . s:evlib_local_external_source_base_relative_dir . '/' . l:src_now

				" after calling each group of scripts, restore options
				if l:needs_restoring_options_flag
					" evaluation order is important, to cater for the error
					"  scenario (! l:success)
					let l:success = evlib#pvt#lib#SourceExternalFilesDoRestore( l:saved_options ) && l:success
					let l:needs_restoring_options_flag = 0
				endif
			endfor
		catch
			" NOTE: do nothing special. just "eat" the exception
			" ... and mark the error to be reported back to our caller
			let l:success = 0 " false
		finally
			if l:needs_restoring_options_flag
				" evaluation order is important, to cater for the error
				"  scenario (! l:success)
				let l:success = evlib#pvt#lib#SourceExternalFilesDoRestore( l:saved_options ) && l:success
				let l:needs_restoring_options_flag = 0
			endif
		endtry
	endif

	return l:success
endfunction

" }}}

" for now, it returns the number of script files *found*.
" the number of actual processed scripts could be less than that number (but
"  the caller should not be interested in that, as files should be sourced to
"  define funcitons and variables, not to do actual processing).
function evlib#pvt#lib#SourceEVLibFiles( src_srcs ) abort
	let l:srcs = []
	" save a little processing time for each iteration by precalculating
	"  temporary constant expressions
	let l:src_dir = g:evlib_global_lib_src_dir . '/'
	" make arg it into a list
	for l:src_now in ( ( type( a:src_srcs ) == type( '' ) ) ? [ a:src_srcs ] : a:src_srcs )
		" sort list in place (alphabetical order is fine)
		" NOTE: if we need to do this manual glob() expansion, put this into a
		"  function and call that from here
		let l:srcs += sort( split( glob( l:src_dir . l:src_now ), '\n', 0 ) )
	endfor
	let l:sources_found_count = len( l:srcs )

	if ( l:sources_found_count > 0 )
		" sorted_each_path_separately_now: " sort list in place (alphabetical order is fine)
		" sorted_each_path_separately_now: sort( l:srcs )
		let l:proc_done_setup = 0
		" NOTE: consider the performance implications of running this code:
		"  * when the script was already "sourced" (using this outer
		"     try..endtry):
		"  * using a try..endtry for each "source" (so we'd skip the files
		"     that were already "sourced");
		"  * not using try..endtry altogether;
		try
			for l:src_now in l:srcs
				" craft a variable name from the filename
				"  (don't worry about the variable name incorporating the
				"  absolute file path components -- as long as it's
				"  consistent, we should not care)
				"  and check for its existence and value
				"
				" note: leaving only valid identifier characters
				"  alternative_prefix: \	'g:evlib_pvt_lib_' .
				let l:var_includecontrol_now =
					\	's:local_' .
					\	substitute(
					\			substitute(
					\					fnamemodify( l:src_now, ':p' ),
					\					'^/', '', ''
					\				),
					\			'[^a-zA-Z0-9_]', '_', 'g'
					\		) .
					\	'_loaded'
				" determine whether the script needs to be skipped
				if ( exists( l:var_includecontrol_now ) && ( eval( l:var_includecontrol_now ) != 0 ) )
					continue
				endif

				" if we are at this point, we are processing this script

				if ( ! l:proc_done_setup )
					" LATER: set up before sourcing this file
					"  ref: evlib#pvt#lib#InternalScriptSaveOptions( dict_saved_options, ... )
					let l:proc_done_setup = !0
				endif
				" marking the file as "loaded", then source the file
				"  (TODO: do filename escaping (careful, the library is not
				"  officially loaded yet))
				execute
					\	'let ' . l:var_includecontrol_now . ' = !0'
					\	. ' | ' .
					\	'source ' . l:src_now
			endfor
		" note: do not catch exceptions
		finally
			if ( l:proc_done_setup )
				" not_done: call s:EVLibLocalUndoSourceSetup( l:saved_cpo )
				"  ref: evlib#pvt#lib#InternalScriptRestoreOptions( dict_saved_options )
			endif
		endtry
	endif

	return l:sources_found_count
endfunction

function evlib#pvt#lib#InitPre( rootdir ) abort
	let l:rc = !0
	let l:rootdir = a:rootdir

	" validation
	"? let l:rc = l:rc && ( strlen( l:rootdir ) > 0 )
	"? let l:rc = l:rc && ( isdirectory( l:rootdir ) > 0 )
	let l:rc = l:rc && ( filereadable( l:rootdir . '/evlib_loader.vim' ) > 0 )

	" commit changes to global variables - part #1
	if ( l:rc != 0 )
		let g:evlib_global_lib_root_dir = l:rootdir
		" note: there will be an implicit check for the readibility of files
		"  in this directory, as we will check the return value of
		"  evlib#pvt#lib#SourceEVLibFiles(), below
		let g:evlib_global_lib_src_dir = g:evlib_global_lib_root_dir . '/lib/evlib'
	endif

	" perform internal initialisation/loading
	if ( l:rc != 0 )
		try
			let l:rc = l:rc && ( evlib#pvt#lib#SourceEVLibFiles( 'c_main.vim' ) > 0 )
		catch " catch all exceptions
			let l:rc = 0
		endtry
	endif

	" commit changes to global variables - part #2
	if ( l:rc != 0 )
	else
		" undo the "part #1" variable setting
		unlet! g:evlib_global_lib_src_dir
		unlet! g:evlib_global_lib_root_dir
	endif
	return l:rc
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
echoerr "the script 'autoload/evlib/pvt/lib.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

