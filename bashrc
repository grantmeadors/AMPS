# .bashrc

# User specific aliases and functions
alias matlab6='/ldcg/matlab_r13/bin/matlab -nosplash -nodesktop'
alias matlab7='/ldcg/matlab_r14_sp3/bin/matlab -nosplash -nodesktop'
alias matlab2007a='/ldcg/matlab_r2007a/bin/matlab -nosplash -nodesktop'
alias matlab2010b='/ldcg/matlab_r2010b/bin/matlab -nosplash -nodesktop'
alias matlab2011a='/ldcg/matlab_r2011a/bin/matlab -nosplash -nodesktop'
alias matlab2012a='/ldcg/matlab_r2012a/bin/matlab -nosplash -nodesktop'
alias ee='eog'
alias gv='ggv'

# Aliases for user directories
#alias cdS='cd /archive/home/gmeadors/matapps/src/searches/stochastic'
#alias cdCC='cd /archive/home/gmeadors/matapps/src/searches/stochastic/CrossCorr'
#alias cdS5j='cd /archive/home/gmeadors/sgwb/S5/input/jobfiles'
#alias cdS5p='cd /archive/home/gmeadors/sgwb/S5/input/paramfiles'
#alias cdS5i='cd /archive/home/gmeadors/sgwb/S5/input'
#alias cdS5o='cd /archive/home/gmeadors/sgwb/S5/output'
#alias cdS5m='cd /archive/home/gmeadors/sgwb/S5/matlab'

# Source global definitions
#if [ -f /etc/bashrc ]; then
#	. /etc/bashrc
#fi

EDITOR='emacs'
export EDITOR
export _CONDOR_DAGMAN_LOG_ON_NFS_IS_ERROR=FALSE

#PATH=$PATH:/usr/local/sbin:/usr1/matlab_r13
#PATH=/opt/lscsoft/gst/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:/ligotools/bin:/ldcg/matlab_r2007a/bin:/opt/pegasus/3.1/bin:/home/pulsar/bin
#export PATH
#BASH_ENV=/home/gmeadors/.bashrc
#export BASH_ENV

#LD_LIBRARY_PATH=/archive/home/vmandic/sgwb/S3/matlab/bin/glnx86:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH

#LSC_DATAGRID_SERVER_LOCATION=/usr1/lcldsk/ldg-3.0
#export LSC_DATAGRID_SERVER_LOCATION
#if [ -f "${LSC_DATAGRID_SERVER_LOCATION}" ]; then
#      source ${LSC_DATAGRID_SERVER_LOCATION}/setup.sh
#fi

export MATLAB_ROOT=/ldcg/matlab_r2012a
#export ARCH=glnx86
export ARCH=glnxa64
#
#if [ $ARCH == "glnx86" ];  then export ARCH_JRE="i386" ; fi
#if [ $ARCH == "glnxa64" ]; then export ARCH_JRE="amd64" ; fi
#if [ $?LD_LIBRARY_PATH ]; then
#    export LD_LIBRARY_PATH=${MATLAB_ROOT}/sys/opengl/lib/${ARCH}:${LD_LIBRARY_PATH}
#else
#    export LD_LIBRARY_PATH="${MATLAB_ROOT}/sys/opengl/lib/${ARCH}"
#fi
#export LD_LIBRARY_PATH=${MATLAB_ROOT}/sys/java/jre/${ARCH}/jre/lib/${ARCH_JRE}:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=${MATLAB_ROOT}/sys/java/jre/${ARCH}/jre/lib/${ARCH_JRE}/server:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=${MATLAB_ROOT}/sys/java/jre/${ARCH}/jre/lib/${ARCH_JRE}/native_threads:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${MATLAB_ROOT}/extern/lib/${ARCH}:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${MATLAB_ROOT}/bin/${ARCH}:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=${MATLAB_ROOT}/sys/os/${ARCH}:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${MATLAB_ROOT}/runtime/${ARCH}:${LD_LIBRARY_PATH}
export XAPPLRESDIR=${MATLAB_ROOT}/X11/app-defaults
#

#eval `/archive/home/jromano/src/ligotools/bin/use_ligotools`
eval `/ligotools/bin/use_ligotools`

#export MATAPPS_TOP=/archive/home/gmeadors/matapps
#source ${MATAPPS_TOP}/SDE/matapps.sh ${MATAPPS_TOP}
#export MATLABPATH=`echo $MATLABPATH | sed 's/\/archive\/home\/gmeadors\/matapps\/SDE\/:\/archive\/home\/gmeadors\/matapps\/SDE/\/archive\/home\/gmeadors\/matapps\/SDE/g'`

#alias cdw='cd /archive/home/omega/opt/omega/bin/'
#alias cdo='cd /archive/home/gmeadors/omega/'
#export wframe=/archive/home/gmeadors/omega/frame
#export wconfig=/archive/home/gmeadors/omega/config
#export wscans=/archive/home/gmeadors/omega/scans
