var tipuesearch = {"pages":[{"title":"Website Permissions","text":"    Summary  This script helps manage website permissions by giving you a clean YAML configuration file in which you define what paths should have READ, WRITE, and EXECUTE permissions, as well as who the user and group should be.  It facilitates different perms by environment: prod, staging, dev.  And automatically handles common Drupal path permissions.  Visit https:\/\/aklump.github.io\/website-perms for full documentation.  Quick Start   Use the following one-liner to install this script.  It should be called from the top directory of the tree above, as indicated in the installation diagram by the .  (d=\"$PWD\" &amp;&amp; (test -d opt || mkdir opt) &amp;&amp; (test -d bin || mkdir bin) &amp;&amp; cd opt &amp;&amp; cloudy core &gt; \/dev\/null &amp;&amp; (test -d perms || (git clone https:\/\/github.com\/aklump\/website-perms.git perms &amp;&amp; rm -rf perms\/.git)) &amp;&amp; (test -s $d\/bin\/perms || ln -s $d\/opt\/perms\/perms.sh $d\/bin\/perms)) &amp;&amp; .\/bin\/perms install  Open bin\/&#95;perms.local.yml and update the user and group values. Open bin\/&#95;perms.yml and modify as needed. In your CLI enter .\/bin\/perms to get an overview.   Requirements  You must have Cloudy installed on your system to install this package.  Installation  The installation script above will generate the following structure where . is a directory above web root and inside your SCM repository.  . \u251c\u2500\u2500 bin \u2502\u00a0\u00a0 \u251c\u2500\u2500 perms -&gt; ..\/opt\/perms\/perms.sh \u2502\u00a0\u00a0 \u251c\u2500\u2500 _perms.custom.sh \u2502\u00a0\u00a0 \u2514\u2500\u2500 config \u2502\u00a0\u00a0     \u251c\u2500\u2500 perms.yml \u2502\u00a0\u00a0     \u2514\u2500\u2500 perms.local.yml \u2514\u2500\u2500 opt     \u251c\u2500\u2500 cloudy     \u2514\u2500\u2500 perms   To Update   Use the following one-liner to update to the latest script version.  It should be called from the top directory of the tree above, as indicated in the diagram by the .  (cd opt &amp;&amp; git clone https:\/\/github.com\/aklump\/website-perms.git .updating__perms &amp;&amp; rsync -a --delete --exclude=.git* .updating__perms\/ perms\/; rm -rf .updating__perms)    Configuration Files       Filename   Description   VCS       perms.yml   Configuration shared across all server environments: prod, staging, dev   yes     perms.local.yml   Configuration overrides for a single environment; not version controlled.   no     &#95;perms.custom.sh   Optional.  A custom Bash script to be sourced during the apply command.  Use it for anything custom that is not handled by configuration values.  Think of this as an apply hook.   yes     Custom Configuration   You may add any additional keys to path_to, which point to paths you may wish to use in perms.custom.sh, they will automatically be made available as variables.  For example $path_to_some_path_of_yours holds the config value and is available in &#95;perms.custom.sh.  They will also be validated to make sure they are paths that exist.   Usage   For a configuration overview .\/bin\/perms To apply permissions: .\/bin\/perms apply To see all commands use .\/bin\/perms help   Contributing  If you find this project useful... please consider making a donation. ","tags":"","url":"README.html"},{"title":"Tasklist","text":"  - [ ] ld--roadmap: Fix the delay caused by deleting files at beginning of compile. - [ ] ld--todos: a task list item - [ ] ld--todos: a task list item @w-10 - [ ] demos--md_extra: Todo items will get aggregated automatically @w10 - [ ] ld--todos: a task list item @w10 - [ ] ld--todos: a task list item @w10.1  ","tags":"","url":"_tasklist.html"},{"title":"Search Results","text":" ","tags":"","url":"search--results.html"}]};
