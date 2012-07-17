#!/usr/bin/python
import subprocess, os, commands, shutil, sys, re, fileinput, time

# Write the HTML header file for displaying science segment results

# Define a function to edit file objects conveniently
def h(text):
    result = headerObject.write(text + '\n')
    return result

# Open the header object
userName = "gmeadors"
sciencesegmentDirectory = "/home/" + userName + \
"/public_html/feedforward/sciencesegments/"
headerObject = open(sciencesegmentDirectory + "HEADER.html", "w")

# Write the header introduction
h("<html>")
h("<head>")
h("<title>Science segments</title>")
h("</head>")
h("")
h("<body>")
h("<center>")
h("<h1>Auxiliary MICH-PRC Subtraction: S6 Feedforward</h1>")
h("</center>")
h("<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
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
h("02012-07-16 (JD 2456125)")
h("")
h("")
h("</p>")
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
segmentListObject.close()

for i, v in enumerate(segmentList):
    # Uncomment these lines to generate directories. 
    segmentName =  'segment-' + str(i).zfill(4) + '-GPS-' + v[0:9] + '-' + v[10:19]
    def segmentDirectory(segmentName, sciencesegmentDirectory):
        segmentLocation = sciencesegmentDirectory + 'allsegments/' + segmentName
        segmentCommand = 'mkdir -p ' + segmentLocation
        #os.system(segmentCommand)
        #print segmentLocation
        # To avoid overloading the file system, insert a pause
        #time.sleep(0.001)
    segmentDirectory(segmentName, sciencesegmentDirectory)


    def monthPlacer(list, i, v):
         greater = []
         lesser = []
         intersection = []
         for j, w in enumerate(list):
             # Greater is the list of all months before the science segment.
             if int(w) <= int(v[0:9]):
                 greater.append(j)
             # Lesser is the list of all months after the science segment.
             if int(w) > int(v[0:9]):
                 lesser.append(j)
         if greater[-1] == lesser[0] - 1:
             return greater[-1]
         else:
             print 'Month start dates appear to be in error.'

    monthPlace = monthPlacer(monthlyListGPS, i, v)
    #print monthPlace
    
    def monthDirectory(monthlyList, monthPlace, segmentName, sciencesegmentDirectory):
        monthInsert = monthlyList[monthPlace]
        monthLocation = sciencesegmentDirectory + 'monthly/' + monthInsert + '/' + segmentName
        monthCommand = 'mkdir -p ' + monthLocation
        #os.system(monthCommand)
        #print monthCommand
        # Again, give the filesystem a pause.
        #time.sleep(0.001)   
    monthDirectory(monthlyList, monthPlace, segmentName, sciencesegmentDirectory)
 




# Close the header object
headerObject.close()
