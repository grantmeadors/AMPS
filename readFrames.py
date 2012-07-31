#!/usr/bin/python
# Grant David Meadors
# 02012-07-30 (JD 2456139)
# g m e a d o r s @ u m i c h . e d u
# readFrames
import numpy
from pylal.Fr import frgetvect1d
output = frgetvect1d('H-H1_LDAS_C02_L2-953164800-128.gwf', 'H1:LDAS-STRAIN', 953164800, 1)
print output
