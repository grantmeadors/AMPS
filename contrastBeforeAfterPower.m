% Grant David Meadors
% contrastBeforeAfterRealImaginary
% g m e a d o r s @ u m i c h . e d u
% 02012-11-13 (JD 2456244)
% Plots the power of Hann
% windows for Hoft, both before and after feedforward

beforeRaw = load('before.txt');
afterRaw = load('after.txt');

% Since each of these files contains not one but eleven frequencies,
% choose only the eleventh element, given slightly below 849 Hz in
% each SFT window

beforeMid = zeros(11, length(beforeRaw)/11);
afterMid = zeros(11, length(afterRaw)/11);
for ii = 1:11
    beforeMid(ii,:) = beforeRaw(ii:11:end);
    afterMid(ii,:) = afterRaw(ii:11:end);
end
before = mean(beforeMid,1);
after = mean(afterMid,1);

beforeL = 1:length(before);
afterL = 1:length(after);

figure(1)
semilogy(beforeL, before,afterL, after)
legend('Before feedforward', 'After feedforward')
title('Hann power component vs SFT number for 11 1/1800 bins centered at 849 Hz')
ylabel('SFT arbitrary units, power')
xlabel('SFT number')
grid on
print('-dpdf', 'HannPower.pdf')
print('-dpng', 'HannPower.png')
close(1)

difference = 2*sqrt(before) - 2*sqrt(after(1:beforeL));
arithmean = mean(difference)*ones(size(difference));

figure(2)
plot(beforeL, difference, beforeL, arithmean)
legend('Before minus after feedforward', 'Arithmetic mean of difference')
xlabel('SFT arbitrary units, amplitude')
ylabel('SFT number')
title('Hann amplitude difference vs SFT number for 11 1/1800 bins centered at 849 Hz')
grid on
print('-dpdf', 'HannAmpDiff.pdf')
print('-dpng', 'HannAmpDiff.png')
close(2)
