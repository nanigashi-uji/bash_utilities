# bash_utilities
Framework to provide the bash utility functions without side-effect

# Description

  `bash_utilities.sh` provides the framework for the bash script utilities.

   - Define shell functions by minimizing the side effect.
     - Only limited number of (global) shell variables will be overwrite.
     - Try to avoid name collisions as much as possible, even when it is read by `source`(`.`).
     - If function with same name has already been defined, it's backup and resorting method are automatically generated.
   - Selective load of functions.
     - If it is loaded/invoked as a symbolic link with the name of the implemented function name, only the function with that name will be loaded/invoked.
     - When it is loaded by `source`(`.`) with arguments, only the specified functions will be loaded.

# Contents

  Entity of the script file
    
    - bin/bash_utilities.sh
    
  Symblic links to `bash_utilities.sh` to change functionality
  
    - bin/run_realpath    -> bash_utilities.sh
    - bin/run_realpath.sh -> bash_utilities.sh
    - bin/which_source    -> bash_utilities.sh
    - bin/which_source.sh -> bash_utilities.sh

# Usage of the script

  - Invoke by entity file
    - Show help with '-h' option
    
    ```
    $ ./bin/bash_utilities.sh -h
    [Usage] % bash_utilities.sh -f function [options]          [-- options for function] arguments_for_function ... 
    [Usage] % bash_utilities.sh             [options] function [options for function]    arguments_for_function ... 
        ---- Define utilitiy for bash script
    [Options]
             -f func_name : Specify the function name to be executed. (Valid only for running as external script)
             -l           : Show the list of function definitions
             -L           : Show the list of restore function definitions
             -t           : Make the list display delimited by a semicolon (Valid only with -l/-L option)
             -r           : Make the list display delimited to newline (Valid only with -l/-L option, default)
             -x           : Run the resotore functions (Valid only with -L option, run once for each)
             -X           : Run the resotore functions (Valid only with -L option, run repeatly as much as possible)
             -R           : Run the resotore functions (Valid only with -L option, run repeatly keep one definition)
             -s           : Show depth of stack(Valid only with -l/-L option, default)
             -v           : Show verbose messages
             -q           : Suppress messages (quiet mode, default)
             -h           : Show Help (this message)
    [Functions] 
                run_realpath, which_source
    ```
    
    - Show list of implemented function names by '-l' option. Showing style can be changed by options `-t` or `-r`.
    
    ```
    $ ./bin/bash_utilities.sh -l
    run_realpath
    which_source
    $ ./bin/bash_utilities.sh -l -t
    run_realpath;which_source;
    ```
    
    - Show list of implemented restoring function names by '-l' option. Showing style can be changed by options `-t` or `-r`.
    
    ```
    $ ./bin/bash_utilities.sh -L 
    restore_run_realpath
    restore_which_source
    $ ./bin/bash_utilities.sh -L -t 
    restore_run_realpath;restore_which_source; 
    ```
    
    - Invoke the implemented function by selecting function name with `-f` option or first argument. if you want to call the function with the option arguments, put additional `--` before them. (otherwise, it will be recognized as the option for `bash_utilities.sh` itself.)
    
    ```
    $ ./bin/bash_utilities.sh -f run_realpath README.md 
    /.../bash_utilities/README.md
    ```
    
    ```
    $ ./bin/bash_utilities.sh run_realpath README.md 
    /.../bash_utilities/README.md
    ```
    
  - Source the entity file
    - Showing help with '-h' option, and list of functions (`-l`, `-L`) and related options (`-t`,`-r`) is same above.
    
    ```
    $ . ./bin/bash_utilities.sh -h
    [Usage] % .      bash_utilities.sh [options] functionname ... 
            % source bash_utilities.sh [options] functionname ... 
        ---- Define utilitiy for bash script
    [Options]
             -n           : Do not overwrite function definition
             -N           : Do not define restore functions
             -l           : Show the list of function definitions
             -L           : Show the list of restore function definitions
             -t           : Make the list display delimited by a semicolon (Valid only with -l/-L option)
             -r           : Make the list display delimited to newline (Valid only with -l/-L option, default)
             -x           : Run the resotore functions (Valid only with -L option, run once for each)
             -X           : Run the resotore functions (Valid only with -L option, run repeatly as much as possible)
             -R           : Run the resotore functions (Valid only with -L option, run repeatly keep one definition)
             -s           : Show depth of stack(Valid only with -l/-L option, default)
             -v           : Show verbose messages
             -q           : Suppress messages (quiet mode, default)
             -h           : Show Help (this message)
    [Functions] 
                run_realpath, which_source
    ```
    
    - If the arguments are given, the functions whose name is specified in the command line arguments and the functions on which it depends are loaded.
      
    ```
    $ . ./bin/bash_utilities.sh run_realpath
    $ declare -F run_realpath which_source restore_run_realpath restore_which_source
    run_realpath
    restore_run_realpath
    $ restore_run_realpath 
    $ declare -F run_realpath which_source restore_run_realpath restore_which_source
    $
    ```
    
    - If it is read without any arguments, all the implemented functions will be loaded.
      
    ```$ . ./bin/bash_utilities.sh
    $ declare -F run_realpath which_source restore_run_realpath restore_which_source
    run_realpath
    which_source
    restore_run_realpath
    restore_which_source
    ```
     
  - Invoke by symbolic links.
    - If it is invoked as a symbolic link with the name as `function_name` or `function_name.sh`, the implemented function with the same name will be invoked with given commandline arguments.
    
    ```
    $ ./bin/run_realpath.sh README.md 
    /.../nanigashi-uji/bash_utilities/README.md
    ```

    ```
    $ env PATH=${PATH}:"${PWD}"/bin ./bin/which_source.sh bash_utilities.sh
    /.../nanigashi-uji/bash_utilities/bin/bash_utilities.sh
    ```

  - Source the symbolic links.
    - If it is load as a symbolic link with the name as `function_name` or `function_name.sh` by `source`(`.`), the implemented function with the same name and the functions on which it depends are loaded.
      
    ```
    $ . bin/run_realpath.sh
    $ declare -F run_realpath which_source restore_run_realpath restore_which_source
    run_realpath
    restore_run_realpath
    $ restore_run_realpath 
    ```
    
    ```
    $ . bin/which_source.sh
    $ declare -F run_realpath which_source restore_run_realpath restore_which_source
    run_realpath
    which_source
    restore_run_realpath
    restore_which_source
    ```

