#!/usr/bin/python
import os, sys

# Peruse frames for structural errors and injection syncronization.
# Grant David Meadors
# 02012-07-03 (JD 2456112)
# g m e a d o r s @ u m i c h . e d u

# First look to see which output files have 'No data found'

def catter(n):
    print n
    headDirectory = '~pulsar/feedforward/'
    particularRun = '2012/06/19'
    tailDirectory = '/AMPS/eleutheriaLogs/'
    logName = 'eleutheria.out.'
    stringFile = headDirectory + particularRun + tailDirectory + logName

    os.system('cat ' + stringFile + str(n) + ' | grep -n "No data found"')

# Run, but only if needed. May need to adjust range to number of jobs
testBit = 0
if testBit == 1:
    [catter(x) for x in range(200)]


# Run peruseFrame on all the frame files in a given directory
def peruser(n, cacheHoft, cacheDARM, analysisDate):
    headDirectory = '/archive/frames/S6/pulsar/feedforward/'
    siteFull = 'LHO/'
    dataDirectory = siteFull[1] + '-' +siteFull[1] + '1_AMPS_C02_L2-' + str(n)
    fullDirectory = headDirectory + siteFull + dataDirectory
    print(fullDirectory)
    files = os.listdir(fullDirectory)
    #analysisDate = '/archive/home/gmeadors/2012/06/18/AMPS/'
    runScript = analysisDate + 'run_peruseFrame-well.sh'
    [os.system(runScript + ' ' + filename + ' ' + cacheHoft + ' ' + cacheDARM) for filename in files]

directoryList = range(9310, 9327+1)
peruser(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])




    
