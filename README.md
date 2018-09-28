# Website Permissions

![perms](images/screenshot.jpg)

## Summary

This script helps manage website permissions by giving you a clean YAML configuration file in which you define what paths should have READ, WRITE, and EXECUTE permissions, as well as who the user and group should be.  It facilitates different perms by environment: prod, staging, dev.  And automatically handles common Drupal path permissions.

**Visit <https://aklump.github.io/website-perms> for full documentation.**

## Quick Start

- Install in your repository root using `cloudy pm-install aklump/perms`
- Open _bin/\_perms.local.yml_ and update the `user` and `group` values.
- Open _bin/\_perms.yml_ and modify as needed.
- In your CLI enter `./bin/perms` to get an overview.

## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system to install this package.

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    ├── bin
    │   ├── perms -> ../opt/perms/perms.sh
    │   ├── _perms.custom.sh
    │   └── config
    │       ├── perms.yml
    │       └── perms.local.yml
    ├── opt
    │   ├── cloudy
    │   └── aklump
    │       └── perms
    └── {public web root}

    
### To Update

- Update to the latest version from your repo root: `cloudy pm-update aklump/perms`

## Configuration Files

| Filename | Description | VCS |
|----------|----------|---|
| _perms.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _perms.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |
| _\_perms.custom.sh_ | Optional.  One of any number of custom Bash scripts to be sourced during the `apply` command.  Use it for anything custom that is not handled by configuration values.  The filename(s) may be configured; see `post_apply_scripts`.  Return non-zero to indicate a failure. You may delete this if not used, but you must remove the path from `post_apply_scripts`.| yes |

### Custom Configuration

* You may add any additional keys to `path_to`, to use them in your `post_apply_scripts`. They will automatically be made available as variables.  For example `$path_to_some_path_of_yours` holds the config value and is available in all `post_apply_scripts`.  They will also be automatically validated to make sure they are paths that do exist.

## Usage

* For a configuration overview `./bin/perms`
* To apply permissions: `./bin/perms apply`
* To see all commands use `./bin/perms help`

If you see `Permission denied` when running commands, you will need to `sudo` the command.

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Fwebsite-perms).
