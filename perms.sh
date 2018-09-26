#!/usr/bin/env bash

#
# @file
# Lorem ipsum dolar sit amet consectador.
#

# Define the configuration file relative to this script.
CONFIG="perms.yml";

# Uncomment this line to enable file logging.
#LOGFILE="perms.log"

# TODO: Event handlers and other functions go here or source another file.
function on_pre_config() {
    if [[ "$(get_command)" == "install" ]]; then
        install_source="$ROOT/install"
        list_clear
        for file in $(ls $install_source); do
            destination="$WDIR/bin/$file"
            if ! [ -e "$destination" ]; then
                cp "$install_source/$file" "$destination" && list_add_item "$file created" || fail_because "Could not copy $file"
            fi
        done
        has_failed && exit_with_failure
        echo_green_list
        exit_with_success "Installation complete."
    fi
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../cloudy/cloudy.sh"
# End Cloudy Bootstrap

# Input validation
validate_input || exit_with_failure "Something didn't work..."
command=$(get_command)

implement_cloudy_basic

# Import configuration as variables.
eval $(get_config_path "path_to.project")
exit_with_failure_if_config_is_not_path "path_to.project"

eval $(get_config_path "path_to.web_root")
exit_with_failure_if_config_is_not_path "path_to.web_root"

eval $(get_config_path "path_to.custom_modules")
exit_with_failure_if_config_is_not_path "path_to.custom_modules"

eval $(get_config -a "perms")
exit_with_failure_if_empty_config "perms.user"
exit_with_failure_if_empty_config "perms.dirs"
exit_with_failure_if_empty_config "perms.files"

# Figure out user/group ownership.
perms_chown=${perms_user}
if [[ "$perms_group" ]]; then
    perms_chown="${perms_chown}:${perms_group}"
fi

#
# Calculate writable paths.
#
eval $(get_config_path -a "writable_paths")

#
# Calculate executable paths.
#
eval $(get_config_path -a "executable_paths")
# This handles Node executables.
for i in $(find "${path_to_web_root}" -wholename "*node_modules/.bin/*"); do
    executable_paths=("${executable_paths[@]}" "$i")
done

# This will handle all of the loft_docs command files.
declare -a loft_docs_dirs=("${path_to_project}" "${path_to_custom_modules}");
for path in "${loft_docs_dirs[@]}"; do
    for i in $(find "$path" -wholename "*/core/update.sh"); do
        executable_paths=("${executable_paths[@]}" $i)
    done
    for i in $(find "$path" -wholename "*/core/clean.sh"); do
        executable_paths=("${executable_paths[@]}" $i)
    done
    for i in $(find "$path" -wholename "*/core/compile.sh"); do
        executable_paths=("${executable_paths[@]}" $i)
    done
    for i in $(find "$path" -wholename "*/core/update.sh"); do
        executable_paths=("${executable_paths[@]}" $i)
    done
    for i in $(find "$path" -wholename "*/core/includes/webpage.tipuesearch.sh"); do
        executable_paths=("${executable_paths[@]}" $i)
    done
done

#
# Calcualte read only paths.
#
eval $(get_config_path -a "readonly_paths")
# Add to the readonly paths by logic.
for i in $(find "${path_to_web_root}" -name '.htaccess' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done
for i in $(find "${path_to_web_root}" -name '.htpasswd' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done
# Drupal settings are handled by configuration.

# Handle other commands.
case $command in
    info)
        echo_title "Configuration Info"

        echo_heading "Ownership and Permission Settings"
        table_add_row "user" "$perms_user"
        table_add_row "group" "$perms_group"
        table_add_row "files" "$perms_files"
        table_add_row "directories" "$perms_dirs"
        table_add_row "writable" "$perms_writable"
        table_add_row "readonly" "$perms_readonly"
        table_add_row "executable" "$perms_executable"
        echo_table && echo

        echo_heading "Read Only Paths Relative to ${path_to_project}"
        for i in "${readonly_paths[@]}"; do
            row="${i/${path_to_project}/ }"
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Writable Paths Relative to ${path_to_project}"
        for i in "${writable_paths[@]}"; do
            row="${i/${path_to_project}/ }"
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Executable Paths Relative to ${path_to_project}"
        for i in "${executable_paths[@]}"; do
            row="${i/${path_to_project}/ }"
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Paths"
        table_add_row "project" "${path_to_project}"
        table_add_row "web_root" "${path_to_web_root}"
        table_add_row "custom_modules" "${path_to_custom_modules}"
        echo_table

        has_failed && exit_with_failure "Configuration errors exist."
        exit_with_success "Config OK"
    ;;

    "apply")

        echo_heading "Apply ownership and file permissions to project"
        find "${path_to_project}" -exec chown $perms_chown {} + || fail_because "Could not chown files and directories."
        find "${path_to_project}" -type d -exec chmod $perms_dirs {} + || fail_because "Could not set default perms on directories."
        find "${path_to_project}" -type f -exec chmod $perms_files {} + || fail_because "Could set default perms on files."

        #
        # Executable permissions.
        #

        # Give execute permissions as configured.
        if [ ${#executable_paths[@]} -gt 0 ]; then
            exit_with_failure_if_empty_config "perms.executable"
            echo_heading "Grant explicit execute permissions"
            echo_list__array=()
            for path in "${executable_paths[@]}"; do
                chmod $perms_executable $path || fail "Could not give execute perms to $path."
                echo_list__array=("${echo_list__array[@]}" "$path")
            done
            has_option "v" && echo_green_list
        fi

        # Readonly directories.
        if [ ${#readonly_paths[@]} -gt 0 ]; then
            exit_with_failure_if_empty_config "perms.readonly"
            echo_heading "Make explicit directories read-only"
            echo_list__array=()
            for path in "${readonly_paths[@]}"; do
              chmod -R $perms_readonly $path
              echo_list__array=("${echo_list__array[@]}" "$path")
            done
            has_option "v" && echo_green_list
        fi

        # Writable directories.
        if [ ${#writable_paths[@]} -gt 0 ]; then
            exit_with_failure_if_empty_config "perms.writable"
            echo_heading "Make explicit directories writable"
            echo_list__array=()
            for path in "${writable_paths[@]}"; do
              chmod -R $perms_writable $path
              echo_list__array=("${echo_list__array[@]}" "$path")
            done
            has_option "v" && echo_green_list
        fi

        # Hide all /docs/public_html folders by adding an .htaccess with deny from all.
        echo_heading "Add deny from all for documentation directories"
        documentation_dirs=($(find "${path_to_web_root}" -depth -wholename "*docs/public_html"))
        documentation_dirs=("${documentation_dirs[@]}" "${path_to_project}/docs")
        if [ ${#documentation_dirs[@]} -gt 0 ]; then
            echo_list__array=()
            for dir in "${documentation_dirs[@]}"; do
                if [ ! -f "$dir/.htaccess" ]; then
                    echo_list__array=("${echo_list__array[@]}" "Writing $dir/.htaccess")
                    echo "deny from all" > "$dir/.htaccess"
                fi
                has_option "v" && echo_green_list
            done
        fi

        #
        #
        # Add any custom to the project extensions as _perms.custom.sh
        #
        test -f "$ROOT/_perms.custom.sh" && echo_heading "Apply custom permissions" && source "$ROOT/_perms.custom.sh"


        has_failed && exit_with_failure
        exit_with_success
    ;;

esac

throw "Unhandled command \"$command\"."
