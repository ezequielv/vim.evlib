" private (internal) - api version support

" boiler plate -- prolog {{{

" "bare vi support" detection/forwarding
if has("eval")

" inclusion control {{{
if ( ! evlib#pvt#init#ShouldSourceThisModule( 'pvt_apiver' ) )
	finish
endif
" }}}

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" versioning support {{{

" NOTE: the lists have got to have the same number of elements
"  (actually, at the moment, the "user" one could have more elements than the
"  "ref" one, but that could change)
function evlib#pvt#apiver#SupportsAPIVersion( ver_components_user, ver_components_ref ) abort
	let l:version_to_check = a:ver_components_user
	for l:index_now in range( len( a:ver_components_ref ) ) " 0 .. len() - 1
		let l:version_component_library_now = a:ver_components_ref[ l:index_now ]
		let l:version_component_user_now = l:version_to_check[ l:index_now ]
		if l:version_component_user_now < l:version_component_library_now
			return !0 " true
		elseif l:version_component_user_now > l:version_component_library_now
			return 0 " false
		endif
		" continue checking (they're equal)
	endfor
	" all the components matched the library's -> API version supported
	return !0 " true
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
echoerr "the script 'autoload/evlib/pvt/apiver.vim' needs support for the following: eval"

" }}} boiler plate -- epilog

