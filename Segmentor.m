classdef Segmentor < handle
    % Extracts proper window times for a given science segment
    % Grant David Meadors
    % 02012-02-29
    
    properties (SetAccess = private)
        tA
        tB
        tIsPreceded
        tIsFollowed
    end
    
    methods
        function tSegment = Segmentor(T, ii)
            % find the subdivision times for the specific segment
            
            % by looking at an 'ii'th element of 't.startlist'
            tSegment.tA = T.list{1}(ii);
            tSegment.tB = T.list{2}(ii);
            tSegment.tIsPreceded = T.list{3}(ii);
            tSegment.tIsFollowed = T.list{4}(ii);
            
            disp(strcat('Beginning science segment ... ', num2str(ii)))
            % apply the subdivider to that specific segment,
            % which gives thirty-minute subsections out to tsub.
        end
    end
    
end

