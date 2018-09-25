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

# Handle other commands.
command=$(get_command)
case $command in

    "install")
        install_source="$ROOT/install"
        bin_dir=$(realpath "$ROOT/../..")

        # Create symlink in bin/perms
        [ -s "$bin_dir/perms" ] || ln -s "$install_source/perms.sh" "$bin_dir/perms" || fail_because "Could not create symlink $bin_dir/perms"

        # Copy over user files.
        list_clear
        for file in "$(ls $install_source)"; do
            if [ ! -e $bin_dir/$file ]; then
                cp $install_source/$file $bin_dir/$file && list_add "$file created" || fail_because "Could not copy $file"
            fi
        done
        echo_green_list

        has_failed && exit_with_failure
        exit_with_success
    ;;

esac

throw "Unhandled command \"$command\"."
