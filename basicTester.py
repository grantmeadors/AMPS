#!/usr/bin/python

import ScienceFinder
T = ScienceFinder.ScienceFinder(953164815, 953165875)
import Segmentor
tSegment = Segmentor.Segmentor(T, 0)
import Subdivider
tSub = Subdivider.Subdivider(tSegment)
import AddendaEditor
inputFileDARM = '/home/pulsar/feedforward/2012/08/14/AMPS/cache/fileList-DARM-953164815-953165875.txt'
inputFileNOISE = '/home/pulsar/feedforward/2012/08/14/AMPS/cache/fileList-NOISE-953164815-953165875.txt'
addenda = AddendaEditor.AddendaEditor(0,0,T.pipe,T.s,\
inputFileDARM,inputFileNOISE,0,0,0,'H')

addenda.initialFixer(tSub, T)

import Data
channels = Data.Data(953164815, 953165875, addenda)
print channels.darm
