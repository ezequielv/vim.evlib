#!/bin/sh
set -e

# support functions {{{
# syntax: f_help [exit_code]
f_help()
{
	echo "$prgname" '[options] [--] [test_scripts]

what gets reported:

-a
    "report all" mode: every line is reported.

-c
    "categorised" mode: report pass and fail
    sections separately.

-o
    "optimised" mode: only report failures;

-q
    "quick" mode: report summaries only;

main mode of operation:

-f
    "filter" mode. do not invoke the vim editor,
    but assume that stdin has the data produced
    by it.
    (default is to invoke the vim editor)

other options:

-p VIMPROGRAM
    use VIMPROGRAM as the vim executable.
    default is "'${g_cmd_vim_default}'".

-O OPTIONS
    specify vim options
    (make sure that escaping is not an issue --
    no spaces, backslashes, etc.)
    TODO: implement

-D
    debug this script (not everything is shown)

-h
    this help message.
'
	[ -n "$1" ] && exit "$1"
	return 0
}
prgname=`basename "$0"`
# }}}

# defaults {{{
g_debug=0
g_cmd_awk=awk
g_cmd_vim_default=vim
g_opermode_default="program"
g_reportmode_default="all"
unset g_cmd_vim
unset g_opermode
unset g_reportmode
unset g_temp_file_vimoutput
# }}}

# getopts {{{
while getopts 'facoqp:Dh' arg
do
	case $arg in
		f)	g_opermode="filter" ;;
		a)	g_reportmode="all" ;;
		c)	g_reportmode="categ" ;;
		o)	g_reportmode="optimised" ;;
		q)	g_reportmode="summary" ;;
		p)	g_cmd_vim="$OPTARG" ;;
		D)	g_debug=1 ;;
		h)	f_help 0 ;;
		?)	f_help 1 1>&2 ;;
	esac
done
shift `expr $OPTIND - 1`
# }}}

# assign values from defaults {{{
[ -z "${g_opermode}" ] && g_opermode="${g_opermode_default}"
[ -z "${g_cmd_vim}" ] && g_cmd_vim="${g_cmd_vim_default}"
[ -z "${g_reportmode}" ] && g_reportmode="${g_reportmode_default}"
# }}}
# validation {{{
if [ "${g_opermode}" = "program" ] ; then
	# FIXME: end program gracefully (get f_abort() from another script)
	which "${g_cmd_vim}" > /dev/null 2> /dev/null
fi
# }}}

# functions {{{
f_trap_EXIT()
{
	if [ -n "${g_temp_file_vimoutput}" ] ; then
		rm -f "${g_temp_file_vimoutput}" || true
		unset g_temp_file_vimoutput
	fi
}
trap f_trap_EXIT EXIT

