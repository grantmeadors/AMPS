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
    for k, eachCombFile in enumerate(combFiles):
        # Each file will have four properties:
        # start time, read in the GPS time of the file name
        # frequency bins, read from the fifth row of the file (0th of combRaw),
        # ratios, read from the sixth (1st of combRaw),
        # and difference, read from the seventh (2nd of combRaw).
        if k == 0:
            times = re.search('-(?P<GPS>\d+)-(\d+)\.', eachCombFile)
            timeArray = np.asarray(times.group(1), dtype=np.int32)
            combRaw = combReader(targetDirectory, eachCombFile)
            frequencyArray = np.asarray(str(combRaw[0]).split(), dtype=np.float32)
            frequencyArray = frequencyArray.astype(int)
            ratioArray = np.asarray(str(combRaw[1]).split(), dtype=np.float32)
            #differenceArray = np.asarray(str(combRaw[2]).split(), dtype=np.float32)
        if k > 0:
            times = re.search('-(?P<GPS>\d+)-(\d+)\.', eachCombFile)
            timeArray = np.vstack([timeArray, np.asarray(times.group(1), dtype=np.int32)])
            combRaw = combReader(targetDirectory, eachCombFile)
            frequencyArray = np.vstack([frequencyArray, np.asarray(str(combRaw[0]).split(), dtype=np.float32)])
            ratioArray = np.vstack([ratioArray, np.asarray(str(combRaw[1]).split(), dtype=np.float32)])
            #differenceArray = np.vstack([differenceArray, np.asarray(str(combRaw[2]).split(), dtype=np.float32)])

    # Now we are going to plot these arrays.
    # First, set a directory for the output. At least for the time being,
    # that can be the same directory as the target directory.
    # Note the inelegant way from extracting the start time as a label.
    graphTitle = targetDirectory + "EleutheriaPostPlotComb" +\
    '-' + str(timeArray[0]).strip("[").strip("]").strip("'")
    #plt.plot(frequencyArray[0], ratioArray[0])
    x, y = np.meshgrid(timeArray, frequencyArray[0])
    plt.contour(x.T, y.T, ratioArray, 50)
    plt.savefig(graphTitle + '.png')
    plt.close()
        

combSpectrum('/home/pulsar/public_html/feedforward/diagnostics/LHO/H-H1_AMPS_C02_L2-9531/')