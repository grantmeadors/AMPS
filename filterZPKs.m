% dat = filterZPKs(zs, ps, ks, rate, dat);
%   filter data with filter given by S-domain ZPK
%
% zs, ps, ks = S-domain ZPK parameters
% rate = data rate
% dat = data vectors (Nsample x Nvector)

function dat = filterZPKs(zs, ps, ks, rate, dat)


  [zd, pd, kd] = bilinear(zs, ps, ks, rate);
  [sos, g] = zp2sos(zd,pd,kd);
  g = real(g);
  
  for n = 1:size(dat, 2)
    dat(:, n) = g * sosfilt(sos, dat(:, n));
  end

end
