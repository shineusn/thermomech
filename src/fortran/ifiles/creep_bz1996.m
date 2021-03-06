function [crp, actEn] = creep_bz1996( nx, nz, fLength, fWidth, zDB, tauratioz, ...
                                      vPl, fs, dSigmaEff_dz )

dx = fLength/nx; % Slip cell length in km
dz = fWidth/nz; % Slip cell depth in km
xDB = fWidth - zDB;

% Creep parameter at zDB. Makes Vcreep = vPl at zDB if tau = fs*Seff at depth
% zDB.
crpzDB = vPl/((fs*dSigmaEff_dz*zDB)^3); % NOTE missing cohesion in original code
%crpzDB = vPl/((fs*( 60 + dSigmaEff_dz*zDB ))^3);

% Get creep parameters according to depth and along strike position
crp = faultcrp( nx, nz, dx, dz, xDB, zDB, crpzDB, tauratioz);

% Add randomness to the creep coefficientds
crp = add_randomness( crp, nx, nz, dx, dz, xDB, zDB, crpzDB, tauratioz  );

% No temperature sensitivity in BZ 1996
actEn = zeros(nz,nx);
end

%------------------------------------------------------------------------------
function crp = faultcrp( nx, nz, dx, dz, xDB, zDB, crpzDB, tauratio)
% Build the creep parameters according to Ben Zion 1996

% Make ratios
zrcrp = 3.0*log(tauratio)/(dz*nz - zDB);
xrcrp = 3.0*log(tauratio)/xDB;

% Get along strike and down dip values
xcell = 0.5*dx + dx*(0:nx-1);
zcell = 0.5*dz + dz*(0:nz-1)';
crpProfile = crpzDB*exp( zrcrp*(zcell - zDB));
crpXsect   = crpzDB*exp( xrcrp*max(xDB - xcell, ...
                                   xcell + xDB - (nx*dx)));

% Build the array based on the max of each
crp = max( repmat( crpProfile, 1, nx), ...
           repmat( crpXsect, nz, 1 ) );

end

%------------------------------------------------------------------------------
function crp = add_randomness( crp, nx, nz, dx, dz, xDB, zDB, crpzDB, tauratio )

% Width of border region that is not adjusted
borderWidth = 3.75;

% Distance from BD transition to use for perturbation
dzPerturb = 1.25;

% Probability of adjustment
probAdjust = 0.2;

% Set the random seed
rand( "state", 1.2345*(1:625)' );

% Ratio
zrcrp = 3.0*log(tauratio)/(nz*dz - zDB);

% Creep strength of brittle region
crpBrittle = crpzDB*exp( -dzPerturb*zrcrp );

% Creep strength of ductile region
crpDuctile = crpzDB*exp( dzPerturb*zrcrp );

% Fault dimensions
faultDepth = nz*dz;
faultLength = nx*dx;

% Calculate depths at the center of each cell
zcell = repmat( 0.5*dz + dz*(0:nz-1)', 1, nx);

% Horizontal positions at center of each cell
xcell = repmat( 0.5*dx + dx*(0:nx-1), nz, 1);

% Generate random numbers
r = rand( nz, nx);

% Keep 20% of the values within bounds
isHit = r <= probAdjust & ...
        zcell < (faultDepth - borderWidth) & ...
        xcell >= borderWidth & xcell < (faultLength - borderWidth);

% Identify creeping parts of the fault
isCreep = zcell >= zDB | xcell <= xDB | xcell >= (faultLength-xDB);

% Give creeping parts a brittle strength
crp( isHit & isCreep ) = crpBrittle;

% Give brittle parts a creep strength
crp( isHit & ~isCreep) = crpDuctile;

end
