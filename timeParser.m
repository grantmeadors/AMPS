function gpsStartTime = timeParser(frameString)
% Grant David Meadors
% 02012-04-24
% gmeadors@umich.edu

% The true start time of a frame will consist of a time at least nine digits long
% These will be consecutive digits, so they will survive.
% In practice, we should be able to get by just assuming that it is at
% least four digits long.

    gpsStartTime0 = regexp(frameString, '[0-9]');
    gpsStartTime1 = gpsStartTime0(diff(gpsStartTime0) == 1);
    gpsStartTime2 = gpsStartTime1(diff(gpsStartTime1) == 1);
    gpsStartTime3 = gpsStartTime2(diff(gpsStartTime2) == 1);
    gpsStartTime0e = fliplr(gpsStartTime0);
    gpsStartTime1e = gpsStartTime0e(diff(gpsStartTime0e) == -1);
    gpsStartTime2e = gpsStartTime1e(diff(gpsStartTime1e) == -1);
    gpsStartTime3e = gpsStartTime2e(diff(gpsStartTime2e) == -1);
    % Keep only the elements that survived between the third levels:
    gpsStartTime = frameString(...
        gpsStartTime3(1):gpsStartTime3e(1));

end
