" inclusion control {{{
if exists( 'g:evlib_test_init01_loaded' ) && ( g:evlib_test_init01_loaded != 0 )
	finish
endif
let g:evlib_test_init01_loaded = 1
" }}}

function evlib#test#init01#HasAccessToThisTest()
	return !0
endfunction
" [debug] echomsg "hello from init.01/autoload/evlib/test/init01.vim"

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
