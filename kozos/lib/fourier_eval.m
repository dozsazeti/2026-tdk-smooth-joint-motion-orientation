function WPR = fourier_eval(p, ang, H)
% FOURIER_EVAL  W,P,R görbe a Fourier-paraméterekből.
%   p   [3*(1+2H) x N]  oszloponként egy egyed;
%                       csatornánként [a0 a1 b1 a2 b2 ...], sorrend W, P, R
%   ang [M x 1]         szögek [deg]
%   WPR [M x 3 x N]
%
%   WPR = fourier_eval(p, ang, H)
%
%   w(th) = a0 + sum_h ( a_h cos(h th) + b_h sin(h th) ),   h = 1..H
%
% -------------------------------------------------------------------------
% MIÉRT FOURIER-SOR?
%   A pálya zárt kör (0° = 360°), ezért az orientációnak is periodikusnak
%   kell lennie: W(0°) = W(360°), és a görbe a záródásnál is törésmentes.
%   A véges Fourier-sor (konstans + H darab cos/sin pár) ezt a felépítése
%   miatt teljesíti, és sima görbét ad. A görbét a kód csak mintavételezi
%   (a kulcspontokban és az LS pontjaiban), nem deriválja.
%   A H (harmonikusok száma) szabja meg, mennyire "hullámos" lehet a görbe:
%   H = 2 -> legfeljebb 2 hullám körönként. Kevés paraméterrel így egy
%   egész körre kiterjedő, sima görbét ír le a GA.
%
% A PARAMÉTEREK SORRENDJE (H = 2 esetén, 3*(1+2*2) = 15 szám egy egyedben):
%   p(1:5)   = W: [a0 a1 b1 a2 b2]
%   p(6:10)  = P: [a0 a1 b1 a2 b2]
%   p(11:15) = R: [a0 a1 b1 a2 b2]
%   a0 = átlagos szög, a_h és b_h = a h-adik harmonikus cos ill. sin
%   amplitúdója [fok].
% -------------------------------------------------------------------------

% A szögeket oszlopvektorrá alakítjuk, hogy a mátrixműveletek méretei
% mindig stimmeljenek (sor- és oszlopvektor bemenetre is működjön).
ang = ang(:);
% Egy csatornára (W, P vagy R) jutó együtthatók száma: 1 konstans + H cos + H sin.
nb = 1 + 2*H;
% B a "bázismátrix": minden sora egy szög, minden oszlopa egy bázisfüggvény
% értéke abban a szögben. Az első oszlop a konstans (a0-hoz tartozó 1-es).
B = ones(numel(ang), nb);
% Végigmegyünk a harmonikusokon (h = 1, 2, ..., H).
for h = 1:H
    % A 2h-adik oszlop a cos(h*th), ehhez az a_h együttható tartozik.
    % cosd = cos fokban megadott szögre (nem kell radiánba váltani).
    B(:, 2*h)   = cosd(h*ang);
    % A (2h+1)-edik oszlop a sin(h*th), ehhez a b_h együttható tartozik.
    B(:, 2*h+1) = sind(h*ang);
end
% Hány egyedet (paramétervektort) értékelünk ki egyszerre: p oszlopainak
% száma. A GA egész populációt ad át, így egy hívással mindet kiszámoljuk.
N = size(p, 2);
% Kimeneti tömb lefoglalása: szögek x 3 csatorna (W,P,R) x egyedek.
WPR = zeros(numel(ang), 3, N);
% A három csatornán (c = 1: W, 2: P, 3: R) külön végigmegyünk.
for c = 1:3
    % p((c-1)*nb + (1:nb), :) kivágja a c-edik csatorna nb együtthatóját
    % minden egyedre (nb x N mátrix). B * (együtthatók) = a görbe értékei
    % minden szögben, minden egyedre (M x N) - ez maga a Fourier-összeg
    % mátrixszorzással. A reshape a 3D tömb c-edik "lapjába" teszi.
    WPR(:, c, :) = reshape(B * p((c-1)*nb + (1:nb), :), numel(ang), 1, N);
end
end
