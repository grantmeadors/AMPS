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
# Choose a directory, e.g. "~pulsar/feedforward/2012/09/12/AMPS",
# from where a feedforward run has been launched

# The results of the frequency comb ratio test are stored in files of the form
# EleutheriaComb-startGPS-stopGPS.txt
# and thus can be found be searching for (substitute LLO if appropriate)
# /home/pulsar/public_html/feedforward/diagnostics/LHO/*/*Comb*
# In each file, the comb frequencies are listed as the values of the columns in
# row 1 (using Matlab indexing, starting from 1), and the ratios as the values
# in row 2.

