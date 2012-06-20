#!/usr/bin/python
import os, sys, re, time

# Grant David Meadors
# 02012-06-18
# gmeadors@umich.edu

# Run  on all the frame files in a given directory
def interstate(n, cacheHoft, observatory, duration, analysisDate):
    def archiveString(headDirectory, siteFull, frameType):
        headDirectory = '/archive/frames/S6/pulsar/feedforward/'
        dataDirectory = siteFull[1] + '-' +siteFull[1] + '1_' + frameType + '_C02_L2-' + str(n)
        fullDirectory = headDirectory + siteFull + dataDirectory
        print(fullDirectory)
        try:
            files = os.listdir(fullDirectory)
        except OSError: 
            disp('OSError found; waiting 5 seconds');
            time.sleep(5)
            try:
                files = os.listdir(fullDirectory)
            except OSError:
                disp('OSError found again; waiting 15 seconds')
                time.sleep(15)
                try:
                    files = os.listdir(fullDirectory)
                except OSError:
                    disp('OSError found again; waiting 60 seconds. Last time')
                    time.sleep(60)
                    files = os.listdir(fullDirectory)
        return files
    fileFilter = archiveString('/archive/frames/S6/pulsar/feedforward/', \
    'L' + observatory + 'O/', 'AMPS')
    #analysisDate = '/archive/home/gmeadors/2012/06/19/AMPS/'


    # The idea will be to do a comparison between cacheHoft and filesFilter and run
    # the interstitialFrame function on the difference.
    filterList = []
    refFrameList = []
    refList = []
    for filterLine in fileFilter:
        filterFrame = str(filterLine)
        # Search for the time of a filtered frame file.
        regexpFilter = re.search('-(?P<GPS>\d+)-(\d+)\.', filterFrame)
        # Create a list of filtered Hoft frame times.
        filterList.append(regexpFilter.group(1)) 
    fileRef = open(cacheHoft, "r")
    for refLine in fileRef:
        refFrame = str(refLine)
        # Search for the reference file
        regexpRef = re.search('-(?P<GPS>\d+)-(\d+)\.', refFrame)
        # Create the list of reference, baseline Hoft frame times.
        regexpRefTime = regexpRef.group(1)
        # First, limit our search only to files in the range of n,
        # to avoid edge effects of overwriting files in adjacent directories
        if ((int(regexpRefTime) >= int(n)*(10**5)) and \
        (int(regexpRefTime) < (int(n)+1)*(10**5))):
            # Only then add it to the list
            refList.append(regexpRefTime) 
    fileRef.close
    # Take the difference between the lists
    diffList = filter(lambda x:x not in filterList, refList)
    runScript = analysisDate + 'run_interstitialFrame-well.sh'
    [os.system(runScript + ' ' + frame + ' ' + cacheHoft + ' ' + observatory + ' ' + duration) for frame in diffList]

interstate(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
# For testing below:
#interstate(9310, '../../18/AMPS/cache/injectionCache-Hoft-931000000-931100000.txt', 'H', 128, '/archive/home/gmeadors/2012/06/19/AMPS/')




    
