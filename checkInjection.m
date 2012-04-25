function output = checkInjection(frame, varargin)

% Grant David Meadors
% 02012-04-24
% gmeadors@umich.edu

% Compares the frame file against a list of known
% successful hardware injections to see whether
% the feedforward algorithm alters them.
% This should also detect any spurious timing shifts.

% The varargin would be the frame data, if being so passed.

frameString = char(frame);

% Decide which site injection list to open based on the input frame
if strcmp(class(frame), 'char')
    disp('Checking injections in the following frame:')
    disp(frameString)
    site = frameString(1);
    siteFull = strcat('L', site, 'O');
else
    disp('Error: wrong input argument. Please specify a string frame name')
end

injectionFile = strcat(site, '1biinjlist.txt');
injectionFileID = fopen(injectionFile, 'r');

cellInjectionFile = textscan(injectionFileID, '%d %s %f %s %*[^\n]');

fclose(injectionFileID);

% Now we have read in the injection list. If an injection went through,
% then the fourth column will say 'Successful'
injectionList = zeros(size(cellInjectionFile{4}));

parfor ii=1:length(cellInjectionFile{4})
    if strcmp(cellInjectionFile{4}(ii), 'Successful')
        injectionList(ii) = cellInjectionFile{1}(ii);
    end
end
% Trim unsuccesful injections
injectionList(injectionList == 0) = [];

% Determine whether an injection would be in the range of this frame file,
% which is to say whether it is between the file name
% and 128 seconds after, as each frame file is 128 second long.

% Using regular expressions is the most reliable way to extract the time:
% But the first three will be unrelated to the GPS time
% One can also do this with str2num(frameString(18:26))
% But only for nine-digit GPS times
% gpsStart = str2num(frameString(18:26))


gpsStartTime = str2num(timeParser(frameString));
disp(gpsStartTime)

injectionInFrame = injectionList(gpsStartTime <= injectionList &...
    injectionList < gpsStartTime + 128);

if length(injectionInFrame) > 0
    disp('Injection in frame: triggering search on this time --')
    disp(injectionInFrame)
    disp(varargin)
else
    disp('No injection in frame')
end

output = 0;
end
