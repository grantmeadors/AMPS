% Grant David Meadors
% contrastBeforeAfterRealImaginary
% g m e a d o r s @ u m i c h . e d u
% 02012-11-19 (JD 2456251)
% Plots the calibrated amplitude of Hann
% windows for Hoft, both before and after feedforward

beforeRaw = load('S6H1_Hann_40_2000test_bins.txt');
afterRaw = load('S6H1_Hann_40_2000feedforward_bins.txt');

% Each file now is  loaded as a matrix, formatted by column:
% SFTnumber Frequency(Hz) rawPower calibratedAmplitude scalefactor timebaseline
% Our object is to average all the calibrated amplitude rows corresponding
% to a given SFT number.

% The text file is zero-indexed
beforeL = sort(unique(beforeRaw(:,1)));
afterL = sort(unique(afterRaw(:,1)));

before = ones(size(beforeL));
after = ones(size(afterL));


% Average over all the bins corresponding to a given SFT number,
% then multiply by sqrt(8/3) because of the Hann window normalization factor.
% Have to shift index on the right-hand side, to compensate for
% Matlab's one-indexing vs the C-generated text file's zero-indexing
for ii = 1:length(before)
    before(ii) = sqrt(8/3) * mean(beforeRaw(beforeRaw(:,1) == ii - 1, 4));
end
for ii = 1:length(after)
    after(ii) = sqrt(8/3) * mean(afterRaw(afterRaw(:,1) == ii - 1, 4));
end
% Strip any NaN -- but there should not be any
before(isnan(before)) = [];
after(isnan(after)) = [];
clear beforeRaw
clear afterRaw

figure(1)
semilogy(beforeL, before,afterL, after)
legend('Before feedforward', 'After feedforward')
title('Hann power component vs SFT number for 563 1/1800 bins centered at 850 Hz')
ylabel('SFT calibrated units, Hoft, amplitude')
xlabel('SFT number')
grid on
print('-dpdf', 'HannAmp.pdf')
print('-dpng', 'HannAmp.png')
close(1)

difference = before-after;
differenceClean = difference;
differenceClean(isnan(difference)) = [];
arithmean = mean(differenceClean)*ones(size(difference));
arithmeanString = horzcat('Arithmetic mean of difference: ', num2str(arithmean(1)));
length(difference)

figure(2)
plot(beforeL, difference, beforeL, arithmean)
legend('Before minus after feedforward', arithmeanString)
xlabel('SFT number')
ylabel('SFT calibrated units, Hoft, amplitude (before - after)')
title({'Hann amplitude difference vs SFT number for 563 1/1800 bins centered at 850 Hz';...
    arithmeanString;...
    horzcat('Median of difference: ', num2str(median(differenceClean)))});
grid on
ylim([-1e-24 1e-24])
print('-dpdf', 'HannAmpDiff.pdf')
print('-dpng', 'HannAmpDiff.png')
close(2)

% Try some statistics
HoftHistVector = 1e-24*(50:100);
beforeHist = hist(before, HoftHistVector);
afterHist = hist(after, HoftHistVector);
arithmeanBefore = mean(before);
arithmeanAfter = mean(after);
arithmeanDifference = arithmeanBefore - arithmeanAfter;
harmmeanBefore = harmmean(before);
harmmeanAfter = harmmean(after);
harmmeanDifference = harmmeanBefore - harmmeanAfter;
harmmeanString = 'Harmonic mean: before, after, difference';

figure(3)
plot(HoftHistVector, beforeHist, HoftHistVector, afterHist)
xlabel('Hoft')
ylabel('Histogram count')
legend('Before feedforward', 'After feedforward')
title({'Hann windowed calibrated amplitude histogram';...
    harmmeanString;...
    num2str(harmmeanBefore);
    num2str(harmmeanAfter);
    num2str(harmmeanDifference)})
grid on
print('-dpdf', 'HannHist.pdf')
print('-dpng', 'HannHist.png')
close(3)
