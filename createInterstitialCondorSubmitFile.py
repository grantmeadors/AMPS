#!/usr/bin/python
import os, commands, shutil, sys, re

# Create a Condor submission file for making AMPS frames between science segs
# Grant David Meadors
# 02012-07-03 (JD 2456112) 
# g m e a d o r s @ u m i c h . e d u

# Define a function to edit file objects conveniently
def h(text):
    result = fileObject.write(text + '\n')
    return result
analysisDate = "2012/06/19"

# Make a directory for the output logs
os.system('mkdir -p interstitialLogs')
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

fileObject = open("/home/pulsar/feedforward/" + analysisDate + "/AMPS/InterstitialSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /home/pulsar/feedforward/" + analysisDate + "/AMPS/interstitial.py")
h("output = /home/pulsar/feedforward/" + analysisDate + "/AMPS/interstitialLogs/interstitial.out.$(process)")
h("error = interstitialLogs/interstitial.err.$(process)")
h("log = interstitialLogs/interstitial.log.$(process)")
h("requirements = Memory >= 3999")
h("")

def queuer(n, observatory, duration, analysisDate):
    thisDataFindOutputHoft = cacher(n, observatory, '1LDAS_C02_L2')
    argumentString = str(n) + \
    ' ' + thisDataFindOutputHoft + ' ' + observatory + ' ' +\
    str(duration) + ' ' + '/home/pulsar/feedforward/' + \
    str(analysisDate) + '/AMPS/'
    h("arguments = " + argumentString)
    h("queue")
    h("")

[queuer(n, 'H', 128, analysisDate) for n in range(9310, 9327+1)]


fileObject.close
