#!/bin/ksh
###############################################################################
#  File Name: pc_funcs.ksh
#  Description: Functions used in PowerCenter scripts #  Usage: See usage() below #  Date: 05/13/2008 # #  Notes and Dependencies:
#  Calls: Requires domain name and domain ini file #  Logs:
#       $CGPC/logs/

# Revision History
# Initial     Date          Revision details
# consps      10/02/2008   New error codes added to error exclusion list
#                          UM_10007, UM_10008, PCSF_10062, PCSF_10520, UM_10037
# consps      02/05/2009   Changes to analyze function
# consps      03/31/2009   Updates for awk/nawk compatibility with SunOS
# consps      05/20/2009   Move scripts to $CGPC/bin folder
#   mbh       10/12/2009   Fixed egrep in fn_analyze_log function
#   mbh       10/13/2009   Changed directory from $CGPC/bin to $CGPC/etc
#   mbh       10/16/2009   Moved pc_repo_list.config to subdirectory cfg
#   mbh       11/04/2009   Set STATUS=0 in fn_same_host
#   ngh       02/05/2014   Authentication info into domain obtained via global ENV variables
#   ngh       02/14/2014   Get repo PASS env using 4th arg instead of 5th from pc_repo_list.config
####################################################################################
# set -x

function fn_log {
 # echo $prog: $(date +%Y.%m.%d_%H:%M:%S) - "$@" |tee -a $LOG  echo $prog: $(date +%Y.%m.%d_%H:%M:%S) - "$@" >> $LOG }

function fn_check_return {
  if [ $1 -ne 0 ]; then
    fn_log "$2 : ERROR"
    STATUS=1
    fn_mail
    exit
  else 
    fn_log "$2 : SUCCESS"
  fi
}

function fn_mail {
  if [ ${#SUBJECT} -ne 0 -a ${#MAILLIST} -ne 0 ]; then
    mailx -r "$SENDER" -s "$SUBJECT " `print $MAILLIST` < $LOG
  fi
}

function fn_check_file {
  STATUS=0
  [[ ! -r $1 ]] && STATUS=1
  fn_check_return $STATUS "Access to $1"
}

function fn_same_user {
  STATUS=0
  CURRID=`whoami`
  [[ $CURRID != "pmadmin" ]] && STATUS=1
  fn_check_return $STATUS "Program $prog run with $CURRID"
}

function fn_same_host {
  [[ $INFA_HOST != `hostname` ]] && STATUS=0
  fn_check_return $STATUS "Program $prog run on host of $DOMAIN"
}

function fn_pass_config {
  CONFIG=$CGPC/.Xcat

  # ---* Verify the access to config file
  STATUS=0
  [[ ! -r $CONFIG ]] && STATUS=1
  fn_check_return $STATUS "Access to $CONFIG"

  # awk/nawk
  AWK=awk
  [ $(uname -s) = "SunOS" ] && AWK=nawk

  # ---* Get script parameters from config file
  $AWK -F: -v label=ENCRPT$PASS '$1==label {print $2}' $CONFIG | \
  read PC_CONST

  fn_check_return $? "Password Configuration"
  export PC_CONST
  export INFA_DEFAULT_DOMAIN_PASSWORD=$PC_CONST
  export INFA_DEFAULT_DATABASE_PASSWORD=$PC_CONST
}

function fn_domain_config {
  CONFIG=$CGPC/etc/cfg/pc_repo_list.config
 
  # ---* Verify the access to config file
  STATUS=0
  [[ ! -r $CONFIG ]] && STATUS=1
  fn_check_return $STATUS "Access to $CONFIG"

  # awk/nawk
  AWK=awk
  [ $(uname -s) = "SunOS" ] && AWK=nawk
  
  # ---* Get script parameters from config file

  $AWK -F: -v label=$DOMAIN '$1==label {print $2, $3, $4, $6, $7, $8, $9}' $CONFIG | \
  read INFA_HOST INFA_PORT PASS DB_USER DB_NAME DB_HOST DB_PORT
  fn_check_return $? "Configuration of $DOMAIN"

  export INFA_DEFAULT_DOMAIN=$DOMAIN
  export INFA_DEFAULT_DOMAIN_USER=pm_repo

}

function fn_repo_config {
  CONFIG=$CGPC/etc/cfg/pc_repo_list.config
    
  # ---* Verify the access to config file
  STATUS=0
  [[ ! -r $CONFIG ]] && STATUS=1
  fn_check_return $STATUS "Access to $CONFIG"

  # awk/nawk
  AWK=awk
  [ $(uname -s) = "SunOS" ] && AWK=nawk

  # ---* Get script parameters from config file
  grep -v ^# $CONFIG | grep -w $REPO | \
  $AWK -F: -v label=$REPO '$1==label {print $2, $3, $4, $6, $7, $8}' $CONFIG | \
  read INFA_HOST INFA_PORT PASS DB_USER DB_NAME DOMAIN
  fn_check_return $? "Configuration of $REPO" 
  export INFA_DEFAULT_DOMAIN=$DOMAIN
  export INFA_DEFAULT_DOMAIN_USER=pm_repo }

function fn_bte_config {
  CONFIG=$CGPC/etc/bte_pc.config

  # ---* Verify the access to config file
  STATUS=0
  [[ ! -r $CONFIG ]] && STATUS=1
  fn_check_return $STATUS "Access to $CONFIG"

  # awk/nawk
  AWK=awk
  [ $(uname -s) = "SunOS" ] && AWK=nawk

  # ---* Get script parameters from config file
  grep -v ^# $CONFIG | grep -w $LABEL | \
  $AWK -F: -v label=$LABEL '$1==label {print $2, $3, $4}' $CONFIG | \
  read REPO PMUSER EMAIL
  fn_check_return $? "BTE configuration for $LABEL"
}

function fn_create_connection {
  export INFA_REPCNX_INFO=/tmp/$prog.$$.cnxinfo
  $INFA_HOME/server/bin/pmrep connect -r $REPO -d $DOMAIN \
  -n $INFA_USER -X PC_CONST  2>&1 > /dev/null
  fn_check_return $? "Connection to $REPO"
}

function fn_close_connection {
  $INFA_HOME/server/bin/pmrep cleanup 2>&1 > /dev/null
  [[ -f $INFA_REPCNX_INFO ]] && rm $INFA_REPCNX_INFO
  unset INFA_USER
  unset PC_CONST
}

function fn_run_infasetup {
  $INFA_HOME/server/infasetup.sh $1 -da "$DB_HOST:$DB_PORT" -du $DB_USER \
    -dt Oracle -ds $DB_NAME $2 > $3  ; ret=$?
    cat $3 | tee -a $LOG
  fn_check_return $ret "Run command $@"
}

function fn_run_infacmd {
  $INFA_HOME/server/bin/infacmd.sh $1 $2 > $3  ; ret=$?
  cat $3 | tee -a $LOG
  fn_check_return $ret "Run command $@"
}

function fn_run_infaservice {
  $INFA_HOME/server/tomcat/bin/infaservice.sh $1 > $2  ; ret=$?
  cat $2 | tee -a $LOG
  fn_check_return $ret "Run command $@"
}

function fn_run_pmrep {
  $INFA_HOME/server/bin/pmrep $1 > $2 ; ret=$?
  cat $2 | tee -a $LOG
  fn_check_return $ret "Run command $@"
}

function fn_connect_pmcmd {
  $INFA_HOME/server/bin/pmcmd $1 -u $INFA_USER -p $PC_CONST $2 > $3  ; ret=$?
  cat $3 | tee -a $LOG
  fn_check_return $ret "Run command $@"
}

function fn_analyze_log {
# ---* Errors to ignore
# OBJM_54542 : password invalid
# CNX_53021 : Received an invalid request.
# SF_34030 : Client application [Workflow Monitor],...., error message [Connection reset by peer] # LM_36320 : Workflow [xxxxx]: Execution failed.
# LM_44198 : Failure writing Repository Connection Id [1291] to disk.
# OBJM_54543 : Database error
# SPC_10008 : Service Process output error # AUTHEN_10000 : The Service Manager failed to authenticate user [pm_repo] in security domain [Native] # AUTHEN_10003 : The Service Manager failed to authenticate user # UM_10034 : The Service Manager could not authenticate user # LM_36803 : Workflow : Could not schedule workflow, time has expired # CNX_53021 : Received an invalid request.
# LM_44237 : Failure writing Repository Connection Id [13] to disk.
# REP_12400 : Repository Error
# REP_12014 : An error occurred while accessing the repository # LGS_10006 : The file was skipped during automatic purge # UM_10007 : The user does not exist in the domain # UM_10008 : The Service Manager failed to create the user # PCSF_10062 : Failed to validate group # PCSF_10520 : A duplicate user reference in group # UM_10037 : The security domain [] does not exist in the domain

IGNORE_LIST="(OBJM_54542|CNX_53021|SF_34030|LM_36320|LM_44198|OBJM_54543|SPC_10008|AUTHEN_10000|AUTHEN_10003|UM_10034|LM_36803|CNX_53021|LM_44237|REP_12400|REP_12014|LGS_10006|UM_10007|UM_10008|PCSF_10062|PCSF_10520|UM_10037)"

# Get number of errors
NBERR=`cat $1 | egrep -c $SEVERITY`
NBIGNORE=`cat $1 | grep -w $SEVERITY | egrep -c $IGNORE_LIST` if [ $NBERR -gt 0 -a $NBERR -gt $NBIGNORE ];then
  STATUS=1
  # At least a message is found
  fn_log "$NBERR message(s) with severity $SEVERITY found"
  egrep $SEVERITY $1 | egrep -v $IGNORE_LIST $1 >> $LOG else
  fn_log "No message with severity $SEVERITY is found"
fi
}

function fn_random_pass {
        typeset LEN=$1
        AWK=awk
        [ $(uname -s) = "SunOS" ] && AWK=nawk
        default_length=6
        if [ $LEN -lt $default_length ]
        then
                LEN=$default_length
        fi
        PWD=$($AWK -v LEN=$LEN -v seed=$RANDOM 'BEGIN {
                charmap = "0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
                charmap_length = length( charmap);
                PWD="";
                srand(seed);
                for ( i = 0; i < LEN; i++ ) {
                  PWD = PWD "" substr( charmap, rand() * charmap_length + 1,1);
                 }
                print PWD
                }'
             )
}
# ---* End of PowerCenter Administration Functions
