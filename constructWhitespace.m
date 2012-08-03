function nextSubWhitespace = constructWhitespace(T, tSub, jj)
    % The amount of data we need for the next window is a complicated question.
    % First, compute the stop time, minus one -- it is an end, hence the minus one,
    % which is necessary in the edge case where the window ends on mod(128),
    % except in the case where the whole science segment started on mod(128).
    if mod(tSub.tStart(1), 128) == 0
        edgeException = 0;
    else
        edgeException = -1;
    end
    insideEnd = tSub.tEnd(jj+1) + edgeException;
    % Then compute the start of the first window of the next frame:
    insideStart = T.s*floor(tSub.tStart(jj+1)/T.s);
    % We need at least that much, but not more than 512 seconds.
    % Since, at jj=end-2, we just took off 512 seconds (but not more),
    % the maximum length the next frame could occupy is
    insideDifference = insideEnd - insideStart - 512;
    % Yet we never want more than 512 seconds in our buffer;
    % we need the min of 512 and the insideDifference for the middle of a long loop,
    % when the latter is larger. This statement keeps out buffer the same size.
    minForBuffer = min([512, insideDifference]);
    % Finally, round to a multiple of the frame length
    nextSubWhitespace = T.s*floor(minForBuffer/T.s);
end
