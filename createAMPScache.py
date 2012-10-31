#!/usr/bin/python
import os, commands, shutil, sys, re

# Create a cache file containing the location of the AMPS frames for a time
# Grant David Meadors
# 02012-10-30 (JD 2456231)
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
analysisDate = "2012/10/30"

# Make a directory for the output logs
os.system('mkdir -p eleutheriaLogs')
os.system('mkdir -p cache')
os.system('mkdir -p logs')

 
# This next function searches LIGO data find and creates a frame cache
# Note that Observatory is set to H, Hanford, by default.
def dataFinder(startTime, stopTime, cacheDARM, cacheNOISE):
    Observatory = "H"
    frameTypeDARM = "H1_AMPS_C02_L2"
    frameLengthDARM = 128
    
    thisStartTime = str(startTime)
    thisEndTime = str(stopTime)

    thisdataFindOutputDARM = cacheDARM

    thisEndTimePlusframeLengthDARM = str(stopTime + frameLengthDARM)
    ligoDataFindStringDARM = \
    "ligo_data_find --observatory=" + Observatory + \
    " --type=" + frameTypeDARM + " --gps-start-time=" + thisStartTime + \
    " --gps-end-time=" + thisEndTimePlusframeLengthDARM + \
    " --url-type=file --lal-cache > " + \
    thisdataFindOutputDARM   
    os.system(ligoDataFindStringDARM)

# The following function will write each job of the DAG file
def dagWriter(jobNumber, startTime, stopTime):
    cacheDARM = "cache/fileList-AMPS-" + \
    str(startTime) + "-" + str(stopTime) + ".txt"
    dataFinder(startTime, stopTime, cacheDARM, "")
# Generate the list of start and stop science segment times
segmentListObject = open(userDirectory + analysisDate + "/AMPS/dividedSeglist.txt")
segmentList = segmentListObject.readlines()
segmentListObject.close
startTimeList = []
stopTimeList = []
for i, v in enumerate(segmentList):
    startTimeList.append(v[0:9])
    stopTimeList.append(v[10:19])

# For test purposes
#dagWriter(1, 953164815, 953164875)
for j in range(0, len(startTimeList)):
    dagWriter(j+1, int(startTimeList[j]), int(stopTimeList[j]))
