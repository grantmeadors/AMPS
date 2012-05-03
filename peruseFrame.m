function output = peruseFrame(frame, varargin)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-05-01
% peruseFrame.m

% peruseFrame examines a specified frame file for
% the AMPS feedforward project and verifies that it 
% contains reasonable data.

% Example of a frame file name:
% H-H1_AMPS_C02_L2-931052672-128.gwf

% Here we assemble the strings that reference the
% frame file
frameString = char(frame);
frameNameHead = '/archive/frames/S6/pulsar/feedforward/';
% The following is only compatible for nine-digit GPS times
% gpsStart = str2num(frameString(18:26)); 
% The following is more broadly compatible
gpsStart = str2num(timeParser(frameString));
site = frameString(1);
siteFull = strcat('L', site, 'O');
frameDirectoryMiddle = frameString(1:21);
fname = strcat(frameNameHead, siteFull, '/', frameDirectoryMiddle, '/',...
    frameString);
disp('Perusing the following file:')
disp(fname)

% The channel name is the AMPS strain channel,
% the Auxiliary MICH-PRC subtraction version of Hoft,
% directly analogous to LDAS-STRAIN.
cname = strcat(site, '1:AMPS-STRAIN');

% Retrieve the frame using frgetvect
[data, tsamp, fsamp, gps0] = frgetvect(fname, cname, gpsStart, 128);

% Display basic diagnostic figures
disp('Data is this many samples long:')
disp(length(data))
disp('Data is this many seconds long:')
% This requires knowing the sampling frequency
% fsamp is not the sampling frequency but an array
% from 0 to (Nyquist - 1/128) Hz. So the sampling frequency is
% 2*(fsamp(end)+1).
samplingFrequency = 2*(fsamp(end)+1/128);
disp(length(data)/samplingFrequency)
disp('Frequency of sampling:')
disp(samplingFrequency)
disp('Starting GPS time:')
disp(gps0)

disp('Checking for anomalous ones, i.e. unwritten array fragments')
anyOneThere = find(data == 1);
if length(anyOneThere) == 0
    disp('No anomalous ones detected')
else
    disp('Anomalous ones detected -- matrix of this many found')
    disp(size(anyOneThere))
end

disp('Checking for repetitions')

% Now fold the data to look for repeated tuples
function differenceInLength = dataFold(data, n)
        dataFolded = zeros(size(downsample(data, 2^(n-1), 0)));
    for ii = 0:(2^(n-1)-1)
        dataFolded = dataFolded + downsample(data, 2^(n-1), ii);
    end
    differenceInLength = length(dataFolded) - length(unique(dataFolded));
end

% Organize the results into an array
maxFolding = 6;
dataFoldResult = zeros(maxFolding, 1);
dataFoldResult(1) = dataFold(data, 1);
disp('This many repeated elements found with no folding')
disp(dataFoldResult(1))
for jj = 2:maxFolding
    if dataFoldResult(jj-1) > 0 
        dataFoldResult(jj) = dataFold(data,jj);
        disp(horzcat('... ', num2str(jj), '-way folding'));
        disp(dataFoldResult(jj))
    end
end

% Now check for syncronization using injections:
% varargin{1} should be the cache listing the frames
cache = char(varargin{1});
output = checkInjection(frameString, data, cache);

  
end

