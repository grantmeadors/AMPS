#!/usr/bin/python

import AddendaEditor
addenda = AddendaEditor.AddendaEditor(0,0,0,0,0,0,0,0,0,'H')
import ScienceFinder
T = ScienceFinder.ScienceFinder(953164815, 953165875)
print T.s
import Segmentor
tSegment = Segmentor.Segmentor(T, 0)
import Subdivider
tSub = Subdivider.Subdivider(tSegment)

addenda.initialFixer(tSub, T)
