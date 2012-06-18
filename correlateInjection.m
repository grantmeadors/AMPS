function results = correlateInjection(frame, varargin)
% Grant David Meadors
% gmeadors@umich.edu
% 02012-06-04 
%
% correlateInjection
% 
% Compares a single injection before and after feedforward.

frameObject.frame = frame;
frameObject.numberArgs = nargin;
if nargin > 1
    frameObject.ref = varargin{1};
end
if nargin > 2
    frameObject.filter = varargin{2};
end
if nargin > 3
    frameObject.injGPSstart = varargin{3};
end
if nargin > 4
    frameObject.frequencyList = varargin{4};
end

function metadata = frameMetadata(frameObject)
    frame = frameObject.frame;
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
    metadata.injectionDirectory =... 
        '/home/gmeadors/public_html/feedforward/programs/injectionStrain/www.gravity.physics.umd.edu/gw/hwinj/s6vsr2/S6VSR2a/';
    metadata.ETMXinjectionDirectory = ...
        '/home/gmeadors/public_html/feedforward/programs/injectionETMX/www.gravity.physics.umd.edu/gw/hwinj/s6vsr2/S6VSR2a/';
    %metadata.injFileName = 'inj_931130713_LHO_strain.txt';
    % A duplicate entry, injStartGPS, may appear later
    % Default to injection GPS start of 931130713 for testing purposes:
    metadata.injGPSstart = 931130713;
    if frameObject.numberArgs >= 4
        metadata.injGPSstart = frameObject.injGPSstart;
    end
    metadata.gpsStart = str2num(timeParser(metadata.frameString));
    metadata.site = metadata.frameString(1);
    metadata.siteFull = strcat('L', metadata.site, 'O');
    % The following set where the feedforward data resides
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
    % Establish the name of the injection estimated strain file:
    metadata.injFileName = strcat(metadata.injectionDirectory, 'inj_',...
        num2str(metadata.injGPSstart), '_', metadata.siteFull, '_',...
        'strain.txt');
    % Establish the name of injection ETMX actuation file:
    metadata.actFileName = strcat(metadata.ETMXinjectionDirectory, 'inj_',...
        num2str(metadata.injGPSstart), '_ETMX_',...
        metadata.site, '1.dat');

    % The channel name is the AMPS strain channel,
    % the Auxiliary MICH-PRC subtraction version of Hoft,
    % directly analogous to LDAS-STRAIN.
    metadata.cname = strcat(metadata.site, '1:AMPS-STRAIN');
    % And the name for the reference:
    metadata.cnameRef = strcat(metadata.site, '1:LDAS-STRAIN');
    % And the name for DARM
    metadata.cnameDARM = strcat(metadata.site, '1:LSC-DARM_ERR');

    % Assume a sampling frequency of 16384 Hz
    metadata.fs = 16384;

    % Choose a center frequency for the injection:
    % (First set defaults for testing time of 931130713)
    metadata.centerFrequency = 153;
    if frameObject.numberArgs >= 5
        metadata.centerFrequency = frameObject.frequencyList(1);
    end
    metadata.frequencyWindow = metadata.centerFrequency + [2 12];

    % Construct a time index:
    metadata.t = metadata.gpsStart + (0:(128*metadata.fs-1))/metadata.fs;
    % Construct a filter:
    % Based on read center frequency for burst injection:
    [metadata.zb, metadata.pb, metadata.kb] = butter(8,...
        2*pi*metadata.frequencyWindow, 's');

    % Initially, look at reference data, 0.
    metadata.refOrFilterFlag = 0;
    % But if nargin > 1, take passed data
    if frameObject.numberArgs >= 3
        metadata.passedDataFlag = 1;
        metadata.ref = frameObject.ref;
        metadata.filter = frameObject.filter;
    else
        metadata.passedDataFlag = 0;
    end
end

metadata = frameMetadata(frameObject);

