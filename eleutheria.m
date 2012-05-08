function complete = eleutheria(time0, time1, inputFileDARM, inputFileNOISE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eleutheria
% Grant David Meadors
% gmeadors@umich.edu
% 02012-05-08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% supplies science times to feedforward function
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    

    function segmentHoft = windower(T, ii, inputFileDARM, inputFileNOISE)
        
        tSegment = Segmentor(T, ii);
        tSub = Subdivider(tSegment);
        
        
        % Initialize Hoft
        Hoft = HoftEditor(T, tSegment, tSub, inputFileDARM);
        
        
        % Create the addenda object as a messenger for data
        addenda = AddendaEditor(ii, 0, T.pipe, T.s,...
            inputFileDARM, inputFileNOISE, 0,...
            0, 0, Hoft.site);
        
        % Filter the first 1024 s subsection for MICH
        Hoft.initialMICH(T, tSub, addenda);
        
        % Then filter for PRC
        Hoft.initialPRC(T, tSegment, tSub, addenda);
        
        clear addenda
        
        % Write initial frames
        Hoft.initialFrameWriter(T, tSegment, tSub)
        

        % Move on to the next subsection
        % In the future, one might vectorize this for loop,
        % But since each subsection consumes about 16384*2048*8 bytes
        % = 268 MB / (2048 s) = 472 MB / hour (9 hour / (4 GB)),
        % and each subsection involves disk access, which will potentially
        % conflict with disk access of the adjoining subsections at the
        % boundaries, this may be risky. We do things serially for now,
        % using less memory and being good grid citizens at the cost of
        % taking longer to finish
        
        % Combine the filtered data in a weighted average
        for jj = 2:length(tSub.tStart)
            % Iterate through the remaining subsections
            % in the science segment
            % Generate a new MICH-filtered subsection
            
            
            addenda = AddendaEditor(0, 0, T.pipe, T.s,...
                inputFileDARM, inputFileNOISE, 1, 0, 0,...
                Hoft.site);
            

            % To be sure, clear all remaining large variables
            % That should have been written into addenda
            clear Hoft.passMICH
            clear Hoft.passPRC
            clear Hoft.passDARM
            
            Hoft.loopMICH(T, tSub, addenda, jj)
            Hoft.loopPRC(T, tSegment, tSub, addenda, jj)
            
            clear addenda
            
            % Clear data
            Hoft.clearer(T, tSub, jj);
             
            
        end
        
        % If successful, return 0
        segmentHoft = 0;
    end

    function allHoft = filterer(time0, time1, inputFileDARM, inputFileNOISE)
        T = ScienceFinder(time0, time1);
        % Now we run the filter on each science segment,
        % subdividing it into thirty minute segments of data and average
        % linearly in "triangular windows"

        
        segmentHoft = 0;
        for ii = 1 % Do not iterate unless for special debugging purposes :length(T.list{1})
            % This is just a check bit that will be 0 if all's well
            segmentHoft = segmentHoft + windower(T, ii, inputFileDARM, inputFileNOISE);
        end
        % Return allHoft = 0 if successful
        allHoft = segmentHoft;
    end


    % Assign "allHoft" from "windower" to the overall output, "Hoft",
    % which we return 0 if successful
    tic
    complete = filterer(time0, time1, inputFileDARM, inputFileNOISE);
    disp('Science segment feedforward complete')
    toc
    
    close all
    clear all
    complete = 0;

end
