% Grant David Meadors
% Matlab post-processing for feedforward
% 02012-03-19

% Clear any existing 'Whole log' entries
system('rm logs/whole_log.txt');
system('rm logs/whole_out.txt');
system('rm logs/whole_err.txt');

% Make sure that i in the bash script ranges to N-1, where N is the number of jobs
system('for i in {0..199}; do cat logs/eleutheria.log.$i >> logs/whole_log.txt; done');
system('for i in {0..199}; do cat logs/eleutheria.out.$i >> logs/whole_out.txt; done');
system('for i in {0..199}; do cat logs/eleutheria.err.$i >> logs/whole_err.txt; done');


% Read image sizes to make sure that none of the jobs is using too much memory
system('cat logs/whole_log.txt | grep -n "Image size of job updated" > logs/whole_imagesize.txt');
[status_image, result_image] = system('wc -l logs/whole_imagesize.txt');
result_image_number = str2num(result_image(1:end-25));


imagesizelines = textread('logs/whole_imagesize.txt', '%s');
imagesize = cell(size(imagesizelines));
% Only one out of ten elements is the actual image size
for ii = 10:10:(result_image_number*10)   
    imagesize{ii} = imagesizelines{ii}; 
end
% Remove empty cells, the remnants of text
imagesize = imagesize(~cellfun('isempty',imagesize));
% Convert from strings to numbers
imagesize = cellfun(@str2num, imagesize);
% Find maximum
disp('Largest image size (in kilobytes)')
maximum_imagesize = max(imagesize);
disp(maximum_imagesize)

% Make file of range estimates files
system('ls ~/public_html/feedforward/diagnostics/*/*Range* > logs/whole_rangelist.txt');
% Make file of range estimates
system('tail -q -n 1 ~/public_html/feedforward/diagnostics/*/*Range* > logs/whole_range.txt');
% Load into Matlab
rangematrix = load('logs/whole_range.txt');

% Make plot of range versus time
figure(4000)
plot(rangematrix(:,1), rangematrix(:,2)/1e3, rangematrix(:,1), rangematrix(:,3)/1e3)
grid on
xlim([931e6 933e6])
xlabel('GPS time (seconds)')
ylabel('Inspiral range (Megaparsecs)')
title('Inspiral range improvement versus time')
legend('Before feedforward','After feedforward')
inspiralGraphName = '/home/gmeadors/public_html/feedforward/diagnostics/inspiralRange';
print('-dpdf', strcat(inspiralGraphName, '.pdf'));
print('-dpng', strcat(inspiralGraphName, '.png'));
close(4000)

% Make plot of normalized range improvement versus time
figure(5000)
plot(rangematrix(:,1), rangematrix(:, 4))
grid on
xlim([931e6 933e6])
xlabel('GPS time (seconds)')
ylabel('After/Before feedforward inspiral range')

% Report average gain
disp('Average gain in inspiral range over the science run (percent)')
averageGain = (mean(rangematrix(:, 4) -1)*1e2);
disp(averageGain)

gainLegend = horzcat('average range gain after feedforward: ', num2str(averageGain),' percent');
legend(gainLegend)

inspiralGainGraphName = strcat(inspiralGraphName, 'Gain');
print('-dpdf', strcat(inspiralGainGraphName, '.pdf'));
print('-dpng', strcat(inspiralGainGraphName, '.png'));

% Close figure
close(5000)
