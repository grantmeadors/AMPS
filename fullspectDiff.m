clear *
hold off

%runlist = ['S5'; 'S6'];
runlist = ['S6'];
run = ['S6'];
%windowlist = ['Hann ';'Tukey']; 
windowlist = 'Tukey';

%ifolist = ['H1'; 'L1'];
ifolist = ['H1'];
plotcolor = ['RED  '; 'GREEN'];

bandlolist = [40   40 69.9 199.9];
bandhilist = [2000 70.1 700.1 2000];
ylolist = [1.e-23 6.e-23 1.e-23 1.e-23];
yhilist = [1.e-21 5.e-21 1.e-21 1.e-21];
bandnames = ['40_2000_Hz ';'40_70_Hz   ';'70_700_Hz  ';'200_2000_Hz'];
% 1 = linear-linear, 2 = linear-log, 3 = log-linear, 4 = log-log
plottypelist = [4 2 2 4];

combinedbandlolist = [40. 55. 96. 110. 144. 165. 429. 677. 932. 984. 1029. 1141.];
combinedbandhilist = [2000. 65. 97. 130. 146. 195. 439. 678. 933. 985. 1031. 1143.];
combinedbandnames = ['40_2000_Hz  ';'55_65_Hz    ';'96_97_Hz    ';'110_130_Hz  ';'144_146_Hz  ';'165_195_Hz  ';'429_439_Hz  ';'677_678_Hz  ';'932_933_Hz  ';'984_985_Hz  ';'1029_1031_Hz';'1141_1143_Hz'];
combinedylolist = [1.e-23 1.e-24 1.e-24 1.e-24 2.e-23 1.e-24 2.e-23 3.e-23 4.e-23 4.e-23 5.e-23 5.e-23];
combinedyhilist = [1.e-21 1.5e-21 2.e-22 1.5e-22 7.e-23 1.e-22 1.e-22 1.4e-22 1.8e-22 2.e-22 3.e-22 2.5e-22];
combinedplottypelist = [4 1 1 1 1 1 1 1 1 1 1 1];

%design = load('design_curve.txt');
%freqdesign = design(:,1);
%sensdesign = design(:,2);

freq = cell(2,2);
amppsd = cell(2,2);
amppswwt = cell(2,2);

% Loop over data runs:

sprintf('Looping over data runs...')
%for irun = 1:length(runlist)
%for irun = 2:2
%   run = strtrim(runlist(irun,1:2));
%   sprintf('Run = %s',run)
irun = 1;

% Loop over interferometers to make single-ifo broadband plots
% showing both unweighted and weighted averages

  sprintf('Looping over single interferometers...')
%  for iifo = 1:length(ifolist) 
  for iifo = 1:1
     ifo = ifolist(iifo,1:2)
     sprintf('ifo = %s',ifo)
     color = strtrim(plotcolor(iifo,:));
     fnameroot = sprintf('%s%s',run,ifo);
     fname1 = sprintf('%s_%s_40_2000test.txt',fnameroot,strtrim(windowlist(irun,:)));
     data1 = load(fname1);
     fname2 = sprintf('%s_%s_40_2000feedforward.txt',fnameroot,strtrim(windowlist(irun,:)));
     data2 = load(fname2);
     freq{irun,iifo} = data1(:,1);
     amppsd{irun,iifo} = data1(:,3) - data2(:,3);
     amppsdwt{irun,iifo} = data1(:,5) - data2(:,3);
     sprintf('Looping over single-IFO bands...')
     for iband = 1:length(bandlolist)
	bandlo = bandlolist(iband);
        bandhi = bandhilist(iband);
        sprintf('Band = %f-%f Hz',bandlo,bandhi)
	ylo = ylolist(iband);
        yhi = yhilist(iband);
        bandname = strtrim(bandnames(iband,:));
        if (plottypelist(iband)==1)
	  plot(freq{irun,iifo},amppsd{irun,iifo},'color','black')
	elseif (plottypelist(iband)==2)
          semilogy(freq{irun,iifo},amppsd{irun,iifo},'color','black')
        elseif (plottypelist(iband)==3)
	  semilogx(freq{irun,iifo},amppsd{irun,iifo},'color','black')
	elseif (plottypelist(iband)==4)
          loglog(freq{irun,iifo},amppsd{irun,iifo},'color','black')
	end
        xlim([bandlo bandhi])
        ylim([ylo yhi])
        hold on
        plot(freq{irun,iifo},amppsdwt{irun,iifo},'color',color)
	%plot(freqdesign,sensdesign,'color','blue');
        grid
	legend('Average amplitude PSD','Weighted average amplitude PSD','Location','North')
	titlestr = sprintf('%s %s Average Spectra (%d-%d Hz)',run,ifo,round(bandlo),round(bandhi));
        title(titlestr)
	fnamepdf = sprintf('%s_%s.pdf',fnameroot,bandname)
        print('-dpdf',fnamepdf)
	fnamepng = sprintf('%s_%s.png',fnameroot,bandname)
        print('-dpng',fnamepng)
        hold off
     end
  end

