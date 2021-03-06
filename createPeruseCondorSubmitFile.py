#!/usr/bin/python
import os, commands, shutil, sys, re

# Create a Condor submission file for post-processing frame perusal
# Grant David Meadors
# 02012-07-03 (JD 2456112)
# g m e a d o r s @ u m i c h . e d u 

# Define a function to edit file objects conveniently
def h(text):
    result = fileObject.write(text + '\n')
    return result
analysisDate = "2012/06/27"

# Make a directory for the output logs
os.system('mkdir -p peruseLogs')
os.system('mkdir -p cache')

# Make a cache file for the data
def cacher(n, Observatory, frameType):
    thisStartTime = str(int(n*1e5))
    thisEndTime = str(int((n+1)*1e5))
    if frameType == '1LDAS_C02_L2':
        frameTypeHoft = Observatory + '1_LDAS_C02_L2' 
        thisDataFindOutput = 'cache/' +\
        'injectionCache' + '-Hoft' +\
        '-' + thisStartTime + '-' + thisEndTime + '.txt'
    elif frameType == 'R':
        frameTypeHoft = 'R'
        thisDataFindOutput = 'cache/' +\
        'injectionCache' + '-DARM' +\
         '-' + thisStartTime + '-' + thisEndTime + '.txt'
    else:
        print 'Unknown frame type: please use R or (site)1LDAS_C02_L2'
   
    dataFindCommand = 'ligo_data_find --observatory='+\
    Observatory +\
    ' --type=' +\
    frameTypeHoft +\
    ' --gps-start-time='+\
    thisStartTime +\
    ' --gps-end-time=' +\
    thisEndTime +\
    ' --url-type=file --lal-cache > ' +\
    thisDataFindOutput
    os.system(dataFindCommand)
    return thisDataFindOutput

fileObject = open("/archive/home/gmeadors/" + analysisDate + "/AMPS/PeruseSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseManyFrames.py")
h("output = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseLogs/peruseManyFrames.out.$(process)")
h("error = peruseLogs/peruseManyFrames.err.$(process)")
h("log = peruseLogs/peruseManyFrames.log.$(process)")
h("requirements = Memory >= 3999")
h("")

def queuer(n, analysisDate):
    thisDataFindOutputHoft = cacher(n, 'H', '1LDAS_C02_L2')
    thisDataFindOutputDARM = cacher(n, 'H', 'R')
    argumentString = str(n) + ' ' + thisDataFindOutputHoft + ' ' +\
    thisDataFindOutputDARM + ' ' +'/archive/home/gmeadors/' +\
    analysisDate + '/AMPS/'
    h("arguments = " + argumentString)
    h("queue")
    h("")

[queuer(n, analysisDate) for n in range(9310, 9327+1)]


fileObject.close
