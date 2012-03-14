function R = InspiralRange(F_temp,H_temp)
% INSPIRALRANGE  Range in kiloparsecs to which a binary inspiral can be detected
%
%    R = INSPIRALRANGE(F,H) returns the average effective range to which a 
%    gravitational-wave detector with strain noise amplitude spectral 
%    density of modulus H evaluated at frequencies F can detect the inspiral 
%    of a pair of 1.4-1.4 solar-mass neutron stars with SNR > 8.
%
%    Requirements:
%      1) H has no zero values.
%      2) F, H are the same size.
%
%    Warnings:
%      1) The ranges reported by INSPIRALRANGE are consistently 10% smaller 
%         than those reported by SenseMonitor when run on the SenseMonitor
%         calibrated PSD dump files.  This appears to be due to the averaging 
%         over multiple frequency bins which is done in making the dump files.
%         Since the range varies inversely with the amplitude spectral density 
%         of the noise, averaging over frequency bins before calculating the 
%         range will tend to lower the range estimate.
%    
%    Conventions:
%      The range reported is that obtained by averaging over sky directions 
%      and orientations of the binary, which is the same convention as used 
%      by SenseMonitor.  To convert to some other conventions do this:
%
%            Inspiral Group:  Multiply the reported range by 2.26
%                      TAMA:  Multiply the reported range by 1.60
%
%    author: Patrick J. Sutton (2003/03/31)

%----- The range is given by 
%
%        R = THETA * R_0 
%
%      where theta = 1.77 by default; this is the SenseMonitor range 
%      convention.  The important conventions are
%
%        THETA = sqrt(16)   = 4     (Inspiral Group convention)
%        THETA = sqrt(8)    = 2.83  (TAMA convention)
%        THETA = sqrt(3.12) = 1.77  (SenseMonitor convention)
%
%      The quantity R_0 in kiloparsecs (kpc) is given by 
%
%        R_0 = ( (5 C^1/3 CHM^5/3 F_7_3)/(96 pi^4/3 SNR_0) )^1/2 / METER_PER_KILOPARSEC
%
%      where  
%      
%        CHM = chirp mass of binary = G/C^2 M0 (M1 M2)^3/5 (M1+M2)^(-1/5)
%        G = Newtonian gravitational constant = 6.67e-11
%        C = speed of light = 2.998e8 m/s  
%        M0 = mass of sun = 2e30 kg
%        M1, M2 = masses of binary components in solar masses M0 = 1.4
%        SNR_0 = threshold signal-to-noise ratio for detection = 8
%        F_7_3 = \int_Fmin^Fmax dF F^(-7/3) H(F)^(-2)
%        Fmin = Lowest frequency for which H(F) is available (default 0)
%        Fmax = Highest frequency below FISCO for which H(F) is available
%        FISCO = (6^1.5*pi*(M1+M2)*M0*G/C^3)^(-1);
%              = (6^1.5*pi*2.8*4.92549095e-6)^(-1);
%              = 1570 (Hz)
%        METER_PER_KILOPARSEC = 3.086e19;
%
%      Note that G*M0/C^3 = 4.92549095e-6 seconds.


%----- Evaluate fixed parameters.
THETA = 1.77;
M0 = 1.989e30;
M1 = 1.4;
M2 = 1.4;
G = 6.67e-11;
C = 299792458;
CHM = G/C^2*M0*(M1*M2)^(3/5)*(M1+M2)^(-1/5);
SNR_0 = 8;
FISCO = (6^1.5*pi*(M1+M2)*M0*G/C^3)^(-1);
% Using 1400Hz makes no difference for S2 LIGO data.
METER_PER_KILOPARSEC = 3.086e19;


%----- Extract that part of spectrum below FISCO.
indices = find(F_temp<FISCO);
F = F_temp(indices);
H = H_temp(indices);


%----- Interpolate to evenly-spaced integer frequencies.
%      Note that this sort of averaging can lower the range estimate.
%      In one example (H1_...404.txt) changed range from 400->390
%      while SenseMon reported 431.
f = [ceil(F(1)):floor(F(end))];
h = interp1(F,H,f);
F = f;
H = h;

%----- Evaluate F_7_3.
integrand = (F.^(-7/3)).*(H.^(-2));
F_7_3 = (F(2)-F(1))*sum(integrand);

%----- Compute range.
%R_0 = (( (5*C^(1/3)*CHM^(5/3)*F_7_3)/(96*pi^(4/3)*SNR_0^2) )^(1/2))/METER_PER_KILOPARSEC
%R = THETA*R_0


%R2 = THETA^2*5.0*CHM^(5.0/3.0)*F_7_3/(96.0*pi^(4.0/3.0)*SNR_0^2)/METER_PER_KILOPARSEC^2
%R = R2^0.5

R = THETA*( 5.0*C^(1.0/3.0)*CHM^(5.0/3.0)*F_7_3/(96.0*pi^(4.0/3.0)*SNR_0^2) )^(0.5)/METER_PER_KILOPARSEC;


