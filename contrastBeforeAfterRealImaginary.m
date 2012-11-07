% Grant David Meadors
% contrastBeforeAfterRealImaginary
% g m e a d o r s @ u m i c h . e d u
% 02012-11-07 (JD 2456239)
% Plots the real and imaginary components of Tukey and Hann
% windows for Hoft, both before and after feedforward

bhr = load('beforeHannReal.txt');
bhi = load('beforeHannImaginary.txt');
btr = load('beforeTukeyReal.txt');
bti = load('beforeTukeyImaginary.txt');
ahr = load('afterHannReal.txt');
ahi = load('afterHannImaginary.txt');
atr = load('afterTukeyReal.txt');
ati = load('afterTukeyImaginary.txt');

% Since each of these files contains not one but eleven frequencies,
% choose only the eleventh element, given slightly below 849 Hz in
% each SFT window

bhr = bhr(1:11:end);
bhi = bhi(1:11:end);
btr = btr(1:11:end);
bti = bti(1:11:end);
ahr = ahr(1:11:end);
ahi = ahi(1:11:end);
atr = atr(1:11:end);
ati = ati(1:11:end);

th = 1:length(bhr);
tt = 1:length(btr);

figure(1)
plot(th, bhr, th, ahr)
legend('Before feedforward', 'After feedforward')
title('Hann real component vs SFT number')
ylabel('SFT arbitrary units')
xlabel('SFT number')
grid on
print('-dpdf', 'HannReal.pdf')
print('-dpng', 'HannReal.png')
close(1)

figure(2)
plot(th, bhi, th, ahi)
legend('Before feedforward', 'After feedforward')
title('Hann imaginary component vs SFT number')
ylabel('SFT arbitrary units')
xlabel('SFT number')
grid on
print('-dpdf', 'HannImaginary.pdf')
print('-dpng', 'HannImaginary.png')
close(2)

figure(3)
plot(tt, btr, tt, atr)
legend('Before feedforward', 'After feedforward')
title('Tukey real component vs SFT number')
ylabel('SFT arbitrary units')
xlabel('SFT number')
grid on
print('-dpdf', 'TukeyReal.pdf')
print('-dpng', 'TukeyReal.png')
close(3)

figure(4)
plot(tt, bti, tt, ati)
legend('Before feedforward', 'After feedforward')
title('Tukey imaginary component vs SFT number')
ylabel('SFT arbitrary units')
xlabel('SFT number')
grid on
print('-dpdf', 'TukeyImaginary.pdf')
print('-dpng', 'TukeyImaginary.png')
close(4)
