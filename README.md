## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system.

## Installation

Install per the following structure where `.` is a directory above web root and inside your SCM repository.

    .
    ├── bin
    │   ├── perms -> ../opt/website-perms/perms.sh
    │   ├── _perms.custom.sh
    │   ├── _perms.yml
    │   └── _perms.local.yml
    └── opt
        ├── cloudy
        └── website-perms

Use the following one-liner to install this script.  It should be called from the top directory of the tree above, a.k.a `.`
    
    (d="$PWD" && (test -d opt || mkdir opt) && (test -d bin || mkdir bin) && cd opt && cloudy core > /dev/null && (test -d website-perms || git clone https://github.com/aklump/website-perms.git) && (test -s $d/bin/perms || ln -s $d/opt/website-perms/perms.sh $d/bin/perms)) && ./bin/perms install

## Configuration Files

| Filename | Description | VCS |
|----------|----------|---|
| _\_perms.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _\_perms.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |
| _\_perms.custom.sh_ | Optional.  A custom Bash script to be sourced during the `apply` command.  Use it for anything custom that is not handled by configuration values.  Think of this as an apply hook. | yes |

## Custom Configuration

* You may add any additional keys to `path_to`, which point to paths you may wish to use in _perms.custom.sh_, they will automatically be made available as variables.  They will also be validated as real paths.


## Usage

To apply permissions: `./bin/perms apply`

To see all commands use `./bin/perms`
    
## To Update

Do a git pull from _opt/website_perms_
