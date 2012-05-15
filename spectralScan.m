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
    metadata.refString = strcat(metadata.frameString(1:5), 'LDAS',...
        metadata.frameString(10:end));
    metadata.frameNameHead = '/archive/frames/S6/pulsar/feedforward/';
    % Note that this reference frame head is only valid for the GPS time
    % 931178496 to 931190912:
    metadata.refNameHead = '/data/node232/frames/S6/LDAShoftC02/';
    % The following is only compatible for nine-digit GPS times
    % gpsStart = str2num(metadata.frameString(18:26)); 
    % The following is more broadly compatible
    metadata.gpsStart = str2num(timeParser(metadata.frameString));
    metadata.site = metadata.frameString(1);
    metadata.siteFull = strcat('L', metadata.site, 'O');
    metadata.frameDirectoryMiddle = metadata.frameString(1:21);
    metadata.refDirectoryMiddle = strcat(metadata.frameDirectoryMiddle(1:5),...
        'LDAS',metadata.frameDirectoryMiddle(10:end));
    metadata.fname = strcat(metadata.frameNameHead, metadata.siteFull, '/',...
        metadata.frameDirectoryMiddle, '/',...
        metadata.frameString);
    metadata.fnameRef = strcat(metadata.refNameHead, metadata.siteFull, '/',...
        metadata.refDirectoryMiddle, '/',...
        metadata.refString);
    disp('Perusing the following file:')
    disp(metadata.fname)

    % The channel name is the AMPS strain channel,
    % the Auxiliary MICH-PRC subtraction version of Hoft,
    % directly analogous to LDAS-STRAIN.
    metadata.cname = strcat(metadata.site, '1:AMPS-STRAIN');
    % And the name for the reference:
    metadata.cnameRef = strcat(metadata.site, '1:LDAS-STRAIN');

    % Assume a sampling frequency of 16384 Hz
    metadata.fs = 16384;

    % Find out which times are in science:
    metadata = onlyScience(metadata);
    % Initially, look at reference data, 0.
    metadata.refOrFilterFlag = 0;
end

metadata = frameMetadata(frame);

function dataOut = firstFrame(metadata);
    % Retrieve the frame using frgetvect
    if metadata.refOrFilterFlag == 0
        [dataOut, tsamp, fsamp, gps0] =...
            frgetvect(metadata.fnameRef, metadata.cnameRef,...
            metadata.gpsStart + metadata.scienceOffset,...
            128 - metadata.scienceOffset);
    elseif metadata.refOrFilterFlag == 1
        [dataOut, tsamp, fsamp, gps0] =...
            frgetvect(metadata.fname, metadata.cname,...
            metadata.gpsStart + metadata.scienceOffset,...
            128 - metadata.scienceOffset);
    end
end
function dataOut = adjacentFrames(data, metadata, beyondTimes)
    % Can test adjacent frames for sanity check:
    newStart = metadata.gpsStart + 128*beyondTimes;

    if metadata.refOrFilterFlag == 0
        frameString1 =...
            strcat(metadata.refString(1:17),...
                num2str(newStart),...
                metadata.refString(27:end));
        fname1 =...
            strcat(metadata.refNameHead,...
                metadata.siteFull, '/',...
                metadata.refDirectoryMiddle, '/',...
                frameString1);
        [data1, tsamp1, fsamp1, gps1] =...
            frgetvect(fname1, metadata.cnameRef, newStart, 128); 
    elseif metadata.refOrFilterFlag == 1
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
    end
    dataOut = [data; data1];
end
function dataOut = combineFrames(metadata)
    dataOut = firstFrame(metadata);
    % Now scan enough frames to have 4096 s. We already have one.
    % Yet that one is not all science data. So grab one more.
    numberOfFrames = (3*4096)/128;
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

function spectra = spectrumMaker(metadata)
    dataOut = combineFrames(metadata);
    disp('Total data obtained:')
    disp(length(dataOut))
    % Decide on a resolution of 4096 Hz
    nfft = 4096*metadata.fs;
    [pdarm, spectra.fx] = pwelch(...
        dataOut, hanning(nfft), nfft/2, nfft, metadata.fs);
    % Take the amplitude spectral density:
    if metadata.refOrFilterFlag == 0
        spectra.adarmRef = sqrt(pdarm)
    elseif metadata.refOrFilterFlag == 1
        spectra.adarmFilter = sqrt(pdarm);
    end
end

function spectra = spectraCompare(metadata)
    spectra = spectrumMaker(metadata);
    metadata.refOrFilterFlag = 1;
    spectrum = spectrumMaker(metadata);
    spectra.adarmFilter = spectrum.adarmFilter;
end

function graphing = grapher(spectra, metadata)
    % Graph the data available
    figure(1) 
    
    outputFileHead = strcat('/home/gmeadors/public_html/feedforward/programs/spectralScan/',...
        'L', metadata.site, 'O', '/',  num2str(floor(metadata.gpsStart/1e5)), '/');
    system(horzcat('mkdir -p ', outputFileHead))
    outputFile = strcat(outputFileHead, 'spectralScan-', num2str(metadata.gpsStart));
    semilogy(spectra.fx, spectra.adarmRef, spectra.fx, spectra.adarmFilter)
    grid on
    xlim([393.0 393.2])
    xlabel('Frequency (Hz)')
    ylabel('Amplitude spectral density (\surdHz)')
    legend('Before feedforward', 'After feedforward')
    titleString = horzcat('Post-filtering spectrum, starting GPS time ', num2str(metadata.gpsStart))
    title(titleString)
    disp(outputFile)
    print('-dpng', strcat(outputFile, '.png'))
    print('-dpdf', strcat(outputFile, '.pdf'))
    close(1)
end

grapher(spectraCompare(metadata), metadata);

end
