#!/usr/bin/python
import math, os, re
import matplotlib as matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

def combSpectrum(targetDirectory):

    # Grant David Meadors
    # g m e a d o r s @  u m i c h . e d u
    # 02012-09-21 (JD 2456192)
    # combSpectrum
    #
    # Scan output log files for parts of the spectrum where feedforward is 
    # adversely affecting Hoft.
    #
    # Input argument: targetDirectory
    # Choose a directory, e.g. "/home/pulsar/public_html/feedforward/diagnostics/LHO/H-H1_AMPS_C02_L2-9531",
    # into which comb files have been written.

    # The results of the frequency comb ratio test are stored in files of the form
    # EleutheriaComb-startGPS-stopGPS.txt
    # and thus can be found be searching for (substitute LLO if appropriate)
    # /home/pulsar/public_html/feedforward/diagnostics/LHO/*/*Comb*
    # In each file, the comb frequencies are listed as the values of the columns in
    # row 5 (using Python indexing, starting from 0), and the ratios as the values
    # in row 6; the differences are in row 7.
    
    # The comb files are in the targest directory.
    # Pull a list of all the comb files.
    targetDirectoryFiles = os.listdir(targetDirectory)
    combFiles = []
    for file in targetDirectoryFiles:
        if file.find('EleutheriaComb') > -1:
            combFiles.append(file)

    # Now write a function that can read an individual file into memory.
    def combReader(targetDirectory, eachCombFile):
        combFileName = targetDirectory + eachCombFile
        try:
            combObject = open(combFileName)
            combLines = combObject.readlines()
            combObject.close()
        except IOError:
            print 'File not found or accessible; skipping'
        return combLines[5:8]
    # Apply the function to all the comb files in the directory.
    timeArray = np.asarray([1])
    frequencyArray = np.asarray([1])
    ratioArray = np.asarray([1])
    differenceArray = np.asarray([1])
    for eachCombFile in combFiles:
        # Each file will have four properties:
        # start time, read in the GPS time of the file name
        # frequency bins, read from the fifth row of the file (0th of combRaw),
        # ratios, read from the sixth (1st of combRaw),
        # and difference, read from the seventh (2nd of combRaw).
        times = re.search('-(?P<GPS>\d+)-(\d+)\.', eachCombFile)
        timeArray = np.vstack([timeArray, np.asarray(times.group(1))])
        combRaw = combReader(targetDirectory, eachCombFile)
        frequencyArray = np.vstack([frequencyArray, np.asarray(combRaw[0])])
        ratioArray = np.vstack([ratioArray, np.asarray(combRaw[1])])
        differenceArray = np.vstack([differenceArray, np.asarray(combRaw[2])])
    # Due to vstack's demand for equal dimensions in each argument,
    # and the null dimensionality of the empty set, the arrays were
    # initialized with a dummy one that is then deleted below.
    timeArray = timeArray[1:]
    frequencyArray = frequencyArray[1:]
    ratioArray = ratioArray[1:]
    differenceArray = differenceArray[1:]
    print timeArray
    print frequencyArray
    print ratioArray
    print differenceArray
        

combSpectrum('/home/pulsar/public_html/feedforward/diagnostics/LHO/H-H1_AMPS_C02_L2-9531/')
