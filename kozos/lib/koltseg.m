function [J, comp] = koltseg(S, Dn, cfg)
% KOLTSEG  A simasági költségfüggvény. A GA és a RoboGuide-futások
%   kiértékelése is ezt hívja, így a kettő ugyanazt a mennyiséget méri.
%   [J, comp] = koltseg(S, Dn, cfg)
%   S  [3 x 6 x N]  négyzetösszegek (dq/ds, d2q/ds2, d3q/ds3) csuklónként (negyzetosszeg)
%   Dn [3 x 6]      normáló osztók (koltseg_osztok)
%   J  [1 x N]      költség = sum_d lambda_d/sum(lambda) * mean_j S(d,j)/Dn(d,j)
%   comp [3 x N]    deriváltrendenkénti rész (mean_j S/Dn), az 1., 2., 3. derivált külön
%
% Az Alap költsége a 'korlat' normálásnál pontosan 1 (az osztókat úgy
% választjuk), ezért egy megoldás költsége közvetlenül az Alaphoz viszonyított
% arány, pl. J = 0.45 azt jelenti, hogy 55%-kal kisebb.
%
% -------------------------------------------------------------------------
% A KÉPLET SZAVAKBAN:
%   1. minden csukló minden deriváltrendjének négyzetösszegét elosztjuk a
%      hozzá tartozó osztóval (Dn), így a csuklók közös skálára kerülnek;
%   2. a 6 csuklóra átlagolunk;
%   3. a 3 deriváltrendet lambda szerint súlyozva összeadjuk
%      (a lambda-kat 1-re normáljuk, így csak az arányuk számít).
%   Mivel ugyanez a függvény értékeli a GA-t és a RoboGuide-futást is,
%   a becsült és a mért javulás közvetlenül összevethető.
% -------------------------------------------------------------------------

% Egyedek (vagy futások) száma.
N = size(S, 3);
% Relatív értékek: S osztva Dn-nel elemenként. A repmat a [3 x 6] osztót
% N példányban egymás mögé teszi, hogy minden egyedre ugyanazzal osszunk.
R = S ./ repmat(Dn, [1 1 N]);
% Átlag a 6 csuklóra (2. dimenzió) -> deriváltrendenkénti rész [3 x N].
comp = reshape(mean(R, 2), 3, N);
% A lambda-súlyok normálása (összegük 1); a [0.2 0.3 0.5] már 1 összegű.
lam = cfg.cost.lambda(:) / sum(cfg.cost.lambda);
% Súlyozott összeg a 3 deriváltrendre -> egy szám egyedenként [1 x N].
J = sum(comp .* repmat(lam, 1, N), 1);
end
