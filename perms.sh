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

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../cloudy/cloudy.sh"
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Something didn't work..."

implement_cloudy_basic

# Import configuration as variables.
eval $(get_config_path_as "project" "path_to.project")
exit_with_failure_if_empty_config "project"

eval $(get_config_path_as "web_root" "path_to.web_root")
exit_with_failure_if_empty_config "web_root"

eval $(get_config_path_as "custom_modules" "path_to.custom_modules")
eval $(get_config_path "path_to.private")

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
# Writable
#
eval $(get_config_path -a "writable_paths")
# Add to the writable paths by logic.
for i in $(ls "$web_root/sites/"); do
    i="$web_root/sites/$i/files"
    [ -d "$i" ] && writable_paths=("${writable_paths[@]}" "$i")
done
for i in $(ls "$path_to_private/"); do
    i="$path_to_private/$i/files"
    [ -d "$i" ] && writable_paths=("${writable_paths[@]}" "$i")
done

#
# Executable
#
eval $(get_config_path -a "executable_paths")
# This handles Node executables.
for i in $(find "$web_root" -wholename "*node_modules/.bin/*"); do
    executable_paths=("${executable_paths[@]}" "$i")
done

# This will handle all of the loft_docs command files.
declare -a loft_docs_dirs=("$project" "$custom_modules");
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
# Read Only
#
eval $(get_config_path -a "readonly_paths")
# Add to the readonly paths by logic.
for i in $(find "$web_root" -name '.htaccess' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done
for i in $(find "$web_root" -name '.htpasswd' -type f); do
   readonly_paths=("${readonly_paths[@]}" "$i")
done

# Handle other commands.
command=$(get_command)
case $command in
    info)
        echo_title "Configuration Info"

        echo_headline "Ownership and Permission Settings"
        table_add_row "user" "$perms_user"
        table_add_row "group" "$perms_group"
        table_add_row "files" "$perms_files"
        table_add_row "directories" "$perms_dirs"
        table_add_row "writable" "$perms_writable"
        table_add_row "readonly" "$perms_readonly"
        table_add_row "executable" "$perms_executable"
        echo_table && echo

        echo_headline "Read Only Paths Relative to $project"
        for i in "${readonly_paths[@]}"; do
            table_add_row "${i/$project/ }"
        done
        echo_table && echo

        echo_headline "Writable Paths Relative to $project"
        for i in "${writable_paths[@]}"; do
            table_add_row "${i/$project/ }"
        done
        echo_table && echo

        echo_headline "Executable Paths Relative to $project"
        for i in "${executable_paths[@]}"; do
            table_add_row "${i/$project/ }"
        done
        echo_table && echo

        echo_headline "Paths"
        table_add_row "project" "$project"
        table_add_row "web_root" "${web_root}"
        table_add_row "private" "${path_to_private}"
        table_add_row "custom_modules" "${custom_modules}"
        echo_table

        exit_with_success "Config OK"
    ;;

    "install")
        install_source="$ROOT/install"
        list_clear
        for file in $(ls $install_source); do
            destination="$WDIR/$file"
            if ! [ -e "$destination" ]; then
                cp "$install_source/$file" "$destination" && list_add_item "$file created" || fail_because "Could not copy $file"
            fi
        done
        has_failed && exit_with_failure
        echo_green_list
        exit_with_success "$(get_title) is installed."
    ;;

    "apply")

        echo_headline "Apply ownership and file permissions to project"
        find "$project" -exec chown $perms_chown {} + || fail_because "Could not chown files and directories."
        find "$project" -type d -exec chmod $perms_dirs {} + || fail_because "Could not set default perms on directories."
        find "$project" -type f -exec chmod $perms_files {} + || fail_because "Could set default perms on files."

        #
        # Executable permissions.
        #

        # Remove execute access to all .sh files.
        echo_headline "Remove execute perms from *.sh"
        find "$project" -type f -name "*.sh" -exec chmod ugo-x {} + || fail_because "Could not remove execute permissions from *.sh"

        # Give execute permissions as configured.
        if [ ${#executable_paths[@]} -gt 0 ]; then
            exit_with_failure_if_empty_config "perms.executable"
            echo_headline "Grant explicit execute permissions"
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
            echo_headline "Make explicit directories read-only"
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
            echo_headline "Make explicit directories writable"
            echo_list__array=()
            for path in "${writable_paths[@]}"; do
              chmod -R $perms_writable $path
              echo_list__array=("${echo_list__array[@]}" "$path")
            done
            has_option "v" && echo_green_list
        fi

        # Hide all /docs/public_html folders by adding an .htaccess with deny from all.
        echo_headline "Add deny from all for documentation directories"
        documentation_dirs=($(find "$web_root" -depth -wholename "*docs/public_html"))
        documentation_dirs=("${documentation_dirs[@]}" "$project/docs")
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
        test -f "$ROOT/_perms.custom.sh" && echo_headline "Apply custom permissions" && source "$ROOT/_perms.custom.sh"


        has_failed && exit_with_failure
        exit_with_success
    ;;

esac

throw "Unhandled command \"$command\"."
