#!/usr/bin/python
import os, commands, shutil, sys, re

# Define a function to edit file objects conveniently
def h(text):
    result = fileObject.write(text + '\n')
    return result
analysisDate = "2012/05/01"

fileObject = open("/archive/home/gmeadors/" + analysisDate + "/AMPS/PeruseSub.sub", "w")

# Write the contents of the file
h("universe = vanilla")
h("executable = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseManyFrames.py")
h("output = /archive/home/gmeadors/" + analysisDate + "/AMPS/peruseLogs/peruseManyFrames.out.$(process)")
h("error = peruseLogs/peruseManyFrames.err.$(process)")
h("log = peruseLogs/peruseManyFrames.log.$(process)")
h("requirements = Memory >= 3999")
h("")

def queuer(n):
    h("arguments = " + str(n))
    h("queue")
    h("")

[queuer(n) for n in range(9310, 9327+1)]


fileObject.close
