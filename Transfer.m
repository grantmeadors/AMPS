classdef Transfer < handle
    % Transform MICH and DARM data into frequency-domain
    % Coherence and transfer functions
    % Grant David Meadors
    % 02012-02-28
    
    properties (SetAccess = private)
        coh
        Fs
        f
        subNOISE_DARM
        PRCfilter
        t
        t0
        t1
        s
        sub12
        pipe
    end
    
    methods
        function frequencies = Transfer(channels)
            frequencies.Fs = channels.Fs;
            
            [frequencies.sub12, frequencies.f, vsig] = f_domainsubtract(...
                channels.darm, channels.noise,...
                hanning(frequencies.Fs), frequencies.Fs,...
                frequencies.Fs, 'noplots');
            frequencies.subNOISE_DARM = 1 ./ vsig.tfxy;
            % Assign additional information used in later code;
            frequencies.coh = vsig.cxy;
            frequencies.PRCfilter = channels.PRCfilter;
            frequencies.t = channels.t;
            frequencies.t0 = channels.t0;
            frequencies.t1 = channels.t1;
            frequencies.s = channels.s;
            frequencies.pipe = channels.pipe;
        end
    end
    
end

