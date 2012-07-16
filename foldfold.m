clear;
ifo = 'H1';
npart = 8;

%dirname = '/home/Aje8/tconvcurrent';
%dirname = '/home/keithr/folding/H1';
dirname = sprintf('./%s',ifo);

%months_month = ['July     ';'August   ';'September';'October  ';'November ';'December ';'January  ';'February ';'March    ';'April    ';'May      ';'June     ';'July     ';'August   ';'September';'October  '];
%months_year = ['2009';'2009';'2009';'2009';'2009';'2009';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010'];
%months_ndays = [31 31 30 31 30 31 31 28 31 30 31 30 31 31 30 31];

months_month = ['July     ';'August   ';'September';'October  ';'December ';'January  ';'February ';'March    ';'April    ';'May      ';'June     ';'July     ';'August   ';'September';'October  '];
months_year = ['2009';'2009';'2009';'2009';'2009';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010'];
months_ndays = [31 31 30 31 31 31 28 31 30 31 30 31 31 30 31];

%months_month = ['December ';'January  ';'February ';'March    ';'April    '];
%months_year = ['2009';'2010';'2010';'2010';'2010'];
%months_ndays = [31 31 30 31 30 31 31 28 31 30 31 30 31 31 30 31];

%months_month = ['December '; 'January  ';'February ';'March    ';'April    ';'May      ';'June     ';'July     ';'August   ';'September';'October  '];
%months_year = ['2009';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010';'2010'];
%months_ndays = [31 31 28 31 30 31 30 31 31 30 31];

labelsummary = sprintf('All of S6 %s',ifo);
fnamepeakssummary = sprintf('./peakfiles/%s_S6_peaks.txt',ifo);
fnamematsummary = sprintf('./matfiles/%s_S6_sum.mat',ifo);
fnamepdfsummary = sprintf('./pdf/%s_S6_sum.pdf',ifo);
fnamepngsummary = sprintf('./png/%s_S6_sum.png',ifo);

NFFT = 16384;

Fs = 16384;

%nmonth = 16;
%nmonth = 1;
%minmonth = 5;
%maxmonth = 5; 
minmonth = 1;
maxmonth = 15;  

fnameindex = sprintf('index_%s.html',ifo);
fidindex = fopen(fnameindex,'w');
fprintf(fidindex,'<center><h1>Folded plots for %s data in the S6 run</h1>\n<table border=1 cellpadding=5>',ifo);
fprintf(fidindex,'<tr><td><center>Grand summary of folded %s data - all of S6<br><a href="%s">Link to spectral peaks list</a><br><a href="%s">Link to .mat summary file</a><br><a href="%s"><img src="%s"></a>\n',ifo,fnamepeakssummary,fnamematsummary,fnamepdfsummary,fnamepngsummary);
for month = minmonth:maxmonth
   month_name = strtrim(months_month(month,:));
   year_name = strtrim(months_year(month,:));
   fnamehtmlmonth = sprintf('%s_%s.html',month_name,year_name);
   fnamematmonth = sprintf('./matfiles/%s_%s_folded.mat',month_name,year_name);
   fnamepeaksmonth = sprintf('./peakfiles/%s_%s_peaks.txt',month_name,year_name);
   fprintf(fidindex,'<tr><td><center><a href="%s">Day-by-day plots for %s %s</a><br><a href="%s">Link to spectral peaks list</a><br>\n<a href="%s">Link to .mat summary file</a>',fnamehtmlmonth,month_name,year_name,fnamepeaksmonth,fnamematmonth);
   fidhtmlmonth = fopen(fnamehtmlmonth,'w');
   fprintf(fidhtmlmonth,'<center><h1>Folded plots for %s %s </h1>\n<table>\n',month_name,year_name);
   labelmonth = sprintf('%s %s %s',ifo,month_name,year_name);
   fnamepdfmonth = sprintf('./pdf/%s_%s_%s_sum.pdf',ifo,month_name,year_name);
   fnamepngmonth = sprintf('./png/%s_%s_%s_sum.png',ifo,month_name,year_name);
   fprintf(fidindex,'<br><a href="%s"><img src="%s"></a>\n',fnamepdfmonth,fnamepngmonth);
   fprintf(fidhtmlmonth,'<hr><a href="%s"><img src="%s"></a><br>Sum of averages for %s %s %s\n',fnamepdfmonth,fnamepngmonth,ifo,month_name,year_name);
   fprintf(fidhtmlmonth,'<table border=1 cellpadding=5>');
   fprintf('Looping over days in %s %s\n',month_name,year_name);
   fnamepattern = sprintf('%s/%s-*-%s*_1sec.mat',dirname,month_name,year_name);
   dirlist = dir(fnamepattern);
   fprintf('Found %d files matching the pattern: %s\n',length(dirlist),fnamepattern);
   ndayspercol = 5;
   nday = 0;
   colwidth = 100/ndayspercol;
   for day = 1:length(dirlist)
      fnameday = strtrim(dirlist(day).name);
      fnamedayfull = sprintf('%s/%s',dirname,fnameday);
      thisday = load(fnamedayfull);
      nsec = thisday.nkeepfold;
      if (nsec>0)
	 fprintf('   Processing file %s - secondsanalyzed = %d\n',fnameday,nsec);
         nday = nday + 1;
         if (mod(nday,ndayspercol)==1)
	    fprintf(fidhtmlmonth,'<tr>\n');
         end
         thisavg = thisday.avgData;
         thisavgHP = thisday.avgDataHP;
         if (nday==1) 
            sumsec = nsec;
	    sumavg = nsec*thisavg;
	    sumavgHP = nsec*thisavgHP;
         else
            sumsec = sumsec + nsec;
	    sumavg = sumavg + nsec*thisavg;
	    sumavgHP = sumavgHP + nsec*thisavgHP;
         end
         labelday = sprintf('%s',fnameday);
         fnamepeaksday = sprintf('./peakfiles/%s%s_peaks.txt',ifo,fnameday);   
         fnamepdfday = sprintf('./pdf/%s%s.pdf',ifo,fnameday);   
         fnamepngday = sprintf('./png/%s%s.png',ifo,fnameday);   
         fnamehtmlday = sprintf('./%s_%s_%s_Day_%d.html',ifo,month_name,year_name,nday);   
         fidhtmlday = fopen(fnamehtmlday,'w');
         fprintf(fidhtmlday,'<center><h1>Division of %s %s %s Day %d into %d cumulative intervals</h1></center>\n<table>\n',ifo,month_name,year_name,nday,npart);
         status = makeplots(thisday.fract,thisday.avgData,Fs,labelday,fnamepeaksday,fnamepdfday,fnamepngday);
         for ipart = 1:npart
	    labelpart = sprintf('%s %s %s Day %d Part %d of %d',ifo,month_name,year_name,nday,ipart,npart);
	    fnamepeakspart = sprintf('./peakfiles/%s_%s_%s_Day_%d_%d_of_%d_peaks.txt',ifo,month_name,year_name,nday,ipart,npart);
	    fnamepdfpart = sprintf('./pdf/%s_%s_%s_Day_%d_%d_of_%d.pdf',ifo,month_name,year_name,nday,ipart,npart);
	    fnamepngpart = sprintf('./png/%s_%s_%s_Day_%d_%d_of_%d.png',ifo,month_name,year_name,nday,ipart,npart);
            fprintf(fidhtmlday,'<tr><td><center><a href="%s">Link to spectral peaks list</a><br><a href="%s"><img src="%s"></a>\n',fnamepeakspart,fnamepdfpart,fnamepngpart);
            if (ipart==1)
	       partdata = thisday.avgData1;
            elseif (ipart==2)
	       partdata = thisday.avgData2;
            elseif (ipart==3)
	       partdata = thisday.avgData3;
            elseif (ipart==4)
	       partdata = thisday.avgData4;
            elseif (ipart==5)
	       partdata = thisday.avgData5;
            elseif (ipart==6)
	       partdata = thisday.avgData6;
            elseif (ipart==7)
	       partdata = thisday.avgData7;
            elseif (ipart==8)
	       partdata = thisday.avgData;
            end
            status = makeplots(thisday.fract,partdata,Fs,labelpart,fnamepeakspart,fnamepdfpart,fnamepngpart);
         end
         fprintf(fidhtmlday,'</table>');
         fprintf(fidhtmlmonth,'<td width=%d%%><center><a href="%s">Link to part-by-part cumulative plots</a><br><a href="%s">Link to spectral peaks list</a><br><a href="./%s/%s">Link to .mat summary file</a><a href="%s"><img  width=100%% src="%s"></a><br>%s %s\n',colwidth,fnamehtmlday,fnamepeaksday,ifo,fnameday,fnamepdfday,fnamepngday,ifo,fnameday);
      else
	 fprintf('   *Skipping* file %s - secondsanalyzed = %d\n',fnameday,nsec);
      end
   end
   sumavg = sumavg / sumsec;
   status = makeplots(thisday.fract,sumavg,Fs,labelmonth,fnamepeaksmonth,fnamepdfmonth,fnamepngmonth);
   sumavgHP = sumavgHP / sumsec;
   if (month==minmonth)
      sumsumsec = sumsec;
      sumsumavg = sumsec*sumavg;
      sumsumavgHP = sumsec*sumavgHP;
   else
      sumsumsec = sumsumsec + sumsec;
      sumsumavg = sumsumavg + sumsec*sumavg;
      sumsumavgHP = sumsumavgHP + sumsec*sumavgHP;
   end
%   subplot(3,1,1);
%   plot(thisday.fract,sumavg);
%   xlabel('GPS time modulus 1 second');
%   titlestr = sprintf('%s average raw folded data value for all of %s %s',ifo,month_name,year_name);
%   title(titlestr);
%   subplot(3,1,2);
%   plot(thisday.fract,sumavgHP);
%   ymaxHP = max(abs(sumavgHP(1638:16384)));
%   ylim([-ymaxHP ymaxHP]);
%   xlabel('GPS time modulus 1 second');
%   titlestr = sprintf('%s average high-passed folded data value for all of %s %s',ifo,month_name,year_name);
%   title(titlestr);
%   subplot(3,1,3);
%   y = sumavg;
%   Fs = 16384;
%   T = 1/Fs;
%   t = (0:thisday.sfoldSize-1)*T;
%   avgPSD = fft(y,thisday.sfoldSize)/thisday.sfoldSize;
%   avgfreq = Fs/2*linspace(0,1,thisday.sfoldSize/2+1);
%   loglog(avgfreq,2.*abs(avgPSD(1:NFFT/2+1)));
%   xlim([100 8192]);
%   xlabel('Frequency (Hz)');
%   titlestr = sprintf('%s spectrum for raw folded data value for all of %s %s',ifo,month_name,year_name);
%   title(titlestr);
%   print('-dpdf',fnamesummarypdf);
%   print('-dpng',fnamesummarypng);
   fprintf(fidhtmlmonth,'</table></center>');
   fclose(fidhtmlmonth);
   fract = thisday.fract;
   save(fnamematmonth,'fract','sumavg','sumavgHP');
end

sumsumavg = sumsumavg / sumsumsec;
sumsumavgHP = sumsumavgHP / sumsumsec;
status = makeplots(thisday.fract,sumsumavg,Fs,labelsummary,fnamepeakssummary,fnamepdfsummary,fnamepngsummary);
save(fnamematsummary,'fract','sumsumavg','sumsumavgHP');

%subplot(3,1,1);
%plot(thisday.fract,sumsumavg);
%xlabel('GPS time modulus 1 second');
%titlestr = sprintf('%s average raw folded data value for all of S6',ifo);
%title(titlestr);
%subplot(3,1,2);
%plot(thisday.fract,sumsumavgHP);
%ymaxHP = max(abs(sumsumavgHP(1638:16384)));
%ylim([-ymaxHP ymaxHP]);
%xlabel('GPS time modulus 1 second');
%titlestr = sprintf('%s average high-passed folded data value for all of S6 (beyond 0.1 s)',ifo);
%title(titlestr);
%subplot(3,1,3);
%y = sumsumavg;
%Fs = 16384;
%T = 1/Fs;
%t = (0:thisday.sfoldSize-1)*T;
%avgPSD = fft(y,thisday.sfoldSize)/thisday.sfoldSize;
%avgfreq = Fs/2*linspace(0,1,thisday.sfoldSize/2+1);
%loglog(avgfreq,2.*abs(avgPSD(1:NFFT/2+1)));
%xlim([100 8192]);
%xlabel('Frequency (Hz)');
%titlestr = sprintf('%s spectrum for raw folded data value for all of S6',ifo);
%title(titlestr);
%print('-dpdf',fnamegrandsummarypdf);
%print('-dpng',fnamegrandsummarypng);

