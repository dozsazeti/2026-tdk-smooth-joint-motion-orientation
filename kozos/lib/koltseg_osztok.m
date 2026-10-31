function Dn = koltseg_osztok(S_alap, cfg)
% KOLTSEG_OSZTOK  Normalizáló osztók a költségfüggvényhez.
%   Dn = koltseg_osztok(S_alap, cfg)
%   S_alap [3 x 6]  az Alap négyzetösszegei (negyzetosszeg)
%   Dn     [3 x 6]  osztók: sor = deriváltrend, oszlop = csukló
%   Két változat (cfg.cost.norm, a config.m-ben választható):
%
%   'korlat' (a dolgozat eredményei ezzel készültek):
%     A csuklók EGYMÁSHOZ viszonyított súlyát a mért korlátok adják
%     (cfg.cost.lim.v / .a / .j). Deriváltrendenként:
%         Dn(d, j) = c_d * L(d, j)^2
%     ahol L(d, j) a j-edik csukló korlátja (d = 1 sebesség, 2 gyorsulás,
%     3 jerk), c_d pedig egy deriváltrendenkénti szorzó, amely úgy van
%     beállítva, hogy az Alap minden deriváltrendben pontosan 1-et adjon.
%     Így az Alap költsége 1, és a %-os javulás ugyanúgy értelmezhető.
%
%   'alap' (összehasonlításra megtartott változat):
%     - J1,J2,J3,J5,J6: saját Alap-érték (padlóval védve)
%     - J4 'atlag': a többi öt csukló Alap-értékének átlaga
%     - J4 'padlo': saját Alap-érték, padlóval
%
% -------------------------------------------------------------------------
% MIÉRT A KORLÁT NÉGYZETE?
%   S(d, j) a d-edik derivált NÉGYZETÉNEK integrálja a körön. Ha ezt a korlát
%   négyzetével osztjuk, akkor azt kapjuk, hogy a csukló deriváltja átlagosan
%   mekkora a saját korlátjához képest (négyzetesen). Egy csukló, amelyik
%   közelebb jár a saját korlátjához, többet számít; egy gyors csukló (pl. a
%   J6, nagy korláttal) ugyanakkora mozgásnál kevesebbet.
% MIÉRT NEM KELL A PÁLYASEBESSÉG?
%   A költség ívhossz szerinti deriváltakkal számol (dq/ds, d2q/ds2,
%   d3q/ds3), a korlátok idő szerintiek. Állandó v pályasebességnél
%   d^d q/dt^d = v^d * d^d q/ds^d, vagyis az átváltás deriváltrendenként
%   egy közös szorzó (v^d), ami minden csuklóra ugyanaz. Ezt a c_d szorzó
%   elnyeli, ezért az eredmény nem függ attól, mekkora v-t veszünk.
% MI LESZ A J4-GYEL?
%   Az Alapban a J4 szinte nem mozdul, ezért az 'alap' normálásnál a J4
%   osztója ~0 lenne, emiatt kell ott a külön 'atlag' / 'padlo' kezelés.
%   A 'korlat' normálásnál a J4 súlyát a saját (nem nulla) korlátja adja,
%   ezért külön kezelés nem kell.
% -------------------------------------------------------------------------

switch cfg.cost.norm
    case 'korlat'
        % A korlátok egy 3 x 6-os mátrixban: sorok = deriváltrend, oszlopok = csukló.
        L = [cfg.cost.lim.v(:)'; cfg.cost.lim.a(:)'; cfg.cost.lim.j(:)'];
        assert(isequal(size(L), [3 6]) && all(L(:) > 0), ...
            'A cfg.cost.lim.v/.a/.j mind 6 elemű, pozitív vektor legyen.');
        Dn = zeros(3, 6);
        for d = 1:3
            % Csuklónkénti súly: 1 / korlát^2.
            w = 1 ./ L(d, :).^2;
            % A szorzó úgy, hogy az Alap ebben a deriváltrendben 1-et adjon:
            % mean_j( S_alap(d,j) / Dn(d,j) ) = 1.
            c = mean(S_alap(d, :) .* w);
            assert(c > 0, 'Az Alap %d. deriváltja minden csuklóra 0.', d);
            Dn(d, :) = c ./ w;
        end

    case 'alap'
        % A J4 indexe a csuklók között (4).
        j4 = cfg.cost.j4_index;
        % A többi csukló indexei: [1 2 3 5 6].
        others = setdiff(1:6, j4);
        % Kiindulás: az osztó = az Alap saját négyzetösszege, ezt módosítjuk lent.
        Dn = S_alap;
        % Deriváltrendenként (1., 2., 3.) külön osztók.
        for d = 1:3
            % Padló: a többi öt csukló mediánjának 5%-a (floor_rel = 0.05).
            fl = cfg.cost.floor_rel * median(S_alap(d, others));
            % A nem-J4 csuklók osztója: saját Alap-érték, de legalább a padló.
            Dn(d, others) = max(S_alap(d, others), fl);
            % A J4 osztójának választása a config szerint.
            switch cfg.cost.j4_weight
                case 'atlag'
                    Dn(d, j4) = mean(Dn(d, others));
                case 'padlo'
                    Dn(d, j4) = max(S_alap(d, j4), fl);
                otherwise
                    error('Ismeretlen J4 súlyozás: %s', cfg.cost.j4_weight);
            end
        end

    otherwise
        error('Ismeretlen normálás: %s (''korlat'' vagy ''alap'')', cfg.cost.norm);
end
end
