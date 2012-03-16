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
#        LD_LIBRARY_PATH=/ldcg/matlab_r2011a/runtime/glnxa64:/ldcg/matlab_r2011a/sys/os/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/server:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64:/ldcg/matlab_r2011a/sys/opengl/lib/glnxa64:/opt/lscsoft/lalstochastic/lib64:/opt/lscsoft/lalpulsar/lib64:/opt/lscsoft/lalburst/lib64:/opt/lscsoft/lalinspiral/lib64:/opt/lscsoft/lalxml/lib64:/opt/lscsoft/lalmetaio/lib64:/opt/lscsoft/lalframe/lib64:/opt/lscsoft/lal/lib64:/opt/lscsoft/glue/lib64/python2.4/site-packages:/opt/lscsoft/libframe/lib64:/opt/lscsoft/libmetaio/lib64:/opt/lscsoft/ldas-tools/lib64:/opt/lscsoft/dol/lib64:/opt/lscsoft/root/lib:/opt/lscsoft/root/lib/5.26:/opt/vdt/globus/lib:/ligotools/lib ;
LD_LIBRARY_PATH=/ldcg/matlab_r2011a/runtime/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ligotools/lib ;
#  XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
  export LD_LIBRARY_PATH;
  export XAPPLRESDIR;
  echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
${exe_dir}/eleutheria $*
exit

