#!/usr/bin/python
import math, subprocess, os, commands, shutil, sys, re, fileinput, time
import matplotlib as matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Write the HTML header file for displaying science segment results

# Define a function to edit file objects conveniently
def h(text):
    result = headerObject.write(text + '\n')
    return result

def s(place, text):
    result = place.write(text + '\n')
    return result

# Open the header object
userName = "pulsar"
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
    h("02012-07-18 (JD 2456127)")
    h("")
    h("")
    h("")

    # Write a science-segment overview header
    allObject = open('../../../../../public_html/feedforward/sciencesegments/' +\
                site + '/' + 'allsegments' + '/' + 'HEADER.html',"w")
    s(allObject, "<html>")
    s(allObject, "<head>")
    s(allObject, "<title>All-science segment overview</title>")
    s(allObject, "</head>")
    s(allObject, "")
    s(allObject, "<body>")
    s(allObject, "<center>")
    s(allObject, "<h1>Auxiliary MICH-PRC Subtraction: S6 Feedforward</h1>")
    s(allObject, "</center>")
    s(allObject, "<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
    s(allObject, "<b>All-science segment overview</b><br />")
    s(allObject, "<br />")
    s(allObject, "<center>")
    s(allObject, "Summary plots of range improvements in all science segments,")
    s(allObject, "four science segments per row.")
    s(allObject, "</center>")
    s(allObject, "<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
    s(allObject, "<table border = 1 cellpadding = 5>")

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
    
        def plotMaker(targets, subList, i, v, userName):
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
            s(dirObject, "<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
            s(dirObject, "Each row shows one feedforward filter window (up to 1024 s, 50% overlap)<br />") 
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
            windowListStart = sorted(greaterAndLesser[0])
            windowListStop = sorted(greaterAndLesser[1])
            # Find the head directory containing the plots:
            def headFinder(subList, window, typeFlag):
                headDirectory = []
                for sub in subList:
                    if int(sub[-4::]) == int(window[0:4]):
                        subPost = sub.find("/public_html")
                        if typeFlag == 'graph':
                            # Remove the "home" string and replace it with
                            # a web-compatible one:
                            subUser = sub[6:subPost]
                            subPointer = "https://ldas-jobs.ligo.caltech.edu" + \
                            "/~" + subUser + \
                            sub[subPost+12::]
                        if typeFlag == 'range':
                            subPointer = "../../../../../public_html" + \
                            sub[subPost+12::]
                        headDirectory = subPointer
                        return headDirectory
            # Make an overall range plot
            def rangeReader(dirObject, subList, before, window, after):
                headDirectory = headFinder(subList, window, 'range')
                rangeTxt = '"' + headDirectory + '/' + before + window + \
                after + ".txt" + '"'
                rangeTxtFile =  rangeTxt[1:-1]
                try:
                    rangeTxtObject = open(rangeTxtFile)
                    inspiralRangeLines = rangeTxtObject.readlines()
                    rangeTxtObject.close()
                    inspiralRange = inspiralRangeLines[1]
                    return str(inspiralRange).split()
                except IOError:
                    print 'File not found or accessible; skipping'
            inspiralRangeList = []
            for k, window in enumerate(windowListStart):
                inspiralRangeList.append(rangeReader(dirObject, subList, "EleutheriaRange-", window, "-" + windowListStop[k]))
            inspiralRangeListClean = []
            inspiralRangeListClean = [x for x in inspiralRangeList if x]
            # Now make the plots proper
            rangeGraphFlag = False
            if len(inspiralRangeListClean) > 0:
                rangeGraphFlag = True
                graphTitle = '../../../../../public_html/feedforward/sciencesegments/' +\
                site + '/' + 'allsegments' + '/' + 'SegmentRangeGraph-' + str(startTime) + '-' + str(stopTime)
                xymatrix = np.asarray(inspiralRangeListClean)
                xaxisRaw = np.asarray(xymatrix[:,0], dtype=np.float32)
                xaxis = [int(round(x)) for x in xaxisRaw]
                beforeRange = xymatrix[:,1]
                afterRange = xymatrix[:,2]
                rangeGain = xymatrix[:,3]
                plt.plot(xaxis, beforeRange, 'b')
                plt.plot(xaxis, afterRange, 'g')
                plt.title('Inspiral range versus time, from ' +\
                str(startTime) + ' to ' + str(stopTime))
                plt.xlabel('GPS time (s)')
                plt.ylabel('Inspiral range (Mpc)')
                plt.legend(('Before feedforward', 'After feedforward'), 'upper right', shadow=True, fancybox=True)
                plt.savefig(graphTitle + '.png')
                plt.close()
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
            # Write a function for the science segment overview range plot
            def ssorp(allObject, i, graphTitle, linkPoint, userName):
                if i % 4 == 0:
                    s(allObject, "<tr>")
                # Convert graph title location to a web-compatible form:
                graphPost = graphTitle.find("/public_html")
                graphPointer = "https://ldas-jobs.ligo.caltech.edu" + \
                "/~" + userName + '/' + \
                graphTitle[graphPost+12::]
                thumb = graphPointer + '.png'
                linkPost = linkPoint.find("/public_html")
                linkWeb = "https://ldas-jobs.ligo.caltech.edu" + \
                "/~" + userName + '/' + \
                linkPoint[linkPost+13::]
                percentageSize = '75'
                sizing = " height=" + '"' + percentageSize + '%"' + \
                " width=" + '"' + percentageSize + '%"'
                s(allObject, "<td><center>")
                s(allObject, "<a href=" + linkWeb + "><img src=" + thumb + sizing + "></a>")
                s(allObject, "</center></td>")
                if (i+1) % 4 == 0:
                    s(allObject, "</tr>")
            # Do the overall science segment graph
            if rangeGraphFlag == True:
                ssorp(allObject, i, graphTitle, targets[0], userName)
            # Write a short function to link images to each column entry
            def cim(dirObject, subList, before, window, after): 
                s(dirObject, "<td><center>")
                headDirectory = headFinder(subList, window, 'graph')
                pdf = '"' + headDirectory + '/' + before + window + \
                after + ".pdf" + '"'
                png = '"' + headDirectory + '/' + before + window + \
                after + ".png" + '"'
                s(dirObject, before[10::] + window + after)
                percentageSize = '75'
                sizing = " height=" + '"' + percentageSize + '%"' + \
                " width=" + '"' + percentageSize + '%"'
                s(dirObject, "<a href=" + pdf + "><img src=" + png + sizing + "></a>")
                s(dirObject, "</center></td>") 
            for k, window in enumerate(windowListStart):
                s(dirObject, "<tr>")
                cim(dirObject, subList, "EleutheriaGraph-", window, "-" + windowListStop[k])
                cim(dirObject, subList, "EleutheriaGraph-", window, "-" + windowListStop[k] + "Zoom")
                cim(dirObject, subList, "EleutheriaFilter-", window, "-MICH")
                cim(dirObject, subList, "EleutheriaFilter-", window, "-PRC")
                s(dirObject, "</tr>")
            s(dirObject, "</table>")
            s(dirObject, "</p>")
            s(dirObject, "</body>")
            s(dirObject, "</html>")
            dirObject.close()
            # Copy one header file to the next location:
            copyCommand = "cp " + firstTarget + " " + secondTarget
            os.system(copyCommand)
            
        plotMaker([segmentLocation, monthLocation], subList, i, v, userName)
        
  
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



    # Close the all-segments overview
    s(allObject, "</table>")
    s(allObject, "</p>")
    s(allObject, "</body>")
    s(allObject, "</html>")
    allObject.close()

    # Close the header object
    h("</p>")
    h("</body>")
    h("</html>")
    headerObject.close()
