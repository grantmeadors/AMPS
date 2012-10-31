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
function eachWindowBin = windowWelch(GPSstart, duration)
    % Obtain first the raw S6 LDAS data, then the feedforward AMPS
    dataLDAS = framePull(GPSstart, 'cache/fileList-DARM-932683547-932692763.txt', 'H', duration, 'LDAS');
    Hoft.LDAS = dataLDAS.Hoft;
    clear dataLDAS
    dataAMPS = framePull(GPSstart, 'cache/fileList-AMPS-932683547-932692763.txt', 'H', duration, 'AMPS');
    Hoft.AMPS = dataAMPS.Hoft;
    clear dataAMPS
    % Then pwelch the data
    Fs = 16384;
    nfft = 16*Fs;
    size(Hoft.LDAS)
    size(Hoft.AMPS)
    [pLDAS, fx] = pwelch(Hoft.LDAS, hanning(nfft), nfft/2, nfft, Fs);
    [pAMPS, fx] = pwelch(Hoft.AMPS, hanning(nfft), nfft/2, nfft, Fs)
    aLDAS = sqrt(pLDAS);
    aAMPS = sqrt(pAMPS);
    eachWindowBin = [aLDAS(fx == 850), aAMPS(fx == 850)];
end
for ii = 0:((932692763-932683547-1024)/1024)
    eachWindowBin = windowWelch(932683547+ii, 1024);
    disp(eachWindowBin)
end

end
