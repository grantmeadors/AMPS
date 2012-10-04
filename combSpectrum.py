#!/usr/bin/python
import math, os, re
import matplotlib as matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np

def combSpectrum(targetDirectory, flag):

    # Grant David Meadors
    # g m e a d o r s @  u m i c h . e d u
    # 02012-10-04 (JD 2456205)
    # combSpectrum
    #
    # Scan output log files for parts of the spectrum where feedforward is 
    # adversely affecting Hoft.
    #
    # Input argument: targetDirectory
    # Choose a directory, e.g. "/home/pulsar/public_html/feedforward/diagnostics/LHO/H-H1_AMPS_C02_L2-9531",
    # into which comb files have been written.
    # Input argument: flag
    # Flag whether the directory itself contains comb files ('one') o
    # is a directory of directories containing comb files ('all')

    # The results of the frequency comb ratio test are stored in files of the form
    # EleutheriaComb-startGPS-stopGPS.txt
    # and thus can be found be searching for (substitute LLO if appropriate)
    # /home/pulsar/public_html/feedforward/diagnostics/LHO/*/*Comb*
    # In each file, the comb frequencies are listed as the values of the columns in
    # row 5 (using Python indexing, starting from 0), and the ratios as the values
    # in row 6; the differences are in row 7.

    if flag == 'all':
    # The comb files are in the directories listed under the target directory.
        highDirectoryList = os.listdir(targetDirectory)
        highDirectoryListDirOnly = [x for x in highDirectoryList if x.find('.') == -1]
        # Because the GPS time 953100000 is used so often for testing,
        # it is temporarily excluded:
        highDirectoryListDirOnly = [x for x in highDirectoryListDirOnly if x.find('9531') == -1]
        combFiles = []
        for x in highDirectoryListDirOnly:
            targetDirectoryFiles = os.listdir(targetDirectory + x)
            for file in targetDirectoryFiles:
                if file.find('EleutheriaComb') > -1:
                    combFiles.append(x + '/' + file)
    if flag == 'one':
        # The comb files are in the target directory.
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
            print 'File not found or accessible; skipping ' +\
            combFileName
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
            differenceArray = np.asarray(str(combRaw[2]).split(), dtype=np.float32)
        if k > 0:
            times = re.search('-(?P<GPS>\d+)-(\d+)\.', eachCombFile)
            timeArray = np.vstack([timeArray, np.asarray(times.group(1), dtype=np.int32)])
            combRaw = combReader(targetDirectory, eachCombFile)
            frequencyArray = np.vstack([frequencyArray, np.asarray(str(combRaw[0]).split(), dtype=np.float32)])
            ratioArray = np.vstack([ratioArray, np.asarray(str(combRaw[1]).split(), dtype=np.float32)])
            differenceArray = np.vstack([differenceArray, np.asarray(str(combRaw[2]).split(), dtype=np.float32)])

    # Now we are going to plot these arrays.
    # First, set a directory for the output. At least for the time being,
    # that can be the same directory as the target directory.
    # Note the inelegant way from extracting the start time as a label.
    graphTitleRatio = targetDirectory + "EleutheriaPostPlotCombRatio" +\
    '-' + str(timeArray[0]).strip("[").strip("]").strip("'")
    graphTitleDiff = targetDirectory + "EleutheriaPostPlotCombDiff" +\
    '-' + str(timeArray[0]).strip("[").strip("]").strip("'")
    x, y = np.meshgrid(timeArray, frequencyArray[0])
    extensions = [x[0, 0], x[-1, -1], y[0, 0], y[-1, -1]]
    # Define a helpfully broken color-scheme as found on the 
    # SciPy Matplotlib Cookbook,
    # http://www.scipy.org/Cookbook/Matplotlib/Show_colormaps
    cdict = {'red': ((0.0, 0.0, 0.0),\
    (0.5, 1.0, 0.7),\
    (1.0, 1.0, 1.0)),\
    'green': ((0.0, 0.0, 0.0),\
    (0.5, 1.0, 0.0),\
    (1.0, 1.0, 1.0)),\
    'blue': ((0.0, 0.0, 0.0),\
    (0.5, 1.0, 0.0),\
    (1.0, 0.5, 1.0))}
    my_cmap = matplotlib.colors.LinearSegmentedColormap('my_colormap', cdict, 256)
    plt.figure()
    CSratio = plt.contourf(x.T, y.T, ratioArray, \
    np.asarray([0.8, 0.85, 0.9, 0.95, \
    1, 1.05, 1.1, 1.15, 1.2]), cmap=my_cmap)
    plt.colorbar(CSratio, shrink=0.8, extend='both')
    plt.xlabel('GPS time (s)')
    plt.ylabel('Frequency (Hz)')
    plt.title('Post/pre-filtering Hoft ratio (lower is better)')
    plt.savefig(graphTitleRatio + 'Contour.png')
    plt.savefig(graphTitleRatio + 'Contour.pdf')
    plt.close()
    plt.clf()
    fig = plt.figure()
    ax = fig.add_subplot(111)
    CSratioIm = ax.imshow(ratioArray.T, origin='lower', \
    interpolation = 'nearest', extent=extensions, vmin=0.8, vmax=1.2,\
    cmap=my_cmap) 
    CSratioIm = fig.colorbar(CSratioIm, shrink = 0.8, extend = 'both')
    ax.set_aspect('auto')
    ax.set_xlabel('GPS time (s)')
    ax.set_ylabel('Frequency (Hz)')
    ax.set_title('Post/pre-filtering Hoft ratio (lower is better)')
    fig.savefig(graphTitleRatio + '.png')
    fig.savefig(graphTitleRatio + '.pdf')
    plt.clf()
    fig = plt.figure()
    ax = fig.add_subplot(111)
    CSdiffIm = ax.imshow(-differenceArray.T, origin='lower', \
    interpolation = 'nearest' , extent=extensions, vmin=-2e-24, vmax=2e-24, \
    cmap=my_cmap)
    plt.show()
    CSdiffIm = fig.colorbar(CSdiffIm, shrink = 0.8, extend = 'both')
    ax.set_aspect('auto')
    ax.set_xlabel('GPS time (s)')
    ax.set_ylabel('Frequency (Hz)')
    ax.set_title('Post - pre Hoft difference (lower is better)')
    fig.savefig(graphTitleDiff + '.png')
    fig.savefig(graphTitleDiff + '.pdf')
    plt.clf()
    plt.figure()
    CSdiff = plt.contourf(x.T, y.T, -differenceArray, \
    np.asarray([-2e-24, -1.5e-24, -1e-24, -5e-25,\
    0, 5e-25, 1e-24, 1.5e-24, 2e-24]), cmap=my_cmap)
    plt.colorbar(CSdiff, shrink=0.8, extend='both')
    plt.xlabel('GPS time (s)')
    plt.ylabel('Frequency (Hz)')
    plt.title('Post - pre Hoft difference (lower is better)')
    plt.savefig(graphTitleDiff + 'Contour.png')
    plt.savefig(graphTitleDiff + 'Contour.pdf')
    plt.close()
        
# Uncomment below to test on one directory only:
combSpectrum('/home/pulsar/public_html/feedforward/diagnostics/LHO/H-H1_AMPS_C02_L2-9531/', 'one')
# Uncomment below to test all directories and produce a whole-run overview.
#grandTarget = '/home/pulsar/public_html/feedforward/diagnostics/LHO/'
#combSpectrum(grandTarget, 'all')
# Uncomment below to test each directory, making plots one-by-one.
#grandTarget = '/home/pulsar/public_html/feedforward/diagnostics/LHO'
#highDirectoryList = os.listdir(grandTarget)
#highDirectoryListDirOnly = [x for x in highDirectoryList if x.find('.') == -1]
#for x in highDirectoryListDirOnly:
#    combSpectrum(grandTarget + '/' + x + '/', 'one')