function dataOut = firstFrame(metadata);
    if metadata.passedDataFlag == 0
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
        elseif metadata.refOrFilterFlag == 4
            setenv('STARTTIME', num2str(metadata.gpsStart));
            setenv('ENDTIME', num2str(metadata.gpsStart+128));          
            [status.darm, result.darm] = system(...
                'ligo_data_find --observatory=H --type=R --gps-start-time=$STARTTIME --gps-end-time=$ENDTIME --url-type=file --lal-cache');
            % Find the number of lines in the result by counting the 'gwf's
            numberOfLines = length(strfind(result.darm, 'gwf'));
            % Create a cell structure to house the names of DARM frames
            listing.darm = cell(numberOfLines, 1);
            % Delimit the boundaries of the file names
            startString = strfind(result.darm, 'file');
            endString = strfind(result.darm, '.gwf');
            % Populate the cell array with the locations of files:
            for jj = 1:numberOfLines
                listing.darm{jj} = result.darm(startString(jj):endString(jj)+length('.gwf'));
            end
            [dataOut,lastIndex,errCode,sRate,times] =...
                readFrames(listing.darm, metadata.cnameDARM, metadata.gpsStart, 128, 1);
        end
    elseif metadata.passedDataFlag == 1
        if metadata.refOrFilterFlag == 0
        disp('Obtaining passed reference data')
            dataOut = metadata.ref.Hoft;
            clear metadata.ref;
        elseif metadata.refOrFilterFlag == 1
            dataOut = metadata.filter;
            clear metadata.filter;
        elseif metadata.refOrFilterFlag == 4
            dataOut = metadata.ref.DARM;
            clear metadata.ref.DARM
        end
    end
end

function plots = plotMaker(metadata)
    if (metadata.refOrFilterFlag == 0) | (metadata.refOrFilterFlag == 1) |...
        (metadata.refOrFilterFlag == 4)
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
    elseif metadata.refOrFilterFlag == 3
        plots.ETMX = filterZPKs(...
            metadata.zb, metadata.pb, metadata.kb, metadata.fs, metadata.ETMX);
    elseif metadata.refOrFilterFlag == 4
        plots.DARM = filterZPKs(...
            metadata.zb, metadata.pb, metadata.kb, metadata.fs, dataOut);
    end
end

function strain = injectionFile(plots, metadata)
    strain = zeros(plots.dataLength, 1);
    strainInj = load(metadata.injFileName);
    %metadata.injStartGPS = str2num(metadata.injFileName(5:13));
    metadata.injStartGPS = metadata.injGPSstart;
    diffGPS = metadata.injStartGPS - metadata.gpsStart;
    diffSamp = metadata.fs * diffGPS;
    % Presumably, the GWF files are indexed from zero, as are injections.
    strain(diffSamp+1:diffSamp+length(strainInj)) = strainInj;
end

function ETMX = actuationFile(plots, metadata)
    ETMX = zeros(plots.dataLength, 1);
    ETMXinj = load(metadata.actFileName);
    metadata.injStartGPS = metadata.injGPSstart;
    diffGPS = metadata.injStartGPS - metadata.gpsStart;
    diffSamp = metadata.fs * diffGPS;
    ETMX(diffSamp+1:diffSamp+length(ETMXinj)) = ETMXinj;
    % Constrain the length, if excessive
    if length(ETMX) > plots.dataLength
        ETMX(plots.dataLength+1:end) = [];
    end
end

function plots = plotCompare(metadata)
    plots = plotMaker(metadata);
    metadata.refOrFilterFlag = 1;
    plotting = plotMaker(metadata);
    plots.darmFilter = plotting.darmFilter;
    clear plotting;
    metadata.refOrFilterFlag = 2;
    strain = injectionFile(plots, metadata);
    metadata.strain = strain; 
    clear strain
    ETMX = actuationFile(plots, metadata);
    metadata.ETMX = ETMX;
    clear ETMX
    plotting = plotMaker(metadata);
    plots.strain = plotting.strain;
    clear plotting
    metadata.refOrFilterFlag = 3;
    plotting = plotMaker(metadata);
    plots.ETMX = plotting.ETMX;
    clear plotting
    metadata.refOrFilterFlag = 4;
    plotting = plotMaker(metadata);
    plots.DARM = plotting.DARM;
    clear plotting
end

