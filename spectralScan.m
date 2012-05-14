function results = spectralScan(frame)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-05-14 
%
% spectralScan
% 
% Search for forests of lines and frequency combs around
% calibration lines and verify that the calibration line
% remains the same height before and after feedforward filtering.

function metadata = frameMetadata(frame)
    % Here we assemble the strings that reference the
    % frame file
    metadata.frameString = char(frame);
    metadata.frameNameHead = '/archive/frames/S6/pulsar/feedforward/';
    % The following is only compatible for nine-digit GPS times
    % gpsStart = str2num(metadata.frameString(18:26)); 
    % The following is more broadly compatible
    metadata.gpsStart = str2num(timeParser(metadata.frameString));
    metadata.site = metadata.frameString(1);
    metadata.siteFull = strcat('L', metadata.site, 'O');
    metadata.frameDirectoryMiddle = metadata.frameString(1:21);
    metadata.fname = strcat(metadata.frameNameHead, metadata.siteFull, '/',...
        metadata.frameDirectoryMiddle, '/',...
        metadata.frameString);
    disp('Perusing the following file:')
    disp(metadata.fname)

    % The channel name is the AMPS strain channel,
    % the Auxiliary MICH-PRC subtraction version of Hoft,
    % directly analogous to LDAS-STRAIN.
    metadata.cname = strcat(metadata.site, '1:AMPS-STRAIN');

    % Assume a sampling frequency of 16384 Hz
    metadata.fs = 16384;

    % Find out which times are in science:
    metadata = onlyScience(metadata);
end

metadata = frameMetadata(frame);

function dataOut = firstFrame(metadata);
    % Retrieve the frame using frgetvect
    [dataOut, tsamp, fsamp, gps0] =...
        frgetvect(metadata.fname, metadata.cname,...
        metadata.gpsStart + metadata.scienceOffset,...
        128 - metadata.scienceOffset);
end
function dataOut = adjacentFrames(data, metadata, beyondTimes)
    % Can test adjacent frames for sanity check:
    newStart = metadata.gpsStart + 128*beyondTimes;
    frameString1 =...
        strcat(metadata.frameString(1:17),...
            num2str(newStart),...
            metadata.frameString(27:end));
    fname1 =...
        strcat(metadata.frameNameHead,...
            metadata.siteFull, '/',...
            metadata.frameDirectoryMiddle, '/',...
            frameString1);
    [data1, tsamp1, fsamp1, gps1] =...
        frgetvect(fname1, metadata.cname, newStart, 128);
    dataOut = [data; data1];
end
function dataOut = combineFrames(metadata)
    dataOut = firstFrame(metadata);
    % Now scan enough frames to have 4096 s. We already have one.
    % Yet that one is not all science data. So grab one more.
    numberOfFrames = (128)/128;
    for ii = 1:numberOfFrames
        disp('Reading frame number:') 
        disp(ii+1)
        dataOut = adjacentFrames(dataOut, metadata, ii);
    end
    % Trim the last frame so that we have an even multiple of 128 s.
    lengthOfData = 128*metadata.fs*...
        floor(length(dataOut)/(128*metadata.fs));
    dataOut = dataOut(1:lengthOfData);
end
dataOut = combineFrames(metadata);
disp('Total data obtained:')
disp(length(dataOut))

function metadata = onlyScience(metadata)
    % Use science segment data to ensure that we take only science data.
    scienceSegments = load('divided200Seglist.txt');
    floorStarts = 128*floor(scienceSegments(:,1)/128);
    scienceNumber = find(floorStarts == metadata.gpsStart);
    scienceStart = scienceSegments(scienceNumber, 1);
    metadata.scienceOffset = scienceStart - metadata.gpsStart;
    disp('Offset of science start from frame (seconds):')
    disp(metadata.scienceOffset)
    metadata.offsetSample = metadata.fs * metadata.scienceOffset;
end

end
