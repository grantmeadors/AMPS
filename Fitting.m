classdef Fitting < handle
    % Apply Vectfit to find a fit to the transfer function
    % Grant David Meadors
    % 02012-04-03
    
    properties (SetAccess = private)
        newNOISE
        za
        pa
        ka
        z
        f
        z0
        Fs
        rmserr
    end
    
    methods
        function filtering = Fitting(frequencies)
            
            % For convenience, copy object variables into shorter local ones 
            f = frequencies.f;
            filtering.Fs = frequencies.Fs;
            pipe = frequencies.pipe;
            site = frequencies.site;
            siteFull = frequencies.siteFull;
            
            
            % Vector fit!
            %filtering.currentTF = 0.878*10^(-36/20); %just the gain of -36dB and 0.878.
            
            
            n = find(f > 50 & f < 5500 & ~isnan(frequencies.subNOISE_DARM));
            %
            z = transpose(frequencies.subNOISE_DARM(n));

            % Keep a copy of the raw transfer function for diagnostics
            z0 = z;
            % This is the subtraction TF (e.g. DARM_ERR/MICH_CTRL)
            % Do not use subNOISE_DARM' as it takes the complex conjugate.
            f = f(n)';
            
            % Initial poles for Vector Fitting:
            % order of approximation
            N = 16;
            poles = logspace(2, log10(filtering.Fs/10), N);
            % make sure poles are below the Nyquist
            
            % Apply averaging to the spectrum to smooth out bumps
            function zOut = logAverager(z, smoothing)
                zMagnitudeSmooth = exp(filter(smoothing, [1 smoothing-1], log(abs(z))));
                zAngleSmooth = exp(filter(smoothing, [1 smoothing-1], log(angle(z))));
                zOut = zMagnitudeSmooth .* exp(1i .* zAngleSmooth);
            end
            
            % Experimental medfilt
            z = medfilt1(z, 10);
            % Apply the averaging; try a smoothing of 1-1e-2
            z = logAverager(z, 1-1e-2);
            % Additional median filtering
            z = medfilt1(z, 10);
            % Try moving average filter
            windowSize = 10;
            movF = ones(1, windowSize)/windowSize;
            z = filter(movF, 1, z);

            
            
            weight = ones(size(f));
            % All frequency points are given equal weight
            
            
            [m, p] = bode(zpk([0 0], -2*pi*[100 100 700 700], 1), 2*pi*f);
            m = squeeze(m);
            weight = weight .* (m(:)');
            
            % notch out the power lines, cal lines, pcal line, violins and f>800
            v   = find((abs(f - 60) < 4) |...
                (abs(f - 120) < 3) | (abs(f - 180) < 3) | ...
                (abs(f-240)<3) | (abs(f-300) < 3) | (abs(f-360) < 3));
            vv = find( (abs(f-46.7) < 3) |...
                (abs(f-391.3) < 3) | (abs(f-1144.3) < 3)| ...
                (abs(f - 346) < 20) | (abs(f-400.2) < 3));
            vvv = find(f>800);
            
            weight([v vv vvv]) = 0;
            
            
            opts.relax = 0;      % Do NOT use vector fitting with relaxed non-triviality constraint
            opts.stable = 1;     % Enforce stable poles
            opts.asymp = 2;      % Include D but not  E in fitting
            opts.skip_pole = 0;  % Do NOT skip pole identification
            opts.skip_res = 0;   % Do NOT skip identification of residues (C,D,E)
            opts.cmplx_ss = 0;   % Create real state space model
            
            opts.spy1 = 0;       % No plotting for first stage of vector fitting
            opts.spy2 = 0;       % No creating magnitude plot for fitting of f(s)
            opts.logx = 1;       % Use logarithmic abscissa axis
            opts.logy = 1;       % Use logarithmic ordinate axis
            opts.errplot = 1;    % Include deviation in magnitude plot
            opts.phaseplot = 1;  % Also produce plot of phase angle (in addition to magnitiude)
            opts.legend = 1;     % Do include legends in plots
            opts.fignum = 337;
            
            disp('vector fitting...')
            [SER,poles, filtering.rmserr,fit] =...
                vectfit4(z, 1i*2*pi*f, poles, weight, opts);
            %
            for kk = 1:14
                [SER,poles,filtering.rmserr,fit] =...
                    vectfit4(z,1i*2*pi*f,poles,weight,opts);
                % pause(0.02)
            end
            %
            disp('Done.')
            
            disp('Resulting state space model produced (see offlinezpks.mat)')
            A = full(SER.A);
            B = SER.B;
            C = SER.C;
            D = SER.D;
            E = SER.E;
            
            % Get real world zeros and poles out of this garbage 
            % (above line is not GDM's words, but appropriate!)
            % ss(A,B,C,D)+zpk(0, [], E) is the SYS object of the fit.
            ourfit = ss(A,B,C,D);% + zpk(0, [], E);
            
            % subtract our fit from the current MICHD to make a new TF
            % note by GDM 2010-09-09: I think that we actually have to add to the how
            % slew of existing filters (which are multiplied by currentTF) and divide
            % by currentTF (because it'll be in series with our new filter).
            
            % We do the subtraction later on, where we add to the existing filters
            [z1, p1, k1] = zpkdata(ourfit,'v');
            % k1 = k1 / currentTF;
            
            z1 = round(z1 * 1e6) / 1e6;
            p1 = round(p1*1e6)/1e6;
            [m01, p01] = bode( zpk(z1, p1, k1), 2*pi*150 );
            % get parameters at 150 Hz
            
            %Trim out the out of band zeros and poles
            zs1 = z1(abs(z1) < 0.5*filtering.Fs*2*pi);
            ps1 = p1(abs(p1) < 0.5*filtering.Fs*2*pi);
            
            [m11, p11] = bode( zpk(zs1, ps1, k1), 2*pi*150 );
            % get parameters at 150 Hz
            ks1 = k1 * m01/m11;
            % fix gain at 150 Hz
            
            % add butterworth LPF because the fit has more zeros than poles
            [z2, p2, k2] = butter(2, 2*pi*7000, 's');
            
            % Finally, if rmserr is too high, quality of fit is bad, and we should
            % not filter. Thus null the gain.
            if pipe == 1
                % Fits seem good if rmserr < 6e-19 for S6 data
                % Maybe try 1e-18 to give more room for early data
                if (1e-18 < filtering.rmserr)
                    k3 = 0;% must try this based on empirical methods0;
                else
                    k3 = 1;
                end
            elseif pipe == 2
                % Uncertain what the rmserr should be for squeezing data
                if (1e0 < filtering.rmserr)
                    k3 = 0;
                else
                    k3 = 1;
                end
            else
                % Default to unity: pass the filter straight through
                k3 = 1;
            end
            
            filtering.newNOISE = zpk([zs1; z2], [ps1; p2], ks1 * k2 * k3);
            
            % %% plot things
            % fitResid=z-transpose(squeeze(freqresp(zpk(ourfit)*zpk(z2,p2,k2),  2*pi*f)));
            %
            ff=10:2000;
            % figure
            figure(210)
            subplot 211
            % loglog(f, abs(z), ff, abs(squeeze(freqresp(zpk(ourfit), 2*pi*ff))), ff, ones(size(ff))*currentTF, ...
            %   ff, abs(squeeze(freqresp(newMICHD, 2*pi*ff))));
            loglog(f, abs(z0), f, abs(z), ff, abs(squeeze(freqresp(filtering.newNOISE, 2*pi*ff))));
            grid on
            xlim([min(ff) max(ff)]);
            ylabel('abs')
            legend('current residual', 'pre-processed residual', 'new filter')
            % legend('current residual', 'fit', 'current MICHD filter', 'new MICHD = red - green', 'Location', 'NorthWest');
            title('Auxiliary channel noise in DARM ERR')
            % title('MICH_\CTRL in DARM\_ERR, in terms of MICHD\_IN')
            subplot 212
            % semilogx(f, angle(z)*180/pi, ff, angle(squeeze(freqresp(zpk(ourfit), 2*pi*ff)))*180/pi, ...
            %   ff, zeros(size(ff)), ff, angle(squeeze(freqresp(newMICHD, 2*pi*ff)))*180/pi);
            semilogx(f, angle(z0)*180/pi, f, angle(z)*180/pi, ff, angle(squeeze(freqresp(filtering.newNOISE, 2*pi*ff)))*180/pi);
            grid on
            ylabel('degree')
            xlabel('Hz')
            xlim([min(ff) max(ff)]);
            % % FillPage('tall');
            if frequencies.PRCfilter
                noiseNameString = 'PRC';
            else
                noiseNameString = 'MICH';
            end
            startName = strcat('-', num2str(frequencies.s*floor(frequencies.t0/frequencies.s)));
            stopName = strcat('-', num2str(frequencies.s*ceil(frequencies.t1/frequencies.s)));
            individualFrameName = strcat(site, '-', site, '1_AMPS_C02_L2', startName, '-', num2str(frequencies.s), '.gwf');
            directoryDiagnosticsFrameName = strcat('/home/pulsar/public_html/feedforward/diagnostics/', siteFull, '/', individualFrameName(1:21));
            setenv('systemDirectoryDiagnosticsFrameName', directoryDiagnosticsFrameName);
            system('mkdir -p $systemDirectoryDiagnosticsFrameName');
            graphName = strcat(directoryDiagnosticsFrameName, '/', 'EleutheriaFilter-', num2str(frequencies.t(1)),'-', noiseNameString);
         
            % print -dpng newMICHDfilter.png
            print('-dpdf', strcat(graphName, '.pdf'));
            print('-dpng', strcat(graphName, '.png'));
            close(210)
            
            %
            %
            %%%%%%%%%%%%%%%%%
            % The -36dB transfer function is actually zeroed, notice, and we have a DC
            % gain of about 10^-5, which should get us the scale we need for offline
            % filtering.
            % All that we have done to subTF:
            % found bad entries
            % set the weights of known lines to zero
            % *VECTOR FITTED*
            % converted from ss to zpk
            % rounded to six decimal places
            % trimmed out of band poles while keeping gain at 150 Hz fixed
            % added a Butterworth to surpress high frequencies
            
            % Notice how well cyan fits over blue. It fits absolutely perfectly over
            % black in the magnitude plot but has (as desired) a 180 degree phase
            % shift.
            
            % Now try to filter with it.
            % We claim that newMICHD's response is equivalent in the
            % frequency domain to subTF.
            
            
            
            
            [zaAll, paAll, filtering.ka] = zpkdata(filtering.newNOISE);
            % Extract zeroes and poles from their cell arrays
            % and return values to output
            filtering.za = zaAll{1};
            filtering.pa = paAll{1};

            filtering.f = f;
            filtering.z = z;
            filtering.z0 = z0;
        end
    end
end


