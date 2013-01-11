#!/usr/bin/python
import os, commands, shutil, sys, re

# Create a Condor DAG submit file for feedforward (eleutheria) jobs.
# Grant David Meadors
# 02012-07-02 (JD 2456111)
# g m e a d o r s @ u m i c h . e d u

# Define a function to edit file objects conveniently
def h(text):
    result = condorObject.write(text + '\n')
    return result
# Define a second, similar function to write to a different file.
# Keep them separate for safety.
def g(text):
    result = dagObject.write(text + '\n')
    return result
userDirectory = "/home/pulsar/feedforward/"
analysisDate = "2013/01/11"

# Make a directory for the output logs
os.system('mkdir -p eleutheriaLogs')
os.system('mkdir -p cache')
os.system('mkdir -p logs')

condorObject = open(userDirectory + analysisDate + "/AMPS/EleutheriaSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /home/pulsar/feedforward/" + analysisDate + "/AMPS/run_eleutheria-well.sh")
h("output = /home/pulsar/feedforward/" + analysisDate + "/AMPS/eleutheriaLogs/eleutheria.out.$(tagstring)")
h("error = eleutheriaLogs/eleutheria.err.$(tagstring)")
h("log = eleutheriaLogs/eleutheria.dag.log")
h("request_memory = 4 GB")
h("environment = HOME=/archive/home/pulsar;LD_LIBRARY_PATH=/ldcg/matlab_r2010b/runtime/glnxa64:/ldcg/matlab_r2010b/bin/glnxa64:/ldcg/matlab_r2010b/extern/lib/glnxa64:/ligotools/lib")
h("notification = never")
h("")
h("arguments = $(argList)")
h("queue 1")
h("")

condorObject.close
 
# This next function searches LIGO data find and creates a frame cache
# Note that Observatory is set to H, Hanford, by default.
def dataFinder(startTime, stopTime, cacheDARM, cacheNOISE):
    Observatory = "H"
    frameTypeDARM = "H1_LDAS_C02_L2"
    frameTypeNOISE = "R"
    frameLengthDARM = 128
    frameLengthNOISE = 32
    
    thisStartTime = str(startTime)
    thisEndTime = str(stopTime)

    thisdataFindOutputDARM = cacheDARM
    thisdataFindOutputNOISE = cacheNOISE

    thisEndTimePlusframeLengthDARM = str(stopTime + frameLengthDARM)
    thisEndTimePlusframeLengthNOISE = str(stopTime + frameLengthNOISE)
    ligoDataFindStringDARM = \
    "ligo_data_find --observatory=" + Observatory + \
    " --type=" + frameTypeDARM + " --gps-start-time=" + thisStartTime + \
    " --gps-end-time=" + thisEndTimePlusframeLengthDARM + \
    " --url-type=file --lal-cache > " + \
    thisdataFindOutputDARM   
    ligoDataFindStringNOISE = \
    "ligo_data_find --observatory=" + Observatory + \
    " --type=" + frameTypeNOISE + " --gps-start-time=" + thisStartTime + \
    " --gps-end-time=" + thisEndTimePlusframeLengthNOISE + \
    " --url-type=file --lal-cache > " + \
    thisdataFindOutputNOISE   
    os.system(ligoDataFindStringDARM)
    os.system(ligoDataFindStringNOISE)

# The following function will write each job of the DAG file
def dagWriter(jobNumber, startTime, stopTime):
    cacheDARM = "cache/fileList-DARM-" + \
    str(startTime) + "-" + str(stopTime) + ".txt"
    cacheNOISE = "cache/fileList-NOISE-" + \
    str(startTime) + "-" + str(stopTime) + ".txt"
    dataFinder(startTime, stopTime, cacheDARM, cacheNOISE)
    argumentList = '"' + str(startTime) + " " + str(stopTime) + " " + cacheDARM + " " + cacheNOISE + '"'
    tagStringLine = "eleutheria_" + str(jobNumber)
    g("JOB " + tagStringLine + " EleutheriaSub.sub")
    g("VARS " + tagStringLine + " argList=" + argumentList + " tagString=" + '"' + tagStringLine + '"')

# Generate the list of start and stop science segment times
segmentListObject = open(userDirectory + analysisDate + "/AMPS/dividedSeglist.txt")
segmentList = segmentListObject.readlines()
segmentListObject.close
startTimeList = []
stopTimeList = []
for i, v in enumerate(segmentList):
    startTimeList.append(v[0:9])
    stopTimeList.append(v[10:19])

dagObject = open(userDirectory + analysisDate + "/AMPS/EleutheriaDAG.dag", "w")
# For test purposes
#dagWriter(1, 953164815, 953164875)
for j in range(0, len(startTimeList)):
    dagWriter(j+1, int(startTimeList[j]), int(stopTimeList[j]))
dagObject.close