function graphing = grapher(plots, metadata)
    % Graph the data available
    figure(1) 
    
    outputFileHead = strcat('/home/gmeadors/public_html/feedforward/programs/spectralScan/',...
        'L', metadata.site, 'O', '/',  num2str(floor(metadata.gpsStart/1e5)), '/');
    system(horzcat('mkdir -p ', outputFileHead))
    % xlimits = metadata.gpsStart + [90.5 90.625];
    % Or one can try to be automated by looking from 1/16 to 2 seconds of the injection
    % The slight delay tries to evade the problem of filter-turn on distorting the estimated
    % strain file
    xlimits = [1/16 2];
    xlimitsGPS = metadata.injGPSstart + xlimits;
    xlimitsOffset = xlimitsGPS - metadata.gpsStart;
    xlimitsIndex = metadata.fs*xlimitsOffset;
    %ylimits  = [-3e-21 3e-21];
    % Create subsets of the data that correspond only to what is graphed
    % Subtract off the GPS start time from the x-axis to make better x-axis
    % labels -- the xlabel will note this offset.
    smallT = metadata.t(xlimitsIndex(1):xlimitsIndex(end)) - metadata.injGPSstart;
    smallDarmRef = plots.darmRef(xlimitsIndex(1):xlimitsIndex(end));
    smallDarmFilter = plots.darmFilter(xlimitsIndex(1):xlimitsIndex(end));
    smallStrain = plots.strain(xlimitsIndex(1):xlimitsIndex(end));
    smallETMX = plots.ETMX(xlimitsIndex(1):xlimitsIndex(end));
    smallDARM = plots.DARM(xlimitsIndex(1):xlimitsIndex(end));
    outputFile = strcat(outputFileHead, 'correlateInjection-', num2str(xlimitsGPS(1)));
    outputFileCrossCorr = strcat(outputFileHead, 'crossCorrInjection-', num2str(xlimitsGPS(1)));
    % Scaling factors based on standard deviation, with some margin for visibility.
    scale.ETMX = 0.3*std(smallDarmRef)/std(smallETMX);
    scale.DARM = 0.2*std(smallDarmRef)/std(smallDARM);
    % Ideally, they would vary in proportion to the DARM-to-Hoft calibration, lest
    % ETMX and DARM occlude Hoft at some frequencies and be overshadowed by it at others.
    plot(smallT, smallDarmRef, smallT, smallDarmFilter,...
         smallT, smallStrain, smallT, scale.ETMX*smallETMX,...
         smallT, scale.DARM*smallDARM)
    xlim(xlimits)
    %ylim(ylimits)
    grid on
    xlabel(horzcat('Time (s) - ', num2str(metadata.injGPSstart)))
    ylabel('Amplitude (strain)')
    legend('Before feedforward', 'After feedforward', 'Injection estimated strain',...
        horzcat('ETMX actuation *', num2str(scale.ETMX)),...
        horzcat('DARM_ERR *', num2str(scale.DARM)))
    titleStringTimeTop = horzcat('Post-filtering injection, GPS s ', num2str(xlimitsGPS(1)),...
        ' to ', num2str(xlimitsGPS(end)));
    titleStringTimeBottom = '(ETMX, DARM not calibrated; for timing comparison only)';
    title({titleStringTimeTop; titleStringTimeBottom})
    disp(outputFile)
    print('-dpng', strcat(outputFile, '.png'))
    print('-dpdf', strcat(outputFile, '.pdf'))
    close(1)

    figure(2)
    nLags = 512;
    [XCFref,lagsRef] = xcorr(smallDarmRef, smallStrain, nLags);   
    [XCFfilter,lagsFilter] = xcorr(smallDarmFilter, smallStrain, nLags);   
    [XCFrefFilter,lagsRefFilter] = xcorr(smallDarmRef, smallDarmFilter, nLags);   
    plot(lagsRef, XCFref, lagsFilter, XCFfilter, lagsRefFilter, XCFrefFilter)
    xlabel('Time lag (1/16384 s)')
    ylabel('Cross-correlation')
    titleStringCrossCorrTop = 'Feedforward (FF) cross-correlations: injection (inj), before(B), after(A)';
    titleStringCrossCorrBottom = horzcat('GPS s ', num2str(xlimits(1)), ' to ', num2str(xlimits(end)));
    title({titleStringCrossCorrTop; titleStringCrossCorrBottom})

    % Display maxima and minima of the lag plots:
    maxDarmRef = find(XCFref == max(XCFref));
    minDarmRef = find(XCFref == min(XCFref));
    maxDarmFilter = find(XCFfilter == max(XCFfilter));
    minDarmFilter = find(XCFfilter == min(XCFfilter));
    maxStrain = find(XCFrefFilter == max(XCFrefFilter));
    minStrain = find(XCFrefFilter == min(XCFrefFilter));
    disp('Position (lag in samples) of max and min cross-correlation:')
    disp('Before-feedforward-to-injection')
    lagsMaxRef = lagsRef(maxDarmRef);
    lagsMinRef = lagsRef(minDarmRef);
    disp(lagsMaxRef)
    disp(lagsMinRef)
    disp('After-feedforward-to-injection')
    lagsMaxFilter = lagsFilter(maxDarmFilter);
    lagsMinFilter = lagsFilter(minDarmFilter);
    disp(lagsMaxFilter)
    disp(lagsMinFilter)
    disp('Before-feedforward-to-after')
    lagsMaxRefFilter = lagsRefFilter(maxStrain);
    lagsMinRefFilter = lagsRefFilter(minStrain);
    disp(lagsMaxRefFilter)
    disp(lagsMinRefFilter)
    disp('Value (strain squared) of max and min cross-correlation:')
    disp('Before-feedforward-to-injection') 
    disp(max(XCFref))
    disp(min(XCFref))
    disp('After-feedforward-to-injection')
    disp(max(XCFfilter))
    disp(min(XCFfilter))
    disp('Before-feedforward-to-after')
    disp(max(XCFrefFilter))
    disp(min(XCFrefFilter))
    % Sound an alarm if there is a shift from before to after:
    if lagsMaxRefFilter ~= 0
        disp(horzcat('Alert! Cross-correlation is shifted from before-to-after by ', num2str(lagsMaxRefFilter)))
    end
    if lagsMaxRef ~= lagsMaxFilter
        disp(horzcat('Alert! After-to-injection is shifted with respect to before-to-injection by ', num2str(lagsMaxFilter - lagsMaxRef)))
    end

    % Now find zero-crossings for each
    % Note that the cross-correlation arrays are of odd-length
    % Here we split them into left (L) and right (R), giving the
    % middle to R
    XCFrefL = XCFref(1:(length(XCFref)-1)/2);
    XCFrefR = XCFref((length(XCFref)+1)/2:end);
    XCFfilterL = XCFfilter(1:(length(XCFfilter)-1)/2);
    XCFfilterR = XCFfilter((length(XCFfilter)+1)/2:end);
    XCFrefFilterL = XCFrefFilter(1:(length(XCFrefFilter)-1)/2);
    XCFrefFilterR = XCFrefFilter((length(XCFrefFilter)+1)/2:end);
    % For ref and filter, find the last greater than zero as one approaches
    % the central minimum; for refFilter, find the last less than zero as one
    % approaches the central maximum.
    % But note: we add the length of L to any R-side value,
    % to respect the index value of the original cross-correlation
    zXrefL = find(XCFrefL >= 0, 1, 'last');
    zXrefR = find(XCFrefR >= 0, 1, 'first') + length(XCFrefL);
    zXfilterL = find(XCFfilterL >= 0, 1, 'last');
    zXfilterR = find(XCFfilterR >= 0, 1, 'first') + length(XCFfilterL);
    zXrefFilterL = find(XCFrefFilterL <= 0, 1, 'last');
    zXrefFilterR = find(XCFrefFilterR <= 0, 1, 'first') + length(XCFrefFilterL);
    % Associate these with a given lag index:
    lagsZrefL = lagsRef(zXrefL);
    lagsZrefR = lagsRef(zXrefR);
    lagsZfilterL = lagsFilter(zXrefL);
    lagsZfilterR = lagsFilter(zXrefR);
    lagsZrefFilterL = lagsRefFilter(zXrefFilterL);
    lagsZrefFilterR = lagsRefFilter(zXrefFilterR);
    % Display these values:
    disp('Zero-crossing indices: before-feedforward-to-injection cross-correlation, left, right of central minumum')
    disp(lagsZrefL)
    disp(lagsZrefR)
    disp('Zero-crossing indices: after-feedforward-to-injection cross-correlation, left, right of central minumum')
    disp(lagsZfilterL)
    disp(lagsZfilterR)
    disp('Zero-crossing indices: before-feedforward-to-after cross-correlation, left, right of central maximum')
    disp(lagsZrefFilterL)
    disp(lagsZrefFilterR)


    legendRef = horzcat('B-FF-to-inj, max, min lag index: ',...
         num2str(lagsMaxRef), ', ', num2str(lagsMinRef),...
         ' 1st L, R 0-crossings: ',...
         num2str(lagsZrefL), ', ', num2str(lagsZrefR));
    legendFilter = horzcat('A-FF-to-inj, max, min lag index: ',...
          num2str(lagsMaxFilter), ', ', num2str(lagsMinFilter),...
          ' 1st L, R 0-crossings: ',...
          num2str(lagsZfilterL), ', ', num2str(lagsZfilterR));
    legendRefFilter = horzcat('B-FF-to-A-FF, max, min lag index: ',...
          num2str(lagsMaxRefFilter), ', ', num2str(lagsMinRefFilter),...
          ' 1st L, R 0-crossings: ',...
          num2str(lagsZrefFilterL), ', ', num2str(lagsZrefFilterR));


    legend(legendRef, legendFilter, legendRefFilter, 'Location', 'SouthEast') 
    %legend('Before-feedforward-to-injection', 'After-feedforward-to-injection', 'Before-feedforward-to-after', 'Location', 'South')
    print('-dpng', strcat(outputFileCrossCorr, '.png'))
    print('-dpdf', strcat(outputFileCrossCorr, '.pdf')) 
    disp(outputFileCrossCorr)
    close(2)
end

grapher(plotCompare(metadata), metadata);

end
