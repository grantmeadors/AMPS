function results = correlateInjection(frame)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-05-29 
%
% correlateInjection
% 
% Compares a single injection before and after feedforward.

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
    metadata.injFileName = 'inj_931130713_LHO_strain.txt';
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

    % Construct a time index:
    metadata.t = metadata.gpsStart + (0:(128*metadata.fs-1))/metadata.fs;
    % Construct a filter:
    [metadata.zb, metadata.pb, metadata.kb] = butter(16, 2*pi*[100 110], 's');

    % Initially, look at reference data, 0.
    metadata.refOrFilterFlag = 0;
end

metadata = frameMetadata(frame);

function dataOut = firstFrame(metadata);
    % Retrieve the frame using frgetvect
    if metadata.refOrFilterFlag == 0
        [dataOut, tsamp, fsamp, gps0] =...
            frgetvect(metadata.fnameRef, metadata.cnameRef,...
            metadata.gpsStart,...
            128);
    elseif metadata.refOrFilterFlag == 1
        [dataOut, tsamp, fsamp, gps0] =...
            frgetvect(metadata.fname, metadata.cname,...
            metadata.gpsStart,...
            128);
    end
end

function plots = plotMaker(metadata)
    if (metadata.refOrFilterFlag == 0) | (metadata.refOrFilterFlag == 1)
        dataOut = firstFrame(metadata);
        disp('Total data obtained:')
        disp(length(dataOut))
        plots.dataLength = length(dataOut);
    end
    % Filter data:
    if metadata.refOrFilterFlag == 0
        plots.darmRef = filterZPKs(...
            metadata.zb, metadata.pb, metadata.kb, metadata.fs, dataOut);
    elseif metadata.refOrFilterFlag == 1
        plots.darmFilter = filterZPKs(...
            metadata.zb, metadata.pb, metadata.kb, metadata.fs, dataOut);
    elseif metadata.refOrFilterFlag == 2
        plots.strain = filterZPKs(...
            metadata.zb, metadata.pb, metadata.kb, metadata.fs, metadata.strain);
    end
end

function strain = injectionFile(plots, metadata)
    strain = zeros(plots.dataLength, 1);
    strainInj = load(metadata.injFileName);
    metadata.injStartGPS = str2num(metadata.injFileName(5:13));
    diffGPS = metadata.injStartGPS - metadata.gpsStart;
    diffSamp = metadata.fs * diffGPS;
    % Presumably, the GWF files are indexed from zero, as are injections.
    strain(diffSamp+1:diffSamp+length(strainInj)) = strainInj;
end

function plots = plotCompare(metadata)
    plots = plotMaker(metadata);
    metadata.refOrFilterFlag = 1;
    plotting = plotMaker(metadata);
    metadata.refOrFilterFlag = 2;
    plots.darmFilter = plotting.darmFilter;
    strain = injectionFile(plots, metadata);
    metadata.strain = strain; 
    plotting = plotMaker(metadata);
    plots.strain = plotting.strain;
end

function graphing = grapher(plots, metadata)
    % Graph the data available
    figure(1) 
    
    outputFileHead = strcat('/home/gmeadors/public_html/feedforward/programs/spectralScan/',...
        'L', metadata.site, 'O', '/',  num2str(floor(metadata.gpsStart/1e5)), '/');
    system(horzcat('mkdir -p ', outputFileHead))
    % xlimits starting at 89 is appropriate for the injection at 931130713.
    xlimits = metadata.gpsStart + [90.375 90.5];
    outputFile = strcat(outputFileHead, 'correlateInjection-', num2str(xlimits(1)));
    plot(metadata.t, plots.darmRef, metadata.t, plots.darmFilter, metadata.t, plots.strain)
    xlimitsIndex = metadata.fs*xlimits;
    xlim(xlimits)
    %ystdLimit = 5*std(plots.darmRef(xlimitsIndex(1):xlimitsIndex(end)));
    %ymean = mean(plots.darmRef(xlimitsIndex(1):xlimitsIndex(end)));
    %ylimits = [(ymean-ystdLimit) (ymean+ystdLimit)];
    %ylim(ylimits)
    ylim([-3e-21 3e-21])
    %ylim([-2e-22 2e-22])
    grid on
    xlabel('Time (s)')
    ylabel('Amplitude (strain)')
    legend('Before feedforward', 'After feedforward', 'Injection estimated strain')
    titleString = horzcat('Post-filtering injection, GPS s ', num2str(xlimits(1)), ' to ', num2str(xlimits(end)))
    title(titleString)
    disp(outputFile)
    print('-dpng', strcat(outputFile, '.png'))
    print('-dpdf', strcat(outputFile, '.pdf'))
    close(1)
end

grapher(plotCompare(metadata), metadata);

end
