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
cache = char(varargin{2});

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

injectionInFrame = injectionList(gpsStartTime <= injectionList &...
    injectionList < gpsStartTime + 128);

if length(injectionInFrame) > 0
    disp('Injection in frame: triggering search on this time --')
    disp(injectionInFrame)
else
    disp('No injection in frame')
end
[baseline, samplingFrequency] = framePull(site, gpsStartTime, duration, cache);
frameSync(varargin{1}, baseline, samplingFrequency, injectionInFrame, gpsStartTime, site)

function [baseline, samplingFrequency] = framePull(site, gpsStartTime, duration, cache)
    %systemCommand = horzcat('ligo_data_find --observatory=', site,...
    %     ' --type=H1_LDAS_C02_L2 --gps-start-time=', num2str(gpsStartTime),...
    %     ' --gps-end-time=', num2str(gpsStartTime+128),...
    %     ' --url-type=file --lal-cache');
    %[status, result] = system(systemCommand);
    %frameLocation = result(48:end);
    cname = strcat(site, '1:LDAS-STRAIN');
    %[baseline, tsamp, fsamp, gps0] = frgetvect(frameLocation, cname, gpsStartTime, duration);
    %samplingFrequency = 2*(fsamp(end)+1/128);
    [baseline,lastIndex,errCode,samplingFrequency,times] =...
         readFrames(cache,cname,gpsStartTime,duration);
end

function frameSync(data, baseline, samplingFrequency, injectionInFrame, gpsStartTime, site)
    % Create a time coordinate
    t = gpsStartTime + (0:(length(data)-1))/samplingFrequency;
    % Bandpass filter the data to the bucket
    [zb, pb, kb] = butter(16, 2*pi*[100 2000], 's');
    dataFilt = filterZPKs(zb, pb, kb, samplingFrequency, data);
    baselineFilt = filterZPKs(zb, pb, kb, samplingFrequency, baseline);
    disp('Display statistics: max, mean, std (before), max, mean, std (after)')
    disp(max(abs(baselineFilt)))
    disp(mean(baselineFilt))
    disp(std(baselineFilt))
    disp(max(abs(dataFilt)))
    disp(mean(dataFilt))
    disp(std(dataFilt))
    % Create the difference:
    difference = dataFilt - baselineFilt;
    disp('Display statistics: max, mean, std (difference)')
    disp(max(abs(difference)))
    disp(mean(difference))
    disp(std(difference))

    % Determine whether the maximum difference is usually large
    if max(abs(difference)) > 1e-1*(std(baselineFilt))
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
        disp(subsetAround(1:22)/std(baselineFilt))
        if max(abs(subsetAround)) > 1e-1*(std(baselineFilt))
            disp('Point around injection is larger than one tenth baseline standard deviation.')
            locationOfInjMax = find(abs(subsetAround) == max(abs(subsetAround)));
            disp('Index in subset of samples around injection:')
            disp(locationOfInjMax)
        end
        disp('Ratio of injection subset standard deviation to rest of difference')
        disp(std(subsetAround)/std(difference))
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
        xlabel('GPS time (s)')
        ylabel('abs(difference): after-before filtering (strain)')
        grid on
        legend('abs(Difference)')
        subplot 212
        semilogy(t, abs(difference))
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
    title('Plot of difference over time')
    disp(outputFile)
    print('-dpng', strcat(outputFile, '.png'))
    close(1)

end


clear baseline
output = 0;

end
