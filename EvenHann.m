function output = EvenHann(x)

% Grant David Meadors
% gmeadors@umich.edu
% 02012-05-08

% Even Hann: produces a Hann window with the even-handed properties
% of triang, namely that an input of EvenHann(2*halfLength) produces
% an output for which output(n) + output(halfLength+n) = 1 for all
% n from 1 to halfLength. Moreover, the output is never zero and is
% symmetrical about halfLength, i.e., output(1:halfLength) =...
% flipud(halfLength+1:end)

% Note that this window is designed only for even lengths of x.

% Make a hann window of length x+3:
basicHann = hann(x+3);

% Discard the first, middle and last indices and concatenate:
output =...
    [basicHann(2:floor((x+3)/2)); basicHann(floor((x+3)/2)+2:end-1)];

end

