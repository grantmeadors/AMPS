classdef Subdivider < handle
    % Grant David Meadors
    % 02012-02-28
    
    properties (SetAccess = private)
        tStart
        tEnd
    end
    
    methods
        function tSub = Subdivider(tSegment)
            % To survive noise non-stationarity, we subdivide the filtering
            % into 1024 second subsections, which we will then fit together.
            % Because they will overlap for 512 seconds with the subsection
            % before and 512 seconds with the subsection after,
            
            % the start of a given science segment is 'tA', the end 'tB'
            tA = tSegment.tA;
            tB = tSegment.tB;
            
            % tStart is a list of start time of the 1024 second subsections,
            % tEnd the end times
            tSub.tStart = [tA; tA + 512*(1:floor((tB - tA)/512))'];
            tSub.tEnd = [tSub.tStart(2:end) + 512; tB];
            
            
            % Check to see if the science segment end before the last
            % 2048 second subsection. If so, cut the subsection short.
            tSub.tEnd(tSub.tEnd > tB) = tB;
            
            
            % Obliterate subsections with zero duration
            tSub.tStart(tSub.tStart == tSub.tEnd) = -1;
            tSub.tEnd(tSub.tStart == -1) = [];
            tSub.tStart(tSub.tStart == -1) = [];
            
            % Obliterate subsections with duration less that 32 s
            tSub.tStart((tSub.tEnd - tSub.tStart) < 32) = -1;
            tSub.tEnd(tSub.tStart == -1) = [];
            tSub.tStart(tSub.tStart == -1) = [];
        end
    end
    
end

