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
            [[ "$file" == "gitignore" ]] && destination="$ROOT/.gitignore"
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
validate_input || exit_with_failure "Input validation failed."
command=$(get_command)

implement_cloudy_basic

# Import configuration as variables.
eval $(get_config_path -a "path_to")
eval $(get_config_keys_as "path_to_keys" "path_to")

# Validate all path_to keys as actual paths.
for key in "${path_to_keys[@]}"; do
    exit_with_failure_if_config_is_not_path "path_to.$key"
done

eval $(get_config -a "perms.readonly" "go-w")
eval $(get_config -a "perms.writable" "ug+w")
eval $(get_config -a "perms.executable" "ug+x")
eval $(get_config -a "perms")
exit_with_failure_if_empty_config "perms.user"
exit_with_failure_if_empty_config "perms.dirs"
exit_with_failure_if_empty_config "perms.files"
exit_with_failure_if_empty_config "perms.readonly"
exit_with_failure_if_empty_config "perms.writable"
exit_with_failure_if_empty_config "perms.executable"

# Figure out user/group ownership.
perms_chown=${perms_user}
if [[ "$perms_group" ]]; then
    perms_chown="${perms_chown}:${perms_group}"
fi

#
# Calculate writable paths.
#
eval $(get_config_path -a "writable_paths")
# Add to the writable paths by logic.

# Drupal public files.
if [ -d "${path_to_web_root}/sites/" ]; then
    for i in $(ls "${path_to_web_root}/sites/"); do
        i="${path_to_web_root}/sites/$i/files"
        [ -d "$i" ] && writable_paths=("${writable_paths[@]}" "$i")
    done
fi

# Drupal private files.
for i in $(ls "$path_to_private/"); do
    i="$path_to_private/$i/files"
    [ -d "$i" ] && writable_paths=("${writable_paths[@]}" "$i")
done

#
# Calculate executable paths
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
# Calculate read only paths.
#
eval $(get_config_path -a "readonly_paths")

# Drupal settings.
if [ -d "${path_to_web_root}/sites/" ]; then
    for i in $(ls "${path_to_web_root}/sites/"); do
        i="${path_to_web_root}/sites/$i/"
        if [ -d "$i" ]; then
            readonly_paths=("${readonly_paths[@]}" "$i")
            for j in $(ls "$i"settings*.php); do
                readonly_paths=("${readonly_paths[@]}" "$j")
            done
        fi
    done
fi

# Add to the readonly paths by logic.
for i in $(find "${path_to_web_root}" -name '.htaccess' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done
for i in $(find "${path_to_web_root}" -name '.htpasswd' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done



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
            row="${i/$path_to_project/}"
            row=${row#/}
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Writable Paths Relative to ${path_to_project}"
        for i in "${writable_paths[@]}"; do
            row="${i/$path_to_project/}"
            row=${row#/}
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Executable Paths Relative to ${path_to_project}"
        for i in "${executable_paths[@]}"; do
            row="${i/$path_to_project/}"
            row=${row#/}
            [ ! -e $i ] && row="$(echo_red $row)" && fail_because "$(basename $i) not found."
            table_add_row "$row"
        done
        echo_table && echo

        echo_heading "Paths"
        for key in "${path_to_keys[@]}"; do
            table_add_row "$key" "$(eval echo "\${path_to_$key}")"
        done
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

        # Readonly directories.
        if [ ${#readonly_paths[@]} -gt 0 ]; then
            exit_with_failure_if_empty_config "perms.readonly"
            echo_heading "Make explicit paths read-only"
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
            echo_heading "Make explicit paths writable"
            echo_list__array=()
            for path in "${writable_paths[@]}"; do
              chmod -R $perms_writable $path
              echo_list__array=("${echo_list__array[@]}" "$path")
            done
            has_option "v" && echo_green_list
        fi

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

        # Hide all /docs/public_html folders by adding an .htaccess with deny from all.
        echo_heading "Add \"deny from all\" for documentation directories"
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
