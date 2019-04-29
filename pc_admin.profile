#!/bin/ksh
###############################################################################
#  File Name: PowerCenter profile
#  Description: PowerCenter Profile
#
#  Date: 07/03/2008
#
#  Revision History
#  Initial     Date          Revision details
#  consps      05/27/2009    Added Autosys environment variables for BTE jobs
#  mbh         06/22/2011    Modified for PowerCener 9.0.1
#  mbh         11/30/2011    Added IBM DB2 environment variables
#  mbh         08/06/2012    Added TIBCO EMS library path
#  ngh         02/11/2014    Modified for Powercenter 9.1.0 on Linux
#  ngh         07/16/2014    Revised SYBASE path that DBA changed for Linux
#                            SYBASE=/users/sybclient/15.5_64 now becomes
#                            SYBASE=/users/sybclient/15.5
#
####################################################################################
# set -x

# ---* PowerCenter Environment Variables INFA_HOME=/users/pmserver96; export INFA_HOME INFA_HOST=`hostname`; export INFA_HOST INFA_USER=pm_repo; export INFA_USER INFA_JAVA_OPTS="-Xmx2048M"; export INFA_JAVA_OPTS SECURITY_DOMAIN=Native; export SECURITY_DOMAIN LD_LIBRARY_PATH=$INFA_HOME/server/bin:$INFA_HOME/source/java/jre/lib/amd64/jli:.:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH PATH=$INFA_HOME/server/bin:$INFA_HOME/server/tomcat/bin:$PATH; export PATH INFA_CLIENT_RESILIENCE_TIMEOUT=30; export INFA_CLIENT_RESILIENCE_TIMEOUT

# ---* ODBC Connectivity
ODBCHOME=$INFA_HOME/ODBC7.1; export ODBCHOME ODBCINI=$ODBCHOME/odbc.ini; export ODBCINI PATH=$ODBCHOME/bin:$PATH; export PATH LD_LIBRARY_PATH=$ODBCHOME/lib:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

# ---* Oracle Environment Variables
#ORACLE_HOME=/users/oraclient/product/10.2.0/client_1; export ORACLE_HOME #ORA_NLS10=$ORACLE_HOME/nls/data; export ORA_NLS10 #TNS_ADMIN=/users/oraclient/tns_admin; export TNS_ADMIN

ORACLE_HOME=$INFA_HOME/links/ora11; export ORACLE_HOME ORA_NLS=$ORACLE_HOME/nls/data; export ORA_NLS LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH PATH=$ORACLE_HOME/bin:$PATH; export PATH NLS_LANG=AMERICAN_AMERICA.AL32UTF8; export NLS_LANG

# ---* IBM DB2 Environment Variables
if [ -f /users/home/cgdb2/sqllib/db2profile ]; then
  . /users/home/cgdb2/sqllib/db2profile
fi

# ---* Sybase Environment Variables
SYBASE=/users/sybclient2; export SYBASE
SYBASE_OCS=OCS-15_0; export SYBASE_OCS
LD_LIBRARY_PATH=$SYBASE/$SYBASE_OCS/lib:$SYBASE/$SYBASE_OCS/lib3p64:$SYBASE/$SYBASE_OCS/lib3p:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH PATH=$SYBASE/$SYBASE_OCS/bin:$PATH; export PATH INCLUDE=$SYBASE/$SYBASE_OCS/include:$INCLUDE; export INCLUDE LIB=$SYBASE/$SYBASE_OCS/lib:$LIB; export LIB

# ---* TIBCO EMS library path
LD_LIBRARY_PATH=/users/tibco/ems/6.3/lib:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

# ---* Unix Environment Variables
LC_ALL=en_US.UTF-8; export LC_ALL
LANG=en_US.UTF-8; export LANG
BKPDIR=$INFA_HOME/backup; export BKPDIR
SENDER=pmadmin@capgroup.com; export SENDER OPCBIN=/opt/OV/bin/OpC; export OPCBIN PATH=/usr/bin:/usr/sbin:/usr/ucb:$OPCBIN:$PATH; export PATH LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

# ---* Autosys Environment Variables
AUTOSYS=/usr/local/autosysr11/autosys; export AUTOSYS #AUTOUSER=/usr/local/autosys/autouser; export AUTOUSER #AUTOSERV=DEV; export AUTOSERV PATH=$AUTOSYS/bin:$PATH; export PATH

# ---* End of Environment Variables
