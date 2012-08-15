class Data:
    # Retrieve data from LIGO servers
    # Grant David Meadors
    # 02012-08-15 (JD 2456155)
    # g m e a d o r s @ u m i c h . e d u

    def __init__(self, t0, t1, addenda):
        # Extract beginning and end times
        self.t = [t0, t1]

        # Assign information to our data object about these times and the frame length
        self.t0 = t0
        self.t1 = t1
        self.s = addenda.s
        self.pipe = addenda.pipe
        self.site = addenda.site
        self.siteFull = addenda.siteFull 

        # Find the start of the first frame and end of the last
        import numpy
        if addenda.frameHeadFlag == 1:
            self.tau1 = int(numpy.floor(self.t[0]/addenda.s)) * addenda.s 
        else:
            self.tau1 = self.t[0]
        if addenda.frameTailFlag == 1:
            self.tau2 = int(numpy.ceil(self.t[1]/addenda.s)) * addenda.s
        else:
            self.tau2 = self.t[1]

        # Find how far shifted the signal is into the science segment
        self.durationHead = \
            self.t[0] - int(numpy.floor(self.t[0]/addenda.s)) * addenda.s
        self.durationTail = \
            int(numpy.ceil(self.t[1]/addenda.s)) * addenda.s - self.t[1]

        # Sampling frequency of MICH and DARM
        self.Fs = 16384
        # Duration over which to generate the feedforward filter
        self.duration = self.t[1] - self.t[0]
        # Duration including unused frame portions
        self.durationPlus = self.tau2 - self.tau1
        # LDAS-STRAIN (DARM, or Hoft) and MICH/PRC channel names
        if addenda.pipe == 1:
            channelname = \
            [ self.site + '1:LDAS-STRAIN', \
            self.site + '1:LSC-MICH_CTRL', \
            self.site + '1:LSC-PRC_CTRL', \
            self.site + '1:IFO-SV_STATE_VECTOR', \
            self.site + '1:LSC-DATA_QUALITY_VECTOR']
        elif addenda.pipe == 2:
            channelname = \
            [ self.site + '1:LSC-DARM_ERR', \
            self.site + '1:LSC-MICH_CTRL', \
            self.site + '1:LSC-PRC_CTRL', \
            self.site + '1:IFO-SV_STATE_VECTOR', \
            self.site + '1:LSC-DATA_QUALITY_VECTOR']

        print 'A list of relevant variables: t0, tau1, t1, tau2, duration, durationPlus, t0+512, tau1+512, duration-512, durationPlus-512'
        print self.t[0]
        print self.tau1
        print self.t[1]
        print self.tau2
        print self.duration
        print self.durationPlus
        print self.t[0] + 512
        print self.tau1 + 512
        print self.duration - 512
        print self.durationPlus - 512

        # Insert a catch function to ensure that the correct amount of data is retrieved from servers
        def readFramesVerily(cache, whichChannel, startTime, duration, samplingFrequency):
            numberOfTries = 100
            import readFrames
            for hh in range(0, numberOfTries):
                dataArray = readFrames.readFrames(\
                cache, whichChannel, startTime, duration)
                if len(dataArray[0]) == (samplingFrequency * duration):
                    hh = numberOfTries + 1
                    break
                if (hh > 0) and (hh < numberOfTries - 1):
                    print 'Failure to correctly retrieve data; pausing and will retry' 
                    import time
                    time.sleep(5) 
                if hh == numberOfTries - 1:
                    print 'Failed to correctly retrieve data after ' +\
                    str(numberOfTries) + ' attempts.'
            return dataArray

        if addenda.PRCfilter == 1:
            # DARM supplied from input arguments
            self.darm = addenda.darm
            addenda.destroyer('darm')
            # PRC filtering
            ############ FILL IN LATER ###############
        else:
            # DARM supplied by frames; grab before and after times too
            if addenda.passFirstFlag == 1:
                print 'FILL IN LATER'
            else:
                self.darm = \
                readFramesVerily(addenda.inputFileDARM, \
                channelname[0],self.tau1,self.durationPlus,16384)
