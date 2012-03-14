#!/usr/bin/python
import subprocess, os, commands, shutil, sys, re, fileinput, time

# Write the HTML header file for displaying science segment results

# Define a function to edit file objects conveniently
def h(text):
    result = headerObject.write(text + '\n')
    return result

# Open the header object
headerObject = open("/home/gmeadors/public_html/feedforward/sciencesegments/HEADER.html", "w")

# Write the header introduction
h("<html>")
h("<head>")
h("<title>Science segments</title>")
h("</head>")
h("")
h("<body>")
h("<b>Science segments</b><br />")
h("<br />")
h("Science segment figures of merit for the <i>Auxiliary MICH-PRC Subtraction</i> (AMPS) feedforward program, <br />")
h("which subtracts measured auxiliary channel noise (MICH_CTRL and PRC_CTRL) <br />")
h("from DARM_ERR or LDAS_STRAIN signal channels for gravitational wave data <br />")
h("by generating a filter from the signal-noise transfer function. <br />")
h("<br />")
h("Grant David Meadors")
h("<br />")
h("g m e a d o r s @ u m i c h . e d u")
h("<br />")
h("02012-03-14")
h("")
h("")
h("</body>")
h("")
h("</html>")

# Create science-segment based directories, if needed
segmentListObject = open("/home/gmeadors/public_html/feedforward/sciencesegments/seglist.txt")

monthlyList = []

# List from July to December
for j in range(7, 13):
    month = '2009-' + str(j).zfill(2)
    monthlyList.append(month)

# List from January to November
for j in range(1, 12):
    month = '2010-' + str(j).zfill(2)
    monthlyList.append(month)

monthlyListGPS = []

for x in monthlyList:
    monthStringGPS = commands.getoutput('tconvert ' + x + '-01')
    monthlyListGPS.append(monthStringGPS)


segmentList = segmentListObject.readlines();

for i, v in enumerate(segmentList):
    segmentName =  'segment-' + str(i).zfill(4) + '-GPS-' + v[0:9] + '-' + v[10:19]
    #segmentCommand = 'mkdir -p ' + 'allsegments/' + segmentName
    #os.system(segmentCommand)
    segmentLocation = '/home/gmeadors/public_html/feedforward/sciencesegments/allsegments/' + segmentName
    #print segmentLocation
    #monthPlace = [monthlyList[j] for j, w in enumerate(monthlyListGPS) if ((int(w) <= int(v[0:9])) & (int(v[0:9]) <= int(monthlyListGPS[j+1])))]
    
    #for j, w in enumerate(monthlyListGPS):
    #    if (int(w) <= int(v[0:9])) & (int(v[0:9]) <= int(monthlyListGPS[j+1])):
    #            #monthPlace = monthlyList[j]
    #            print 'hello'
    #print monthPlace

    def monthPlacer(list, v):
         greater = []
         lesser = []
         greaterList = [greater.append(j) for j, w in enumerate(list) if (int(w) <= int(v[0:9]))]
         print greaterList

    monthPlacer(monthlyListGPS, v)

    # To avoid overloading the file system, insert a pause
    time.sleep(0.001)


segmentListObject.close()

# Close the header object
headerObject.close()
