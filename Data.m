classdef Data < handle
    % Retrieve data from LIGO servers
    % Grant David Meadors
    % 02012-02-28
    
    properties (SetAccess = private)
        t0
        t1
        tau1
        tau2
        s
        pipe
        durationHead
        durationTail
        duration
        durationPlus
        darm
        noise
        tailStartIndex
        frameHead
        frameTail
        stateVector
        dqFlag
        Fs
        t
        mich
        prc
        PRCfilter
    end
    
    methods
        function channels = Data(t0, t1, addenda)
            % Extract beginning and end times
            channels.t(1) = t0;
            channels.t(2) = t1;
            
            % Assign information to our data object about these times and the frame length
            channels.t0 = t0;
            channels.t1 = t1;
            channels.s = addenda.s;
            channels.pipe = addenda.pipe;
            
            % Find the start of the first frame and end of the last
            if addenda.frameHeadFlag == 1
                channels.tau1 = floor(channels.t(1)/addenda.s) * addenda.s;
            else
                channels.tau1 = channels.t(1);
            end
            if addenda.frameTailFlag == 1
                channels.tau2 = ceil(channels.t(2)/addenda.s) * addenda.s;
            else
                channels.tau2 = channels.t(2);
            end
            
            % Find how far shifted the signal is into the science segment
            channels.durationHead = channels.t(1) - floor(channels.t(1)/addenda.s) * addenda.s;
            channels.durationTail = ceil(channels.t(2)/addenda.s) * addenda.s - channels.t(2);
            
            % Sampling frequency of MICH and DARM
            channels.Fs = 16384;
            % Duration over which to generate the feedforward filter
            channels.duration = channels.t(2) - channels.t(1);
            % Duration including unused frame portions
            channels.durationPlus = channels.tau2 - channels.tau1;
            % LDAS-STRAIN (DARM, or Hoft) and MICH/PRC channel names
            if addenda.pipe == 1
                channelname =...
                    {'H1:LDAS-STRAIN' 'H1:LSC-MICH_CTRL' 'H1:LSC-PRC_CTRL' 'H1:IFO-SV_STATE_VECTOR' 'H1:LSC-DATA_QUALITY_VECTOR'};
            elseif addenda.pipe == 2
                channelname = ...
                    {'H1:LSC-DARM_ERR' 'H1:LSC-MICH_CTRL' 'H1:LSC-PRC_CTRL' 'H1:IFO-SV_STATE_VECTOR' 'H1:LSC-DATA_QUALITY_VECTOR'};
            end
            
            % Generate a list of frame files between t0 and t1 using ligo_data_find
            % Keeping variable internal to Matlab
            %[status.darm, result.darm] = system(...
            %    'ligo_data_find --observatory=H --type=H1_LDAS_C02_L2 --gps-start-time=$STARTTIME --gps-end-time=$ENDTIME --url-type=file --lal-cache');
            %[status.noise, result.noise] = system(...
            %    'ligo_data_find --observatory=H --type=R --gps-start-time=$STARTTIME --gps-end-time=$ENDTIME --url-type=file --lal-cache');
            
            
            disp('A list of relevant variables: t1, tau1, t2, tau2, duration, durationPlus, t1+512, tau1+512, duration-512, durationPlus-512')
            disp(channels.t(1))
            disp(channels.tau1)
            disp(channels.t(2))
            disp(channels.tau2)
            disp(channels.duration)
            disp(channels.durationPlus)
            disp(channels.t(1)+512)
            disp(channels.tau1+512)
            disp(channels.duration-512)
            disp(channels.durationPlus-512)

            % insert a catch function to ensure that the correct amount of data is retrieved from servers
            function dataArray = readFramesVerily(cache, whichChannel, startTime, duration, samplingFrequency)
                numberOfTries = 10;
                for hh = 1:numberOfTries
                    dataArray = readFrames(cache, whichChannel, startTime, duration);
                    if length(dataArray) == (samplingFrequency*duration)
                        hh = numberOfTries + 1;
                    end    
                    if (hh > 1) & (hh < numberOfTries)
                        disp('Failure to correctly retrieve data; pausing and will retry')
                        pause(5);
                    end
                    if hh == numberOfTries
                        disp(horzcat('Failed to correctly retrieve data after ', num2str(numberOfTries), ' attempts.'))
                    end
                end 
            end            

            if addenda.PRCfilter == 1
                % DARM supplied from input arguments
                channels.darm = addenda.darm;
                addenda.destroyer('darm');
                % PRC filtering
                if addenda.passFirstFlag == 1
                    if channels.duration > 512
                        disp('This message will display if the second subsection is doing the correct thing for PRC')
                        channels.noise = [addenda.passPRC;...
                            readFramesVerily(addenda.inputFileNOISE, channelname{3},channels.t(1)+512,channels.duration-512, 16384)];
                        disp('Check on PRC')
                        lengthPRC = length(addenda.passPRC);
                        addenda.passPRC((end-10):end)
                        disp('Check on new: first three samples should be same as last above')
                        channels.noise((lengthPRC-2):(lengthPRC+10))
                        addenda.destroyer('passPRC');
                    else
                        channels.noise = addenda.passPRC;
                        addenda.destroyer('passPRC');
                    end
                else
                    channels.noise =...
                        readFramesVerily(addenda.inputFileNOISE, channelname{3},channels.t(1),channels.duration, 16384);
                end
            else
                
                % DARM supplied by frames; grab before and after times too
                if addenda.passFirstFlag == 1
                    if channels.durationPlus > 512
                        if addenda.frameTailFlag == 0
                            disp('This message will display if the second subsection is doing the correct thing for DARM')
                            channels.darm = [addenda.passDARM;...
                                readFramesVerily(addenda.inputFileDARM, channelname{1},channels.t(1)+512,channels.duration-512, 16384)];
                            disp('Check on DARM')
                            lengthDARM = length(addenda.passDARM);
                            addenda.passDARM((end-10):end)
                            disp('Check on new: first three samples should be same as last above')
                            channels.darm((lengthDARM-2):(lengthDARM+10))
                            addenda.destroyer('passDARM');
                        elseif addenda.frameTailFlag == 1
                            channels.darm = [addenda.passDARM;...
                                readFramesVerily(addenda.inputFileDARM, channelname{1},channels.t(1)+512,(channels.tau2-channels.t(1)-512), 16384)];
                            addenda.destroyer('passDARM');
                        end
                    else
                        channels.darm = [addenda.passDARM;...
                            readFramesVerily(addenda.inputFileDARM, channelname{1},channels.t(2),(channels.tau2-channels.t(2)), 16384)];
                        addenda.destroyer('passDARM');
                    end
                else
                    channels.darm =...
                        readFramesVerily(addenda.inputFileDARM, channelname{1},channels.tau1,channels.durationPlus, 16384);
                end
                % Break the head of the frame the segment off for later use,
                if addenda.frameHeadFlag == 1
                    channels.frameHead = channels.darm(1:(channels.Fs*( channels.t(1)-channels.tau1 )));
                end
                % Do the same with the tail
                channels.tailStartIndex = length(channels.darm) - channels.Fs*(channels.tau2 - channels.t(2)) + 1;
                if addenda.frameTailFlag == 1
                    channels.frameTail = channels.darm(channels.tailStartIndex:end);
                end
                
                % Reduce to only the science segment data
                if addenda.frameTailFlag == 1
                    channels.darm(channels.tailStartIndex:end) = [];
                end
                if addenda.frameHeadFlag == 1
                    channels.darm(1:(channels.Fs*( channels.t(1)-channels.tau1 ))) = [];
                end
                
                % MICH filtering
                if addenda.passFirstFlag == 1
                    if channels.duration > 512
                        disp('This message will display if the second subsection is doing the correct thing for MICH')
                        channels.noise = [addenda.passMICH;...
                            readFramesVerily(addenda.inputFileNOISE, channelname{2},channels.t(1)+512,channels.duration-512, 16384)];
                        disp('Check on MICH')
                        lengthMICH = length(addenda.passMICH);
                        addenda.passMICH((end-10):end)
                        disp('Check on new: first three samples should be same as last above')
                        channels.noise((lengthMICH-2):(lengthMICH+10))
                        addenda.destroyer('passMICH');
                    else
                        channels.noise = addenda.passMICH;
                        addenda.destroyer('passMICH');
                    end
                else
                    channels.noise =...
                        readFramesVerily(addenda.inputFileNOISE, channelname{2},channels.t(1),channels.duration, 16384);
                end
                
                if addenda.pipe == 1
                    % Retrieve state vector and data quality flags
                    channels.stateVector =...
                        readFramesVerily(addenda.inputFileDARM, channelname{4},channels.tau1,channels.durationPlus, 16);
                    channels.dqFlag =...
                        readFramesVerily(addenda.inputFileDARM, channelname{5},channels.tau1,channels.durationPlus, 1);
                end
            end
            
            disp('darm is this long')
            length(channels.darm)
            disp('vnoise is this long')
            length(channels.noise)
            
            % Detrend DARM and NOISE in parallel
            %darmNoise = detrend([vector.darm vector.noise]);
            
            % Assign DARM and MICH to output
            
            
            if length(channels.darm) > 512*16384
                if addenda.PRCfilter == 0
                    channels.mich = channels.noise((512*16384+1):end);
                elseif addenda.PRCfilter == 1
                    channels.prc = channels.noise((512*16384+1):end);
                end
            end
            channels.PRCfilter = addenda.PRCfilter;
            
           
        end
        function wienerFilter(channels)
            % weight DARM and emphasize the bucket
            zs = [];
            ps = [];
            zweight = -2*pi*[0 0 0];
            pweight = -2*pi*[70 70 70 300 300 300];
            zs = [zs; zweight];
            ps = [ps; pweight];
            
            resamplingFactor = 16;

            [m, p] = bode(zpk(zs, ps, 1), 2*pi*150);
            [zd, pd, kd] = bilinear(zs', ps', 1/m, channels.Fs/resamplingFactor);
            [sos1, g1] = zp2sos(zd, pd, kd);
            g1 = real(g1);
            
            %darm1 = g1 * sosfilt(sos1, channels.darm);
            %noise1 = g1 * sosfilt(sos1, channels.noise);
            
            % Downsample to 1024 Hz
            disp('Original noise size')
            disp(size(channels.noise))
            bandEmphasize = @(inputG, inputSOS, inputVector, inputResamplingFactor)...
                inputG * sosfilt(inputSOS, detrend(decimate(inputVector,...
                inputResamplingFactor, 'fir')));
            %darm1 = detrend(decimate(darm1, resamplingFactor, 'fir'));
            %noise1 = detrend(decimate(noise1, resamplingFactor, 'fir'));

            % Filter per the above weighting
            darm1 = bandEmphasize(g1, sos1, channels.darm, resamplingFactor);
            noise1 = bandEmphasize(g1, sos1, channels.noise, resamplingFactor);

            % Apply a strong low-pass
            [zh, ph, kh] = butter(10, 70/(channels.Fs/(2*resamplingFactor)), 'high');
            [mj, p] = bode(zpk(zh, ph, kh), 2*pi*150);
            [zj, pj, kj] = bilinear(zh, ph, kh, 1/mj, channels.Fs);
            [sos2, g2] = zp2sos(zh, ph, kh);
            g2 = real(g2);
            darm1 = g2 * sosfilt(sos2, darm1);
            noise1 = g2 * sosfilt(sos2, noise1);

            notchSpots = [60 120 180 240 300 360 46.7 391.3 346 400.2]; %1144.3 is out of band
            
            % Generate IIR notches
            function [output1, output2] = notcher(input1, input2, a, b)
                [z, p, k] = butter(10, [a b]./(channels.Fs/(2*resamplingFactor)), 'stop');
                [sos, g] = zp2sos(z, p, k);
                g = real(g);
                output1 = g * sosfilt(sos, input1);
                output2 = g * sosfilt(sos, input2);
                %[b, a] = butter(2, [a b]./(channels.Fs/(2*resamplingFactor)), 'stop');
                %output1 = filter(b, a, input1);
                %output2 = filter(b, a, input2);
            end
            
            % Apply the notches
            for ii = 1:length(notchSpots)
                [darm1, noise1] = notcher(darm1, noise1, notchSpots(ii) - 3, notchSpots(ii) + 3);
            end
            
            % Prepare the Wiener filter
            
            % Number of taps
            N = 2048;
            
            
            % Concatenate the input data columns into a matrix
            wiener_input_data = [darm1(:) noise1(:)];
            
            
            disp('Calculating Wiener filter')
            [h, R, P] = misofw(N-1, wiener_input_data, darm1);
           
            disp('Applying Wiener filter') 
            noise1 = filter(h, 1, noise1);
 
            % Upsample
            channels.noise =  interp(noise1, resamplingFactor);
            disp('Post-wiener noise size')
            disp(size(channels.noise))
        end
        function preFilter(channels)
            % pre-filter the noise by low-passing it
            [zpre, ppre, kpre] = butter(2, 2*pi*700, 's');
            channels.noise = filterZPKs(zpre, ppre, kpre, channels.Fs, channels.noise);
        end
        function feedforwardFilter(channels, za, pa, ka)
            % now apply the TF-fit feedforward filter to the noise
            channels.noise = filterZPKs(za, pa, ka, channels.Fs, channels.noise);
        end
        function destroyer(channels, fieldName)
            if strcmp(fieldName, 'darm')
                channels.darm = [];
            elseif strcmp(fieldName, 'frameHead')
                channels.frameHead = [];
            elseif strcmp(fieldName, 'frameTail')
                channels.frameTail = [];
            elseif strcmp(fieldName, 'mich')
                channels.mich = [];
            elseif strcmp(fieldName, 'prc')
                channels.prc = [];
            end
        end
    end
   
    
end

