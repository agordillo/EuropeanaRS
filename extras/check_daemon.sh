#!/bin/bash

echo "[Start] EuropeanaRS check daemons script"

: ${RAILS_ENV="production"} #to get the environment variable or define it
: ${RAILS_ROOT="/u/apps/europeanars/current"}
: ${SPHINX_PID_FILE="$RAILS_ROOT/log/$RAILS_ENV.sphinx.pid"}
: ${CAP_USER="europeanars"}

rvm_installed=true

run_sphinx=false
if test -f $SPHINX_PID_FILE; then
        sphinx_ps="$(ps -p `cat $SPHINX_PID_FILE` -o comm=)"
        if [ "$sphinx_ps" != "searchd" ]; then
                run_sphinx=true
                rm $SPHINX_PID_FILE
        fi
else
        run_sphinx=true
fi

if $run_sphinx; then
        echo "Let's run sphinx!"
        cd $RAILS_ROOT
        SPHINX_COMMAND="-u $CAP_USER -H bundle exec rake ts:rebuild RAILS_ENV=$RAILS_ENV"
        if $rvm_installed; then
                source "/home/$CAP_USER/.rvm/scripts/rvm"
                SPHINX_COMMAND="rvmsudo $SPHINX_COMMAND"
        else
                SPHINX_COMMAND="sudo $SPHINX_COMMAND"
        fi
        $SPHINX_COMMAND

        #fix sphinx pid file permissions
        /bin/chmod 777 $RAILS_ROOT/log/$RAILS_ENV.searchd*
        /bin/chown $CAP_USER:www-data $RAILS_ROOT/log/$RAILS_ENV.searchd*
else
        echo "Sphinx already running"
fi

echo "[Finish] EuropeanaRS check daemons script"