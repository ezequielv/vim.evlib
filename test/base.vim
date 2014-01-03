" test/base.vim
"
" needs/includes:
"  * call s:EVLibTest_Module_Load( 'evtest/proc/evtstd/c-defs.vim' );
"
" output:
"  * instanciates a new variable g:evlib_test_base_object_last;
"
" side effects:
"  * other than the global variable that is set on output, it should have no
"     other side effects of its own;
"  * because it includes '.../evtstd/c-defs.vim' (see above), it overwrites
"     the previous value (if it exists) of
"     g:evlib_test_evtest_evtstd_base_object_last
"

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control -- start {{{
if ( ! exists( 's:evlib_test_base_loaded' ) ) || ( exists( 'g:evlib_test_base_forceload' ) && ( g:evlib_test_base_forceload != 0 ) )
let s:evlib_test_base_loaded = 1
unlet! g:evlib_test_base_forceload
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" everything in this file will be part of: s:evlib_test_base_object

" variables and functions {{{

" support functions {{{
let s:evlib_test_base_debug = ( ( exists( 'g:evlib_test_base_debug' ) ) ? ( g:evlib_test_base_debug ) : 0 )

function! s:IsDebuggingEnabled()
	return ( s:evlib_test_base_debug != 0 )
endfunction

function! s:DebugMessage( msg )
	if s:IsDebuggingEnabled()
		echomsg '[debug] ' . a:msg
	endif
endfunction

function! s:DebugExceptionCaught()
	if ( ! s:IsDebuggingEnabled() ) | return | endif

	" (see ':h throw-variables')
	if v:exception != ''
		call s:DebugMessage( 'caught exception "'. v:exception . '" in ' . v:throwpoint )
	else
		call s:DebugMessage( 'nothing caught' )
	endif
endfunction
" }}}

" general variables {{{
let s:evlib_test_base_testdir = fnamemodify( expand( '<sfile>' ), ':p:h' )
let s:evlib_test_base_rootdir = fnamemodify( s:evlib_test_base_testdir, ':h' )
let s:evlib_test_base_test_testtrees_rootdir = s:evlib_test_base_testdir . '/test_trees'
" }}}

" general functions {{{

function! s:EVLibTest_Local_fnameescape( fname )
	if exists( '*fnameescape' )
		return fnameescape( a:fname )
	else
		" (see ':h escape()')
		return escape( a:fname, ' \' )
	endif
endfunction

" }}}

" test framework modules {{{
function! s:EVLibTest_Module_Load( module )
	let l:filepath = s:evlib_test_base_testdir . '/' . a:module
	" (see ':h escape()')
	execute 'source ' . s:EVLibTest_Local_fnameescape( l:filepath )
	return !0 " true
endfunction
" }}}
" }}}

" support for output redirection {{{
let s:evlib_test_base_global_outputredir_flag = 0
unlet! s:evlib_test_base_global_outputredir_object_last
let s:evlib_test_base_global_outputredir_object_last = ''

function! s:EVLibTest_TestOutput_IsRedirectingOutput()
	return ( s:evlib_test_base_global_outputredir_flag != 0 )
endfunction

" args:
" * redir_expression
"
" returns:
"  dictionary with the following entries:
"   * 'success': "boolean" (==0, !=0);
"   * 'redir_dict': (only when 'success' != 0);
function! s:EVLibTest_TestOutput_NormaliseValidateRedirExpr( redir_expression )
	let l:debug_message_prefix = 's:EVLibTest_TestOutput_NormaliseValidateRedirExpr(): '

	let l:success = !0 " true
	let l:redir_dict = {}	" default

	if l:success
		let l:filename_or_dict_type = type( a:redir_expression )
		if ( l:filename_or_dict_type == type( '' ) )
			" this check is not strictly necessary (an empty string should be
			"  picked up by the '!empty()' check on 'filename', below)
			"? let l:success = l:success && ( ! empty( a:redir_expression ) )

			" MAYBE: do further parsing, to support string to dict conversions
			"  for all supported types
			let l:redir_dict = {
						\		'redir_type': 'file',
						\		'filename': a:redir_expression,
						\	}
		elseif ( l:filename_or_dict_type == type( {} ) )
			let l:redir_dict = deepcopy( a:redir_expression )
		else
			" FIXME: throw an exception, report an error
			let l:success = 0 " false
		endif
	endif

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingOutput() )

	" make sure the src entry is valid {{{
	let l:success = l:success && ( has_key( l:redir_dict, 'redir_type' ) )
	if l:success
		let l:redir_type = l:redir_dict.redir_type
		if ( l:redir_type == 'file' )
			let l:success = l:success && ( ! empty( l:redir_dict.filename ) )
		elseif ( l:redir_type == 'reg' )
			let l:success = l:success && ( match( l:redir_dict.register, '^[a-z]$' ) >= 0 ) )
		elseif ( l:redir_type == 'var' )
			let l:success = l:success && ( ! empty( l:redir_dict.varname ) )
		else
			" FIXME: throw an exception, report an error
			let l:success = 0 " false
		endif
	endif
	" }}}

	call s:DebugMessage( l:debug_message_prefix . ' l:redir_dict = ' . string( l:redir_dict ) )
	call s:DebugMessage( l:debug_message_prefix . ' l:success = ' . string( l:success ) )

	let l:retdict = {
				\		'success': l:success,
				\	}
	if l:success
		let l:retdict.redir_dict = l:redir_dict
	endif
	return l:retdict
endfunction

" args:
" * redir_expression
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
function! s:EVLibTest_TestOutput_Do_Redir( redir_expression, ... )
	let l:debug_message_prefix = 's:EVLibTest_TestOutput_Do_Redir(): '

	let l:success = !0 " true
	let l:redir_overwrite_flag = ( ( a:0 > 0 ) ? a:1 : ( 0 ) )
	let l:redir_dict = {}	" default value

	if l:success
		let l:normalise_redir_retdict = s:EVLibTest_TestOutput_NormaliseValidateRedirExpr( a:redir_expression )
		let l:success = l:success && l:normalise_redir_retdict.success
		if l:success
			let l:redir_dict = l:normalise_redir_retdict.redir_dict
		endif
	endif

	call s:DebugMessage( l:debug_message_prefix . ' l:redir_dict = ' . string( l:redir_dict ) )
	call s:DebugMessage( l:debug_message_prefix . ' l:success = ' . string( l:success ) )
	if l:success
		let l:redir_type = l:redir_dict.redir_type
		if ( l:redir_type == 'file' )
			" NOTE: alternative, use option 'verbosefile' instead
			"  (see ":h 'verbosefile'")
			let l:redir_ex_command_prefix = ( l:redir_overwrite_flag ? 'redir! >' : 'redir >>' ) . ' '
			execute l:redir_ex_command_prefix . s:EVLibTest_Local_fnameescape( l:redir_dict.filename )
		elseif ( l:redir_type == 'reg' )
			let l:redir_ex_command_prefix = 'redir @'
			let l:redir_ex_command_suffix = ( l:redir_overwrite_flag ? '>' : '>>' )
			execute l:redir_ex_command_prefix . tolower( l:redir_dict.register ) . l:redir_ex_command_suffix
		elseif ( l:redir_type == 'var' )
			if ( l:redir_overwrite_flag )
				" make sure that we will not get type incompatibilities by
				"  undefining the variable first
				execute 'unlet! ' . l:redir_dict.varname
			endif
			let l:redir_ex_command_prefix = 'redir ' . ( l:redir_overwrite_flag ? '=>' : '=>>' ) . ' '
			execute l:redir_ex_command_prefix . l:redir_dict.varname
		else
			let l:success = 0 " false
		endif
		if l:success
			let s:evlib_test_base_global_outputredir_flag = 1
		endif
	endif
	return l:success
endfunction

" args: [ redir_expression ]
"  * redir_expression: (ignored if empty)
"
" returns:
"  on success, an instance of the right type that can be passed onto other
"   redirection functions;
"  on error, an instance that should hold 'empty( return_value )';
function! s:EVLibTest_TestOutput_OptionalGetRedirExpression( ... )
	let l:success = !0 " true
	let l:redir_expression_default = ''
	let l:redir_expression = l:redir_expression_default

	if l:success
		let l:stage = 1
		while ( l:success ) && ( empty( l:redir_expression ) )
			let l:stage_finished = !0 " true (by default)
			let l:stage_is_last = 0 " false
			" avoid type assignment clashing -> undefine the variable(s)
			unlet! l:redir_expression
			unlet! l:redir_expression_now

			" note: if ( ! l:success ) the while condition will stop the loop
			if l:success
				if l:stage == 1
					" process optional argument
					let l:redir_expression_now = ( ( a:0 > 0 ) ? ( a:1 ) : '' )
				elseif l:stage == 2
					let l:stage_is_last = !0 " true

					if ( ! exists( 'l:variables_list' ) )
						let l:variables_list = [
									\		'g:evlib_test_outputfile',
									\		'$EVLIB_VIM_TEST_OUTPUTFILE',
									\	]
					endif
					" remove the first element from the list, and store it in
					"  l:var_now
					" note: we know that the list is always non-empty at this point
					let l:var_now = remove( l:variables_list, 0 )

					if l:success && exists( l:var_now )
						let l:redir_expression_now = eval( l:var_now )
					endif

					let l:stage_finished = empty( l:variables_list )
					" tidy up after ourselves before leaving this stage for
					"  good
					if ( l:stage_finished )
						unlet l:variables_list
					endif
				endif
			endif
			if l:success && exists( 'l:redir_expression_now' ) && ( ! empty( l:redir_expression_now ) )
				let l:redir_expression = l:redir_expression_now
			endif

			" make sure the 'while' expression is valid
			"  (and that we can return this variable outside this loop)
			if ( ! exists( 'l:redir_expression' ) )
				let l:redir_expression = l:redir_expression_default
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

	" note: the type does not matter (that much): return an empty object in
	"  the case of an error
	return ( l:success ? l:redir_expression : '' )
endfunction

" args: [ do_redir_now_flag [, redir_filename [, redir_overwrite_flag ] ] ]
" * do_redir_now_flag (default: TRUE);
" * redir_filename: empty or unspecified to use automatic name detection;
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
"
" returns: success state
function! s:EVLibTest_TestOutput_InitAndOpen( ... )
	let l:debug_message_prefix = 's:EVLibTest_TestOutput_InitAndOpen(): '

	let l:success = !0 " true
	let l:do_redir_now_flag = ( ( a:0 > 0 ) ? ( a:1 ) : ( !0 ) )
	let l:redir_expression_user = ( ( a:0 > 1 ) ? ( a:2 ) : '' )
	let l:redir_overwrite_flag = ( ( a:0 > 2 ) ? ( a:3 ) : ( 0 ) )

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingOutput() )

	if l:success
		let l:redir_object = s:EVLibTest_TestOutput_OptionalGetRedirExpression( l:redir_expression_user )
	endif
	call s:DebugMessage( l:debug_message_prefix . 'l:do_redir_now_flag: ' . string( l:do_redir_now_flag ) . ', l:success: ' . string( l:success ) . ', l:redir_object: ' . string( l:redir_object ) )
	if l:success && ( ! empty( l:redir_object ) )
		call s:DebugMessage( l:debug_message_prefix . ' got a filename to redirect to' )
		if l:do_redir_now_flag
			let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( l:redir_object, l:redir_overwrite_flag )
		endif
		" note: purposedly writing these other (globally/script
		"  scoped) variables
		if l:success
			call s:DebugMessage( l:debug_message_prefix . ' saving l:redir_object: ' . string( l:redir_object ) )
			unlet! s:evlib_test_base_global_outputredir_object_last
			let s:evlib_test_base_global_outputredir_object_last = l:redir_object
		endif
	endif

	return l:success
endfunction

" args:
" * redir_overwrite_flag: if unspecified, uses the default: 0 (false);
function! s:EVLibTest_TestOutput_Reopen( ... )
	let l:debug_message_prefix = 's:EVLibTest_TestOutput_Reopen(): '

	let l:success = !0 " true
	let l:redir_overwrite_flag = ( ( a:0 > 0 ) ? a:1 : ( 0 ) )

	let l:success = l:success && ( ! s:EVLibTest_TestOutput_IsRedirectingOutput() )
	" note: technically, we don't need to check for 'empty(object)', as it
	"  should be picked up by s:EVLibTest_TestOutput_Do_Redir()
	let l:success = l:success && exists( 's:evlib_test_base_global_outputredir_object_last' ) && ( ! empty( s:evlib_test_base_global_outputredir_object_last ) )

	call s:DebugMessage( l:debug_message_prefix . 'l:redir_overwrite_flag: ' . string( l:redir_overwrite_flag ) . ', l:success: ' . string( l:success ) )
	" do it {{{
	let l:success = l:success && s:EVLibTest_TestOutput_Do_Redir( s:evlib_test_base_global_outputredir_object_last, l:redir_overwrite_flag )
	" }}}

	return l:success
endfunction

function! s:EVLibTest_TestOutput_Close()
	let l:success = !0 " success

	let l:success = l:success && s:EVLibTest_TestOutput_IsRedirectingOutput()
	if l:success
		" end redirection (see ':h :redir')
		redir END
		let s:evlib_test_base_global_outputredir_flag = 0
	endif
	return l:success
endfunction

" }}}

" support for sourcing "processor" scripts and invoking their functions {{{

function! s:EVLibTest_GenUserScript_ClearVars( var_names )
	for l:var_name_now in a:var_names
		if exists( l:var_name_now )
			execute 'unlet! ' . l:var_name_now
		endif
	endfor
endfunction

" this function provides a generic way to "source" a vim script, using
"  variables with predefined names for input ("to_script") and outout
"  ("from_script")
"
" this function:
"  * provides a "safe" way to source those scripts (catching exceptions);
"  * clears out previous values for the "input" and "output" variable names
"     before "sourcing" the script;
"  * perform the assignments on behalf of this function's callers, so that the
"    script being "sourced" is guaranteed a consistent environment in which to
"    run;
"  * clears out previous values for the "input" and "output" variable names
"     after "sourcing" the script;
"
" args:
"  * vars_to_script: dictionary with elements following this format:
"     { VARIABLE_NAME, VARIABLE_VALUE }
"     where VARIABLE_NAME is a string (usually 'g:some_variable_name'), and
"      VARIABLE_VALUE is of any valid type.  the VARIABLE_VALUE is usually
"      'deepcopy()'-ed, for maximum separation between the caller and the
"      sourced script;
"  * vars_from_script: list of strings, each being a VARIABLE_NAME;
"
" return value:
"  * a dictionary consisting of elements with the following keys:
"  * 'sourced': "boolean" (==0, !=0 integer) (equivalent to dictionary.'procexittype' == 'ok');
"  * 'procexittype': one of the following: 'notsourced', 'ok', 'exception'
"  * 'variables': a dictionary, with keys equal to the elements passed in
"     vars_from_script.  if a variable was not set by the user script, it will
"     not exist as a key in this dictionary (this behaviour might change in
"     the future);
function! s:EVLibTest_GenUserScript_Source( scriptname, vars_to_script, vars_from_script )
	let l:debug_message_prefix = 's:EVLibTest_GenUserScript_Source(): '

	let l:success = !0 " true
	let l:ret_procexittype = 'notsourced'
	let l:ret_variables = {}

	let l:success = l:success && filereadable( a:scriptname )
	call s:DebugMessage( l:debug_message_prefix . 'l:success: ' . string( l:success ) )

	let l:inputoutput_varnames = keys( a:vars_to_script ) + a:vars_from_script
	call s:DebugMessage( l:debug_message_prefix . 'l:inputoutput_varnames: ' . string( l:inputoutput_varnames ) )

	" clear all input/output variables
	call s:EVLibTest_GenUserScript_ClearVars( l:inputoutput_varnames )

	if l:success
		for l:var_name_now in keys( a:vars_to_script )
			execute 'let ' . l:var_name_now . ' = deepcopy( a:vars_to_script[ l:var_name_now ] )'
		endfor
	endif

	if l:success
		try
			let l:ret_procexittype = 'ok'
			" TODO: se if we can make the 'source' non-silent, if needed
			execute 'silent source ' . s:EVLibTest_Local_fnameescape( a:scriptname )
			call s:DebugMessage( l:debug_message_prefix . 'sourced "' . a:scriptname . '" successfully' )
		catch
			call s:DebugMessage( l:debug_message_prefix . 'sourcing "' . a:scriptname . '" threw an exception' )
			let l:ret_procexittype = 'exception'
		endtry
	endif

	if l:success
		for l:var_name_now in a:vars_from_script
			if exists( l:var_name_now )
				let l:ret_variables[ l:var_name_now ] = eval( l:var_name_now )
			endif
		endfor
	endif

	" clear all input/output variables
	call s:EVLibTest_GenUserScript_ClearVars( l:inputoutput_varnames )

	" fill out return value(s) {{{
	let l:retdict = {}
	let l:retdict.sourced = ( l:ret_procexittype == 'ok' )
	let l:retdict.procexittype = l:ret_procexittype
	if ( l:retdict.sourced )
		let l:retdict.variables = l:ret_variables
	endif
	" }}}

	return l:retdict
endfunction

" reference:
"
" scripts implementing the functions to be invoked should communicate with
"  this module (or any caller) through the following protocol:
"
" environment:
"  the processing scripts are executed with the "output" buffer currently
"  active.  this means, amongst other things, that the buffer can be used to
"  store variables and functions, as it will be the buffer that will contain
"  the test output.
"
" * no buffer switching is allowed;
" * no buffer content/state/option manipulation is allowed;
"
" for the moment, all scripts can use the following variable scopes:
"
"  g: (global): for communicating with the calling script(s), and only using
"   the variable names described below;
"
"  s: (script): for short-lived variables (like s:cpo_save), but it's
"   recommended *not* to instanciate permanent variables and/or functions on
"   this scope;
"
"  b: (buffer): for everything that does not fall in the categories defined
"   above. in particular, it's recommended to define in this scope:
"   * functions (such as the one to be used for 'foldexpr', 'foldtext', etc.);
"   * variables: anything that the processing script might need in the
"      "global" (ie., non-"local" ('l:') scope);
"
"  input:
"   * g:evlib_test_processor_operation
"      one of:
"       * 'define_functions'
"        * input: there is currently no input (dictionary is empty);
"        * output: a dictionary with the following keys:
"         * 'functions': a dictionary that has elements following this format:
"          { FUNCTION_NAME, FUNCREF_FOR_FUNCTION_NAME }
"          * for each FUNCTION_NAME, the inputs and outputs should be
"             well-defined, and consistent across all processor scripts.
"
"   * g:evlib_test_processor_input
"      a dictionary whose actual keys will be dependant on the operation the
"      script is asked to do.
"
"   * g:evlib_test_processor_output

" s:EVLibTest_ProcessorDef_Invoke() {{{
"
" invokes the user function whose name is given in a:function_name, passing a
"  single parameter (the dictionary specified in a:function_args), and
"  returning its value (as an element in the dictionary returned by this
"  function).
"
" args:
" * processor_defs_data [in/out]: read and conditionally updated by this
"    function;
" * function_name: string describing the Funcref member to be invoked;
" * function_args: dictionary with the argument for the function_name
"    function.
"  * the actual keys, the value types, etc. should all be defined at the
"     function declaration level (see the reference for that);
"
" returns:
" * a dictionary consisting of elements with the following keys:
"  * 'invoked': "boolean" (==0, !=0 integer);
"  * 'retvalue' (when 'invoked' != 0): value as returned from the invoked
"     function (will probably be a dictionary itself);
"
" side effects:
" * will throw if there is an unrecoverable error;
" * will do nothing if the function is not defined;
"
function! s:EVLibTest_ProcessorDef_Invoke( processor_defs_data, function_name, function_args )
	let l:debug_message_prefix = 's:EVLibTest_ProcessorDef_Invoke(): '

	let l:success = !0 " true
	let l:ret_invoked = 0 " false
	" avoid trying to source the file if we've tried before and failed
	let l:process_source_script_flag = (
				\		( ! has_key( a:processor_defs_data, 'functions' ) )
				\		&&
				\		( ! has_key( a:processor_defs_data, 'sourced_processor_script' ) )
				\	)

	call s:DebugMessage( l:debug_message_prefix . 'l:process_source_script_flag: ' . string( l:process_source_script_flag ) )
	" 'source' the script if we need to
	if l:success && ( l:process_source_script_flag )
		" attempt to process the script to define the functions
		let l:source_ret_value = s:EVLibTest_GenUserScript_Source(
					\		a:processor_defs_data.processor_script,
					\		{
					\			'g:evlib_test_processor_operation': 'define_functions',
					\			'g:evlib_test_processor_input': {},
					\		},
					\		[
					\			'g:evlib_test_processor_output',
					\		]
					\	)
		let l:success = l:success && ( l:source_ret_value.procexittype == 'ok' )
		" whatever happened, we flag that we've tried
		let a:processor_defs_data.sourced_processor_script = !0 " true
		call s:DebugMessage( l:debug_message_prefix . ' called s:EVLibTest_GenUserScript_Source(). l:success: ' . string( l:success ) )

		if l:success
			let l:sourced_output_dict = l:source_ret_value.variables[ 'g:evlib_test_processor_output' ]
			let l:sourced_output_dict_keys = keys( l:sourced_output_dict )
		endif
		" make sure we've got the required keys in the output dictionary
		"  (removes the elements that it finds, and makes sure that there are
		"  no leftovers)
		let l:success = l:success && empty(
					\		filter(
					\				copy( [
					\						'functions',
					\					] ),
					\				'( ! ( index( l:sourced_output_dict_keys, v:val ) >= 0 ) )'
					\			)
					\	)
		call s:DebugMessage( l:debug_message_prefix . ' checked required keys. l:success: ' . string( l:success ) )

		" TODO: validate the needed functions to consider the processor
		"  "sourcing" successful

		" copy the values into the user's processor_defs_data
		if l:success
			for l:ret_key_now in [
					\		'functions',
					\	]
				let a:processor_defs_data[ l:ret_key_now ] = l:sourced_output_dict[ l:ret_key_now ]
			endfor
		endif

		call s:DebugMessage( l:debug_message_prefix . ' finished processor script processing. l:success: ' . string( l:success ) )
	endif

	" at this point, we may have sourced the script now, or maybe we've tried
	"  before -> refresh 'success' state
	let l:success = l:success && ( has_key( a:processor_defs_data, 'functions' ) )
	call s:DebugMessage( l:debug_message_prefix . 'checked required keys. l:success: ' . string( l:success ) )

	" invoke the function requested by the user
	if l:success
		let l:processor_functions_dict = a:processor_defs_data.functions
		" if the function is not found, we'll reset 'success' for now
		"  (this could also be moved to the 'if' below, so that no variable
		"  gets changed, whilst still maintaining the function call
		"  conditional)
		let l:success = l:success && ( has_key( l:processor_functions_dict, a:function_name ) )
	endif

	if l:success
		" NOTE: for now, make 'invoke' mean "successfully executed", not just
		"  "I've made a call to that function, and that is no guarantee as to
		"  whether it worked"
		try
			call s:DebugMessage( l:debug_message_prefix . 'about to call "' . a:function_name . '( ' . string( a:function_args ) . ' )"' )
			" attempt to call the Funcref stored in the dictionary entry
			let l:ret_value = l:processor_functions_dict[ a:function_name ]( a:function_args )
			let l:ret_invoked = !0 " true
		catch
			" do nothing in particular, as l:ret_invoked should remain == 0
			call s:DebugMessage( l:debug_message_prefix . 'invoking the function ' . string( a:function_name ) . ' has thrown an exception' )
			call s:DebugExceptionCaught()
		endtry
		let l:success = l:success && l:ret_invoked
	endif

	" epilog: prepare the return value (dictionary)
	let l:retdict = {
				\		'invoked': l:ret_invoked,
				\	}
	if l:ret_invoked
		let l:retdict.retvalue = l:ret_value
	endif

	call s:DebugMessage( l:debug_message_prefix . 'returning: ' . string( l:retdict ) )
	return l:retdict
endfunction
" }}}

" }}}

" high-level "processor" function wrappers {{{

" s:EVLibTest_ProcessorDef_Invoke_WriteTestContextInfo() {{{
" invokes the processor function 'f_writetestcontextinfo'
"
" returns:
"  == 0 (false): if the function returned 0 (false) or if the function was not
"                 defined (or not invoked for any other reason);
"  != 0 (true):  if the function was invoked and returned !0 (true);
function! s:EVLibTest_ProcessorDef_Invoke_WriteTestContextInfo( processor_defs_data, function_args )
	silent let l:retvalue = s:EVLibTest_ProcessorDef_Invoke( a:processor_defs_data, 'f_writetestcontextinfo', a:function_args )
	return ( l:retvalue.invoked && l:retvalue.retvalue )
endfunction
" }}}

" s:EVLibTest_ProcessorDef_Invoke_WriteErrorMessage() {{{
" invokes the processor function 'f_writeerrormessage'
"
" returns:
"  == 0 (false): if the function returned 0 (false) or if the function was not
"                 defined (or not invoked for any other reason);
"  != 0 (true):  if the function was invoked and returned !0 (true);
function! s:EVLibTest_ProcessorDef_Invoke_WriteErrorMessage( processor_defs_data, function_args )
	silent let l:retvalue = s:EVLibTest_ProcessorDef_Invoke( a:processor_defs_data, 'f_writeerrormessage', a:function_args )
	return ( l:retvalue.invoked && l:retvalue.retvalue )
endfunction
" }}}

" user-friendly functions to call {{{

"  s:EVLibTest_ProcessorDef_Invoke_WriteTestContextInfo(), without having to
"  know the input dictionary structure
function! s:EVLibTest_ProcessorDef_UserCall_WriteTestContextInfo( processor_defs_data, contextlevel, infostring )
	return s:EVLibTest_ProcessorDef_Invoke_WriteTestContextInfo(
				\		a:processor_defs_data,
				\		{
				\			'contextlevel': a:contextlevel,
				\			'info': a:infostring,
				\		}
				\	)
endfunction

"  s:EVLibTest_ProcessorDef_Invoke_WriteErrorMessage(), without having to
"  know the input dictionary structure
function! s:EVLibTest_ProcessorDef_UserCall_WriteErrorMessage( processor_defs_data, errormessage )
	return s:EVLibTest_ProcessorDef_Invoke_WriteErrorMessage(
				\		a:processor_defs_data,
				\		{
				\			'message': a:errormessage,
				\		}
				\	)
endfunction

" }}}

" }}}

" everything in this file will be part of: s:evlib_test_base_object {{{
" TODO: define the functions directly in the dictionary object, to avoid this ugly hack
" from ':h <SID>' {{{
function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
" }}}
let s:funpref = '<SNR>' . s:SID() . '_'
call s:DebugMessage( 'base.vim: s:SID(): ' . string( s:SID() ) . ', s:funpref: ' . string( s:funpref ) )
" NOTE: values are copied (no references), so this is only a good method to
"  expose constants ('c_' prefix)
let s:evlib_test_base_object = {
		\		'c_testdir':				s:evlib_test_base_testdir,
		\		'c_rootdir':				s:evlib_test_base_rootdir,
		\		'c_testtrees_rootdir':		s:evlib_test_base_test_testtrees_rootdir,
		\
		\		'f_testoutput_close':						function( s:funpref . 'EVLibTest_TestOutput_Close' ),
		\		'f_testoutput_reopen':						function( s:funpref . 'EVLibTest_TestOutput_Reopen' ),
		\		'f_testoutput_initandopen':					function( s:funpref . 'EVLibTest_TestOutput_InitAndOpen' ),
		\		'f_testoutput_optionalgetredirexpression':	function( s:funpref . 'EVLibTest_TestOutput_OptionalGetRedirExpression' ),
		\		'f_testoutput_redir':						function( s:funpref . 'EVLibTest_TestOutput_Do_Redir' ),
		\		'f_testoutput_isredirectingoutput':			function( s:funpref . 'EVLibTest_TestOutput_IsRedirectingOutput' ),
		\
		\		'f_module_load':							function( s:funpref . 'EVLibTest_Module_Load' ),
		\		'f_fnameescape':							function( s:funpref . 'EVLibTest_Local_fnameescape' ),
		\
		\		'f_genuserscript_clearvars':				function( s:funpref . 'EVLibTest_GenUserScript_ClearVars' ),
		\		'f_genuserscript_source':					function( s:funpref . 'EVLibTest_GenUserScript_Source' ),
		\		'f_processordef_invoke':					function( s:funpref . 'EVLibTest_ProcessorDef_Invoke' ),
		\
		\		'f_processordef_invoke_writetestcontextinfo':	function( s:funpref . 'EVLibTest_ProcessorDef_Invoke_WriteTestContextInfo' ),
		\		'f_processordef_invoke_writeerrormessage':		function( s:funpref . 'EVLibTest_ProcessorDef_Invoke_WriteErrorMessage' ),
		\
		\		'f_processordef_usercall_writetestcontextinfo':	function( s:funpref . 'EVLibTest_ProcessorDef_UserCall_WriteTestContextInfo' ),
		\		'f_processordef_usercall_writeerrormessage':	function( s:funpref . 'EVLibTest_ProcessorDef_UserCall_WriteErrorMessage' ),
		\	}
" }}}

" inclusion control -- end {{{
endif " ... s:evlib_test_base_loaded ...
" }}}

" preserve the script object(s) as global {{{
unlet! g:evlib_test_base_object_last
let g:evlib_test_base_object_last = s:evlib_test_base_object
" }}}

" boiler plate -- epilog (customised) {{{

" restore old "compatibility" options {{{
if exists( 's:cpo_save' )
	let &cpo = s:cpo_save
	unlet s:cpo_save
endif
" }}}

" non-eval versions would skip over the "endif"
finish
endif " "eval"
" compatible mode
echoerr "the script 'test/base.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix foldmethod=marker:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
