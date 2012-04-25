#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MCR environment for the current $ARCH and executes 
# the specified command.
#
exe_name=$0
exe_dir=`dirname "$0"`
echo "------------------------------------------"
#if [ "x$1" = "x" ]; then
#  echo Usage:
#  echo    $0 \<deployedMCRroot\> args
#else
  echo Setting up environment variables
#  MCRROOT="$1"
  echo ---
#  LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
#  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
#  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
#	MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64 ;
#	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
#	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
#	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
#	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
#  XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
LD_LIBRARY_PATH=/ldcg/matlab_r2011a/runtime/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ligotools/lib ;
  export LD_LIBRARY_PATH;
  export XAPPLRESDIR;
  echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
#  shift 1
#  args=
#  while [ $# -gt 0 ]; do
#      token=`echo "$1" | sed 's/ /\\\\ /g'`   # Add blackslash before each blank
#      args="${args} ${token}" 
#     shift
#  done
#  eval "${exe_dir}"/peruseFrame $args
${exe_dir}/peruseFrame $*
#fi
exit

