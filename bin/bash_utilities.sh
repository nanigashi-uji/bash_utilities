#!/bin/bash
# -*- mode: shell-script ; -*-
#
# Framework to provide the bash utility functions without side-effect
#     by Uji Nanigashi (53845049+nanigashi-uji@users.noreply.github.com)
#     https://github.com/nanigashi-uji/bash_utilities.git
#

. /dev/stdin <<< "$(
      "${SED:-sed}" -nE \
       -e '/^ *#{3,} *___BEGIN_DEFINE_BASH_UTILITIES_CODE___ *#{3,}/,/^ *#{3,} *___END_DEFINE_BASH_UTILITIES_CODE___ *#{3,}/ {
               /___(BEGIN|END)_DEFINE_BASH_UTILITIES_CODE___/d ;
               /__DEFINE_BASH_UTILITIES_CODE_ORIGINAL__/{
                   s/__DEFINE_BASH_UTILITIES_CODE_ORIGINAL__.*$//p; q ;
               };
               p ;
           } ;' "${BASH_SOURCE[0]}";
    declare -f define_bash_utilities | "${SED:-sed}" -Ee 's/([\"\$\\])/\\\1/g' ;
    "${SED:-sed}" -nE \
       -e '/^ *#{3,} *___BEGIN_DEFINE_BASH_UTILITIES_CODE___ *#{3,}/,/^ *#{3,} *___END_DEFINE_BASH_UTILITIES_CODE___ *#{3,}/ {
               /__DEFINE_BASH_UTILITIES_CODE_ORIGINAL__/,/___END_DEFINE_BASH_UTILITIES_CODE___/ {
                   s/^.*__DEFINE_BASH_UTILITIES_CODE_ORIGINAL__//;
                   /___(BEGIN|END)_DEFINE_BASH_UTILITIES_CODE___/ d;  p ;
               } ;
           }' "${BASH_SOURCE[0]}"
)"

if [ "$0" == "${BASH_SOURCE[0]:-$0}" ]; then
    define_bash_utilities "$@"
    exit $?
else
    define_bash_utilities "$@"
    # unset -f define_bash_utilities
    return $?
fi

### ___BEGIN_DEFINE_BASH_UTILITIES_CODE___ ###

