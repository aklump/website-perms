## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system.

## Installation

Suggestion installation is per the following structure where `.` is a directory above web root and inside your SCM repository.

    .
    ├── bin
    │   └── perms -> ../opt/perms.sh
    └── opt
        ├── cloudy
        └── website-perms

Here a snippet to git clone and create the structure as above.
    
    (d="$PWD" && (test -d opt || mkdir opt) && (test -d bin || mkdir bin) && cd opt && cloudy core > /dev/null && (test -d website-perms || git clone https://github.com/aklump/website-perms.git) && (test -s $d/bin/perms || ln -s $d/opt/website-perms/perms.sh $d/bin/perms))
    
    
