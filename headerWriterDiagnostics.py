#!/usr/bin/python
import os, commands, shutil, sys, re

# Write the HTML header file for displaying science segment results

# Define a function to edit file objects conveniently
def h(text):
    result = headerObject.write(text + '\n')
    return result

# Open the header object
headerObject = open("/home/gmeadors/public_html/feedforward/diagnostics/HEADER.html", "w")

# Write the header introduction
h("<html>")
h("<head>")
h("<title>Feedforward diagnostics</title>")
h("</head>")
h("")
h("<body>")
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
h("02012-03-14")
h("")
h("")
h("</body>")
h("")
h("</html>")

# Close the header object
headerObject.close()
