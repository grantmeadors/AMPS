function Hoft = aletheia(t0, t1, addenda)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% aletheia
% Grant David Meadors
% gmeadors@umich.edu
% 02012-02-28
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generates a true feedforward filter for MICH->DARM at time 't0'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% A typical start time in LIGO Hanford Observatory during S6
% t0 = gps('2010-03-21 00:00:00');


Hoft = Feedforward(t0, t1, addenda);


end
