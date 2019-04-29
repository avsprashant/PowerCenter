#!/bin/ksh
###############################################################################
#  File Name: pc_infaservice.ksh
#  Description: Script for starting/shutting down PowerCenter Domain #  Usage: See usage() below  #  Date: 05/13/2008 # #  Notes and Dependencies:
#  Calls: Requires domain name and domain ini file #  Logs:
#       $INFA_HOME/logs/
#
# Revision History
# Initial     Date          Revision details
# CONSPS      06/22/2009    Updates to include CGPC
#   mbh       10/13/2009    Changed directory from $CGPC/bin to $CGPC/etc
#   ngh       06/01/2011    Exit if domain is already UP when attempting startup.
#   ngh       06/07/2011    Cross reference check with pc_repo_list.config to make
#                              sure remote PC are not accidentally started. 
#                              Exit if that condition exists.
#   ngh       06/16/2011    Put CGPC back to /users/cgpowercenter.
#   ngh       06/24/2011    Remove unintended exit statement.
#   ngh       02/12/2014    Change echo to "echo -e" via alias for Linux
#                           Rewrote nslookup logic
#   ngh       02/14/2014    Catch command line missing arguments
#   prashant  10/28/2017    Change grep -e to egrep. Syntax correction.
####################################################################################

# ---* Source profile
[ "$(uname|tr '[:upper:]' '[:lower:]')" = "linux" ] && alias 'echo=echo -e'
CGPC=/users/cgpowercenter; export CGPC
[ -f $CGPC/etc/pc_admin.profile ] && . $CGPC/etc/pc_admin.profile || exit [ -f $CGPC/etc/pc_funcs.ksh ] && . $CGPC/etc/pc_funcs.ksh || exit

echo $0 `date +"%a %d%b%y %H:%M:%S"` `whoami` `who am i 2>/dev/null| read x y z; echo $x` >>$CGPC/logs/PC_event.log

prog="`basename $0`"
REPO_LST=$CGPC/etc/cfg/pc_repo_list.config
LOG=$CGPC/logs/`echo $prog | cut -f1 -d.`_`date +'%y%m%d.%H%M%S'`.log SUBJECT="$prog on $INFA_HOST $*"
INFAOUT=/tmp/$prog.$$
STATUS=0
typeset -l COMMAND
FLG=/tmp/pc_bounce.flg

# ---* Usage Function
usage()
  {
    echo "usage: $prog -d domain -c command [-xh]"
    echo "             -d domain_name  (required) "
    echo "             -c command (startup|shutdown) (required)"
    echo "             -x set list (for debug)"
    echo "             -h usage "
    exit 1
  }

[ $# -lt 1 ] && echo "Requires arguments" && usage
  
# ---* Start the program execution
while getopts d:c:xh argx
do
  case $argx in
    d) DOMAIN=$OPTARG;;
    c) COMMAND=$OPTARG;;
    x) set -x;; 
    h) usage;;
  esac
done

[ -z "$DOMAIN" ] && echo "requires -d domain" && usage [ -z "$COMMAND" ] && echo "requires -c startup|shutdown" && usage [ -z "$(echo $COMMAND|egrep "startup|shutdown")" ] && echo "-c must be startup|shutdown" && usage fn_log $SUBJECT echo "\n$SUBJECT"

# Check for DOMAIN running on its repective host. Cross check with pc_repo_list.config. 
# Want to avoid shutting down remote domain by accident.
dns_alias=$(grep ^$DOMAIN: $REPO_LST | awk -F: '{print $2}') dom_host=`nslookup $dns_alias|grep ^Name | awk -F: '{print $2}'|awk -F. '{print $1}' | awk '{print $1}'` dom_host_cnt=`grep ^${DOMAIN}: $REPO_LST | wc -l` if [ $dom_host_cnt -eq 1 ]; then
	curr_host=`hostname`
	if [ "$dom_host" != "$curr_host" ]; then
		echo "\nCannot startup/shutdown $DOMAIN on remote host $dom_host from $curr_host - EXIT"
		fn_log "Cannot startup/shutdown $DOMAIN on remote host $dom_host from $curr_host- EXIT"
		exit 1
	fi
elif [ $dom_host_cnt -gt 1 ]; then
	echo "\nFound multiple hosts: $dom_host for DOMAIN $DOMAIN in pc_repo_list.config - EXIT"
	exit 1
else
	echo "\nDOMAIN $DOMAIN NOT FOUND in pc_repo_list.config - EXIT"
	exit 1
fi

# Check for DOMAIN being UP if startup
OS=$(uname)
if [ -n "$(echo $OS | grep -i sunos)" ]; then
	ps_cmd="/usr/ucb/ps -auxww"
elif [ -n "$(echo $OS | grep -i linux)" ]; then
	ps_cmd="$(which ps) auxww"
fi
domain_is_up=$($ps_cmd |grep pmadmin|grep java|grep INFA_HOME) if [ $COMMAND = "startup" ]; then
	if [ -n "$domain_is_up" ]; then
		echo "\nFOUND DOMAIN $DOMAIN is UP"
		echo ""
		$ps_cmd |grep pmadmin|grep java|grep INFA_HOME
		echo "\nAttempting to START DOMAIN $DOMAIN that is UP - EXIT"
		fn_log "Attempting to START DOMAIN $DOMAIN that is UP - EXIT"
		exit
	else
		echo "\nFOUND DOMAIN $DOMAIN is DOWN\n"
	fi
elif [ $COMMAND = "shutdown" ]; then
	if [ -n "$domain_is_up" ]; then
		echo "\nFOUND DOMAIN $DOMAIN is UP\n"
		$ps_cmd |grep pmadmin|grep java|grep INFA_HOME
		echo ""
	fi
fi

# ---* Make sure all required parameters were specified [ -z "DOMAIN" -o -z "$COMMAND" ] && usage

# ---* Validate domain configuration
fn_domain_config

# ---* Check if user name is correct for the script fn_same_user

# ---* Check if hostname is correct for the domain fn_same_host

# ---* Execute infaservice (startup/shutdown) fn_run_infaservice $COMMAND $INFAOUT

# ---* Manage the PowerCenter Bounce Flag if [ $COMMAND = "shutdown" ]; then
  touch $FLG
elif [ $COMMAND = "startup" ]; then
  sleep 120
  [ -f $FLG ] && rm $FLG
fi

# ---* Cleanup
[ -f $INFAOUT ] && rm $INFAOUT

# ---* End of startup/shutdown script
