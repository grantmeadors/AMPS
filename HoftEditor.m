classdef HoftEditor < handle
    % Edit and manages the Hoft object for feedforward
    % Grant David Meadors
    % 02012-02-29
    
    properties (SetAccess = private)
        tSub
        tScienceStart
        tScienceEnd
        offlineZPK
        rmserr
        frameHead
        frameTail
        dqFlagLast
        stateVectorLast
        dqFlagRate
        stateVectorRate
        passDARM
        passMICH
        passPRC
        mich
        prc
        gpsStart
        tStart
        tEnd
        nA
        nB
        qWindow
        p
        r
        s
        T
        data
        baseline
        frameHeadFlag
        frameTailFlag
        startOffset
        startOffsetDQ
        startOffsetSV
        vetoAlarm
        anticipateFlag
        isFirstSubFlag
        stateVector
        dqFlag
        successVector
    end
    
    methods
        function Hoft = HoftEditor(T, tSub, inputFileDARM)
            Hoft.tSub = tSub;
            Hoft.tScienceStart = tSub.tStart(1);
            Hoft.tScienceEnd = tSub.tEnd(end);
            Hoft.offlineZPK = [];
            Hoft.rmserr = [];
            Hoft.frameHead = [];
            Hoft.frameTail = [];
            Hoft.dqFlagLast = [];
            Hoft.stateVectorLast = [];
            if T.pipe == 1
                Hoft.dqFlagRate = 1; %2^nextpow2(Hoft.dqFlagRate);
                Hoft.stateVectorRate = 16; %2^nextpow2(Hoft.stateVectorRate);
            end
            Hoft.passDARM = [];
            Hoft.passMICH = [];
            Hoft.passPRC = [];
            Hoft.mich = [];
            Hoft.prc = [];
            % Now we need to initialize an array for the data
            % Extract the GPS start time of the first frame from
            % its file name
            fid = fopen(inputFileDARM);
            listContents = fscanf(fid, '%c');
            fclose(fid);
            if T.pipe == 1
                Hoft.gpsStart = sscanf(listContents(18:26),'%d');
            elseif T.pipe == 2
                Hoft.gpsStart = sscanf(listContents(5:15),'%d');
            end
            Hoft.T = T;
            Hoft.tStart = tSub.tStart(1);
            Hoft.tEnd = tSub.tEnd(1);
            Hoft.nA = [];
            Hoft.nB =[];
            Hoft.p = [];
            Hoft.r = [];
            Hoft.data = [];
            Hoft.baseline = [];
            Hoft.frameHeadFlag = [];
            Hoft.frameTailFlag = [];
            Hoft.startOffset = [];
            Hoft.startOffsetDQ = [];
            Hoft.startOffsetSV = [];
            Hoft.vetoAlarm = 0;
            Hoft.isFirstSubFlag = 1;
            Hoft.successVector = [];
        end
        function constructVector(Hoft, totalFrameDuration)
            Hoft.data = ones(16384*totalFrameDuration, 1);
            Hoft.baseline = ones(16384*totalFrameDuration, 1);
        end
        function initialMICH(Hoft, T, tSub, addenda)
            
            addenda.initialFixer(tSub, T);

            % Call the filter function itself
            aFirstHoft = aletheia(tSub.tStart(1), tSub.tEnd(1), addenda);
            
            % Extract related data
            Hoft.offlineZPK.MICH(1) = aFirstHoft.offlineZPK.MICH;
            Hoft.rmserr.MICH(1) = aFirstHoft.rmserr.MICH;
            if addenda.frameHeadFlag == 1;
                disp('Sizes of frame heads being written')
                disp(size(aFirstHoft.frameHead))
                Hoft.frameHead = aFirstHoft.frameHead(:);
                disp(size(Hoft.frameHead))
                clear aFirstHoft.frameHead
            end
            if T.pipe == 1
                Hoft.dqFlagLast = aFirstHoft.dqFlag;
                clear aFirstHoft.dqFlag
                Hoft.stateVectorLast = aFirstHoft.stateVector;
                clear aFirstHoft.stateVector
            end
            
            
            
            
            
            
            
            % Save these values, because we dispose of addenda later
            Hoft.frameHeadFlag = addenda.frameHeadFlag;
            Hoft.frameTailFlag = addenda.frameTailFlag;
            
            
            
            if addenda.frameTailFlag == 1
                disp('Here the frame tail is supposed to be set')
                disp(size(aFirstHoft.frameTail))
                Hoft.frameTail = aFirstHoft.frameTail(:);
            end
            if length(tSub.tStart) > 1
                Hoft.passMICH = aFirstHoft.mich;
                clear aFirstHoft.mich
            end

            addenda.initialPRC(aFirstHoft);

            clear aFirstHoft
        end
        function initialPRC(Hoft, T, tSegment, tSub, addenda)
            % Actually filter for PRC
            firstHoft = aletheia(tSub.tStart(1), tSub.tEnd(1), addenda);
            
            Hoft.offlineZPK.PRC(1) = firstHoft.offlineZPK.PRC;
            Hoft.rmserr.PRC(1) = firstHoft.rmserr.PRC;
            % Cleanup
            clear addenda
            if length(tSub.tStart) > 1
                Hoft.passPRC = firstHoft.prc;
                clear firstHoft.prc
            end
            
            
            
            
            % Frames are 128 seconds long, so round up the science
            % segment length to the nearest multiple of 128 seconds,
            totalFrameDuration = T.s*ceil((tSub.tEnd(1) - Hoft.gpsStart)/T.s);
            % If the GPS start time coincides with a frame boundary
            % (i.e. is divisible by 128), then add 128 s more.            
            if Hoft.gpsStart == Hoft.gpsStart - mod(Hoft.gpsStart, 128)
                totalFrameDuration = totalFrameDuration + 128;
            end

            % Find the different between the start of the science segment
            % and the start of the first frame, in number of samples
            Hoft.startOffset = 16384*(tSegment.tA - Hoft.gpsStart);
            if T.pipe == 1
                Hoft.startOffsetDQ = Hoft.dqFlagRate*(tSegment.tA - Hoft.gpsStart);
                Hoft.startOffsetSV = Hoft.stateVectorRate*(tSegment.tA - Hoft.gpsStart);
            end
            % We write the science segment starting one sample later, at nA
            Hoft.nA = Hoft.startOffset + 1;
            
            % The very last science segment sample we write will be nB
            Hoft.nB = 16384*(tSegment.tB - Hoft.gpsStart);
            
            % The length of our first subsection is r, which may be up to
            % 16384*1024
            Hoft.r = length(firstHoft.data);
            
            % We want to build triangular ramps,
            % up and down each being 16384*512 samples long
            Hoft.p = 16384*512;
            % Build a triangular window in that shape:
            Hoft.qWindow = triang(2*Hoft.p);
            
            % Construct the vectors where our data will be placed:
            Hoft.constructVector(totalFrameDuration);
            disp('Length of Hoft data vector')
            disp(length(Hoft.data))
            %Hoft.data = ones(16384*totalFrameDuration, 1);
            
            if T.pipe == 1
                Hoft.dqFlag = ones(Hoft.dqFlagRate*totalFrameDuration, 1);
                Hoft.stateVector = ones(Hoft.stateVectorRate*totalFrameDuration, 1);
            end
            
            % Introduce the old, out-of-science data:
            if Hoft.frameHeadFlag == 1
                Hoft.data(1:Hoft.startOffset) = Hoft.frameHead(:);
                clear Hoft.frameHead;
            end
            if Hoft.frameTailFlag == 1
                disp('Sizes of frame tail being written into data')
                disp(size(Hoft.data((Hoft.startOffset+Hoft.r+1):end)))
                disp(size(Hoft.frameTail(:)))
                  
                Hoft.data((Hoft.startOffset+Hoft.r+1):end) = Hoft.frameTail(:);
                clear Hoft.frameTail
            end
            % Introduce the first filtered data;
            Hoft.data(Hoft.nA:(Hoft.startOffset+Hoft.r)) = firstHoft.data(:);
            clear firstHoft.data
            if T.pipe ==1
                Hoft.dqFlag(1:length(Hoft.dqFlagLast)) = Hoft.dqFlagLast(:);
                clear Hoft.dqFlagLast
                Hoft.stateVector(1:length(Hoft.stateVectorLast)) = Hoft.stateVectorLast(:);
                clear Hoft.stateVectorLast
            end
            
            
            
            Hoft.baseline(Hoft.nA:(Hoft.startOffset+Hoft.r)) =  firstHoft.baseline(:);
            
            
            clear firstHoft
        end
        function initialFrameWriter(Hoft, T, tSegment, tSub)
            if length(tSub.tStart) == 1
                Hoft.anticipateFlag = 0;
            else
                Hoft.anticipateFlag = 1;
            end
            
            
            
            % Write this subsection, but only if this "science segment"
            % is not preceeded by another
            if tSegment.tIsPreceded == 0
                % Also, initialize then clear the as-yet-unused newHoft variable
                newHoft = 1;
                jj = 1;
                jjStart = 1;
                dataReviewer(Hoft, newHoft, jj, jjStart);
                clear newHoft jj jjStart
            end
            
            % If we will continue, clear the first 512 seconds of frames
            % and add whitespace to their ends if necessary
            if length(tSub.tStart) > 1
                Hoft.isFirstSubFlag = 0;
                Hoft.data(1:(16384*512)) = [];
                Hoft.baseline(1:(16384*512)) = [];
                if T.pipe == 1
                    Hoft.dqFlag(1:(1*512)) = [];
                    Hoft.stateVector(1:(16*512)) = [];
                end
                Hoft.gpsStart = Hoft.gpsStart + 512;
                if length(tSub.tStart) > 2
                    nextSubWhitespace = T.s*floor(min([512, (tSub.tEnd(2)-T.s*floor(tSub.tStart(2)/T.s)-512)])/T.s);
                    Hoft.data = [Hoft.data; ones(16384*nextSubWhitespace, 1)];
                    Hoft.baseline = [Hoft.baseline; ones(16384*nextSubWhitespace, 1)];
                    if T.pipe == 1
                        Hoft.dqFlag = [Hoft.dqFlag; ones(1*nextSubWhitespace, 1)];
                        Hoft.stateVector = [Hoft.stateVector; ones(16*nextSubWhitespace, 1)];
                    end
                end
            end
            
            disp('Offline ZPKs displayed below')
            Hoft.offlineZPK.MICH(1)
            Hoft.offlineZPK.PRC(1)
            disp('RMS errors displayered below')
            Hoft.rmserr.MICH(1)
            Hoft.rmserr.PRC(1)
        end
        function loopMICH(Hoft, T, tSub, addenda, jj)
            disp('Lengths of passed DARM, MICH and PRC vrctors:')
            disp(length(addenda.passDARM))
            disp(length(addenda.passMICH))
            disp(length(addenda.passPRC))
            
            Hoft.tStart = tSub.tStart(jj);
            Hoft.tEnd = tSub.tEnd(jj);
            Hoft.vetoAlarm = 0;
            
            % Set addenda to appropriate values for the given loop
            addenda.loopFixer(Hoft, jj, tSub);
            
            % Actual MICH filtering
            aNewHoft = aletheia(tSub.tStart(jj), tSub.tEnd(jj), addenda);
            
            Hoft.offlineZPK.MICH(jj) = aNewHoft.offlineZPK.MICH;
            Hoft.rmserr.MICH(jj) = aNewHoft.rmserr.MICH;
            addenda.destroyer('passMICH');
            addenda.destroyer('passDARM');
            if jj ~= length(tSub.tStart)
                Hoft.passMICH = aNewHoft.mich;
            end
            clear aNewHoft.mich
            if addenda.frameTailFlag == 1
                Hoft.frameTail = aNewHoft.frameTail;
                disp('Preparing to attach dangling frame after segment')
            end
            if T.pipe == 1
                Hoft.dqFlagLast = aNewHoft.dqFlag;
                Hoft.stateVectorLast = aNewHoft.stateVector;
            end
            
            % Then filter for PRC
            addenda.loopPRC(aNewHoft);
            clear aNewHoft
        end
        function loopPRC(Hoft, T, tSegment, tSub, addenda, jj)
            % Actual PRC filtering
            newHoft = aletheia(tSub.tStart(jj), tSub.tEnd(jj), addenda);
            
            clear addenda
            if jj ~= length(tSub.tStart)
                Hoft.passDARM = newHoft.baseline((Hoft.p+1):end);
                Hoft.passPRC = newHoft.prc;
            end
            Hoft.offlineZPK.PRC(jj) = newHoft.offlineZPK.PRC;
            Hoft.rmserr.PRC(jj) = newHoft.rmserr.PRC;
            clear newHoft.prc
            
            disp('Offline ZPKs displayed below')
            Hoft.offlineZPK.MICH(jj)
            Hoft.offlineZPK.PRC(jj)
            disp('RMS errors are displayed below')
            Hoft.rmserr.MICH(jj)
            Hoft.rmserr.PRC(jj)
            
            % Check how long the segment is, which will be very
            % important for the last subsection --
            % it will probably not be 1024 seconds long!
            Hoft.s = length(newHoft.data);
            
            % Define the end of the section of data partly filtered so far
            %jjEnd = startOffset + jj*(16384*1024);
            % Define the start of the section we are going to window
            jjStart = Hoft.startOffset ;%+ (jj-1)*16384*512;
            % There is no windowing of DQ or SV, so use jj not jj-1
            % Because we will just append
            if T.pipe == 1
                jjStartDQ = Hoft.startOffsetDQ ;%+ (jj)*Hoft.dqFlagRate*512;
                jjStartSV = Hoft.startOffsetSV ;%+ (jj)*Hoft.stateVectorRate*512;
                % Append the data quality and state vector data to their arrays
                Hoft.dqFlag((jjStartDQ+1):(jjStartDQ+length(Hoft.dqFlagLast))) =...
                    Hoft.dqFlagLast(:);
                Hoft.stateVector((jjStartSV+1):(jjStartSV+length(Hoft.stateVectorLast)))=...
                    Hoft.stateVectorLast(:);
            end
            
            
            
            
            windowFramer(Hoft, tSub, Hoft.p, Hoft.s, newHoft, jj, jjStart);
            
            
            % Will we expect more data?
            if jj == (length(tSub.tStart))
                Hoft.anticipateFlag = 0;
            end
            
            % Write the data, but on the last subsection, don't write if it
            % will be followed by another "science segment"
            % In either case, review the data to see if it passes veto flags
            % Before writing
            if jj < (length(tSub.tStart))
                dataReviewer(Hoft, newHoft, jj, jjStart);
            elseif tSegment.tIsFollowed ~= 1
                dataReviewer(Hoft, newHoft, jj, jjStart);
            else
                disp('Holding off writing in anticipation of sub-segment')
            end
            
            clear newHoft
        end
        function dataReviewer(Hoft, newHoft, jj, jjStart)
            frameWriter(Hoft);
            Hoft.vetoAlarm = (Hoft.successVector.range | Hoft.successVector.comb);
            if (Hoft.vetoAlarm & ~(Hoft.isFirstSubFlag)) == 1
                disp('Veto alarm raised in window; writing baseline instead of filtered data')
                newHoft.vetoSubstituteBaseline;
                windowFramer(Hoft, Hoft.tSub, Hoft.p, Hoft.s, newHoft, jj, jjStart);
                clear vetoHoft
                frameWriter(Hoft);
            elseif (Hoft.vetoAlarm & Hoft.isFirstSubFlag ) == 1
                disp('Veto alarm raised; will write baseline')
                frameWriter(Hoft);
            end
        end
        
        function windowFramer(Hoft, tSub, p, s, newHoft, jj, jjStart)
            % For the segment, perform the triangular windowing here
            
            if p <= s
                % Apply the rising edge of the triangle
                % to the first half of a new subsection
                newSegmentFirst =...
                    Hoft.qWindow(1:p) .*...
                    newHoft.data(1:p);
                % Apply the falling edge of the triangle
                % to the last half of an old subsection
                % qWindow is 2*p long, so end = 2*p.
                oldSegmentLast =...
                    Hoft.qWindow((p+1):end) .*...
                    Hoft.data((jjStart+1):(jjStart+p));
                % Add the above two together
                Hoft.data((jjStart+1):(jjStart+p)) =...
                    newSegmentFirst + oldSegmentLast;
                %clear newSegmentFirst
                %clear oldSegmentLast
                % Write the non-overlapping part of the new subsection
                % to the tail of the filtered part of the science segment
                Hoft.data((jjStart+p+1):(jjStart+s)) =...
                    newHoft.data((p+1):s);
                %clear newHoft.data
            else
                % The last subsection, if it's shorter than
                % 512 seconds, will
                % overlap completely with the penultimate subsection.
                % Ergo, there's no
                % concatenation that extends the tail.
                % Otherwise, the process is similar.
                newSegmentFirst =...
                    Hoft.qWindow(1:s) .*...
                    newHoft.data(1:s);
                %clear newHoft.data
                oldSegmentLast =...
                    Hoft.qWindow((p+1):(p+s)) .*...
                    Hoft.data((jjStart+1):(jjStart+s));
                Hoft.data((jjStart+1):(jjStart+s)) =...
                    newSegmentFirst + oldSegmentLast;
                %clear newSegmentFirst
                %clear oldSegmentLast
            end
            if jj == length(tSub.tStart)
                disp('Displaying lengths of Hoft.data, Hoft.data((jjStart+s+1):end), and Hoft.frameTail')
                disp(length(Hoft.data))
                disp(length(Hoft.data((jjStart+s+1))))
                disp(length(Hoft.frameTail))
                Hoft.data((jjStart+s+1):end) = Hoft.frameTail;
                disp('Continuing to attach dangling frame after segment')
            end
            
            
            
            % Repeat the above process with unfiltered data
            % to get a baseline measurement
                if p <= s
                    newBaselineFirst =...
                        Hoft.qWindow(1:p) .*...
                        newHoft.baseline(1:p);
                    oldBaselineLast =...
                        Hoft.qWindow((p+1):end) .*...
                        Hoft.baseline((jjStart+1):(jjStart+p));
                    Hoft.baseline((jjStart+1):(jjStart+p)) =...
                        newBaselineFirst + oldBaselineLast;
                    %clear newBaselineFirst
                    %clear oldBaselineLast
                    Hoft.baseline((jjStart+p+1):(jjStart+s)) =...
                        newHoft.baseline((p+1):s);
                    %clear newHoft.baseline
                else
                    newBaselineFirst =...
                        Hoft.qWindow(1:s) .*...
                        newHoft.baseline(1:s);
                    %clear newHoft.baseline
                    oldBaselineLast =...
                        Hoft.qWindow((p+1):(p+s)) .*...
                        Hoft.baseline((jjStart+1):(jjStart+s));
                    Hoft.baseline((jjStart+1):(jjStart+s)) =...
                        newBaselineFirst + oldBaselineLast;
                    %clear newBaselineFirst
                    %clear oldBaselineLast
                end
                
                
            
        end
        function clearer(Hoft, T, tSub, jj)
            % Now clear the next 512 seconds
            if jj ~= length(tSub.tStart)
                Hoft.data(1:(16384*512)) = [];
                Hoft.baseline(1:(16384*512)) = [];
                if T.pipe == 1
                    Hoft.dqFlag(1:(1*512)) = [];
                    Hoft.stateVector(1:(16*512)) = [];
                end
                Hoft.gpsStart = Hoft.gpsStart + 512;
                % And append if they are enough segments ahead that it will be needed.
                if jj < (length(tSub.tStart)-1)
                    nextSubWhitespace = 128*floor(min([512, (tSub.tEnd(jj+1)-128*floor(tSub.tStart(jj+1)/128)-512)])/128);
                    Hoft.data = [Hoft.data; ones(16384*nextSubWhitespace, 1)];
                    Hoft.baseline = [Hoft.baseline; ones(16384*nextSubWhitespace, 1)];
                    if T.pipe == 1
                        Hoft.dqFlag = [Hoft.dqFlag; ones(1*nextSubWhitespace, 1)];
                        Hoft.stateVector = [Hoft.stateVector; ones(16*nextSubWhitespace, 1)];
                    end
                end
            end
        end
        function frameWriter(Hoft)
            
            % Now we want to write the data to frames
            
           
            
            rTotal = length(Hoft.data);
            secondsDuration = rTotal / 16384;
            
            
            disp('Amount of data to be written')
            disp(rTotal)
            disp(secondsDuration)
            
            % If the vetoAlarm has been risen and this is a single window,
            % the only thing we can do is not replace the data: write the
            % baseline instead
            if ((Hoft.vetoAlarm & Hoft.isFirstSubFlag ) & ~(Hoft.anticipateFlag))== 1
                Hoft.data = Hoft.baseline;
                disp('Filtering unable to improve data; writing baseline instead')
            end
            % For windowed segments, we have the option of writing the
            % baseline only in the faulty window. That is done outside this
            % function.
            
            
            % If this is the last segment, write everything
            % If this another segment follows, only write 512 s
            if Hoft.anticipateFlag == 1
                numberOfFrames = (512 / Hoft.T.s);
            else
                numberOfFrames = ceil(secondsDuration / Hoft.T.s);
            end
            
            
            
            % Now we display the results graphically
            %     % Adjust nA and r for graphing purposes
            %     elseif isFirstSubFlag == 0
            %         nA = 1;
            %         if anticipateFlag == 0
            %             r =
            %         elseif anticipateFlag == 1
            %             r = (16384*512 - 1);
            %         end
            %     end
            
            
            if Hoft.isFirstSubFlag == 0
                Hoft.nA = 1;
            end
            
            if Hoft.anticipateFlag == 1
                Hoft.r = (16384*512 - 1);
            end
            if Hoft.anticipateFlag == 0
                if Hoft.isFirstSubFlag == 0
                    Hoft.r = Hoft.s;
                end
            end
            
            
            
            % Generate names
            startNameBasic = strcat('-', num2str(Hoft.gpsStart + (1-1)*Hoft.T.s) );
            stopNameBasic = strcat('-', num2str(Hoft.gpsStart + (numberOfFrames)*Hoft.T.s) );
            
            % Uncomment the mkframe commands below to write output
            
            
            prototypeFrameName = strcat('H-H1_AMPS_C02_L2',startNameBasic, stopNameBasic,'-', num2str(Hoft.T.s), '.gwf');
            directoryDiagnosticsFrameName = strcat('/home/gmeadors/public_html/feedforward/diagnostics/', prototypeFrameName(1:21));
            
            % Generate names
            %startSubName = strcat('-', num2str(gpsStart) );
            %stopSubName = strcat('-', num2str(gpsStart + numberOfFrames*128) );
            startSubName = strcat('-', num2str(Hoft.tStart));
            stopSubName = strcat('-', num2str(Hoft.tEnd));
            
            % determine outputFile here
            outputFile = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaRange', startSubName, stopSubName, '.txt');
            outputFileComb = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaComb', startSubName, stopSubName, '.txt');
            outputFileFFT = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaFFT', startSubName, stopSubName, '.mat');
            outputFileGraph = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaGraph', startSubName, stopSubName);
            outputFileGauss = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaGauss', startSubName, stopSubName);
            %outputFileTopGraph = strcat('EleutheriaGraph', startSubName, stopSubName);
            
            % For the overlay of transfer functions and other diagnostics
            if Hoft.anticipateFlag == 0
                scienceStart = strcat('-', num2str(Hoft.tScienceStart));
                scienceEnd = strcat('-', num2str(Hoft.tScienceEnd));
                outputFileTF = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaTF', scienceStart, scienceEnd);
                outputFileFit = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaFit', scienceStart, scienceEnd, '.txt');
                outputFileSub = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaSub', scienceStart, scienceEnd, '.txt');
            end
            
            function vetoMover(outputFileGraph)
                % If this window was vetoed, move and relabel the file containing its graph;
                % the original filename references the 'safe', post-veto window for consistency with
                % all other filenames for diagnostic files, which refer to safe windows.
                moveName = @(graphFile, filetype, zoomed) horzcat(graphFile, zoomed, filetype);
                moveCommand = @(graphFile, filetype, zoomed) horzcat(...
                    'mv ', moveName(graphFile, filetype, zoomed), ' ', moveName(graphFile, strcat('-vetoed', filetype), zoomed));
                
                system(moveCommand(outputFileGraph, '.pdf', ''));
                system(moveCommand(outputFileGraph, '.png', ''));
                system(moveCommand(outputFileGraph, '.pdf', 'Zoom'));
                system(moveCommand(outputFileGraph, '.png', 'Zoom'));
            end
            if Hoft.vetoAlarm == 1
                vetoMover(outputFileGraph);
            end
            
            disp('Calculating pre- and post-filter PSD')
            tic
            Fs = 16384;
            % Decide on FFT size, up to 1/16 Hz if possible
            % Never fewer than two averages
            if (Hoft.r / Fs) > 32
                nfft = 16*Fs;
            else
                nfft = ( 2^(nextpow2(Hoft.r./Fs)-2) )*Fs;
            end
            
            [pdarm, fx] = pwelch(...
                Hoft.baseline(Hoft.nA:(Hoft.nA+Hoft.r-1)),hanning(nfft),nfft/2,nfft,Fs);
            [perr, fx] = pwelch(...
                Hoft.data(Hoft.nA:(Hoft.nA+Hoft.r-1)),hanning(nfft),nfft/2,nfft,Fs);
            pdarm = sqrt(pdarm);
            perr = sqrt(perr);
            toc
            
            
            if Hoft.T.pipe == 2
                calcurveFile = load('calcurveFile.mat');
                calcurve = calcurveFile.calcurve;
                
                pdarmcal =(abs(calcurve).^2 .* pdarm(2:end).^2).^(1/2) ./4e3;
                perrcal = (abs(calcurve).^2 .* perr(2:end).^2 ).^(1/2) ./4e3;
            end
            
            
            figure(2010)
            %xlim([50*16 2000*16])
            %ylim([1e-23 2e-22])
            if Hoft.T.pipe == 1
                loglog(fx, pdarm, fx, perr)
            elseif Hoft.T.pipe == 2
                loglog(fx(2:end), pdarmcal, fx(2:end), perrcal)
            end
            grid on
            legend('DARM before filtering', 'DARM after filtering')
            xlabel('Frequency [Hz]')
            ylabel('Sensitivity [magnitude/\surdHz]')
            title('DARM before and after MICH feedforward')
            print('-dpdf', strcat(outputFileGraph, '.pdf'))
            print('-dpng', strcat(outputFileGraph, '.png'))
            %print('-dpdf', strcat(outputFileTopGraph, '.pdf'))
            %print('-dpng', strcat(outputFileTopGraph, '.png'))
            close(2010)
            figure(2011)
            if Hoft.T.pipe == 1
                loglog(fx, pdarm, fx, perr)
            elseif Hoft.T.pipe == 2
                loglog(fx(2:end), pdarmcal, fx(2:end), perrcal)
            end
            grid on
            legend('DARM before filtering', 'DARM after filtering')
            xlabel('Frequency [Hz]')
            ylabel('Sensitivity [magnitude/\surdHz]')
            title('DARM before and after MICH feedforward')
            xlim([50 2000])
            ylim([1e-23 2e-22])
            print('-dpdf', strcat(outputFileGraph, 'Zoom.pdf'))
            print('-dpng', strcat(outputFileGraph, 'Zoom.png'))
            close(2011)
            
            if Hoft.anticipateFlag == 0
                f = (10:2000)';
                fblock = repmat(f, 1, length(Hoft.offlineZPK.MICH));
                fitMagMICH = zeros(length(f), length(Hoft.offlineZPK.MICH));
                fitMagPRC = fitMagMICH;
                fitPhaseMICH = fitMagMICH;
                fitPhasePRC = fitMagMICH;
                
                for gg = 1:length(Hoft.offlineZPK.MICH)
                    respMICH = squeeze(freqresp(Hoft.offlineZPK.MICH(gg), 2*pi*f));
                    respPRC = squeeze(freqresp(Hoft.offlineZPK.PRC(gg), 2*pi*f));
                    fitMagMICH(:, gg) = abs(respMICH);
                    fitMagPRC(:, gg) = abs(respPRC);
                    fitPhaseMICH(:, gg) = angle(respMICH)*180/pi;
                    fitPhasePRC(:, gg) = angle(respPRC)*180/pi;
                    clear respMICH respPRC
                end
                
                figure(2050)
                subplot 211
                loglog(fblock, fitMagMICH);
                grid on
                xlim([min(f) max(f)]);
                ylabel('abs')
                subplot 212
                semilogx(fblock, fitPhaseMICH);
                grid on
                xlim([min(f) max(f)]);
                ylabel('degree');
                xlabel('Hz');
                print('-dpdf',strcat(outputFileTF, '-MICH', '.pdf'));
                print('-dpng', strcat(outputFileTF, '-MICH', '.png'));
                close(2050)
                figure(2051)
                subplot 211
                loglog(fblock, fitMagPRC);
                grid on
                xlim([min(f) max(f)]);
                ylabel('abs')
                subplot 212
                semilogx(fblock, fitPhasePRC);
                grid on
                xlim([min(f) max(f)]);
                ylabel('degree')
                xlabel('Hz')
                print('-dpdf', strcat(outputFileTF, '-PRC', '.pdf'));
                print('-dpng', strcat(outputFileTF, '-PRC', '.png'));
                close(2051)
            end
            
            if Hoft.T.pipe == 1
                pdarmcal = pdarm;
                perrcal = perr;
            end
            
            save(outputFileFFT, 'pdarmcal','perrcal');
            
            if Hoft.T.pipe == 1
                prefilterrange = InspiralRange(fx(2:end), pdarmcal(2:end));
                postfilterrange = InspiralRange(fx(2:end), perrcal(2:end));
            elseif Hoft.T.pipe == 2
                prefilterrange = InspiralRange(fx(2:end), pdarmcal);
                postfilterrange = InspiralRange(fx(2:end), perrcal);
            end
            rangegain = [Hoft.tStart prefilterrange postfilterrange postfilterrange/prefilterrange];
            fid = fopen(outputFile, 'w');
            fprintf(fid, '%s', 'Start GPS time, pre-filter range (kpc), post-filter range (kpc), post/pre-filter ratio')
            fprintf(fid, '\n')
            fprintf(fid, '%f ', rangegain);
            fprintf(fid, '\n')
            %save rangegain.txt rangegain -ASCII
            fclose(fid);
            clear fid
            prefilt =...
                strcat({'Pre-filter range was '},...
                num2str(prefilterrange), ' kpc');
            postfilt =...
                strcat({'Post-filter range is '},...
                num2str(postfilterrange), ' kpc');
            ranger = strcat({'Improvement factor is '},...
                num2str(postfilterrange/prefilterrange));
            disp(prefilt)
            disp(postfilt)
            disp(ranger)
            
            % Print out goodness of fits at the end of the science segment
            if Hoft.anticipateFlag == 0
                fidFit = fopen(outputFileFit, 'w');
                fprintf(fidFit, '%s', 'Window, RMS MICH TF error, RMS PRC TF error')
                fprintf(fidFit, '\n');
                for qq = 1:length(Hoft.rmserr.MICH)
                    clear rmserrString
                    rmserrString = strcat(num2str(qq), 32, num2str(Hoft.rmserr.MICH(qq)), 32, num2str(Hoft.rmserr.PRC(qq)) );
                    fprintf(fidFit, '%s', rmserrString);
                    clear rmserrString
                    fprintf(fidFit, '\n');
                    %rmserrMICH = strcat({'RMS MICH TF error, window '}, num2str(qq), {' is '}, num2str(Hoft.rmserr(qq).MICH));
                    %rmserrPRC = strcat({'RMS PRC  TF error, window '}, num2str(qq), {' is '}, num2str(Hoft.rmserr(qq).PRC));
                    %fprintf(fidFit, '%s ', rmserrMICH);
                    %fprintf(fidFit, '\n');
                    %fprintf(fidFit, '%s ', rmserrPRC);
                    %fprintf(fidFit, '\n');
                end
                fclose(fidFit);
                clear fidFit
            end
            
            % Print out lists of subsegment windows analyzed
            if Hoft.anticipateFlag == 0
                fidSub = fopen(outputFileSub, 'w');
                fprintf(fidSub, '%s', 'Window, window start GPS time, window end GPS time')
                fprintf(fidSub, '\n');
                for rr = 1:length(Hoft.tSub.tStart)
                    clear tSubTimeString
                    tSubTimeString = strcat(num2str(rr), 32, num2str(Hoft.tSub.tStart(rr)), 32, num2str(Hoft.tSub.tEnd(rr)));
                    fprintf(fidSub, '%s', tSubTimeString);
                    clear tSubTimeString
                    fprintf(fidSub, '\n')
                end
                fclose(fidSub);
                clear fidSub
            end
            
            % Estimate Gaussianity:
            [NN, XX] = hist(Hoft.baseline(Hoft.nA:(Hoft.nA+Hoft.r-1)), 2^10);
            [NNc, XXc] = hist(Hoft.data(Hoft.nA:Hoft.nA+Hoft.r-1), 2^10);
            
            figure(2012)
            plot(XX, sqrt(log(NN)), XXc, sqrt(log(NNc)))
            grid on
            xlabel('Magnitude readout')
            ylabel('Histogrammed sqrt(log(quantity))')
            legend('DARM before filtering', 'DARM after filtering')
            title('DARM Gaussianity (including low frequency noise)')
            print('-dpng', strcat(outputFileGauss, '.png'));
            close(2012)
            
            % Estimate Gaussianity in the bucket
            % Bandpass for the bucket:
            [zbGauss, pbGauss, kbGauss] = butter(16, 2*pi*[130 170], 's');
            filttest = filterZPKs(zbGauss, pbGauss, kbGauss, Fs, Hoft.baseline(Hoft.nA:(Hoft.nA+Hoft.r-1)));
            filttest_c = filterZPKs(zbGauss, pbGauss, kbGauss, Fs, Hoft.data(Hoft.nA:(Hoft.nA+Hoft.r-1)));
            [pfilts, fy] = pwelch(filttest, hanning(nfft), nfft/2, nfft, Fs);
            [pfilts_c, fy] = pwelch(filttest_c, hanning(nfft), nfft/2, nfft, Fs);
            pfilts = sqrt(pfilts);
            pfilts_c = sqrt(pfilts_c);
            [NNf, XXf] = hist(filttest, 2^10);
            [NNfc, XXfc] = hist(filttest_c, 2^10);
            
            % Can verify the Gaussianity with a log-log of the PSD
            figure(2013)
            loglog(fy, pfilts, fy, pfilts_c)
            grid on
            xlabel('Frequency [Hz]')
            ylabel('Sensitivity [magnitude/\surdHz]')
            legend('DARM before filtering', 'DARM after filtering')
            title('Bandpassed DARM PSD')
            print('-dpng', strcat(outputFileGauss, '-bandpassPlot', '.png'));
            close(2013)
            figure(2014)
            % The histogram itself
            plot(XXf, sqrt(log(NNf)), XXfc, sqrt(log(NNfc)))
            %xlim([-3e-6 3e-6])
            xlabel('Magnitude readout')
            ylabel('Histogrammed sqrt(log(quantity))')
            legend('DARM before filtering', 'DARM after filtering')
            title('DARM Gaussianity (bandpassed bucket only)')
            print('-dpng', strcat(outputFileGauss, '-filteredBandpassed', '.png'));
            
            
            % Success is declared zero, good,
            % if the filter does not hurt inspiral
            % range by more than one-tenth of one percent;
            Hoft.successVector.range =...
                (1 - (postfilterrange >= 0.999*prefilterrange));
            
            % Compare values at a comb of frequencies:
            % 100 to 2000 Hz with known peaks excluded
            function combOutput = comber(Fs, nfft, pre, post)
                % Set up frequency combs, five bins wide, centered on 'C'
                % nfft/Fs is the 1/(binwidth)
                % r/Fs is the number of seconds in the sample, r
                % Thus r/nfft is the number of averages
                frequencyCombA = (nfft./Fs) .* (...
                    [65, 70, 75, 85, 90, 95, 105, 110,...
                    130, 140, 150, 160, 170, 190,...
                    210, 220, 230, 250, 260, 270, 280, 290,...
                    320, 450, 550, 650, 750, 850, 950, 1050,...
                    1170, 1250, 1350, 1450, 1550, 1650, 1750,...
                    1850, 1950, 2000]) - 2;
                frequencyCombB = frequencyCombA + 1;
                frequencyCombC = frequencyCombA + 2;
                frequencyCombD = frequencyCombA + 3;
                frequencyCombE = frequencyCombA + 4;
                
                % Calculate ratios for the five bins at points in the comb
                RatioA = post(frequencyCombA) ./ pre(frequencyCombA);
                RatioB = post(frequencyCombB) ./ pre(frequencyCombB);
                RatioC = post(frequencyCombC) ./ pre(frequencyCombC);
                RatioD = post(frequencyCombD) ./ pre(frequencyCombD);
                RatioE = post(frequencyCombE) ./ pre(frequencyCombE);
                
                % Take the average of the five bins
                combOutput.Ratio = (RatioA + RatioB + RatioC + RatioD + RatioE) / 5;
                % Compare to a cutoff: veto (one) if the post-filter spectrum
                % is more than 1.2 times worse than pre-filter,
                % or more generous if less than 32 averages
                % else pass (zero)
                combOutput.combLimit = max(1.2, 1.2 * sqrt(32 / (Hoft.r/nfft)));
                combOutput.maximum = max(combOutput.Ratio >= combOutput.combLimit );
                
                disp('Comb limit for this window')
                combOutput.combLimit
                disp('Values of combed points')
                combOutput.Ratio
                disp('Maximum should be Boolean')
                combOutput.maximum
                
                % Store the bin index number in the output:
                combOutput.frequencyCombC = frequencyCombC;
                % And the frequency values
                combOutput.frequencyList = (Fs./nfft).*frequencyCombC;
            end
            combOutputResult = comber(Fs, nfft, pdarmcal, perrcal);
            Hoft.successVector.comb = combOutputResult.maximum;
            disp('success (0) or failure (1) of the data in range and comb veto tests:')
            Hoft.successVector.range
            Hoft.successVector.comb
            
            % Write values at the frequency combed points to a text file:
            fidComb = fopen(outputFileComb, 'w');
            fprintf(fidComb, '%s', horzcat('Frequency (Hz) ', num2str(combOutputResult.frequencyList)));
            fprintf(fidComb, '\n');
            fprintf(fidComb, '%s', horzcat('Post/Pre-Filter Ratio ', num2str( (combOutputResult.Ratio)' )));
            fprintf(fidComb, '\n');
            fprintf(fidComb, '%s', horzcat('Comb limit ', num2str(combOutputResult.combLimit)));
            fprintf(fidComb, '\n');
            fclose(fidComb);
            clear fidFit
            
            % Try 'railroad track diversion"; if it fails, then use the
            % baseline instead of the the filtered version in the second
            % half of the segment.
            
            
            disp('This many frames are being written')
            disp(numberOfFrames)
            
            
            
            % Now, perform writing and range gain calculation for each frame
            % Or, if the Hoft veto has already been trigged,
            % then write anyway -- we have done all possible to preserve data.
            if ((Hoft.successVector.range == 0) & (Hoft.successVector.comb == 0)) | Hoft.vetoAlarm
                for kk = 1:numberOfFrames
                    
                    
                    
                    
                    % Generate names
                    startName = strcat('-', num2str(Hoft.gpsStart + (kk-1)*Hoft.T.s) );
                    stopName = strcat('-', num2str(Hoft.gpsStart + (kk)*Hoft.T.s) );
                    
                    % Uncomment the mkframe commands below to write output
                    
                    
                    HoftSub.data = Hoft.data( ((kk-1)*Hoft.T.s*16384 + 1):(kk*Hoft.T.s*16384) );
                    HoftSub.data = double(HoftSub.data);
                    disp('HoftSub.data is this long')
                    length(HoftSub.data)
                    HoftSub.channel = 'H1:AMPS-STRAIN';
                    HoftSub.type = 'd';
                    HoftSub.mode = 'a';
                    individualFrameName = strcat('H-H1_AMPS_C02_L2',startName, stopName,'-', num2str(Hoft.T.s), '.gwf');
                    directoryDataFrameName = strcat('/home/gmeadors/public_html/feedforward/data/', individualFrameName(1:21));
                    %directoryDiagnosticsFrameName = strcat('/home/gmeadors/public_html/feedforward/diagnostics/', individualFrameName(1:21));
                    setenv('systemDirectoryDataFrameName', directoryDataFrameName);
                    setenv('systemDirectoryDiagnosticsFrameName', directoryDiagnosticsFrameName);
                    system('mkdir -p $systemDirectoryDataFrameName');
                    system('mkdir -p $systemDirectoryDiagnosticsFrameName');
                    frameName = strcat(directoryDataFrameName, '/', individualFrameName);
                    mkframe(frameName, HoftSub, 'n', Hoft.T.s, Hoft.gpsStart);
                    
                    if Hoft.T.pipe == 1
                        % Write data quality and state vector
                        stateVectorSub.data = Hoft.stateVector( ((kk-1)*Hoft.T.s*16 + 1):(kk*Hoft.T.s*16) );
                        stateVectorSub.data = double(stateVectorSub.data);
                        disp('stateVectorSub.data is this long')
                        length(stateVectorSub.data)
                        stateVectorSub.channel = 'H1:AMPS-SV_STATE_VECTOR';
                        stateVectorSub.type = 'd';
                        stateVectorSub.mode = 'a';
                        mkframe(frameName, stateVectorSub, 'a', Hoft.T.s, Hoft.gpsStart);
                        clear stateVectorSub
                        dqFlagSub.data = Hoft.dqFlag( ((kk-1)*Hoft.T.s*1 + 1):(kk*Hoft.T.s*1) );
                        dqFlagSub.data = double(dqFlagSub.data);
                        disp('dqFlagSub.data is this long')
                        length(dqFlagSub.data)
                        dqFlagSub.channel = 'H1:AMPS-DATA_QUALITY_FLAG';
                        dqFlagSub.type = 'd';
                        dqFlagSub.mode = 'a';
                        mkframe(frameName, dqFlagSub, 'a', Hoft.T.s, Hoft.gpsStart);
                        clear dqFlagSub
                    end
                    
                    
                    % Finally, send the filtered (and, for comparison, unfiltered)
                    % data into a cell array of science segments,
                    % into the 'ii'th cell
                    % (For prototyping only; disable during Condor runs)
                    
                    %disp(strcat(...
                    %    'Finishing science segment number ...', num2str(ii)))
                    %disp(strcat(...
                    %    'Number of samples in segment ...', num2str(size(Hoft.data))))
                    %            allHoft.segment{ii} = Hoft.segment;
                    %            allHoft.baseline{ii} = Hoft.baseline;
                    %            allHoft.frameList{ii} = Hoft.fullListing;
                    
                    
                end
            else
                disp('Window fails veto test.')
                disp('Range veto (zero is good, one is bad)')
                Hoft.successVector.range
                disp('Comb veto (zero is good, one is bad)')
                Hoft.successVector.comb
            end
            
            %successVector = 0;
            
        end
    end
    
end

