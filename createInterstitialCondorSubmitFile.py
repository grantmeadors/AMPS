#!/usr/bin/python
import os, commands, shutil, sys, re

# Define a function to edit file objects conveniently
def h(text):
    result = fileObject.write(text + '\n')
    return result
analysisDate = "2012/06/18-1"

# Make a directory for the output logs
os.system('mkdir -p interstialLogs')
os.system('mkdir -p cache')

# Make a cache file for the data
def cacher(n, Observatory, frameType):
    thisStartTime = str(int(n*1e5))
    thisEndTime = str(int((n+1)*1e5))
    if frameType == '1LDAS_C02_L2':
        frameTypeHoft = Observatory + '1_LDAS_C02_L2' 
        thisDataFindOutput = 'cache/' +\
        'interstitialCache' + '-Hoft' +\
        '-' + thisStartTime + '-' + thisEndTime + '.txt'
    else:
        print 'Unknown frame type: please use (site)1LDAS_C02_L2'
   
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

fileObject = open("/archive/home/gmeadors/" + analysisDate + "/AMPS/InterstitialSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseManyFrames.py")
h("output = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseLogs/peruseManyFrames.out.$(process)")
h("error = peruseLogs/peruseManyFrames.err.$(process)")
h("log = peruseLogs/peruseManyFrames.log.$(process)")
h("requirements = Memory >= 3999")
h("")

def queuer(n):
    thisDataFindOutputHoft = cacher(n, 'H', '1LDAS_C02_L2')
    h("arguments = " + str(n) + ' ' + thisDataFindOutputHoft)
    h("queue")
    h("")

[queuer(n) for n in range(9310, 9327+1)]


fileObject.close
