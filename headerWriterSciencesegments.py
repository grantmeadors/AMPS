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
                 # Greater is the list of all months before or equal to the
                 # start science segment.
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
    
        def plotMaker(targets, subList, i, v):
            startTime = int(v[0:9])
            stopTime = int(v[10:19])
            firstTarget = targets[0] + '/' + "HEADER.html"
            secondTarget = targets[1] + '/' + "HEADER.html"
            dirObject = open(firstTarget, "w")
            s(dirObject, "<html>")
            s(dirObject, "<head>")
            s(dirObject, "<title>Feedforward science segment</title>")
            s(dirObject, "</head>")
            s(dirObject, "<body>")
            s(dirObject, "<center>")
            sciString = str(i + 1) + " from GPS time " + v[0:9] + " to " + v[10:19]
            s(dirObject, "<h1>Diagnostics for science segment " +  sciString + "</h1>")
            s(dirObject, "</center>")
            s(dirObject, "<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
            s(dirObject, "<table border = 1 cellpadding = 5>")
            # Now comes the complicated work of organizing only the right
            # graphs from the listed directories and of then integrating them
            # into a table.
            # First, proceed as with the parallel diagnostic directories
            sub1files = []
            for dir in subList:
                sub1files.append(os.listdir(dir))
            candidateWindowListStart = []
            candidateWindowListStop = []
            for subentry in sub1files:
                # Nested for loop to handle list of lists
                for subsubentry in subentry:
                    if subsubentry.find('EleutheriaGraph') > -1:
                        if subsubentry.find('Zoom.png') > -1:
                            candidateWindowListStart.append(subsubentry[16:25]) 
                            candidateWindowListStop.append(subsubentry[26:35])
            # Now we have to find out whether these candidates are within
            # the science segment. 
            def segPlacer(listStart, listStop, startTime, stopTime):
                greater = []
                lesser = []
                for j, w in enumerate(listStart):
                    # Greater is the list of all start candidates after the start
                    # of the science segment but before its end
                    if int(w) >= startTime:
                        if int(w) <= stopTime: 
                            greater.append(w)
                for j, w in enumerate(listStop):
                    # Lesser is the list of all stop candidates before the stop
                    # of the science segment but before its end
                    if int(w) <= stopTime:
                        if int(w) >= startTime:
                            lesser.append(w)
                if (not len(lesser) == len(greater)):
                    print "Mismatch in number of diagnostic files"
                return [greater, lesser]
            greaterAndLesser = segPlacer(candidateWindowListStart, candidateWindowListStop, startTime, stopTime)
            windowListStart = greaterAndLesser[0]
            windowListStop = greaterAndLesser[1]
            # Make the column labels
            def c(dirObject, string):
                s(dirObject, "<td>")
                s(dirObject, "<center>" + string + "</center>")
                s(dirObject, "</td>")
            s(dirObject, "<tr>")
            c(dirObject, "<b>Spectrum</b>")
            c(dirObject, "<b>Spectrum (zoom)</b>")
            c(dirObject, "<b>MICH Filter TF</b>")
            c(dirObject, "<b>PRC Filter TF</b>")
            s(dirObject, "</tr>")
            # Write a short function to link images to each column entry
            def cim(dirObject, subList, before, window, after): 
                s(dirObject, "<td><center>")
                headDirectory = []
                for sub in subList:
                    if int(sub[-4::]) == int(window[0:4]):
                        # Remove the "home" string and replace it with
                        # a web-compatible one:
                        subPost = sub.find("/public_html")
                        subUser = sub[6:subPost]
                        subPointer = "http://ldas-jobs.ligo.caltech.edu" + \
                        "/~" + subUser + sub[subPost+12::]
                        headDirectory = subPointer
                pdf = '"' + headDirectory + '/' + before + window + \
                after + ".pdf" + '"'
                png = '"' + headDirectory + '/' + before + window + \
                after + ".png" + '"'
                s(dirObject, before[10::])
                s(dirObject, "<a href=" + pdf + "><img src=" + png + "></a>")
                s(dirObject, "</center></td>")
            for i, window in enumerate(windowListStart):
                s(dirObject, "<tr>")
                cim(dirObject, subList, "EleutheriaGraph-", window, "-" + windowListStop[i])
                s(dirObject, "</tr>")
            s(dirObject, "</table>")
            s(dirObject, "</p>")
            s(dirObject, "</body>")
            s(dirObject, "</html>")
            dirObject.close()
            # Copy one header file to the next location:
            copyCommand = "cp " + firstTarget + " " + secondTarget
            os.system(copyCommand)
            
        plotMaker([segmentLocation, monthLocation], subList, i, v)
        
  
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
