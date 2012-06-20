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
    cname =...
        {strcat(observatory, '1:LDAS-STRAIN')...
         strcat(observatory, '1:IFO-SV_STATE_VECTOR')...
         strcat(observatory, '1:LSC-DATA_QUALITY_VECTOR')};
    [Hoft.baseline,lastIndex,errCode,samplingFrequency.baseline,times] =...
        readFrames(cache, cname{1}, frame, duration); 
    [Hoft.stateVector ,lastIndex,errCode,samplingFrequency.stateVector,times] =...
        readFrames(cache, cname{2}, frame, duration);
    [Hoft.dqFlag, lastIndex,errCode,samplingFrequency.dqFlag,times] =...
        readFrames(cache, cname{3}, frame, duration);
    disp('Retrieved the following number of samples for Hoft, state vector and DQ flag')
    disp(length(Hoft.baseline))
    disp(length(Hoft.stateVector))
    disp(length(Hoft.dqFlag))
    data.Hoft = Hoft;
    data.samplingFrequency = samplingFrequency;
end
function finale = framePush(frame, cache, observatory, duration)
    if ~isnumeric(frame)
        frame = str2double(frame);
    end
    size(frame)
    frame
    if ~isnumeric(duration)
        duration = str2double(duration);
    end
    size(duration)
    duration
    data = framePull(frame, cache, observatory, duration);
    startName = strcat('-', num2str(frame));
    site = observatory;
    siteFull = strcat('L', observatory, 'O');
    individualFrameName = strcat(site, '-',...
        site, '1_AMPS_C02_L2',...
        startName, '-', num2str(duration), '.gwf');
    directoryDataFrameName = strcat('/archive/frames/S6/pulsar/feedforward/', siteFull, '/', individualFrameName(1:21));
    frameName = strcat(directoryDataFrameName, '/', individualFrameName);
    % We can absolutely sure that we are not over-writing a file:
    [status, result] = system(horzcat('ls ', frameName));
    if length(strfind(result, 'No such file or directory'))
        disp('Frame file does not yet exist')
        safeGuardBit = 0;
    else 
        disp('Frame file already exists')
        safeGuardBit = 1;
    end
    % However, for testing purposes we may overwrite frequencly, so
    safeGuardBit = 0;

    if safeGuardBit == 0
        disp('Writing this frame:')
        disp(frameName)
        % Start a new frame and write Hoft into it.
        HoftSub.data = double(data.Hoft.baseline);
        HoftSub.channel = strcat(site, '1:AMPS-STRAIN');
        HoftSub.type = 'd';
        HoftSub.mode = 'a';
        mkframe(frameName, HoftSub, 'n', duration, frame);
        % Append the frame with state vector information.
        stateVectorSub.data = double(data.Hoft.stateVector);
        stateVectorSub.channel = strcat(site, '1:AMPS-SV_STATE_VECTOR');
        stateVectorSub.type = 'd';
        stateVectorSub.mode = 'a';
        mkframe(frameName, stateVectorSub, 'a', duration, frame);
        % Append the frame with DQ flag information
        dqFlagSub.data = double(data.Hoft.dqFlag);
        dqFlagSub.channel = strcat(site, '1:AMPS-DATA_QUALITY_FLAG');
        dqFlagSub.type = 'd';
        dqFlagSub.mode = 'a';
        mkframe(frameName, dqFlagSub, 'a', duration, frame);
    end
    % We are done.
    finale = 'Interstitial frame appears successfully written.';
end

output = framePush(frame, cache, observatory, duration);

  
end

