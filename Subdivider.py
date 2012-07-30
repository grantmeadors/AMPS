class Subdivider:
    # To survive noise non-stationarity,
    # we subdivide the filtering into 1024 second
    # subsections, or windows, which we will
    # then fit together.
    # Grant David Meadors
    # 02012-07-29 (JD 2456139)
    # g m e a d o r s @ u m i c h . e d u

    def __init__(self, tSegment):
        # Because they will overlap for 512 seconds
        # with the subsection before and 512 seconds
        # with the subsection after,
        # the start of a given science segment is 'tA',
        # the end 'tB'
        tA = tSegment.tA
        tB = tSegment.tB
       
        # tStart is a list of start times of the 
        # 1024 second subsections,
        # tEnd the end times
        import math
        self.tStart = [tA] +\
        [tA + 512*x for x in range(1, int(math.floor(tB-tA)/512)+1)]
        self.tEnd = [tA + 2*512*x for x in range(1, int(math.floor(tB-tA)/512)+1)] +\
        [tB]
        
        # Check to see if the science segment ends before the last
        # 1024 seconds subsection. If so, cut the subsection short.
        self.tEnd = [tB if (x > tB) else x for x in self.tEnd]
        
        # Obliterate subsections with zero duration
        self.tStart = [-1 if (x == self.tEnd[i]) else x \
        for i, x in enumerate(self.tStart)]
        self.tEnd = [[] if (self.tStart[i] == -1) else x \
        for i, x in enumerate(self.tEnd)]
        self.tStart = [[] if (x == -1) else x \
        for i,x in enumerate(self.tStart)]

        # Obliterate subsections with duration less than 32 s
        self.tStart = [-1 if (self.tEnd[i] - x < 32) else x \
        for i, x in enumerate(self.tStart)]
        self.tEnd = [[] if (self.tStart[i] == -1) else x \
        for i, x in enumerate(self.tEnd)]
        self.tStart = [[] if (self.tStart[i] == -1) else x \
        for i, x in enumerate(self.tStart)]

        self.tStart = [x for x in self.tStart if x != []]
        self.tEnd = [x for x in self.tEnd if x != []]