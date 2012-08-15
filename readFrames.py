#!/usr/bin/python
# Grant David Meadors
# 02012-08-14 (JD 2456154)
# g m e a d o r s @ u m i c h . e d u
# readFrames
# Based on code by Gregory Mendell
import re, numpy
from pylal.Fr import frgetvect1d

def readFrames(fileList, chanName, startGPSTime, duration, fileListIsInMemory=None, startIndex=None):
    # Comments below, unless noted otherwise, are verbatim from the
    # comments of Greg Mendell in the Matlab version of this code.
    # # # # # # # # # # # # # # # # # #

    # usage: [data,lastIndex,errCode,sRate,times] = readFrames(fileList,chanName,startGPSTime,duration,fileListIsInMemory,startIndex)
    #
    # Examples:
    # 1. Read 60 s of H1:LSC-DARM_ERR from files listed in a lal cache file myLALCacheFilt.txt (e.g., as returned by ligo_data_find):
    #
    #    x = readFrames('myLALCacheFile.txt','H1:LSC-DARM_ERR',940000000,60)
    #
    # 2. Read 60 s of H1:LSC-DARM_ERR if myFileList is a list of filenames held in memory
    #
    #    x = readFrames(myFileList,'H1:LSC-DARM_ERR',940000000,60,1) 
    # 
    # 3. Read 60 s of H1:LSC-DARM_ERR data from a list of files, myFileList:
    #
    #    myFileList = ['/path/filename1', '/path/filename2', '/path/filename3' ...]
    #    myChannel = 'H1:LSC-DARM_ERR'
    #    startGPSTime = 940000000
    #    endGPSTime = 940000000 + 86400
    #    duration = 60
    #    startIndex = 1
    #    while (startGPSTime < endGPSTime):
    #        x = readFrames(myFileList,myChannel,startGPSTime,duration,1,startIndex)      
    #        lastIndex = x[1]
    #
    #        # Do something with x...
    #
    #        # Update for the next call in the loop:
    #        startGPSTime = startGPSTime + duration
    #        startIndex = lastIndex
    #       
    # 
    # Inputs:
    #
    # fileList: A filename with a lal-cache style list of frame files or a list of filesnames. (SEe isListNotFile option below.)
    # chanName: The name of the channel to read from the frames.
    # startGPSTime: The GPS start time of first sample to return.
    # duration: The duration in seconds to return.
    # fileListIsInMemory: Set this to 1 if fileList is a list of filenames, and not a fileName with this list. (Optional) 
    # startIndex: The index from which to start in the list of files (optional, default is 1)
    #
    # Outputs:
    #
    # data: The data from channel.
    # lastIndex: The last index used in the list of files
    # errCode: the error code returned (0 means no error)
    # sRate: The sample rate of this channel.
    # times: the times, 0, corresponds to startGPSTime.
    #
    # Note the last two Input options are useful if a long list of files held in memory is send to readFrames over and over,
    # with each call running on the next sequential subset of the files. For example, if fileList contains the list of files
    # covering an entire day, and we wish to run on every 60 seconds of data, then set isListNotFile to 1 and duration to 60,
    # and after each call to readFrames update startGPSTime to startGPSTime + duration, and update startIndex to the returned
    # value of lastIndex. The readFrames function will then pick up from the correct place in the fileList from which the last call left off.

    # Initialize variables:
    errCode = 0
    endGPSTime = startGPSTime + duration
    durationFound = 0
    fileLocalHostStr = 'file://localhost'
    fileLocalHostStrLen = len(fileLocalHostStr)
    data = numpy.array([])

    # set default values:
    if fileListIsInMemory is None:
        fileListIsInMemory = 0
    if startIndex is None:
        startIndex = 1

    ###########################################
    # 
    # Read in the fileList or initialize listOfFiles
    #
    ###########################################
    if (fileListIsInMemory > 0):
        listOfFiles = fileList
    else:
        fileListObject = open(fileList)        
        listOfFiles = [line.strip().split()[4] for line in fileListObject]
        fileListObject.close()
    listOfFilesLen = len(listOfFiles)

    ###########################################
    #
    # Here is the main loop over the listOfFiles
    # Note that listOfFiles contains lines like this,
    #
    # ['H', 'H1_LDAS_C02_L2', '953164800', '128', 'file://localhost/data/node191/frames/S6/LDAShoftC02/LHO/H-H1_LDAS_C02_L2-9531/H-H1_LDAS_C02_L2-953164800-128.gwf']
    # ['H', 'H1_LDAS_C02_L2', '953164928', '128', 'file://localhost/data/node191/frames/S6/LDAShoftC02/LHO/H-H1_LDAS_C02_L2-9531/H-H1_LDAS_C02_L2-953164928-128.gwf']
    #
    # or a list like this,
    #
    # ['/path/filename1  ', '/path/filename2  ', '/path/filename3  ' ...] 
    #
    # Keeping everything past file://localhost, go through the list of files and parse out the
    # filename, GPS start times, and duration of each file and read the data from each file with
    # data between startGPSTime and endGPSTime. Break off of the loop when endGPSTime is reached.
    #
    ###########################################
    for k, j in enumerate(listOfFiles[startIndex - 1:listOfFilesLen]):
        
        # Get the filename with the path from each line in listOfFiles.
        thisLine = str(j) # convert this line into string data
        thisPos = thisLine.find(fileLocalHostStr) # find the position of the fileLocalHostStr string:
        if thisPos > -1: 
            thisFile = thisLine[thisPos + fileLocalHostStrLen:] # slice out the filename with the path
        else:
            thisFile = thisLine

        # parse out the GPS time and duration and get the start/end time of thisFile.
        regExpOut = re.search('-(?P<GPS>\d+)-(?P<DUR>\d+)\.', thisFile)
        thisStartTime = int(regExpOut.group('GPS'))
        thisDuration = int(regExpOut.group('DUR'))
        thisEndTime = thisStartTime + thisDuration

        if (thisEndTime <= startGPSTime):
            continue # This file ends before the start of the data we want; continue to the next file
        elif (thisStartTime >= endGPSTime):
            break # This file starts after the end of the data we want; break out of the loop
        else:
            # This file contains some of the data we want. Read it out using frgetvect.
            gpsStart = max([startGPSTime, thisStartTime])
            gpsEnd = min( [endGPSTime, thisEndTime])
            dur = gpsEnd - gpsStart
            try:
                thisData = frgetvect1d(thisFile, chanName, gpsStart, dur)
                data = numpy.concatenate((data, thisData[0]))
                durationFound = durationFound + dur 
            except KeyError:
                errCode = 1
                print 'Error reading data from ' + str(thisFile)
            if (thisEndTime >= endGPSTime):
                # This file ends after the end of the data we want; break out of the loop.            
                break
    
    # Set lastIndex to the last index used in the loop above:
    lastIndex = k
    
    if (len(data) == 0):
        print 'No data found'
        errCode = 2
    elif (durationFound < duration):
        print 'Some data is missing'
        errCode = 3

    nSamples = len(data)
    sRate = int(numpy.floor(nSamples/duration + 0.5))
    deltaT = 1.0/(1.0*sRate)
    times = numpy.array(range(0, nSamples)) * deltaT 
    return [data, lastIndex, errCode, sRate, times]

# For testing demonstrations:
#output = readFrames('/home/pulsar/feedforward/2012/08/14/AMPS/cache/fileList-DARM-953164815-953165875.txt', 'H1:LDAS-STRAIN', 953164815, 129)
#exampleListOfFiles = ['H H1_LDAS_C02_L2 953164800 128 file://localhost/data/node191/frames/S6/LDAShoftC02/LHO/H-H1_LDAS_C02_L2-9531/H-H1_LDAS_C02_L2-953164800-128.gwf', 'H H1_LDAS_C02_L2 953164928 128 file://localhost/data/node191/frames/S6/LDAShoftC02/LHO/H-H1_LDAS_C02_L2-9531/H-H1_LDAS_C02_L2-953164928-128.gwf']
#output = readFrames(exampleListOfFiles, 'H1:LDAS-STRAIN', 953164815, 129,1)
#print output
