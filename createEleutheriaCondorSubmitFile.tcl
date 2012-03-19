#!/usr/bin/env tclsh

# File: CreateEleutheriaCondorSubmitFile.tcl Started: 2011-09-20
# Original Author: Greg Mendell
# Derivative Author: Grant Meadors

# Define parameters here:

#set startTime 900000000
set startTime 953164815
#set endTime 900100000
set endTime 953166875
#set deltaT 86400; # The time per condor job
#set deltaT 7200; # The time per condor job
set Observatory "H";
set frameTypeDARM "H1_LDAS_C02_L2";
set frameTypeNOISE "R";
set frameLengthDARM 128;
set frameLengthNOISE 32;
set condorSubmitFileName "EleutheriaSub.sub";
set executablePathAndName "/archive/home/gmeadors/2012/03/19/AMPS/run_eleutheria-well.sh"
#set analysisTime 60; # time per line of output
set matlabPath "/ldcg/matlab_r2011a"
set outputDirectory "/archive/home/gmeadors/2012/03/19/AMPS"
#set stateVectorChan "H1:IFO-SV_STATE_VECTOR"
#set channelList "H1:IO-1811_I,H1:IO-1811_Q,H1:IOO-MC_PWR_IN,H1:IOO-MC_TRANS_SUM,H1:PSL-ISS_OLMONPD_NW"

#######################
# MAIN CODE STARTS HERE 
#######################

# Make a location for the outputs from ligo_data_find
if {[catch {exec mkdir cache} result]}  {
   # Continue
}

# Make a location for the logs from condor
if {[catch {exec mkdir logs} result]}  {
   # Continue
}

# Find all the data using ligo_data_find
set fp [open "dividedSeglist.txt" r]
set file_data [read $fp]
close $fp
set data [split $file_data "\n"]
foreach {one} $data {
  lappend col1 [lindex $one 0]
  lappend col2 [lindex $one 1]
}
set col1 [lreplace $col1 end end]
set col2 [lreplace $col2 end end]

#proc print12 {array}{
#upvar $array a
#puts "$a(1)"
#}
#print12 col1

#set print12 [lindex $col2 end]
#puts $print12
#set print23 [llength $col1]
#puts $print23

foreach i $col1 j $col2 {

set thisStartTime $i
set thisEndTime $j


  # Find the end time for this job
#  set thisEndTime [expr $thisStartTime + $deltaT];
  set frameLengthDARM 128
  set frameLengthNOISE 32


  # Run ligo_data_find to find the data between thisStartTime and thisEndTime:
  set thisdataFindOutputDARM "cache/fileList-DARM-$thisStartTime-$thisEndTime.txt"
  set thisdataFindOutputNOISE "cache/fileList-NOISE-$thisStartTime-$thisEndTime.txt"
  # Include extra data at the ends to make sure we not miss any:
  #set thisStartTimeMinusframeLengthDARM [expr $thisStartTime - $frameLengthDARM];
  #set thisStartTimeMinusframeLengthNOISE [expr $thisStartTime - $frameLengthNOISE];
  set thisEndTimePlusframeLengthDARM [expr $thisEndTime + $frameLengthDARM];
  set thisEndTimePlusframeLengthNOISE [expr $thisEndTime + $frameLengthNOISE];
  set cmd "exec ligo_data_find --observatory=$Observatory --type=$frameTypeDARM --gps-start-time=$thisStartTime --gps-end-time=$thisEndTimePlusframeLengthDARM --url-type=file --lal-cache > $thisdataFindOutputDARM";
  if {[catch {eval $cmd } result]}  {
     puts "Error running $cmd";
  }
  set cmd "exec ligo_data_find --observatory=$Observatory --type=$frameTypeNOISE --gps-start-time=$thisStartTime --gps-end-time=$thisEndTimePlusframeLengthNOISE --url-type=file --lal-cache > $thisdataFindOutputNOISE";
  if {[catch {eval $cmd } result]}  {
     puts "Error running $cmd";
  }

}
  # update thisStartTime for next job
#  set thisStartTime $thisEndTime;

#}

# Open the Condor submit file:

set fid [open $condorSubmitFileName "w"];

# Write the Condor submit file header information:
puts $fid "universe = vanilla";
#puts $fid "getenv = True";
puts $fid "executable = $executablePathAndName";
puts $fid "output = $outputDirectory/logs/eleutheria.out.\$(process)"
puts $fid "error = logs/eleutheria.err.\$(process)"
puts $fid "log = logs/eleutheria.log.\$(process)"
puts $fid "requirements = Memory >= 3999"
puts $fid "concurrency_limits = 40"

#puts $fid "environment = HOME=/archive/home/gmeadors;LD_LIBRARY_PATH=/ldcg/matlab_r2011a/sys/os/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/server:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64:/ldcg/matlab_r2011a/sys/opengl/lib/glnxa64:/opt/lscsoft/lalstochastic/lib64:/opt/lscsoft/lalpulsar/lib64:/opt/lscsoft/lalburst/lib64:/opt/lscsoft/lalinspiral/lib64:/opt/lscsoft/lalxml/lib64:/opt/lscsoft/lalmetaio/lib64:/opt/lscsoft/lalframe/lib64:/opt/lscsoft/lal/lib64:/opt/lscsoft/glue/lib64/python2.4/site-packages:/opt/lscsoft/libframe/lib64:/opt/lscsoft/libmetaio/lib64:/opt/lscsoft/ldas-tools/lib64:/opt/lscsoft/dol/lib64:/opt/lscsoft/root/lib:/opt/lscsoft/root/lib/5.26:/opt/vdt/globus/lib:/ligotools/lib"

#puts $fid "environment = HOME=/archive/home/gmeadors;LD_LIBRARY_PATH=/ldcg/matlab_r2011a/runtime/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64/server:/ldcg/matlab_r2011a/sys/java/jre/glnxa64/jre/lib/amd64:/ldcg/matlab_r2011a/sys/opengl/lib/glnxa64:/ligotools/lib"

puts $fid "environment = HOME=/archive/home/gmeadors;LD_LIBRARY_PATH=/ldcg/matlab_r2011a/runtime/glnxa64:/ldcg/matlab_r2011a/bin/glnxa64:/ldcg/matlab_r2011a/extern/lib/glnxa64:/ligotools/lib"

# Write out the command lines for all the condor jobs:
#set thisStartTime $startTime
#set thisEndTime $endTime


foreach i $col1 j $col2 {

set thisStartTime $i
set thisEndTime $j

#
#  # Find the end time for this job
#  set thisEndTime [expr $thisStartTime + $deltaT];
#
#  # Queue job for data between thisStartTime and thisEndTime:
#
  set thisdataFindOutputDARM "cache/fileList-DARM-$thisStartTime-$thisEndTime.txt"
  set thisdataFindOutputNOISE "cache/fileList-NOISE-$thisStartTime-$thisEndTime.txt"
  set thisdataFindOutput "cache/fileList-$thisStartTime-$thisEndTime.txt";
  #set outputFileName "EleutheriaOutput-$thisStartTime-$thisEndTime.txt";
#
#  set argumentList "$matlabPath $thisdataFindOutput $stateVectorChan $channelList $thisStartTime $thisEndTime $analysisTime $outputFileName"
  set argumentList "$thisStartTime $thisEndTime $thisdataFindOutputDARM $thisdataFindOutputNOISE"

  puts $fid " ";
  puts $fid "arguments = $argumentList"
  puts $fid "queue";
#
#  # update thisStartTime for next job
#  set thisStartTime $thisEndTime;
#
}

close $fid;
