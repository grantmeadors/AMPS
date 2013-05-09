classdef AddendaEditor < handle
    % Produces the ubiquitous addenda object that carries information
    % between the filtering and the Hoft generation stages
    % Grant David Meadors
    % 02012-04-03
    
    properties (SetAccess = private)
        darm
        passDARM
        passPRC
        passMICH
        PRCfilter
        frameHeadFlag
        frameTailFlag
        baseline
        s
        pipe
        inputFileDARM
        inputFileNOISE
        passFirstFlag
        baselineCheck
        site
        siteFull
        oddFrameWarning
    end
    
    methods
        function addenda = AddendaEditor(...
                baselineCheck, PRCfilter, pipe, s,...
                inputFileDARM, inputFileNOISE, passFirstFlag,...
                frameHeadFlag, frameTailFlag, siteName)
            addenda.darm = [];
            addenda.passDARM = [];
            addenda.passPRC = [];
            addenda.passMICH = [];
            addenda.PRCfilter = PRCfilter;
            addenda.frameHeadFlag = frameHeadFlag;
            addenda.frameTailFlag = frameTailFlag;
            addenda.baseline = [];
            addenda.s = s;
            addenda.pipe = pipe;
            addenda.inputFileDARM = inputFileDARM;
            addenda.inputFileNOISE = inputFileNOISE;
            addenda.passFirstFlag = passFirstFlag;
            addenda.baselineCheck = baselineCheck;
            addenda.site = siteName;
            addenda.siteFull = strcat('L', siteName, 'O');
        end
        function initialFixer(addenda, oddFrameWarning, tSub, T)
            tau1 = floor(tSub.tStart(1) / T.s)*T.s;
            tau2 = ceil(tSub.tEnd(1) / T.s)*T.s;
            if tSub.tStart(1) == tau1
                addenda.frameHeadFlag = 0;
            else
                addenda.frameHeadFlag = 1;
            end
            % For short segments, include the frame tail.
            % Short is any single window. Single windows are naturally
            % up to 512 seconds long, but we aggregate any second windows
            % less than 32 seconds long into them, so "short" means
            % less than or equal to 512+32 seconds long.
            if (tSub.tEnd(1) - tSub.tStart(1)) > (512+32)
                addenda.frameTailFlag = 0;
            elseif tSub.tEnd(1) == tau2
                addenda.frameTailFlag = 0;
            else
                addenda.frameTailFlag = 1;
            end
            addenda.oddFrameWarning = oddFrameWarning;
        end
        function loopFixer(addenda, Hoft, jj, tSub)
            if jj == length(tSub.tStart)
                addenda.frameTailFlag = 1;
            end
            
            if jj == 2
                nC = Hoft.nA;
                nD = nC - 1 + 16384*( min([(512), (tSub.tEnd(2)-tSub.tStart(1)-512) ]) );
                addenda.passDARM = Hoft.baseline(nC:nD);
                addenda.passMICH = Hoft.passMICH;
                clear Hoft.passMICH
                addenda.passPRC = Hoft.passPRC;
                clear Hoft.passPRC
            elseif jj > 2
                addenda.passDARM = Hoft.passDARM;
                clear Hoft.passDARM
                addenda.passMICH = Hoft.passMICH;
                clear Hoft.passMICH
                addenda.passPRC = Hoft.passPRC;
                clear Hoft.passPRC
            end
            addenda.oddFrameWarning = Hoft.oddFrameWarning;
        end
        function initialPRC(addenda, aFirstHoft)
            addenda.PRCfilter = 1;
            addenda.passFirstFlag = 0;
            addenda.baseline = aFirstHoft.baseline;
            clear aFirstHoft.baseline
            addenda.darm  = aFirstHoft.data;
            clear aFirstHoft.data
            addenda.frameHeadFlag = 0;
            addenda.frameTailFlag = 0;
        end
        function loopPRC(addenda, aNewHoft)
            addenda.PRCfilter = 1;
            addenda.frameTailFlag = 0;
            addenda.baseline = aNewHoft.baseline;
            clear aNewHoft.baseline
            addenda.darm = aNewHoft.data;
        end
        function destroyer(addenda, fieldName)
            if strcmp(fieldName, 'darm')
                addenda.darm = [];
            elseif strcmp(fieldName, 'baseline')
                addenda.baseline = [];
            elseif strcmp(fieldName, 'passPRC')
                addenda.passPRC = [];
            elseif strcmp(fieldName, 'passMICH')
                addenda.passMICH = [];
            elseif strcmp(fieldName, 'passDARM')
                addenda.passDARM = [];
            end
        end
    end
    
end

