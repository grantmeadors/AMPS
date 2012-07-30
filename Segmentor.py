class Segmentor:
    # Extracts proper window times for a given science segment
    # Grant David Meadors
    # 02012-07-29 (JD 2456139)
    # g m e a d o r s @ u m i c h . e d u

    def __init__(self, T, ii):
        # Find the subdivision times for the specific segment
        # by looking at an 'ii'th element of 'T.list'
        self.tA = T.list[0][ii]
        self.tB = T.list[1][ii]
        self.tIsPreceded = T.list[2][ii]
        self.tIsFollowed = T.list[3][ii]

        # Apply the subdivider to that specific segment,
        # Which gives 1024 second windows out to tSub.
        print 'Beginning science segment ... ' + str(ii+1)
