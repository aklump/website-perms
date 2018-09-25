## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system.

## Installation

Suggestion installation is per the following structure where `.` is a directory above web root and inside your SCM repository.

    .
    ├── bin
    │   ├── perms -> ../opt/perms.sh
    │   ├── perms.custom.sh
    │   └── perms.local.yml
    └── opt
        ├── cloudy
        └── website-perms

To create the above structure, you can use the following one-liner which does just that.  It should be called from the top directory of the tree above, a.k.a `.`.
    
    (d="$PWD" && (test -d opt || mkdir opt) && (test -d bin || mkdir bin) && cd opt && cloudy core > /dev/null && (test -d website-perms || git clone https://github.com/aklump/website-perms.git) && (test -s $d/bin/perms || ln -s $d/opt/website-perms/perms.sh $d/bin/perms)) && ./bin/perms install
    
## To Update

Do a git pull from _opt/website_perms_.
