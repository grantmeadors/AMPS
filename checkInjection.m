function output = checkInjection(frame, varargin)

% Grant David Meadors
% 02012-04-24
% gmeadors@umich.edu

% Compares the frame file against a list of known
% successful hardware injections to see whether
% the feedforward algorithm alters them.
% This should also detect any spurious timing shifts.

% The varargin would be the frame data, if being so passed.
% The second varargin should be a string containing the location of a cache.


frameString = char(frame);
cache = varargin{2};

% Decide which site injection list to open based on the input frame
if strcmp(class(frame), 'char')
    disp('Checking injections in the following frame:')
    disp(frameString)
    site = frameString(1);
    siteFull = strcat('L', site, 'O');
    duration = 128;
else
    disp('Error: wrong input argument. Please specify a string frame name')
end

% This is the basic file that details whether injections were successful.
injectionFile = strcat(site, '1biinjlist.txt');
injectionFileID = fopen(injectionFile, 'r');
cellInjectionFile = textscan(injectionFileID, '%d %s %f %s %*[^\n]');
fclose(injectionFileID);

% This is the detailed file that lists parameters.
parameterFile = 'burst_hwinj_params.txt';
parameterFileID = fopen(parameterFile, 'r');
cellParameterFile = textscan(parameterFileID,...
     'filestart=%d burstgps=%f %s rmsSNR=%f %s %*[^\n]');
fclose(parameterFileID);

% Now we have read in the injection list. If an injection went through,
% then the fourth column will say 'Successful'
injectionList = zeros(size(cellInjectionFile{4}));

parfor ii=1:length(cellInjectionFile{4})
    checkSuccessful = strcmp(cellInjectionFile{4}(ii), 'Successful');
    % Verify that is burst injection; note the tilde for logical NOT
    checkType = ~isempty(strfind(cellInjectionFile{2}(ii), 'inj_')); 
    if (checkSuccessful & checkType)
        injectionList(ii) = cellInjectionFile{1}(ii);
    end
end
% Trim unsuccesful and non-burst injections
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

injectionInFrame = injectionList(gpsStartTime <= injectionList &...
    injectionList < gpsStartTime + 128);

if length(injectionInFrame) > 0
    % Determine type of injection
    frequencyList = zeros(size(cellParameterFile{5}));
    parfor ii=1:length(injectionList)
        checkSinegaussian = strcmp(cellParameterFile{3}(ii), 'typesinegaussian=1');
        checkTime = (injectionInFrame(1) == cellParameterFile{1}(ii));
        if (checkSinegaussian & checkTime)
            rawFreqColumn = cellParameterFile{5}(ii) 
            frequencyList(ii) = str2num(rawFreqColumn{1}(6:end)); 
        end
    end
    frequencyList(frequencyList == 0) = [];
    
    disp('Injection in frame: triggering search on this time --')
    disp(injectionInFrame)
else
    disp('No injection in frame')
    frequencyList = [];
end
if length(frequencyList) > 0
    [baseline, samplingFrequency] = framePull(site, gpsStartTime, duration, cache);
    frameSync(varargin{1}, baseline, samplingFrequency, injectionInFrame, frequencyList, gpsStartTime, site, frame)
end
cache.Hoft
cache.DARM

function [baseline, samplingFrequency] = framePull(site, gpsStartTime, duration, cache)
    % First pull DARM_ERR
    % Note duration is a variable.
    cname = strcat(site, '1:LSC-DARM_ERR');
    [rawBaseline,lastIndex,errCode,samplingFrequency,times] =...
         readFrames(cache.DARM,cname,gpsStartTime, 128);
    baseline.DARM = rawBaseline;
    clear rawBaseline
    % Then pull Hoft 
    % Duration is a variable based on the name of the filtered frame.
    cname = strcat(site, '1:LDAS-STRAIN');
    [rawBaseline,lastIndex,errCode,samplingFrequency,times] =...
         readFrames(cache.Hoft,cname,gpsStartTime,duration);
    baseline.Hoft = rawBaseline;
    clear rawBaseline
    testBit = 0;
    if testBit == 1
        % Can read subsequent frame Hoft  for a sanity check
        [baseline1, lastIndex1, errCode1, samplingFrequency1, times1] =...
             readFrames(cache, cname, gpsStartTime+128, duration);
        baseline = [baseline; baseline1];
    end
end

