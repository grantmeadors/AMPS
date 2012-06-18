#!/usr/bin/python
import os, sys

# Grant David Meadors
# 02012-04-24
# gmeadors@umich.edu

# First look to see which output files have 'No data found'

def catter(n):
    print n
    headDirectory = '~pulsar/feedforward/'
    particularRun = '2012/04/14'
    tailDirectory = '/AMPS/logs/'
    logName = 'eleutheria.out.'
    stringFile = headDirectory + particularRun + tailDirectory + logName

    os.system('cat ' + stringFile + str(n) + ' | grep -n "No data found"')

# Run, but only if needed. May need to adjust range to number of jobs
testBit = 0
if testBit == 0:
    [catter(x) for x in range(200)]


# Run peruseFrame on all the frame files in a given directory
def peruser(n, cacheHoft, cacheDARM):
    headDirectory = '/archive/frames/S6/pulsar/feedforward/'
    siteFull = 'LHO/'
    dataDirectory = siteFull[1] + '-' +siteFull[1] + '1_AMPS_C02_L2-' + str(n)
    fullDirectory = headDirectory + siteFull + dataDirectory
    print(fullDirectory)
    files = os.listdir(fullDirectory)
    analysisDate = '/archive/home/gmeadors/2012/06/18/AMPS/'
    runScript = analysisDate + 'run_peruseFrame-well.sh'
    [os.system(runScript + ' ' + filename + ' ' + cacheHoft + cacheDARM) for filename in files]

directoryList = range(9310, 9327+1)
peruser(sys.argv[1], sys.argv[2], sys.argv[3])




    
