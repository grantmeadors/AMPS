function result = pwelchPost()
% Grant David Meadors
% 02012-10-30 (JD 2456231)
% g m e a d o r s @ u m i c h . e d u
% pwelchPost
% 
% Calculates the pwelch of a stretch of data
% Before and after feedforward
%
% Example of a frame file name:
% H-H1_LDAS_C02_L2-931052672-128.gwf
% Example of input arguments:
% frame = 932683547
% cacheDARM = cache/fileList-DARM-932683547-932692763.txt
% And for pulling AMPS, try
% cacheAMPS = cache/fileList-AMPS-932683547-932692763.txt
% observatory = H
% duration = 9216

% First we retrieve the LDAS-STRAIN data from disk

function data = framePull(frame, cache, observatory, duration, ctype)
    cname =...
        {strcat(observatory, '1:', ctype, '-STRAIN')};
    function dataArray = readFramesVerily(cache, whichChannel, startTime, duration, samplingFrequency)
        numberOfTries = 100;
        for hh = 1:numberOfTries
            dataArray = readFrames(...
                cache, whichChannel, startTime, duration);
            if length(dataArray) == (samplingFrequency*duration)
                hh = numberOfTries + 1;
                break
            end
            if (hh > 1) & (hh < numberOfTries)
                disp('Failure to correctly retrieve data; pausing and will retry')
                pause(5);
            end
            if hh == numberOfTries
                disp(horzcat(...
                'Failed to correctly retrieve data after ',...
                num2str(numberOfTries), ' attempts.'))
            end
        end
    end
    Hoft.baseline  =...
        readFramesVerily(cache, cname{1}, frame, duration, 16384); 
    disp('Retrieved the following number of samples for Hoft')
    disp(length(Hoft.baseline))
    data.Hoft = Hoft;
end
% Build a function to retrieve data and pwelch it for each window, 1024 s long
function eachWindow = windowWelch(GPSstart, duration)
    % Obtain first the raw S6 LDAS data, then the feedforward AMPS
    dataLDAS = framePull(GPSstart, 'cache/fileList-DARM-932683547-932692763.txt', 'H', duration, 'LDAS');
    Hoft.LDAS = dataLDAS.Hoft.baseline;
    clear dataLDAS
    dataAMPS = framePull(GPSstart, 'cache/fileList-AMPS-932683547-932692763.txt', 'H', duration, 'AMPS');
    Hoft.AMPS = dataAMPS.Hoft.baseline;
    clear dataAMPS
    % Then pwelch the data
    Fs = 16384;
    nfft = 16*Fs;
    [pLDAS, fx] = pwelch(Hoft.LDAS, hanning(nfft), nfft/2, nfft, Fs);
    [pAMPS, fx] = pwelch(Hoft.AMPS, hanning(nfft), nfft/2, nfft, Fs);
    aLDAS = sqrt(pLDAS);
    aAMPS = sqrt(pAMPS);
    eachWindow.Bin = [aLDAS(fx == 850), aAMPS(fx == 850)];
    bin = find(fx == 850);
    % It would seem that my comb may be off center, as it calculates
    % 1/(binwidth) * frequency,
    % but Matlab's pwelch is indexed with 0 Hz at bin 1,
    % 1/(binwidth) at bin 2, et c.
    % So in my prior comb calculations, I had 
    % assumed 0 Hz at bin 0, et c. So to match that
    % earlier, wrong
    % model and see if I can replicate its results,
    % I need to shift all of my bins down by one.
    % Nota bene:
    % even if they are in the correct place, there is still
    % discrepancy with the harmonic average method
    eachWindow.Comb = [...
        (aLDAS(bin-3)+aLDAS(bin-2)+aLDAS(bin-1)+aLDAS(bin+0)+aLDAS(bin+1))/5 ...
        ,...
        (aAMPS(bin-3)+aAMPS(bin-2)+aAMPS(bin-1)+aAMPS(bin+0)+aAMPS(bin+1))/5 ...
        ];
end
numberOfWindows = ((932692763-932683547-1024)/512)+1;
windowBins = zeros(numberOfWindows, 2);
windowCombs = zeros(numberOfWindows,2);
for ii = 0:(numberOfWindows-1)
    eachWindow = windowWelch(932683547+ii, 1024);
    windowBins(ii+1, :) = eachWindow.Bin(:);
    windowCombs(ii+1, :) = eachWindow.Comb(:);
end
    disp('Raw values of before (left) and after (right) feedforward Hoft per window bin')
    disp(windowBins)
    disp('Arithmetic mean of window bins, 850 Hz only')
    disp('Before feedforward')
    disp(mean(windowBins(:, 1)))
    disp('After feedforward')
    disp(mean(windowBins(:, 2)))
    disp('Harmonic mean of window bins, 850 Hz only')
    disp('Before feedforward')
    disp(harmmean(windowBins(:, 1)))
    disp('After feedforward')
    disp(harmmean(windowBins(:, 2)))
    disp('Raw values of before (left) and after (right) feedforward Hoft per window bin')
    disp('Includes 5 bins, 2 to either side of 850 Hz, 1/16 Hz bin size')
    disp(windowCombs)
    disp('Arithmetic mean of window combs, 850 Hz')
    disp('Before feedforward')
    disp(mean(windowCombs(:, 1)))
    disp('After feedforward')
    disp(mean(windowCombs(:, 2)))
    disp('Harmonic mean of window combs, 850 Hz')
    disp('Before feedforward')
    disp(harmmean(windowCombs(:, 1)))
    disp('After feedforward')
    disp(harmmean(windowCombs(:, 2)))

end
