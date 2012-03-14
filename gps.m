% GPS just runs the ligotool tconvert on the 
% optional argument STRING
%
% with no string it returns the current gps second
%
% for tconvert help do gps(' ')

function GPSNumber = gps(s)

if nargin==0
    [a,b] = unix([ ' ' getenv('LIGOTOOLS') '/bin/tconvert now' ]);
else
    [a,b] = unix([ ' ' getenv('LIGOTOOLS') '/bin/tconvert ' s ]);
end

GPSNumber = str2double(regexp(b, '\d{9}', 'match'));

return;