f_filter_results()
{
	case "${g_reportmode}" in
		all)
			# TODO: still use the awk program below, but force the summary
			#  (IDEA: add another variable to let all the lines from input through)
			# IDEA: "grep out" empty lines
			grep -v '^[ \t]*$'
			;;
		categ|optimised|summary)
			l_filter_results_report_summary=1
			case "${g_reportmode}" in
				categ)
					l_filter_results_report_success=1
					l_filter_results_report_failures=1
					;;
				optimised)
					l_filter_results_report_success=0
					l_filter_results_report_failures=1
					;;
				summary)
					l_filter_results_report_success=0
					l_filter_results_report_failures=0
					;;
			esac
			${g_cmd_awk} \
				-v "g_debug=${g_debug}" \
				-v "g_report_success=${l_filter_results_report_success}" \
				-v "g_report_errors=${l_filter_results_report_failures}" \
				-v "g_report_summary=${l_filter_results_report_summary}" \
				'
				function f_debug( msg ) {
					if ( g_debug ) {
						print "[debug] " msg > "/dev/stderr"
					}
				}
				function f_debug_lineparsing( msg ) {
					f_debug( msg " -- r_line = {" r_line "}; r_line_rest = {" r_line_rest "};" )
				}
				function f_array_append_one( dst, src_elem ) {
					dst[ ++dst[ 0 ] ] = src_elem
				}
				function f_array_append( dst, src 				, isrc ) {
					for ( isrc = 1; isrc <= src[0]; ++isrc ) {
						f_array_append_one( dst, src[ isrc ] )
					}
				}
				function f_group_end_resolved_array( result_array ) {
					f_array_append_one( result_array, g_current_group_id " (#" g_current_group_number ")" )
					f_array_append( result_array, g_current_group_lines )
				}
				function f_group_end() {
					if ( g_in_group ) {
						# do stuff at the end of a group
						if ( g_current_group_success ) {
							f_group_end_resolved_array( g_current_suite_lines_success )
							++g_current_suite_ngroups_success
						}
						else {
							f_group_end_resolved_array( g_current_suite_lines_error )
							++g_current_suite_ngroups_error
						}
						g_in_group = 0
						g_current_group_lines[0] = 0
					}
				}
				function f_suite_end_common_lines_update( a_arr_dst, a_arr_src ) {
					if ( a_arr_src[ 0 ] > 0 ) {
						f_array_append_one( a_arr_dst, g_current_suite_id )
						f_array_append_one( a_arr_dst, "" )
						f_array_append( a_arr_dst, a_arr_src )
					}
				}
				function f_suite_end() {
					if ( g_in_suite ) {
						f_group_end()
						# do stuff at the end of the suite
						f_suite_end_common_lines_update( g_total_lines_success, g_current_suite_lines_success )
						f_suite_end_common_lines_update( g_total_lines_error, g_current_suite_lines_error )
						if ( ( g_current_suite_ngroups_error == 0 ) && ( g_current_suite_ngroups_success > 0 ) ) {
							++g_total_nsuites_success
							f_array_append_one( g_total_lines_suites_success, g_current_suite_id )
						}
						else if ( ( g_current_suite_ngroups_error != 0 ) ) {
							++g_total_nsuites_failure
							f_array_append_one( g_total_lines_suites_failure, g_current_suite_id )
						}
						g_in_suite = 0
						g_current_suite_lines_success[0] = 0
						g_current_suite_lines_error[0] = 0
					}
				}
				function f_suite_begin( suite_id ) {
					f_suite_end()
					g_in_suite = 1
					g_current_suite_id = suite_id
					g_current_suite_success = 1
					g_current_group_number = 0
					g_current_suite_ngroups_success = 0
					g_current_suite_ngroups_error = 0
				}
				function f_group_begin( group_id ) {
					f_group_end()
					g_in_group = 1
					g_current_group_id = group_id
					++g_current_group_number
					g_current_group_success = 1
				}
				BEGIN {
					g_total_lines_success[0] = 0
					g_total_lines_error[0] = 0
					g_total_lines_suites_success[0] = 0
					g_total_lines_suites_failure[0] = 0
					g_in_group = 0
					g_in_suite = 0
				}
				{
					r_line = $0
					r_addline = 0
					r_addseparator = 0
					r_endcurrentgrouporsuite = 0
					if ( sub( "^TEST: ?", "", r_line ) > 0 ) {
						r_line_rest = r_line

						# example: TEST: SUITE: expression tests (should get 100%) [{test}/vimrc_01_selftest-ex-local-pass.vim]
						if ( sub( "^SUITE: *", "", r_line_rest ) > 0 ) {
							f_debug_lineparsing( "suite line" )
							f_suite_begin( r_line )
						}
						# example: TEST: [library high-level sanity check]
						#  old: I was replacing with "\\1"
						else if ( sub( "^(\\[.*\\])[ ]*$", "", r_line_rest ) > 0 ) {
							f_debug_lineparsing( "group start" )
							f_group_begin( r_line )
						}
						# example: TEST: RESULTS (group total): tests: 7, pass: 7 -- rate: 100.00%
						# example: TEST: RESULTS (Total): tests: 7, pass: 7 -- rate: 100.00%
						#  old: I was replacing with "\\1"
						else if ( sub( "^RESULTS \\(([^\\)]*)\\).*rate: [0-9\\.%]*[ ]*$", "", r_line_rest ) > 0 ) {
							f_debug_lineparsing( "results line" )
							r_addline = 1
							r_addseparator = 1
							r_endcurrentgrouporsuite = 1
						}
						# example: TEST:    library not intialised yet (safe check) . . . . . [pass]
						#  old: I was replacing with "\\1"
						else if ( sub( "^   .*\\[([a-zA-Z\\.-]*)\\][ ]*$", "", r_line_rest ) > 0 ) {
							f_debug_lineparsing( "test line" )
							r_line_rest = r_line
							r_line_test_success = ( match( r_line_rest, "^.*\\[pass\\][ ]*$" ) > 0 )
							f_debug( " test passed: " r_line_test_success )
							g_current_group_success = g_current_group_success && r_line_test_success
							r_addline = 1
						}
						# example: TEST:
						else if ( sub( "^[ ]*$", "", r_line_rest ) > 0 ) {
							f_debug_lineparsing( "empty line" )
						}
						else {
							f_debug_lineparsing( "unrecognised test line: " )
							r_addline = 1
						}
					}
					else {
						f_debug( "unrecognised input line -- r_line = {" r_line "}" )
					}
					# TODO: handling of lines outside a group is not really that tidy/correct
					if ( r_addline ) {
						if ( g_in_group ) {
							f_array_append_one( g_current_group_lines, r_line )
							if ( r_addseparator ) {
								f_array_append_one( g_current_group_lines, "" )
							}
						}
						else if ( g_in_suite ) {
							if ( g_current_suite_ngroups_success > 0 ) {
								f_array_append_one( g_current_suite_lines_success, r_line )
								if ( r_addseparator ) {
									f_array_append_one( g_current_suite_lines_success, "" )
								}
							}
							if ( g_current_suite_ngroups_error > 0 ) {
								f_array_append_one( g_current_suite_lines_error, r_line )
								if ( r_addseparator ) {
									f_array_append_one( g_current_suite_lines_error, "" )
								}
							}
						}
						else {
							f_debug( "found line without an active group or suite: " r_line )
						}
					}
					if ( r_endcurrentgrouporsuite ) {
						if ( g_in_group ) {
							f_group_end()
						}
						else if ( g_in_suite ) {
							f_suite_end()
						}
					}
				}
				function f_report_makemargkin( a_marginsize ) {
					return sprintf( "%*s", a_marginsize, " " )
				}
				function f_report_array( a_arr, a_msg, a_marginsize, a_nextralines			, l_arrsize, l_i, l_marginstring ) {
					l_arrsize = a_arr[ 0 ]
					if ( l_arrsize > 0 ) {
						l_marginstring = f_report_makemargkin( a_marginsize )
						if ( length( a_msg ) > 0 ) {
							print a_msg
							print ""
						}
						for ( l_i = 1; l_i <= l_arrsize; ++l_i ) {
							print l_marginstring a_arr[ l_i ]
						}
						for ( l_i = 1; l_i <= a_nextralines; ++l_i ) {
							print ""
						}
					}
				}
				END {
					f_suite_end()

					l_report_arrays_margin = 3
					l_report_prefix = "REPORT: "
					if ( g_report_success ) {
						f_report_array( g_total_lines_success, l_report_prefix "successful tests", l_report_arrays_margin )
					}
					if ( g_report_errors ) {
						f_report_array( g_total_lines_error, l_report_prefix "failed tests", l_report_arrays_margin )
					}
					if ( g_report_summary ) {
						f_report_array( g_total_lines_suites_success, l_report_prefix "successful suites", l_report_arrays_margin, 1 )
						f_report_array( g_total_lines_suites_failure, l_report_prefix "suites with failures", l_report_arrays_margin, 1 )
						l_report_prefix = "SUMMARY: "
						printf "%ssuites: %d successful, %d with failures\n\n", l_report_prefix, g_total_nsuites_success, g_total_nsuites_failure
					}
				}
				'
			;;
		*)
			return 1 ;; # internal error
	esac
}