% Make combined-IFO plots using for the full spectrum 
% and for particular (mostly) narrowband regions

%  sprintf('Looping over combined-IFO bands...')
%  for iband = 1:length(combinedbandlolist)  
%     bandlo = combinedbandlolist(iband);
%     bandhi = combinedbandhilist(iband);
%     ylo = combinedylolist(iband);
%     yhi = combinedyhilist(iband);
%     bandname = strtrim(combinedbandnames(iband,:));
%     sprintf('Band = %f-%f Hz',bandlo,bandhi)
%
%     if (combinedplottypelist(iband)==1)
%       plot(freqdesign,sensdesign,'color','blue')
%     elseif (combinedplottypelist(iband)==2)
%       semilogy(freqdesign,sensdesign,'color','blue')
%     elseif (combinedplottypelist(iband)==3)
%       semilogx(freqdesign,sensdesign,'color','blue')
%     elseif (combinedplottypelist(iband)==4)
%       loglog(freqdesign,sensdesign,'color','blue')
%     end
%     xlim([bandlo bandhi])
%     ylim([ylo yhi])
%     titlestr = sprintf('%s Average Spectra (%d-%d Hz)',run,round(bandlo),round(bandhi));
%     title(titlestr)
%     hold on
%
%     for iifo = 1:length(ifolist)
%        color = strtrim(plotcolor(iifo,:));
%        plot(freq{irun,iifo},amppsd{irun,iifo},'color',color)
%        plot(freq{irun,iifo},amppsdwt{irun,iifo},'color',color)
%     end
%	legend('Initial LIGO design','Average H1 amplitude PSD','Weighted average H1 amplitude PSD','Average L1 amplitude PSD','Weighted average L1 amplitude PSD','Location','North')
%     fnameroot = sprintf('%s_combined',run);
%     fnamepdf = sprintf('%s_%s.pdf',fnameroot,bandname)
%     print('-dpdf',fnamepdf)
%     fnamepng = sprintf('%s_%s.png',fnameroot,bandname)
%     print('-dpng',fnamepng)
%     hold off
%   end
%end

% Save key data in .mat file

%frequency = freq{1,1};

%S5H1amppsd = amppsd{1,1};
%S5H1amppsdwt = amppsdwt{1,1};
%S5L1amppsd = amppsd{1,2};
%S5L1amppsdwt = amppsdwt{1,2};

%save ('S5spectradata.mat', 'frequency','S5H1amppsd', 'S5H1amppsdwt', 'S5L1amppsd', 'S5L1amppsdwt');

%S6H1amppsd = amppsd{2,1};
%S6H1amppsdwt = amppsdwt{2,1};
%S6L1amppsd = amppsd{2,2};
%S6L1amppsdwt = amppsdwt{2,2};

%save ('S6spectradata.mat', 'frequency','S6H1amppsd', 'S6H1amppsdwt', 'S6L1amppsd', 'S6L1amppsdwt');
