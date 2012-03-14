function Hoft = segmentDivider(time0, time1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eleutheria
% Grant Meadors
% gmeadors@umich.edu
% 2011-11-01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% supplies science times to feedforward function
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    function T = scienceFinder(time0, time1)
        % Analyze the start and end times to determine the boundaries
        % of science segments in between
        % Load a list of science segments
        T.segments = load('seglist.txt');
        % Input start and stop times
        if isnumeric(time0);
            T.time(1) = time0;
            T.time(2) = time1;
        else
            T.time(1) = str2num(time0);
            T.time(2) = str2num(time1);
        end        

        % Find out whether t0 and t1 are in science mode or not
        % T.finder finds the last science segment (s) 
        % start (n=1) and end (n=2) times before a given time (t)
        T.finder = @(n, t, s) s(find(s(:, n) <= t, 1, 'last'), n);
        % T.compare returns Boolean 1 if the last science segment (s) start
        % before a given time (t) was after the last segment end -- meaning
        % that the time (t) is in science -- and 0 if outside of science.
        T.compare = @(t, s) T.finder(1, t, s) > T.finder(2, t, s);            
        
        % Find out about all the times in segment (s) between t(1) and t(2)
        % returns a list of science start times if n=1, end times if n=2
        T.between = @(n, t, s) s(t(1) <= s(:,n) & s(:,n) <= t(2), n);
        
        % Produce a list of science segment start (n=1) and stop (n=2)
        % times based on a segment list (s) between times t(1) and t(2)
        % If in science (T.compare returns 1), then concatenate t(n) with
        % the list of times returned by T.between. If outside of science,
        % just use the science segments in between.

        T.list = cell(2, 1);
        T.list{1} = unique(T.between(1, T.time, T.segments));
        T.list{2} = unique(T.between(2, T.time, T.segments));
        if T.compare(T.time(1), T.segments)
            T.list{1} = unique([T.time(1); T.list{1}]);
        end
        if T.compare(T.time(1), T.segments)
            T.list{2} = unique([T.list{2}; T.time(2)]);
        end  
        
        % If t0 wasn't in science, then all start times are between t0 & t1
        % If t1 wasn't in science, then all end times are between t0 & t1
        % If it finds no science in between t0 and t1, Matlab will beep
    end

    function tSub = subdivider(tSegment)
        % To survive noise non-stationarity, we subdivide the filtering
        % into 1024*16 second subsections, which we will then fit together.
        % Because they will overlap for 512*2 seconds with the subsection 
        % before and 512*2 seconds with the subsection after, 

        %16*1024 s is about 4.55 hours
        
        % the start of a given science segment is 'tA', the end 'tB'
        tA = tSegment.tA;
        tB = tSegment.tB;
        
        % tStart is a list of start time of the 16*512 second subsections,
        % tEnd the end times
        tStart = [tA; tA + (32*512)*(1:floor((tB - tA)/(32*512)))'];
        % Instead of fifty percent overlap (via 32*512), overlap for 1024 s
        tEnd = [tStart(2:end) + (2*512); tB];

        
        % Check to see if the science segment ends before the last
        % 16*1024 second subsection. If so, cut the subsection short.
        tStart(tStart > tB) = tB;
        tEnd(tEnd > tB) = tB;
        


        % Obliterate subsections with zero duration
        tStart(tStart == tEnd) = -1;
        tEnd(tStart == -1) = [];
        tStart(tStart == -1) = [];
        
        % Set two column vectors to indicate whether this subsegment is
        % preceded or followed by another
        
        tIsPreceded = [0; ones((length(tStart)-1), 1)];
        tIsFollowed = [ones((length(tEnd)-1), 1); 0];
        
        
        % Assign the list of subsection starts and ends to output
        tSub.tStart = tStart;
        tSub.tEnd = tEnd;
        tSub.tIsPreceded = tIsPreceded;
        tSub.tIsFollowed = tIsFollowed;
    end

    function segmentHoft = windower(T)
        
        % find the subdivision times for the specific segment
        
        fullSeglist{1} = [];
        fullSeglist{2} = [];
        fullSeglist{3} = [];
        fullSeglist{4} = [];

        % by looking at an 'ii'th element of 't.startlist'
        %for ii = 1:100
           
        for ii = 1:length(T.list{1})
            tSegment.tA = T.list{1}(ii);
            tSegment.tB = T.list{2}(ii);
            tSub = subdivider(tSegment);
            
            fullSeglist{1} = [fullSeglist{1}; tSub.tStart];
            fullSeglist{2} = [fullSeglist{2}; tSub.tEnd];
            fullSeglist{3} = [fullSeglist{3}; tSub.tIsPreceded];
            fullSeglist{4} = [fullSeglist{4}; tSub.tIsFollowed];
            
            clear tSegment
            clear tSub
        end
        
        
        
        fullSeglistMat = cell2mat(fullSeglist);
        dlmwrite('dividedSeglist.txt', fullSeglistMat, 'precision', 9);
        

        
    end
        
    T = scienceFinder(time0, time1);
    windower(T);
end
