% Grant David Meadors
% Matlab post-processing for feedforward
% 02012-08-02 (JD 2456142)
% g m e a d o r s @ u m i c h . e d u

% Clear any existing 'Whole log' entries
%system('rm eleutheriaLogs/whole_log.txt');
%system('rm eleutheriaLogs/whole_out.txt');
%system('rm eleutheriaLogs/whole_err.txt');

% Make sure that i in the bash script ranges to N-1, where N is the number of jobs
%system('cat eleutheriaLogs/eleutheria.dag.log >> eleutheriaLogs/whole_log.txt');
%system('for i in {1..200}; do cat eleutheriaLogs/eleutheria.out.eleutheria_$i >> eleutheriaLogs/whole_out.txt; done');
%system('for i in {1..200}; do cat eleutheriaLogs/eleutheria.err.eleutheria_$i >> eleutheriaLogs/whole_err.txt; done');


% Read image sizes to make sure that none of the jobs is using too much memory
%system('cat eleutheriaLogs/whole_log.txt | grep -n "Image size of job updated" > eleutheriaLogs/whole_imagesize.txt');
%[status_image, result_image] = system('wc -l eleutheriaLogs/whole_imagesize.txt');
%result_image_number = str2num(result_image(1:end-35));


%imagesizelines = textread('eleutheriaLogs/whole_imagesize.txt', '%s');
%imagesize = cell(size(imagesizelines));
% Only one out of ten elements is the actual image size
%for ii = 10:10:(result_image_number*10)   
%    imagesize{ii} = imagesizelines{ii}; 
%end
% Remove empty cells, the remnants of text
%imagesize = imagesize(~cellfun('isempty',imagesize));
% Convert from strings to numbers
%imagesize = cellfun(@str2num, imagesize);
% Find maximum
%disp('Largest image size (in kilobytes)')
%maximum_imagesize = max(imagesize);
%disp(maximum_imagesize)

for ii = 3:7
    % Make file of range estimates files
    systemCommandRangelist = ...
        horzcat('ls /home/pulsar/public_html/feedforward/diagnostics/LHO/*L2-9', num2str(ii),...
        '*/*Range* >> eleutheriaLogs/whole_rangelist_LHO.txt');
    % Make file of range estimates
    systemCommandRange = ...
        horzcat('tail -q -n 1 /home/pulsar/public_html/feedforward/diagnostics/LHO/*L2-9', num2str(ii),...
        '*/*Range* >> eleutheriaLogs/whole_range_LHO.txt');
    system(systemCommandRangelist);
    system(systemCommandRange);
end
 Load into Matlab
rangematrix = load('eleutheriaLogs/whole_range_LHO.txt');

% Make plot of range versus time
figure(4000)
plot(rangematrix(:,1), rangematrix(:,2)/1e3, rangematrix(:,1), rangematrix(:,3)/1e3)
grid on
xlim([931e6 973e6])
xlabel('GPS time (seconds)')
ylabel('Inspiral range (Megaparsecs)')
title('Inspiral range improvement versus time')
legend('Before feedforward','After feedforward')
inspiralGraphName = '/home/gmeadors/public_html/feedforward/diagnostics/LHO/inspiralRange';
print('-dpdf', strcat(inspiralGraphName, '.pdf'));
print('-dpng', strcat(inspiralGraphName, '.png'));
close(4000)

% Make plot of normalized range improvement versus time
figure(5000)
plot(rangematrix(:,1), rangematrix(:, 4))
grid on
xlim([931e6 973e6])
xlabel('GPS time (seconds)')
ylabel('After/Before feedforward inspiral range')
title('Inspiral range gain versus time')

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

% Try making smoothed plots
inspiralSmoothName = 'inspiralRangeSmooth';
figure(6000)
plot(rangematrix(:,1), smooth(rangematrix(:,2)/1e3,50), rangematrix(:,1), smooth(rangematrix(:,3)/1e3,50))
grid on
xlim([931e6 973e6])
xlabel('GPS time (seconds)')
ylabel('Inspiral range (Megaparsecs)')
title('Smoothed inspiral range improvement versus time')
beforeAvg = mean(rangematrix(:,2)/1e3);
afterAvg = mean(rangematrix(:,3)/1e3);
beforeNameSmooth = horzcat('Before feedforward: ', num2str(beforeAvg), ' Mpc arithmetric mean');
afterNameSmooth = horzcat('After feedforward: ', num2str(afterAvg), ' Mpc arithmetric mean');
legend(beforeNameSmooth, afterNameSmooth)
print('-dpdf', strcat(inspiralSmoothName, '.pdf'));
print('-dpng', strcat(inspiralSmoothName, '.png'));
close(6000)

figure(7000)
plot(rangematrix(:, 1), smooth(rangematrix(:, 4), 50))
grid on
xlim([931e6 973e6])
xlabel('GPS time (seconds)')
ylabel('Smoothed after/before feedforward inspiral range')
title('Smoothed inspiral range gain versus time')
legend(gainLegend)
inspiralSmoothGainGraphName = strcat(inspiralSmoothName , 'Gain');
print('-dpdf', strcat(inspiralSmoothGainGraphName, '.pdf'));
print('-dpng', strcat(inspiralSmoothGainGraphName, '.png'));
close(7000)

