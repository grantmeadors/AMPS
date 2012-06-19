function output = interstitialFrame(frame, cache, observatory, duration)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-06-18
% interstitialFrame.m
%
% interstitialFrame accepts a frame input from S6 Hoft and
% writes out the same output relabelled as LDAS-STRAIN,
% along with state vector and DQ flag. It is designed to do
% this for times that are not written directly by the
% feedforward program.
%
% Example of a frame file name:
% H-H1_AMPS_C02_L2-931052672-128.gwf
% Example of input arguments:
% frame = 931052672
% cache = cache/interstitialCache-Hoft-931000000-932000000.txt
% observatory = H
% duration = 128

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
testBit = 0;
if testBit == 1
    % Can test adjacent frame for sanity check:
    frameString1 = strcat(frameString(1:17), num2str(gpsStart+128), frameString(27:end));
    fname1 = strcat(frameNameHead, siteFull, '/', frameDirectoryMiddle, '/',...
        frameString1);
    [data1, tsamp1, fsamp1, gps1] = frgetvect(fname1, cname, gpsStart+128, 128);
    data = [data; data1];
end

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
   
  
end

