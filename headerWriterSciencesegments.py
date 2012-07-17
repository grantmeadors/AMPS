#!/usr/bin/python
import math, subprocess, os, commands, shutil, sys, re, fileinput, time

# Write the HTML header file for displaying science segment results

# Define a function to edit file objects conveniently
def h(text):
    result = headerObject.write(text + '\n')
    return result

def s(place, text):
    result = place.write(text + '\n')
    return result

# Open the header object
userName = "gmeadors"
siteList = ["LHO"]
for site in siteList:
    sciencesegmentDirectory = "/home/" + userName + \
    "/public_html/feedforward/sciencesegments/" + site + "/"
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
    h("")

    # Create science-segment based directories, if needed
    segmentListObject = open(sciencesegmentDirectory + "seglist.txt")

    monthlyList = []

    # List from July to December
    for j in range(7, 13):
        month = '2009-' + str(j).zfill(2)
        monthlyList.append(month)

    # List from January to November
    for j in range(1, 12):
        month = '2010-' + str(j).zfill(2)
        monthlyList.append(month)

    # Make sure that these months exist as directories
    for month in monthlyList:
        monthBasic = 'mkdir -p' + sciencesegmentDirectory + 'monthly' + month
        #os.system(monthBasic)

    monthlyListGPS = []

    for x in monthlyList:
        monthStringGPS = commands.getoutput('tconvert ' + x + '-01')
        monthlyListGPS.append(monthStringGPS)




    segmentList = segmentListObject.readlines();
    segmentListObject.close()

    for i, v in enumerate(segmentList):
        # Uncomment these lines to generate directories. 
        segmentName =  'segment-' + str(i+1).zfill(4) + '-GPS-' + v[0:9] + '-' + v[10:19]
        def segmentDirectory(segmentName, sciencesegmentDirectory):
            segmentLocation = sciencesegmentDirectory + 'allsegments/' + segmentName
            segmentCommand = 'mkdir -p ' + segmentLocation
            #os.system(segmentCommand)
            #print segmentLocation
            # To avoid overloading the file system, insert a pause
            #time.sleep(0.001)
            return segmentLocation
        segmentLocation = segmentDirectory(segmentName, sciencesegmentDirectory)


        def monthPlacer(list, i, v):
             greater = []
             lesser = []
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
            return monthLocation
        monthLocation = monthDirectory(monthlyList, monthPlace, segmentName, sciencesegmentDirectory)

        def plotFinder(userName, site, i, v):
            # For a given target directory associated with a science segment,
            # we must calculate the location of its diagnostics.
            # First, note the floors of the GPS start and stop times.
            startTime = v[0:9]
            stopTime = v[10:19]
            # Note that the directories are subdivided into 1e5 s
            floorStartTime = int(math.floor(int(startTime)/1e5))
            floorStopTime = int(math.floor(int(stopTime)/1e5))
            # Now the directories range from the start to the stop
            # (Add one due to python's way of indexing)
            dirRange = range(floorStartTime, floorStopTime + 1)
            # Now reference the appropriate diagnostic directories
            diagnosticDirectory = "/home/" + userName + \
            "/public_html/feedforward/diagnostics/" + site + "/"
            subString = []
            for subDir in dirRange:
                subString.append(site[1] + "-" + site[1] + "1_AMPS_C02_L2-" + \
                str(subDir))
            subDiagnosticDirectory = []
            for subName in subString:
                if os.path.isdir(diagnosticDirectory + subName):
                    subDiagnosticDirectory.append(diagnosticDirectory + subName)
            return subDiagnosticDirectory
        subList = plotFinder(userName, site, i, v)
    
        #def plotMaker(targets, subList, i, v):
        #    firstTarget = targets[0] + '/' + "HEADER.html"
        #    secondTarget = targets[1] + '/' + "HEADER.html"
        #    dirObject = open(firstTarget, "w")
        #    dirObject.close()
        #    print secondTarget
            
        #plotMaker([segmentLocation, monthLocation], subList, i, v)
        
  
    # Now create links to the month directories from the top level, for convenience:
    pathToMonth = sciencesegmentDirectory + "monthly" + "/"
    sub0files = os.listdir(pathToMonth)
    directoriesRaw = []
    for entry in sub0files:
        if os.path.isdir(pathToMonth + entry):
            directoriesRaw.append(entry)
    directories = sorted(directoriesRaw)
    h("<br />")
    h("<br />")
    h("<b>Science segments by month</b><br />")
    for dir in directories:
        h("<a href = " + "monthly" + "/" + dir + ">" + "Diagnostics for month " + dir + "</a><br />")




    h("</p>")
    h("</body>")
    h("</html>")
    # Close the header object
    headerObject.close()
