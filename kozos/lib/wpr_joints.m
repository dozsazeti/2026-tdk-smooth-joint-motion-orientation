function [Qk, badk, outk] = wpr_joints(G, WPR)
% WPR_JOINTS  Csuklószögek a kulcspontokban adott W,P,R értékekhez
%             (trilineáris interpoláció a rácson), egész populációra.
%   [Qk, badk, outk] = wpr_joints(G, WPR)
%   G    a rács (cand_beolvas vagy k2_beolvas kimenete)
%   WPR  [K x 3 x N]   W,P,R (a rács koordinátáiban, vagyis eltérésként)
%                      a K kulcspontban, N egyedre
%   Qk   [K x 6 x N]   interpolált J1..J6
%   badk [K x N]       "rosszság" 0..1 (szingularitás / átfordulás közelsége)
%   outk [K x N]       rácson kívüli túllépés [deg] (0 = rendben)
%
% -------------------------------------------------------------------------
% MIÉRT INTERPOLÁCIÓ?
%   A RoboGuide IK-t csak a rácspontokban futtattuk le (pl. ±45°, 3°-os
%   lépés -> 31^3 = 29 791 W,P,R kombináció kulcspontonként). A GA viszont
%   tetszőleges (nem rácsra eső) W,P,R értéket kérhet. A trilineáris
%   interpoláció a W,P,R-t körülvevő kocka 8 sarkának csuklószögeiből
%   súlyozott átlagot képez -> folytonos becslés a rácspontok között.
% -------------------------------------------------------------------------

% Rövid nevek: K kulcspont, n rácspont tengelyenként, g0 a rács eleje
% (pl. -45), h a lépésköz (pl. 3), gmax a rács vége (pl. +45).
K = G.K;  n = G.n;  g0 = G.grid(1);  h = G.step;  gmax = G.grid(end);
% Egyedek száma.
N = size(WPR, 3);

% Átrendezés: minden (kulcspont, egyed) pár egy sor, oszlopok: W, P, R.
% Így az interpolációt egyszerre, vektorosan végezzük minden párra.
X = reshape(permute(WPR, [1 3 2]), K*N, 3);          % sorok: (k, egyed)
% Minden sorhoz, melyik kulcspontról van szó (1..K, N-szer ismételve).
kk = repmat((1:K)', N, 1);

% Rácson kívüli túllépés: |W|, |P|, |R| mennyivel nagyobb a rács határánál
% (0, ha belül van). Összegezve a 3 szögre, kulcspontonként és egyedenként.
% (A rács szimmetrikus, ±gmax, ezért elég az abszolút értéket nézni.)
outk = reshape(sum(max(0, abs(X) - gmax), 2), K, N);
% A kilógó értékeket a rács szélére "vágjuk", hogy az interpoláció ne
% indexeljen a rácson kívülre. A kilógást a büntetés (outk) kezeli.
X = min(max(X, g0), gmax);

% Folytonos rácsindex: hányadik lépésnél tartunk a rács elejétől
% (pl. W = -40.5, g0 = -45, h = 3 -> u = 1.5).
u = (X - g0) / h;
% A cella bal alsó sarkának indexe (0-alapú). Legfeljebb n-2, hogy a
% "+1"-es szomszéd még a rácson belül legyen (a felső szélen is).
i = min(floor(u), n-2);            % 0-alapú cellaindex
% Hol vagyunk a cellán belül tengelyenként: 0 = bal sarok, 1 = jobb sarok.
t = u - i;

% A kulcspont blokkjának kezdete a G.V táblában: minden kulcsponthoz n^3
% sor tartozik (az összes W,P,R kombináció), egymás után.
base = 1 + n^3*(kk-1);
% Gyűjtő: 6 csuklószög + 1 "rossz" jelző súlyozott összege.
acc = zeros(K*N, 7);
% A cella 8 sarkán megyünk végig. A c szám 3 bitje mondja meg, hogy a
% W, P, R tengelyen a bal (0) vagy jobb (1) sarkot vesszük.
for c = 0:7
    % b = [W-bit P-bit R-bit], pl. c = 5 -> b = [1 0 1].
    b = [bitand(c,1) bitand(c,2)/2 bitand(c,4)/4];
    % A sarok súlya: tengelyenként t (ha jobb sarok) vagy 1-t (ha bal),
    % a három szorzata. A 8 súly összege mindig 1.
    w = prod((b .* t) + ((1-b) .* (1-t)), 2);
    % A sarok sorindexe a G.V táblában (ugyanaz a képlet, mint a
    % cand_beolvas-ban: iW + n*(iP-1) + n^2*(iR-1) + n^3*(k-1)).
    lin = base + (i(:,1)+b(1)) + n*(i(:,2)+b(2)) + n^2*(i(:,3)+b(3));
    % Súlyozott hozzáadás: a sarok 6 csuklószöge és "rossz" jelzője.
    acc = acc + w .* G.V(lin, :);
end

% Vissza az eredeti alakba: K kulcspont x 6 csukló x N egyed.
Qk   = permute(reshape(acc(:,1:6), K, N, 6), [1 3 2]);
% A "rossz" jelző interpolált értéke: 0 = minden sarok jó, 1 = mind rossz,
% közte arányosan. Így a büntetés is folytonos, a GA "érzi" a közeledést.
badk = reshape(acc(:,7), K, N);
end
