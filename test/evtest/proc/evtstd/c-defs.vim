" test/evtest/proc/evtstd/c-defs.vim
"
" needs/includes:
"  * nothing ("root" file);
"
" output:
"  * instanciates a new variable g:evlib_test_evtest_evtstd_base_object_last
"
" side effects:
"  * other than the global variable that is set on output, it should have no
"     other side effects of its own;
"

" boiler plate -- prolog {{{

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

" }}} boiler plate -- prolog

" every constant (and function) here will be inside s:evlib_test_evtest_evtstd_base_object {{{
let s:evlib_test_evtest_evtstd_base_object = {
	\		'c_output_lineprefix_string': 'TEST: ',
	\	}
" }}}

" expose s:evlib_test_evtest_evtstd_base_object to a global symbol our
"  "includer" will have access to {{{
let g:evlib_test_evtest_evtstd_base_object_last = s:evlib_test_evtest_evtstd_base_object
" }}}

" boiler plate -- epilog {{{

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" }}} boiler plate -- epilog

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
