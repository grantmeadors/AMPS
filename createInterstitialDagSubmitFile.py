#!/usr/bin/python
import os, commands, shutil, sys, re

# Create a Condor DAG submission file for making AMPS frames between science segs
# Grant David Meadors
# 02013-05-22 (JD 2456435) 
# g m e a d o r s @ u m i c h . e d u

# Define a function to edit file objects conveniently
def h(text):
    result = condorObject.write(text + '\n')
    return result
# Define a second, similar function to write to a different file.
# Keep them separate for safety.
def g(text):
    result = dagObject.write(text + '\n')
analysisDate = "2013/05/22-interstitial-LHO"

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

condorObject = open("/home/pulsar/feedforward/" + analysisDate + "/AMPS/InterstitialSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /home/pulsar/feedforward/" + analysisDate + "/AMPS/interstitial.py")
h("output = /home/pulsar/feedforward/" + analysisDate + "/AMPS/interstitialLogs/interstitial.out.$(tagstring)")
h("error = interstitialLogs/interstitial.err.$(tagstring)")
h("log = interstitialLogs/interstitial.log.$(tagstring)")
h("request_memory = 4 GB")
h("notification = never")
h("")
h("arguments = $(argList)")
h("queue 1")
h("")

condorObject.close

startOfRange = 9330
dagObject = open("/home/pulsar/feedforward/" + analysisDate + "/AMPS/InterstitialDAG.dag", "w")
def queuer(n, observatory, duration, analysisDate, startOfRange):
    thisDataFindOutputHoft = cacher(n, observatory, '1LDAS_C02_L2')
    argumentString = '"' + str(n) + \
    ' ' + thisDataFindOutputHoft + ' ' + observatory + ' ' +\
    str(duration) + ' ' + '/home/pulsar/feedforward/' + \
    str(analysisDate) + '/AMPS/' + '"'
    tagStringLine = "interstitial_" + str(n - startOfRange + 1)
    g("JOB " + tagStringLine + " InterstitialSub.sub")
    g("VARS " + tagStringLine + " argList=" + argumentString + " tagString=" + '"' + tagStringLine + '"')
dagObject.close

[queuer(n, 'H', 128, analysisDate, startOfRange) for n in range(startOfRange, startOfRange+2)]