# Procedure for Implementing a New Feature (New shell function)

1. Implement the new shell function in the area between the line marked

    ```
    ################################################################
    #        Function definitions                                  #
    ################################################################
    ```

    and the line marked

    ```
    ################################################################
    #        End of function definitions                           #
    ################################################################
    ```

    according the following template. **If it is needed to refere the shell script source path, `"${BASH_SOURCE[2]}"` instead of usual `"${BASH_SOURCE}"` because the functions will be loaded indirectly**.

    ```
    ####
    #### function_name : Description of the function
    ####  
    local func_tbd='function_name'
    if declare -f "${func_tbd}" 1>/dev/null 2>&1 && [ ${opt_not_ovrwrt:-0} -ne 0 ]; then
        [ ${opt_verbose:-0} -ne 0 ] && echo "Function is already defined. (Skipped) : ${func_tbd}" 1>&2
    elif chk_inlist "${func_tbd}" "${selected_func[@]}"; then
        local funcs_defined=( "${funcs_defined[@]}" "${func_tbd}" )
    
        function_name () {
            local script_src="${BASH_SOURCE[2]}"
            return 0
        }
        
    fi
    ```

2. (Optional) If the implemented function will use other functions defined at the same file, Implement the function dependency in the area between the line marked

    ```
    ###############################################################
    #       Resolving dependencies between functions              #
    ###############################################################
    ```

    and the line marked

    ```
    #
    # Backup function definitions
    #
    ```

    according the following template.

    ```
    # Template to describe the dependency between functions
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
    ```

3. (Optional) Make the symblic link to `bash_utilities.sh` with new function name ( or `function_name.sh` ).

## Author
  Nanigashi Uji (53845049+nanigashi-uji@users.noreply.github.com)
