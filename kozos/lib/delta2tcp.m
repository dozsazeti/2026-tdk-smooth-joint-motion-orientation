function WPR = delta2tcp(D, cfg)
% DELTA2TCP  Orientáció-eltérés (dW, dP, dR) -> a robotnak szóló W, P, R.
%   WPR = delta2tcp(D, cfg)
%   D   [N x 3]  eltérés [fok] az alapálláshoz (cfg.tool.alap_wpr) képest
%   WPR [N x 3]  W, P, R [fok] a tool frame-re; ez kerül a CAND.TXT-be és
%                az LS programokba
%
%   WPR = cfg.tool.alap_wpr + D
%   Az eltérés egyszerűen hozzáadódik az alapállás W, P, R szögeihez (UT 3-mal
%   180 / 0 / -90, vagyis lefelé néző szerszám). A dW, dP, dR tehát a robot
%   saját W, P, R szögeinek változása, mátrixos átszámolás nincs benne.
%
%   Az alapállás W-je 180 fok, ezért a ±45 fokos rács átlépi a ±180 fokot.
%   A kiírt értéket a FANUC által használt tartományba (-180 < x <= 180)
%   hozzuk, pl. 183 -> -177; ez ugyanazt a szöget jelenti. A GA és a
%   rácsfájlok (CAND.csv, CAND2.csv) a folytonos eltéréssel dolgoznak, őket
%   ez az átfordulás nem érinti.
WPR = cfg.tool.alap_wpr + D;           % alapállás + eltérés (soronként)
WPR = mod(WPR + 180, 360) - 180;       % -> [-180, 180)
WPR(abs(WPR + 180) < 1e-9) = 180;      % -180 helyett 180 (a FANUC így írja)
WPR = round(WPR * 1e6) / 1e6;          % numerikus zaj levágása
WPR(WPR == 0) = 0;                     % -0 -> 0
end
