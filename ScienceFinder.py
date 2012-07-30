class ScienceFinder:
    # Analyze the start and end times to determine
    # the boundaries of science segments in between
    # T is the default class object name
    # Grant David Meadors
    # 02012-07-29 (JD 2456139)
    # g m e a d o r s @ u m i c h . e d u

    def __init__(self, time0, time1):
        # Load a list of science segments
        segmentListObject = open("dividedSeglist.txt")
        segmentList = [line.strip().split() for line in segmentListObject]
        segmentListObject.close()
        self.segments = segmentList 

        # Decide what type of pipeline to use:
        # self.pipe = 1 for science run S6, self.pipe = 2 for squeezing
        # For future reference,
        # note the size of gwf frame files in seconds
        # self.S = 32 for squeezing data, = 128 for science run S6
        self.pipe = 1
        if self.pipe == 1:
            self.S = 128
        elif self.pipe == 2:
            self.S = 32
        
        # Input start and stop times
        self.time = [int(time0), int(time1)]

        # Find out whether t0 and t1 are in science mode or not
        # self.finder finds the last science segment (s)
        # start (n=0) and end (n=1) times before a given time (t)
        def lastOne(list):
            if len(list) > 0:
                return list[-1]
            else:
                return 0
        self.finder = lambda n, t, s: \
        lastOne([int(x[n]) for x in s if int(x[n]) <= int(t)])
        # self.compare returns Boolean True if the last science segment (s)
        # start before a given time was after the last segment end --
        # meaning that the time is in science -- and False if outside
        # of science
        self.compare = lambda t, s: self.finder(0, t, s) > self.finder(1, t, s)

        # Find out about all the times in segment (s) between t(0) and t(1)
        # returns a list of science start times if n=0, end times if n=1
        self.between = lambda n, t, s: \
        [int(x[n]) for x in s if (int(t[0]) <= int(x[n]) & int(x[n]) <= int(t[1]))]

        # Produce a list of science segment start (n=0) and stop (n=1)
        # times based on a segment list (s) between times t(0) and t(1)
        # If in science (self.compare returns True) then concatenate t(n) with
        # the list of times returned by self.between. If outside of science,
        # just use the science segments in between.
        self.list = [[],[],[],[]]

        # Only take first start and last end, to handle overlapping
        # science "segments" that are in fact broken-up long science
        # segments that would be too long to run in one piece
        self.list[0] = sorted(list(set(self.between(0, self.time, self.segments))))[0]
        self.list[1] = sorted(list(set(self.between(1, self.time, self.segments))))[-1]
        
        # Make sure that the start and stop times are adjusted if asked
        # to start within a segment (should not happen in practice)
        if self.compare(self.time[0], self.segments):
            self.list[0] = sorted(list(set([self.time[0], self.list[0]])))
        if self.compare(self.time[0], self.segments):
            self.list[1] = sorted(list(set([self.list[1], self.time[1]])))
        for i, x in enumerate([self.list[0]]):
            if set([int(y[0]) for y in self.segments]).intersection(set(x)):
                 self.list[2] = [int(z[2]) for z in self.segments if \
                 set([int(z[0])]).intersection(set(x))]
            else:
                self.list[2] = 0
        for i, x in enumerate([self.list[1]]):
            if set([int(y[1]) for y in self.segments]).intersection(set(x)):
                 self.list[3] = [int(z[3]) for z in self.segments if \
                 set([int(z[1])]).intersection(set(x))]
            else:
                self.list[3] = 0
        
         # If time0 was not in science, then all start times are between time0 & time1
         # If time1 was not in science, then all end times are between time0 and time1
         # If it finds no science in between time0 and time1, Python will report an error