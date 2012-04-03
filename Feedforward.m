classdef Feedforward < handle
    % Apply the feedforward filter
    % Grant David Meadors
    % 02012-02-28
    
    properties (SetAccess = private)
       data
       offlineZPK
       rmserr
       baseline
       frameHead
       frameTail
       stateVector
       dqFlag
       mich
       prc
    end
    
    methods
        function hoft0 = Feedforward(t0, t1, addenda)
            
            % Call functions
            channels = Data(t0, t1, addenda);
            addenda.destroyer('darm');
            addenda.destroyer('PassDARM');
            addenda.destroyer('PassPRC');
            addenda.destroyer('PassMICH');
            
            %% Apply Wiener filtering to create witness
            %channels.wienerFilter
            
            frequencies = Transfer(channels);
            filtering = Fitting(frequencies);
            clear frequencies
            
            disp('frame tail length')
            disp(length(channels.frameTail))
            
            
            % FILTER!
            % Internally, filterZPKs converts the ZPK filter from continuous to
            % discrete time using 'bilinear' and then converts the discrete time model
            % to a section order section, which filters the data supplied in the last
            % argument (for us, mich).
            disp('Filtering (offline)!')
            tic
            
            % Extract zeros and poles from struct, for conciseness and
            % because we want to save them later.
            za = filtering.za;
            pa = filtering.pa;
            ka = filtering.ka;
            
            
            
            
            
            % pre-filter data
            channels.preFilter
            
            
            
            
            % Use feedforward filter
            channels.feedforwardFilter(za, pa, ka)
            
            
            % Add filtered MICH to DARM
            % (we absorbed a minus sign when we converted ss->zpk)
            % !!! FILTER !!!
            hoft0.data = channels.darm - channels.noise;
            
            
            
            % Quack the newMICHD filter at 16384 Hz and save the z, p, and k
            % as well as the newMICHD filter

            % Copy site names for convenience
            site = addenda.site;
            siteFull = addenda.siteFull;
            
            startName = strcat('-', num2str(addenda.s*floor(t0/addenda.s)));
            stopName = strcat('-', num2str(addenda.s*ceil(t1/addenda.s)));
            individualFrameName = strcat(site, '-', site, '1_AMPS_C02_L2', startName, stopName, '-', num2str(addenda.s), '.gwf');
            directoryDiagnosticsFrameName = strcat('/home/gmeadors/public_html/feedforward/diagnostics/', siteFull, individualFrameName(1:21));
            setenv('systemDirectoryDiagnosticsFrameName', directoryDiagnosticsFrameName);
            system('mkdir -p $systemDirectoryDiagnosticsFrameName');
            
            offlineNameStart = strcat(directoryDiagnosticsFrameName,'/', 'EleutheriaOfflineZPK', '-', num2str(t0), '-', num2str(t1));
            if addenda.PRCfilter == 0
                offlinezpks = strcat(offlineNameStart, '-MICH', '.mat');
                hoft0.offlineZPK.MICH = filtering.newNOISE;
                hoft0.rmserr.MICH = filtering.rmserr;
            elseif addenda.PRCfilter == 1
                offlinezpks = strcat(offlineNameStart, '-PRC', '.mat');
                hoft0.offlineZPK.PRC = filtering.newNOISE;
                hoft0.rmserr.PRC = filtering.rmserr;
            end

            saveNewNOISE = filtering.newNOISE;            
            clear filtering

            % newNOISE = filtering.newNOISE;
            save(offlinezpks, 'saveNewNOISE', 'za', 'pa', 'ka');
            %quack3(newMICHD, 16384)
            
            % Assign to output
            
            if addenda.PRCfilter == 1
                hoft0.baseline = addenda.baseline;
                addenda.destroyer('baseline');
            else
                hoft0.baseline = channels.darm;
                channels.destroyer('darm');
            end
            
            if addenda.frameHeadFlag == 1
                hoft0.frameHead = ones(size(channels.frameHead));
                hoft0.frameHead(:) = channels.frameHead(:);
                channels.destroyer('frameHead');
            end
            if addenda.frameTailFlag == 1
                hoft0.frameTail = ones(size(channels.frameTail));
                hoft0.frameTail(:) = channels.frameTail(:);
                channels.destroyer('frameTail');
            end
            if addenda.PRCfilter == 0
                if addenda.pipe == 1
                    hoft0.stateVector = channels.stateVector;
                    hoft0.dqFlag = channels.dqFlag;
                end
                if length(hoft0.data) > 512*16384
                    hoft0.mich = channels.mich;
                    channels.destroyer('mich');
                end
            elseif addenda.PRCfilter == 1
                if length(hoft0.data) > 512*16384
                    hoft0.prc = channels.prc;
                    channels.destroyer('prc');
                end
            end
            clear channels
            
            
            
            disp('Exporting baseline to check filter improvement')
            
            
            toc
            
            
            
        end
        function vetoSubstituteBaseline(Hoft)
            Hoft.data = Hoft.baseline;
        end
    end
    
end

