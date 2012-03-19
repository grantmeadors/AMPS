classdef ScienceFinder < handle
    % Grant David Meadors
    % 02012-02-28
    
    properties (SetAccess = private)
        segments
        pipe
        s
        time
        finder
        compare
        between
        list
    end
    
    methods
        function T = ScienceFinder(time0, time1)
            % Analyze the start and end times to determine the boundaries
            % of science segments in between
            % Load a list of science segments
            T.segments = load('testSeglist.txt');
            
            % Decide  what type of pipeline to use:
            % T.pipe = 1 for science run S6, T.pipe = 2 for squeezing
            % For future reference,
            % note the size of gwf frame files in seconds
            % T.s = 32 for squeezing data, = 128 for science run S6
            T.pipe = 1;
            if T.pipe == 1
                T.s = 128;
            elseif T.pipe == 2
                T.s = 32;
            end
            
            
            % Input start and stop times
            if isnumeric(time0);
                T.time(1) = time0;
                T.time(2) = time1;
            else
                T.time(1) = str2double(time0);
                T.time(2) = str2double(time1);
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
            
            for ii = length(T.list{1})
                if sum(T.segments(:, 1) == T.list{1}(ii))
                    T.list{3}(ii) = T.segments(T.segments(:,1) == T.list{1}(ii), 3);
                else
                    T.list{3}(ii) = 0;
                end
                if sum(T.segments(:,2) == T.list{2}(ii))
                    T.list{4}(ii) = T.segments(T.segments(:,2) == T.list{2}(ii), 3);
                else
                    T.list{4}(ii) = 0;
                end
            end
            
            % If t0 wasn't in science, then all start times are between t0 & t1
            % If t1 wasn't in science, then all end times are between t0 & t1
            % If it finds no science in between t0 and t1, Matlab will beep
        end
    end
    
end

