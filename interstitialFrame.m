function output = interstitialFrame(frame, cache, observatory, duration)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-06-19
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

% First we retrieve the LDAS-STRAIN data from disk
% Along with the state vector and data quality flag

function data = framePull(frame, cache, observatory, duration)
    cname = strcat(observatory, '1:LDAS-STRAIN');
    [baseline,lastIndex,errCode,samplingFrequency,times] =...
        readFrames(cache, cname, frame, duration);
end


% Here we assemble the strings that will reference the
% frame file when we output it to disk
%frameString = char(frame);
%frameNameHead = '/archive/frames/S6/pulsar/feedforward/';
% The following is more broadly compatible
%gpsStart = str2num(timeParser(frameString));
%site = frameString(1);
%siteFull = strcat('L', site, 'O');
%frameDirectoryMiddle = frameString(1:21);
%fname = strcat(frameNameHead, siteFull, '/', frameDirectoryMiddle, '/',...
%    frameString);
%disp(fname)

% The channel name is the AMPS strain channel,
% the Auxiliary MICH-PRC subtraction version of Hoft,
% directly analogous to LDAS-STRAIN.
cname = strcat(site, '1:AMPS-STRAIN');


samplingFrequency = 2*(fsamp(end)+1/128);
disp(length(data)/samplingFrequency)
disp('Frequency of sampling:')
disp(samplingFrequency)
disp('Starting GPS time:')
disp(gps0)
   
  
end

