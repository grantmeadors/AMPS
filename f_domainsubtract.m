function varargout = f_domainsubtract(X, Y, window1, nfft, Fs, varargin)

% This function does frequency domain subtraction of two signals.
%  ------------------------------------------------
%  TFest is an estimate of H(s) = < X(s)/Y(s) >
%        then our subtraction in the laplace domain is
%  sub(s) = X(s) - H(s)*Y(s)
%        which implies
%  Pss = Pxx + abs(H)^2*Pyy - 2*Re{H*Pyx}*weighting    (or equivalently: 2*Re{conj(H)*Pxy})
%        Where Pxx is the PSD of x (in MATLAB, pwelch(x,...)) and weighting
%        is the coherence
%
%  ------------------------------------------------
% Note that MATLABs Pyx = CPSD(Y,X,..) uses the conjugate FFT of X, and the
% FFT of Y
%  --------------------------------------
% window is generally an nfft point hanning window, and varargin is either
% 3 numbers corresponding to the figure numbers I want to make my plots, or
% the string 'noplots' to not plot anything
%
% the default overlap of the segments is 50%
%
% davidym@caltech.edu
% 2/15/2010
%
% added varargout - Rana  - Apr 24, 2010

% Altered for speed of use in feedforward - Grant David Meadors, 2012-04-03
% Then returned to normal, 2012-09-12
% for testing, Pyy, Pyx = 1;

%% Estimate the Transfer Function of my System
TFest = tfestimate(Y, X, window1, nfft/2, nfft, Fs); % Y-->H(s)-->X

% Calculating PSD of my Subtraction
numavg = floor(2*length(X)/nfft) - 1; % Number of averages

[Cohxy]    = mscohere(X, Y, window1, nfft/2, nfft, Fs);
[Pxx,Pxxf] = pwelch(X,  window1, nfft/2, nfft, Fs);
[Pyy]      = pwelch(Y,  window1, nfft/2, nfft, Fs);
[Pyx]      = cpsd(Y, X, window1, nfft/2, nfft, Fs);

PSDsub  = Pxx + abs(TFest).^2.*Pyy - 2*real(TFest.*Pyx);
PSDsubf = Pxxf;

% optionally supply all of the internal FFT products (to save doing it again outside of this function)
if nargout > 0
    varargout{1} = PSDsub;
    if nargout > 1
        varargout{2} = PSDsubf;
        if nargout == 3
            v.pxx   = Pxx;
            v.pyy   = Pyy;
            v.tfxy  = 1./TFest;  % Gives Y/X instead of X/Y
            v.cxy   = Cohxy;
            varargout{3} = v;
        end
    end
end

%% Plots generated below (or not)
if strcmp(varargin(1),'noplots')==1
    %sprintf('%s','Running subtraction code without generating Plots')
else
    min_subtractionresidual = sqrt(1-Cohxy);
    my_subtractionresidual  = sqrt(PSDsub./Pxx);
    figure(varargin{1})
        loglog(...
            PSDsubf,min_subtractionresidual,'x',...
            PSDsubf,my_subtractionresidual)
        title(strcat({'Subtraction Residual Num Avgs = '},num2str(numavg)))
        grid
        axis tight
        xlabel('Frequency (Hz)')
        ylabel('Residual')
        legend('Theoretical Minimum$\;\;\;$','Subtraction Obtained','Location','NorthWest')
        
    figure(varargin{2})
        loglog(...
            PSDsubf,sqrt(Pxx),'g',...
            PSDsubf,sqrt(Pyy),'r',...
            PSDsubf,sqrt(PSDsub),'black')
        title(strcat({'Subtraction Spectrum Num Avgs = '},num2str(numavg)))
       grid
       axis tight
       xlabel('Frequency (Hz)')
    
end
    
