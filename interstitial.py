#!/usr/bin/python
import os, sys

# Grant David Meadors
# 02012-06-18
# gmeadors@umich.edu

# Run  on all the frame files in a given directory
def interstate(n, cacheHoft):
    def archiveString(headDirectory, siteFull, frameType):
        headDirectory = '/archive/frames/S6/pulsar/feedforward/'
        dataDirectory = siteFull[1] + '-' +siteFull[1] + '1_' + frameType + '_C02_L2-' + str(n)
        fullDirectory = headDirectory + siteFull + dataDirectory
        print(fullDirectory)
        files = os.listdir(fullDirectory)
        return files
    filesFilter = archiveString('/archive/frames/S6/pulsar/feedforward/', 'LHO/', 'AMPS')
    analysisDate = '/archive/home/gmeadors/2012/06/18-1/AMPS/'


    # The idea will be to do a comparison between cacheHoft and filesFilter and run
    # the interstitialFrame function on the difference.
    for filename in filesFilter:
        print filename
     
    fileObject = open(cacheHoft, "r")
    for line in fileObject:
        frameLine = str(line)
        frameLine.find()
    fileObject.close
    #runScript = analysisDate + 'run_interstitialFrame-well.sh'
    #[os.system(runScript + ' ' + filename + ' ' + cacheHoft) for filename in files]

#directoryList = range(9310, 9327+1)
#interstate(sys.argv[1], sys.argv[2])

# For testing only
interstate(9310, '../../18/AMPS/cache/injectionCache-Hoft-931000000-931100000.txt')




    
