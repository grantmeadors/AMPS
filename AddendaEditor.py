class AddendaEditor:
    # Produces the ubiquitous addenda object that carries information
    # between the filtering and the Hoft generation stages
    # Grant David Meadors
    # 02012-08-15 (JD 2456155)
    # g m e a d o r s @ u m i c h . e d u

    def __init__(self, \
    baselineCheck, PRCfilter, pipe, s, \
    inputFileDARM, inputFileNOISE, passFirstFlag, \
    frameHeadFlag, frameTailFlag, siteName):
        self.darm = []
        self.passDARM = []
        self.passPRC = []
        self.passMICH = []
        self.PRCfilter = PRCfilter
        self.frameHeadFlag = frameHeadFlag
        self.frameTailFlag = frameTailFlag
        self.baseline = []
        self.s = s
        self.pipe = pipe
        self.inputFileDARM = inputFileDARM
        self.inputFileNOISE = inputFileNOISE
        self.passFirstFlag = passFirstFlag
        self.baselineCheck = baselineCheck
        self.site = siteName
        self.siteFull = 'L' + siteName + 'O'
    def initialFixer(self, tSub, T):
        import numpy
        tau1 = int(numpy.floor(tSub.tStart[0] / T.s)) * T.s
        tau2 = int(numpy.ceil(tSub.tEnd[0] / T.s)) * T.s
        if tSub.tStart[0] == tau1:
            self.frameHeadFlag = 0
        else: 
            self.frameHeadFlag = 1
        # For short segments, including the frame tail.
        # Short is any single window. Single windows are naturally
        # up to 512 seconds long, but we aggregate any second windows
        # less than 32 seconds long into them, so "short" means
        # less than or equal to 512+32 seconds long.
        if (tSub.tEnd[0] - tSub.tStart[0]) > (512+32):
            self.frameTailFlag = 0
        elif tSub.tEnd[1] == tau2:
            self.frameTailFlag = 0
        else:
            self.frameTailFlag = 1
    def loopFixer(self, Hoft, jj, tSub):
        if jj == len(tSub.tStart):
            self.frameTailFlag = 1
        if jj == 2:
            nC = Hoft.nA
            nD = nC + 16384 * (min([512, tSub.tEnd[1] - tSub.tEnd[0] - 512]))
            self.passDARM = Hoft.baseline[nC:nD]
            self.passMICH = Hoft.passMICH
            del Hoft.passMICH
            self.passPRC = Hoft.passPRC
            del Hoft.passPRC
        elif jj > 2:
            self.passDARM = Hoft.passDARM
            del Hoft.passDARM
            self.passMICH = Hoft.passMICH
            del Hoft.passMICH
            self.passPRC = Hoft.passPRC
            del hoft.passPRC
    def initialPRC(self, aFirstHoft):
        self.PRCfilter = 1
        self.passFirstFlag = 0
        self.baseline = aFirstHoft.baseline
        del aFirstHoft.baseline 
        self.darm = aFirstHoft.data
        del aFirstHoft.data
        self.frameHeadFlag = 0
        self.frameTailFlag = 0
    def loopPRC(self, aNewHoft):
        self.PRCfilter = 1
        self.frameTailFlag = 0
        self.baseline = aNewHoft.baseline
        del aNewHoft.baseline
        self.darm = aNewHoft.data
    def destroyer(self, fieldName):
        if str(fieldName) == 'darm':
            self.darm = []
        elif str(fieldName) == 'baseline':
            self.baseline = []
        elif str(fieldName) == 'passPRC':
            self.passPRC = []
        elif str(fieldName) == 'passMICH':
            self.passMICH = []
        elif str(fieldName) == 'passDARM':
            self.passDARM = []
