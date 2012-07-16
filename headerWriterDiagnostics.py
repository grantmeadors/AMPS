#!/usr/bin/python
import os, commands, shutil, sys, re

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
    diagnosticDirectory = "/home/" + userName + \
    "/public_html/feedforward/diagnostics/" + site + "/"
    headerObject = open(diagnosticDirectory + "HEADER.html", "w")

    # Write the header introduction
    h("<html>")
    h("<head>")
    h("<title>Feedforward diagnostics</title>")
    h("</head>")
    h("")
    h("<body>")
    h("<center>")
    h("<h1>Auxiliary MICH-PRC Subtraction: S6 Feedforward</h1>")
    h("</center>")
    h("<p style = " + '"' + "font-family:sans-serif"+'"' + ">")
    h("<b>Feedforward diagnostics</b><br />")
    h("<br />")
    h("Diagnostics for the <i>Auxiliary MICH-PRC Subtraction</i> (AMPS) feedforward program, <br />")
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

    # Locate the files and directories underneath:
    sub0files = os.listdir(diagnosticDirectory)
    directoriesRaw = []
    for entry in sub0files:
        if entry.find('AMPS') > -1:
            if os.path.isdir(diagnosticDirectory + entry):
                directoriesRaw.append(entry)
    directories = sorted(directoriesRaw)

    # Make links to subdirectories:
    h("<br />")
    h("<br />")
    h("<b>Diagnostic directories</b><br />")
    for dir in directories:
        # The five zeros at the end are because directories contain 100000 s each.
        dirTime = dir[17:21] + "00000"
        dirTimePlus = str(int(dirTime) + 100000)
        dirTimeString = dirTime + " to " + dirTimePlus
        h("<a href = " + dir + ">" + "Diagnostics for GPS times " + dirTimeString + "</a><br />")

    # Font family
    h("</p>")

    # Close the header
    h("</body>")
    h("")
    h("</html>")

    # Close the header object
    headerObject.close()

    for dir in directories:
        dirObject = open(diagnosticDirectory + dir + '/' + "HEADER.html", "w")
        s(dirObject, "<html>")
        s(dirObject, "<head>")
        s(dirObject, "<title>Feedforward diagnostics</title>")
        s(dirObject, "</head>")
        s(dirObject, "<body>")
        s(dirObject, "<center>")
        # The five zeros at the end are because directories contain 100000 s each.
        dirTime = dir[17:21] + "00000"
        dirTimePlus = str(int(dirTime) + 100000)
        dirTimeString = dirTime + " to " + dirTimePlus
        s(dirObject, "<h1>Diagnostics for GPS times " + dirTimeString + "</h1>")
        s(dirObject, "</center>")
        s(dirObject, "</body>")
        s(dirObject, "</html>")
        dirObject.close()