function frameSync(data, baseline, samplingFrequency, injectionInFrame, frequencyList, gpsStartTime, site, frame)
    % Create a time coordinate
    t = gpsStartTime + (0:(length(data)-1))/samplingFrequency;
    % Bandpass filter the data to the bucket
    [zb, pb, kb] = butter(16, 2*pi*[100 2000], 's');
    dataFilt = filterZPKs(zb, pb, kb, samplingFrequency, data);
    baselineFilt.DARM = filterZPKs(zb, pb, kb, samplingFrequency, baseline.DARM);
    baselineFilt.Hoft = filterZPKs(zb, pb, kb, samplingFrequency, baseline.Hoft);
    disp('Display statistics: max, mean, std (before), max, mean, std (after)')
    disp(max(abs(baselineFilt.Hoft)))
    disp(mean(baselineFilt.Hoft))
    disp(std(baselineFilt.Hoft))
    disp(max(abs(dataFilt)))
    disp(mean(dataFilt))
    disp(std(dataFilt))
    % Create the difference:
    difference = dataFilt - baselineFilt.Hoft;
    disp('Display statistics: max, mean, std (difference)')
    disp(max(abs(difference)))
    disp(mean(difference))
    disp(std(difference))

    % Determine whether the maximum difference is usually large
    if max(abs(difference)) > 1e-1*(std(baselineFilt.Hoft))
        disp('Maximum difference is larger than one tenth baseline standard deviation.')
        locationOfMaximum = find(abs(difference) == max(abs(difference)));
        disp('Maximum located at index')
        disp(locationOfMaximum)
        if locationOfMaximum < 16384
            disp('Maximum within 1st second')
        elseif locationOfMaximum < 2*16384
            disp('Maximum within 2nd second')
        end
    end

    % Ascertain whether anything unusual happens around the injection time
    % Note: we only look at the first injection, if there are multiple ones:
    if length(injectionInFrame) > 0
        injectionGPStime = injectionInFrame(1);
        injectionIndex = samplingFrequency*(injectionGPStime - gpsStartTime);
        if injectionIndex > 11
            subsetAround = difference((injectionIndex - 10):(injectionIndex + 1e5));
            disp('Ten samples before and ten thousand after injection start:')
        else
            % Possible that the injection could occur at the beginning of the frame
            subsetAround = difference(injectionIndex);
            disp('Injection at the very beginning of the frame:')
        end
        disp(subsetAround(1:22))
        disp('Normalized to baseline standard deviation:')
        disp(subsetAround(1:22)/std(baselineFilt.Hoft))
        if max(abs(subsetAround)) > 1e-1*(std(baselineFilt.Hoft))
            disp('Point around injection is larger than one tenth baseline standard deviation.')
            locationOfInjMax = find(abs(subsetAround) == max(abs(subsetAround)));
            disp('Index in subset of samples around injection:')
            disp(locationOfInjMax)
        end
        disp('Ratio of injection subset standard deviation to rest of difference')
        disp(std(subsetAround)/std(difference))

        % Check the cross-correlation
        if length(frequencyList) > 0
            disp('Checking injection cross-correlation')
            correlateInjection(frame, baseline, data, injectionGPStime, frequencyList);
        end
    end
    


    % Graph the difference
    figure(1) 
    
    outputFileHead = strcat('/home/gmeadors/public_html/feedforward/programs/syncInjections/',...
        'L', site, 'O', '/',  num2str(floor(gpsStartTime/1e5)), '/');
    system(horzcat('mkdir -p ', outputFileHead))
    outputFile = strcat(outputFileHead, 'differenceGraph-', num2str(gpsStartTime));
    if max(abs(difference)) > 0
        subplot 211
        plot(t, abs(difference)) 
        xlim([t(1) t(end)])
        xlabel('GPS time (s)')
        ylabel('abs(difference): after-before filtering (strain)')
        grid on
        legend('abs(Difference)')
        subplot 212
        semilogy(t, abs(difference))
        xlim([t(1) t(end)])
        xlabel('GPS time (s)')
        ylabel('abs(difference): after-before filtering (strain)')
        grid on
        legend('abs(Difference)')
    else
        plot(t, abs(difference))
        xlabel('GPS time (s)')
        ylabel('abs(difference): after-before filtering (strain)')
        grid on
        legend('abs(Difference)')
    end
    titleString = horzcat('Difference vs time, starting GPS time ', num2str(gpsStartTime))
    title(titleString)
    disp(outputFile)
    print('-dpng', strcat(outputFile, '.png'))
    close(1)

end


clear baseline
output = 0;

end
