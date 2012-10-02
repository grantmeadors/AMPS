%function noOutput = plotAMPSspectraFFT(FFTinput)

% Grant David Meadors
% g m e a d o r s @ u m i c h . e d u
% 02012-07-26 (JD 2456135)

FFTinput = 'EleutheriaFFT-953164815-953165839.mat';
load(FFTinput);
f = 8192/length(pdarmcal):8192/length(pdarmcal):8192;
diff = pdarmcal - perrcal;
resampleFactor = 16;
resampleFilterSize = 32;
fR = resample(f, 1, resampleFactor, resampleFilterSize);
diffR = resample(diff, 1, resampleFactor, resampleFilterSize);
plot(fR, diffR)
xlim([30 2000])
ylim([-1e-24 1e-24])
grid on

%end