function define_bash_utilities () {
    # Description
    local desc="Define utilitiy for bash script"
    local def_define_bash_utilities_bak="__DEFINE_BASH_UTILITIES_CODE_ORIGINAL__"

    local script_path="$(which "${BASH_SOURCE[1]:-$0}")"
    if [ -z "${script_path}" ]; then
        if [ -f "${BASH_SOURCE[1]}" ]; then
            local script_path="${BASH_SOURCE[1]}"
        elif [[ "${BASH_SOURCE[1]}" =~ '/' ]] ; then
            local _rpcmd=
            for _rpcmd in "${REALPATH:-realpath}" realpath grealpath ; do
                if type -a "${_rpcmd}" 1>/dev/null 2>&1 ; then
                    local script_path="$("${_rpcmd}" "${BASH_SOURCE[1]}")"
                    break
                fi
            done
            if [ -z "${script_path}" ]; then
                local _idir="$(dirname "${BASH_SOURCE[1]}")"
                local _adir="$(cd "${_idir}" 2>/dev/null && pwd -L)" || { _adir="${_idir}" ; }
                local script_path="${_adir%/}/${BASH_SOURCE[1]##*/}"
            fi
        else
            local _seekpath= ifs_orig="${IFS}" IFS=':' _i= _fp=
            shopt -q sourcepath          && local _seekpath="${_seekpath}${_seekpath:+:}${PATH}"
            test -z "${POSIXLY_CORRECT}" && local _seekpath="${_seekpath}${_seekpath:+:}${PWD}"
            local script_path="${BASH_SOURCE[1]}"
            for _i in ${_seekpath}; do
                _fp="${_i%/}/${_arg##*/}"
                if [ -f "${_fp}" ]; then
                    local script_path="${_fp}"
                    break
                fi
            done
            IFS="${ifs_orig}"
        fi
    fi

    local script_name="$(basename "${script_path}")"
    local runas="${script_name%.sh}"

    # Prepare Help Messages
    local funcstatus=0
    local echo_usage_bk="$(declare -f echo_usage)"
    local chk_inlist_bk="$(declare -f chk_inlist)"
    local cleanup_bk="$(declare -f cleanup)"

    function echo_usage () {
        local idcall="${1:-1}"
        local this="${2:-${BASH_SOURCE[2]:-$0}}"
        if [ "$0" == "${BASH_SOURCE[2]:-$0}" ]; then
          if [ ${idcall:-1} -eq 1 ]; then
                echo "[Usage] % $(basename ${this}) -f function [options]          [-- options for function] arguments_for_function ... "      1>&2
                echo "[Usage] % $(basename ${this})             [options] function [options for function]    arguments_for_function ... "      1>&2
            else
                echo "[Usage] % $(basename ${this}) [options] [-- options_for_function] arguments_for_function ... " 1>&2
            fi
        else
            if [ ${idcall:-1} -eq 2 ]; then
                echo "[Usage] % .      $(basename ${this}) [options] functionname ... " 1>&2
                echo "        % source $(basename ${this}) [options] functionname ... " 1>&2
            else
                echo "[Usage] % .      $(basename ${this}) [options]" 1>&2
                echo "        % source $(basename ${this}) [options]" 1>&2
            fi
        fi
        echo "    ---- ${desc}" 1>&2
        echo "[Options]"        1>&2
        if [ "$0" == "${BASH_SOURCE[2]:-$0}" -a  ${idcall:-1} -eq 1 ]; then
            echo "         -f func_name : Specify the function name to be executed. (Valid only for running as external script)" 1>&2
        elif [ "$0" != "${BASH_SOURCE[2]:-$0}" ]; then
            echo "         -n           : Do not overwrite function definition" 1>&2
            echo "         -N           : Do not define restore functions"      1>&2
        fi
        echo "         -l           : Show the list of function definitions"                                                    1>&2
        echo "         -L           : Show the list of restore function definitions"                                            1>&2
        echo "         -t           : Make the list display delimited by a semicolon (Valid only with -l/-L option)"            1>&2
        echo "         -r           : Make the list display delimited to newline (Valid only with -l/-L option, default)"       1>&2
        echo "         -x           : Run the resotore functions (Valid only with -L option, run once for each)"                1>&2
        echo "         -X           : Run the resotore functions (Valid only with -L option, run repeatly as much as possible)" 1>&2
        echo "         -R           : Run the resotore functions (Valid only with -L option, run repeatly keep one definition)" 1>&2
        echo "         -s           : Show depth of stack(Valid only with -l/-L option, default)"                               1>&2
        echo "         -v           : Show verbose messages"                                                                    1>&2
        echo "         -q           : Suppress messages (quiet mode, default)"                                                  1>&2
        echo "         -h           : Show Help (this message)"                                                                 1>&2
        if [ "${#func_defs[@]}" -gt 0 ]; then
            echo   "[Functions] "                      1>&2
            printf "            %s" "${func_defs[0]}"; 1>&2
            printf ", %s" "${func_defs[@]:1}"          1>&2
            printf "\n"                                1>&2
        fi
        return
    }

    function chk_inlist () {
        local _f="$1" _i= _s=1; shift
        for _i in "$@"; do
            [ "x${_i:-0}" == "x${_f:-1}" ] && { _s=0 ; break ; }
        done
        return ${_s}
    }

    local hndlrhup_bk="$(trap -p SIGHUP)"
    local hndlrint_bk="$(trap -p SIGINT)"
    local hndlrquit_bk="$(trap -p SIGQUIT)"
    local hndlrterm_bk="$(trap -p SIGTERM)"

    trap -- 'cleanup ; kill -1  $$' SIGHUP
    trap -- 'cleanup ; kill -2  $$' SIGINT
    trap -- 'cleanup ; kill -3  $$' SIGQUIT
    trap -- 'cleanup ; kill -15 $$' SIGTERM

    function cleanup () {
        # Restore  signal handler
        if [ -n "${hndlrhup_bk}"  ] ; then eval "${hndlrhup_bk}"  ;  else trap --  1 ; fi
        if [ -n "${hndlrint_bk}"  ] ; then eval "${hndlrint_bk}"  ;  else trap --  2 ; fi
        if [ -n "${hndlrquit_bk}" ] ; then eval "${hndlrquit_bk}" ;  else trap --  3 ; fi
        if [ -n "${hndlrterm_bk}" ] ; then eval "${hndlrterm_bk}" ;  else trap -- 15 ; fi

        # Restore functions
        unset echo_usage
        test -n "${echo_usage_bk}" &&  eval "${echo_usage_bk}"

        unset chk_inlist
        test -n "${chk_inlist_bk}" &&  eval "${chk_inlist_bk}"

        unset cleanup
        test -n "${cleanup_bk}" &&  eval "${cleanup_bk}"

        unset -f define_bash_utilities
        [ -n "${def_define_bash_utilities_bak}" ] && eval "${def_define_bash_utilities_bak}"
     }

    local run_args=() selected_func=() defined_func=()

    local sed_pick_def=( -E -n -e 's/#.*//g' \
                            -e '/^ *(function +)?'"${FUNCNAME[0]}"' *\(\)/,/^ *(function +)?cleanup *\(\)/! s/ *(function +)?([0-9a-zA-Z_]+) *\( *\) *{?/\2/gp')


    local func_defs=( $("${SED:-sed}" "${sed_pick_def[@]}" "${script_path}") )


    local _iarg=
    local opt_funcexec="" opt_help=0 opt_list=0 opt_verbose=0 opt_not_ovrwrt=0 opt_dlmtr="\n" opt_not_restorable=0 opt_run_restore=0 opt_show_stack=0
    if [ "$0" == "${BASH_SOURCE[1]:-$0}" ]; then
        local opt_not_restorable=1
    fi

    if [ -L "${script_path}" ] &&  chk_inlist "${runas}" "${func_defs[@]}" ; then

        # If the functon definition is invoked from a symbolic link
        # with the same name as a certain function, then only that
        # function is defined. Also, if the function is executed as a
        # external script, the function will be executed with the
        # command line argument passed.
        local selected_func=( "${runas}" )
        local opt_funcexec="${runas}"
        local run_args=( "$@" )

    else

        local OPT="" OPTARG="" OPTIND=""
        if [ "$0" == "${BASH_SOURCE[1]:-$0}" ]; then
            local _cmdopts="hlLxXRstrvqf:"
        else
            local _cmdopts="hlLxXRstrvqnNt"
        fi
        while getopts "${_cmdopts}" OPT ; do
            case "${OPT}" in
                f)  opt_funcexec="${OPTARG}" ;;
                h)  opt_help=1 ;;
                l)  opt_list=1 ;;
                L)  opt_list=2 ;;
                t)  opt_dlmtr=";" ;;
                r)  opt_dlmtr="\n" ;;
                x)  opt_run_restore=1 ;;
                R)  opt_run_restore=2 ;;
                X)  opt_run_restore=3 ;;
                s)  opt_show_stack=1 ;;
                v)  opt_verbose=$((opt_verbose+1)) ;;
                q)  opt_verbose=0 ;;
                n)  opt_not_ovrwrt=1 ;;
                N)  opt_not_restorable=1 ;;
                \?) opt_help=2 ;;
                *)  opt_help=3 ;;

            esac
        done
        shift $((OPTIND - 1))

        if [ "$0" == "${BASH_SOURCE[1]:-$0}" ]; then
            [ ${opt_verbose:-0} -gt 1 ] && echo "[${FUNCNAME[0]:-$0}:${BASH_SOURCE[1]:-$0}] : Run as external process" 1>&2
        else
            [ ${opt_verbose:-0} -gt 1 ] && echo "[${FUNCNAME[0]:-$0}:${BASH_SOURCE[1]:-$0}] : Loaded as same process" 1>&2
        fi

        if [ ${opt_list:-0} -ne 0 ]; then
            local func_tbd=
            if [ ${opt_list:-0} -eq 1 ]; then
                if [ ${opt_show_stack:-0} -ne 0 ]; then
                    for func_tbd in "${func_defs[@]}"; do
                        declare -F "${func_tbd}" 1>/dev/null 2>&1 && local chk="defined" || local chk="undefined"
                        local num_stack=$(eval echo '${#__'"${func_tbd}"'_bk[@]}')
                        "${PRINTF:-printf}" "%-25s : %-10s : stack depth = %d\n" "${func_tbd}" "${chk}" "${num_stack:-0}"
                    done
                else
                    "${PRINTF:-printf}" "%s${opt_dlmtr}" "${func_defs[@]}"
                fi
            else
                if [ ${opt_run_restore:-0} -eq 0 ]; then
                    if [ ${opt_show_stack:-0} -ne 0 ]; then
                        for func_tbd in "${func_defs[@]}"; do
                            declare -F "restore_${func_tbd}" 1>/dev/null 2>&1 && local chk="defined" || local chk="undefined"
                            local num_stack=$(eval echo '${#__restore_'"${func_tbd}"'_bk[@]}')
                            "${PRINTF:-printf}" "%-32s : %-10s : stack depth = %d\n" "restore_${func_tbd}" "${chk}" "${num_stack:-0}"
                        done
                    else
                        "${PRINTF:-printf}" "restore_%s${opt_dlmtr}" "${func_defs[@]}"
                    fi
                else
                    for func_tbd in "${func_defs[@]}"; do
                        if [ ${opt_run_restore:-0} -eq 1 ]; then
                            if [ ${opt_verbose:-0} -ne 0 ]; then
                                echo declare -F "restore_${func_tbd}"' 1>/dev/null 2>&1 && '"restore_${func_tbd}"
                            fi
                            declare -F "restore_${func_tbd}" 1>/dev/null 2>&1 && "restore_${func_tbd}"
                        elif [ ${opt_run_restore:-0} -eq 2 ]; then
                            local num_bk=$(eval echo '${#__restore_'"${func_tbd}"'_bk[@]}')
                            local _i=
                            for ((_i=1;_i<num_bk;_i++)); do
                                if [ ${opt_verbose:-0} -ne 0 ]; then
                                    echo 'declare -F restore_'"${func_tbd}"' 1>/dev/null 2>&1 && restore_'"${func_tbd}"
                                fi
                                declare -F "restore_${func_tbd}" 1>/dev/null 2>&1 && "restore_${func_tbd}"
                            done
                        elif [ ${opt_run_restore:-0} -gt 2 ]; then
                            while declare -F restore_'"${func_tbd}"' 1>/dev/null 2>&1 ; do
                                if [ ${opt_verbose:-0} -ne 0 ]; then
                                    echo "restore_${func_tbd}"
                                fi
                                "restore_${func_tbd}"
                            done
                        fi
                    done
                fi
            fi
            [[ "${opt_dlmtr}" == "\n" ]] || echo ;
            cleanup
            return 0
        fi

        if [ "$0" == "${BASH_SOURCE[1]:-$0}" ]; then
            if [ ${opt_help:-0} -ne 0 ]; then
                echo_usage 1 "${script_name}"
                cleanup
                return $((${opt_help}-1))
            fi
            # Otherwise, if this script is invoked as new process,
            # execute function specified by "-f" option or first argument
            # with remaining arguments.
            if [ -n "${opt_funcexec}" ]; then
                if chk_inlist "${opt_funcexec}" "${func_defs[@]}"; then
                    local selected_func=( "${opt_funcexec}" )
                    local run_args=( "$@" )
                else
                    [ ${opt_verbose:-0} -ne 0 ] && echo "Can not find function : ${opt_funcexec}" 1>&2
                    local opt_funcexec=''
                fi
            else
                if [ $# -lt 1 ]; then
                    [ ${opt_verbose:-0} -ne 0 ] && echo "No function specified: (do nothing)" 1>&2
                else
                    if chk_inlist "${1}" "${func_defs[@]}"; then
                        local opt_funcexec="$1" selected_func=( "${1}" )
                        shift
                        local run_args=( "$@" )
                    else
                        [ ${opt_verbose:-0} -ne 0 ] && echo "Can not find function : ${1} : (do nothing)" 1>&2
                    fi
                fi
            fi
        else
            if [ ${opt_help:-0} -ne 0 ]; then
                echo_usage 2 "${script_name}"
                cleanup
                return $((${opt_help}-1))
            fi
            # Otherwise, when this script is read by ``source'' (``.''),
            # the functions specified by the command line arguments, if
            # any, or all functions without command line arguments are
            # defined.

            if [ $# -gt 0 ]; then
                local selected_func=( $("${PRINTF:-printf}" "%s\n" "$@" | "${GREP:-grep}" -x $("${PRINTF:-printf}" -- "-e %s " "${func_defs[@]}")))
                if [ ${#selected_func[@]} -lt 1 ]; then
                    [ ${opt_verbose:-0} -ne 0 ] && echo "No match definitions in : $@" 1>&2
                fi
            else
                local selected_func=( "${func_defs[@]}" )
            fi
            local opt_funcexec='' run_args=()
        fi
    fi


    ###############################################################
    #       Resolving dependencies between functions              #
    ###############################################################

    # which_source needs run_realpath
    local func_tbd='which_source'
    local func_deps=( 'run_realpath' )
    if chk_inlist "${func_tbd}" "${selected_func[@]}"; then
        local _fdep=
        for _fdep in "${func_deps[@]}"; do
            if declare -f "${_fdep}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -eq 0 ] ; then
                continue
            fi
            local selected_func=( "${selected_func[@]}" "${_fdep}" )
        done
    fi

    #
    # Make list without duplicated candidates
    #
    local selected_func=( $("${PRINTF:-printf}" "%s\n" "${selected_func[@]}" | "${SORT:-sort}" | "${UNIQ:-uniq}") )
    #
    # Backup function definitions
    #
    local func_tbd=
    if [ ${opt_not_restorable:-0} -eq 0 ]; then
        for func_tbd in "${selected_func[@]}"; do
            if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -eq 0 ]; then
                eval '__'"${func_tbd}"'_bk=( "$(declare -f "'"${func_tbd}"'" "${__'"${func_tbd}"'_bk[@]}" )" )'
            fi
        done
    fi

    ################################################################
    #        Function definitions                                  #
    ################################################################

    ####
    #### run_realpath : Seek realpath and use it
    ####
    local func_tbd='run_realpath'

    if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -ne 0 ]; then
        [ ${opt_verbose:-0} -ne 0 ] && echo "Function is already defined. (Skipped) : ${func_tbd}" 1>&2
    elif chk_inlist "${func_tbd}" "${selected_func[@]}"; then
        local funcs_defined=( "${funcs_defined[@]}" "${func_tbd}" )

        run_realpath () {
            # local script_src="${BASH_SOURCE[2]}"
            local _rpcmd= _i= _s=0
            for _rpcmd in "${REALPATH:-realpath}" realpath grealpath ; do
                if type -a "${_rpcmd}" 1>/dev/null 2>&1 ; then
                    "${_rpcmd}" "$@"
                    return $?
                fi
            done
            if type -a "${PYTHON:-python3}" 1>/dev/null 2>&1; then
                for _i in "$@"; do
                    "${PYTHON:-python3}" -c "import os.path; print(os.path.realpath('""${_i}""'))" || _s=1
                done
                return ${_s}
            fi
            for _i in "$@"; do
                local _idir="$(dirname "${_i}")"
                local _adir="$(cd "${_idir}" 2>/dev/null && pwd -L)" || { _adir="${_idir}" ; _s=1 ; }
                echo "${_adir%/}/${_i##*/}"
            done
            return ${_s}
        }

    fi



    ####
    #### which_source : Seek the source file
    ####
    local func_tbd='which_source'

    if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -ne 0 ]; then
        [ ${opt_verbose:-0} -ne 0 ] && echo "Function is already defined. (Skipped) : ${func_tbd}" 1>&2
    elif chk_inlist "${func_tbd}" "${selected_func[@]}"; then
        local funcs_defined=( "${funcs_defined[@]}" "${func_tbd}" )

        which_source () {
            # local script_src="${BASH_SOURCE[2]}"
            # Use "run_realpath"
            [ $# -lt 1 ] && return
            local _arg="${1}" _ret= _s=0
            if [[ "${_arg}" =~ '/' ]] ; then
                _ret="$(run_realpath "${_arg}")"
                if [ $? -eq 0 -a -f "${_ret}" ]; then
                    _s=0
                else
                    _s=1
                    echo "[${FUNCNAME[0]}] ERROR: File not exist: ${_arg}" 1>&2
                fi
            else
                local _seekpath= IFS=':' _i= _fp=
                shopt -q sourcepath          && local _seekpath="${_seekpath}${_seekpath:+:}${PATH}"
                test -z "${POSIXLY_CORRECT}" && local _seekpath="${_seekpath}${_seekpath:+:}${PWD}"
                for _i in ${_seekpath}; do
                    _fp="${_i%/}/${_arg##*/}"
                    if [ -f "${_fp}" ]; then
                        _ret="${_fp}"
                        _s=0
                        break
                    fi
                done
                if [ -z "${_ret}" ]; then
                    _s=1
                    echo "[${FUNCNAME[0]}] ERROR: Can not find : ${_arg}" 1>&2
                fi
            fi
            echo "${_ret}"
            return "${_s}"
        }
    fi


    # ####
    # #### Template
    # ####
    # #### function_name : Description of the function
    # ####
    # local func_tbd='function_name'
    # if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -ne 0 ]; then
    #     [ ${opt_verbose:-0} -ne 0 ] && echo "Function is already defined. (Skipped) : ${func_tbd}" 1>&2
    # elif chk_inlist "${func_tbd}" "${selected_func[@]}"; then
    #     local funcs_defined=( "${funcs_defined[@]}" "${func_tbd}" )
    #
    #     function_name () {
    #         local script_src="${BASH_SOURCE[2]}"
    #         return 0
    #     }
    #
    # fi

    # ####
    # #### Another Template
    # ####
    # #### function_name : Description of the function
    # ####
    # local func_tbd='function_name'
    # if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -ne 0 ]; then
    #     [ ${opt_verbose:-0} -ne 0 ] && echo "Function is already defined. (Skipped) : ${func_tbd}" 1>&2
    # elif chk_inlist "${func_tbd}" "${selected_func[@]}"; then
    #     local funcs_defined=( "${funcs_defined[@]}" "${func_tbd}" )
    # 
    #     function function_name () {
    #         # Description
    #         local desc="Template of shell script without side effect for 'source'"
    #         local script_src="${BASH_SOURCE[2]}"
    #         # Prepare Help Messages
    #         local funcstatus=0
    #         local echo_function_usage_bk="$(declare -f echo_function_usage)"
    #         local function_cleanup_bk="$(declare -f function_cleanup)"
    #         local tmpfiles=()
    #         local tmpdirs=()
    # 
    #         function echo_function_usage () {
    #             if [ "$0" == "${BASH_SOURCE[2]:-$0}" ]; then
    #                 local this=$0
    #             else
    #                 local this="${FUNCNAME[1]}"
    #             fi
    #             echo "[Usage] % $(basename ${this}) options"            1>&2
    #             echo "    ---- ${desc}"                                 1>&2
    #             echo "[Options]"                                        1>&2
    #             echo "           -d path   : Set destenation "          1>&2
    #             echo "           -h        : Show Help (this message)"  1>&2
    #             return
    #             :
    #         }
    # 
    #         local hndlrhup_bk="$(trap -p SIGHUP)"
    #         local hndlrint_bk="$(trap -p SIGINT)"
    #         local hndlrquit_bk="$(trap -p SIGQUIT)"
    #         local hndlrterm_bk="$(trap -p SIGTERM)"
    # 
    #         trap -- 'function_cleanup ; kill -1  $$' SIGHUP
    #         trap -- 'function_cleanup ; kill -2  $$' SIGINT
    #         trap -- 'function_cleanup ; kill -3  $$' SIGQUIT
    #         trap -- 'function_cleanup ; kill -15 $$' SIGTERM
    # 
    #         function function_cleanup () {
    # 
    #             # removr temporary files and directories
    #             if [ ${#tmpfiles} -gt 0 ]; then
    #                 rm -f "${tmpfiles[@]}"
    #             fi
    #             if [ ${#tmpdirs} -gt 0 ]; then
    #                 rm -rf "${tmpdirs[@]}"
    #             fi
    # 
    #             # Restore  signal handler
    #             if [ -n "${hndlrhup_bk}"  ] ; then eval "${hndlrhup_bk}"  ;  else trap --  1 ; fi
    #             if [ -n "${hndlrint_bk}"  ] ; then eval "${hndlrint_bk}"  ;  else trap --  2 ; fi
    #             if [ -n "${hndlrquit_bk}" ] ; then eval "${hndlrquit_bk}" ;  else trap --  3 ; fi
    #             if [ -n "${hndlrterm_bk}" ] ; then eval "${hndlrterm_bk}" ;  else trap -- 15 ; fi
    # 
    #             # Restore alias and functions
    # 
    #             unset echo_function_usage
    #             test -n "${echo_function_usage_bk}" && { eval "${echo_function_usage_bk}" ; }
    # 
    #             unset function_cleanup
    #             test -n "${function_cleanup_bk}"    && { eval "${function_cleanup_bk}"    ; }
    #         }
    # 
    #         # Analyze command line options
    #         local OPT="" OPTARG="" OPTIND=""
    #         local dest=""
    #         while getopts "d:h" OPT ; do
    #             case "${OPT}" in
    #                 d) local dest="${OPTARG}"
    #                    ;;
    #                 h) echo_function_usage
    #                    function_cleanup
    #                    return 0
    #                    ;;
    #                 \?) echo_function_usage
    #                     function_cleanup
    #                     return 1
    #                     ;;
    #             esac
    #         done
    #         shift $((OPTIND - 1))
    # 
    #         local scriptpath="${BASH_SOURCE[2]:-$0}"
    #         local scriptdir="$(dirname "${scriptpath}")"
    #         if [ "$0" == "${BASH_SOURCE[2]:-$0}" ]; then
    #             local this="$(basename "${scriptpath}")"
    #         else
    #             local this="${FUNCNAME[0]}"
    #         fi
    # 
    #         local tmpdir0=$(mktemp -d "${this}.tmp.XXXXXX" )
    #         local tmpdirs=( "${tmpdirs[@]}" "${tmpdir0}" )
    #         local tmpfile0=$(mktemp   "${this}.tmp.XXXXXX" )
    #         local tmpfiles=( "${tmpfiles[@]}" "${tmpfile0}" )
    # 
    #         echo "------------------------------"
    #         echo "called as ${this} (src=${script_src})"
    #         echo "ARGS:" "$@"
    #         echo "------------------------------"
    #         echo_function_usage 0
    # 
    #         # clean up
    #         function_cleanup
    #         return ${funcstatus}
    #     }
    # 
    # fi

    ################################################################
    #        End of function definitions                           #
    ################################################################
    #
    # Define the functions from restore the original definition
    #
    local func_tbd=
    if [ ${opt_not_restorable:-0} -eq 0 ]; then
        for func_tbd in "${funcs_defined[@]}"; do

            if eval 'declare -f restore_'"${func_tbd}" 1>/dev/null 2>&1 ; then
                eval '__restore_'"${func_tbd}"'_bk=( "$(declare -f restore_'"${func_tbd}"')" "${__restore_'"${func_tbd}"'_bk[@]}" )'
            fi

            eval 'restore_'"${func_tbd}"' () {
                unset -f '"${func_tbd}"'
                if [ "x$1" == "x-f" -o "x$1" == "x-C" ]; then
                    if [ "${#__'"${func_tbd}"'_bk[@]}" -gt 1 ]; then
                        __'"${func_tbd}"'_bk=( "${__'"${func_tbd}"'_bk[$((${#__'"${func_tbd}"'_bk[@]}-1))]}" )
                    fi
                    if [ "${#__restore_'"${func_tbd}"'_bk[@]}" -gt 1 ]; then
                        __restore_'"${func_tbd}"'_bk=( "${__restore_'"${func_tbd}"'_bk[$((${#__restore_'"${func_tbd}"'_bk[@]}-1))]}" )
                    fi
                fi

                if [ ${#__'"${func_tbd}"'_bk[@]} -gt 0 ]; then
                    test -n "${__'"${func_tbd}"'_bk[0]}" -a "x$1" \!= "x-C" \
                        && eval "${__'"${func_tbd}"'_bk[0]}"
                    if [ ${#__'"${func_tbd}"'_bk[@]} -gt 1 ]; then
                        __'"${func_tbd}"'_bk=( "${__'"${func_tbd}"'_bk[@]:1}" )
                    else
                        unset __'"${func_tbd}"'_bk
                    fi
                fi

                unset -f restore_'"${func_tbd}"'
                if [ ${#__restore_'"${func_tbd}"'_bk[@]} -gt 0 ]; then
                    test -n "${__restore_'"${func_tbd}"'_bk[0]}" -a "x$1" \!= "x-C" \
                        && eval "${__restore_'"${func_tbd}"'_bk[0]}"
                    if [ ${#__restore_'"${func_tbd}"'_bk[@]} -gt 1 ]; then
                        __restore_'"${func_tbd}"'_bk=( "${__restore_'"${func_tbd}"'_bk[@]:1}" )
                    else
                        unset __restore_'"${func_tbd}"'_bk
                    fi
                fi
            }'
        done
    fi

    #
    # Invoking function if specified
    #
    if [ "$0" == "${BASH_SOURCE[1]:-$0}" ]; then
        if [ -n "${opt_funcexec}" ] ; then
            if declare -f "${opt_funcexec}" 1> /dev/null 2>&1 ; then
                "${opt_funcexec}" "${run_args[@]}"
            else
                echo "Function is not defined : ${opt_funcexec}" 1>&2
                cleanup
                return 1
            fi
        fi
    fi
    cleanup
    return 0
}

### ___END_DEFINE_BASH_UTILITIES_CODE___ ###

#
# The script definition is ended here.
#