f_getresults()
{
	case "${g_opermode}" in
		program)
			# validate that we have got parameters (abort if we don't)
			if ! [ $# -gt 0 ] ; then
				f_help 1
			fi

			g_temp_file_vimoutput=`mktemp`

			for l_getresults_file_now in "$@"
			do
				if ! [ -r "${l_getresults_file_now}" ] ; then
					# FIXME: report error
					continue
				fi
				# NOTE: I've added the redirection of '2>' so that
				#  the standard messages (':echo', ':echomsg', etc.) would not
				#  be output to the stdout/stderr of this script
				env EVLIB_VIM_TEST_OUTPUTFILE="${g_temp_file_vimoutput}" \
					${g_cmd_vim} \
							-e \
							--noplugin \
							-u "${l_getresults_file_now}" \
							-U NONE \
							+q \
							2> /dev/null \
						|| true
			done
			[ -r "${g_temp_file_vimoutput}" ] && cat "${g_temp_file_vimoutput}"
			;;

		filter)
			cat
			;;

		*)
			return 1 ;; # internal error
	esac
}
# }}}

# main code {{{
f_getresults "$@" | f_filter_results
# }}}

# vim600: set filetype=sh fileformat=unix:
# vim: set noexpandtab:
# vi: set autoindent tabstop=4 shiftwidth=4:
