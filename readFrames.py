#!/usr/bin/python
# Grant David Meadors
# 02012-08-14 (JD 2456154)
# g m e a d o r s @ u m i c h . e d u
# readFrames
# Based on code by Gregory Mendell
import numpy
from pylal.Fr import frgetvect1d

# Testing tools:
#output = frgetvect1d('/data/node191/frames/S6/LDAShoftC02/LHO/H-H1_LDAS_C02_L2-9531/H-H1_LDAS_C02_L2-953164800-128.gwf', 'H1:LDAS-STRAIN', 953164800, 1)
#print output

def readFrames(fileList, chanName, startGPSTime, duration, fileListIsInMemory, startIndex):
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
    # (feature not supported -- Grant David Meadors) 
    # 3. Read 60 s of H1:LSC-DARM_ERR data from a list of files, myFileList:
    # (feature not supported -- Grant David Meadors)
    # 
    # Inputs:
    #
    # fileList: A filename with a lal-cache style list of frame files or a list of filesnames. (SEe isListNotFile option below.)
    # chanName: The name of the channel to read from the frames.
    # startGPSTime: The GPS start time of first sample to return.
    # duration: The duration in seconds to return.
    # fileListIsInMemory: Set this to 1 if fileList is a list of filenames, and not a fileName with this list. (Optional) 
    # startIndex: The index from which to start in the list of files (optional, default is 1)
    return [data, lastIndex, errCode, sRate, times]
