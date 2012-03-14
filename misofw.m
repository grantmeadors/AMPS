function varargout = misofw(N,X,y)
% MISOFIRWIENER Optimal FIR Wiener filter for multiple inputs.
%   MISO_FIRWIENER(N,X,Y) computes the optimal FIR Wiener filter of order
%   N, given any number of (stationary) random input signals as the columns
%   of matrix X, and one output signal in column vector Y.

%   Author: Keenan Pepper
%   Last modified: 2007/08/02

%   References:
%     [1] Y. Huang, J. Benesty, and J. Chen, Acoustic MIMO Signal
%     Processing, Springer-Verlag, 2006, page 48

if nargin == 3
  % Number of input channels.
  M = size(X,2);
else
  error('Needs 3 input arguments.')
end

% Input covariance matrix.
R = zeros(M*(N+1),M*(N+1));
for m = 1:M
    for kk = m:M
        rmi = xcorr(X(:,m),X(:,kk),N);
        Rmi = toeplitz(flipud(rmi(1:N+1)),rmi(N+1:2*N+1));
        top = (m-1)*(N+1)+1;
        bottom = m*(N+1);
        left = (kk-1)*(N+1)+1;
        right = kk*(N+1);
        R(top:bottom,left:right) = Rmi;
        if kk ~= m
            R(left:right,top:bottom) = Rmi';  % Take advantage of hermiticity.
        end
    end
end

% Cross-correlation vector.
P = zeros(1,M*(N+1));
for kk = 1:M
    top = (kk-1)*(N+1)+1;
    bottom = kk*(N+1);
    p = xcorr(y,X(:,kk),N);
    P(top:bottom) = p(N+1:2*N+1)';
end

% Uses \ instead of / to avoid taking the matrix inverse.
WW = P/R;
%WW = P'\R;

if nargout > 0
  varargout{1} = WW;
  if nargout == 3
    varargout{2} = R;
    varargout{3} = P;
  end
else
  error('Must have at least 1 output argument.')
end



