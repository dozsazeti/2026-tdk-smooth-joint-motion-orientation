function seed_rng(s)
% SEED_RNG  A véletlenszám-generátor kezdőértékének (seed) beállítása.
%   seed_rng(s)
%   Ugyanazzal a seeddel a GA pontosan ugyanazt a "véletlen" sorozatot
%   kapja, így egy futás bármikor számjegyre megismételhető. MATLAB és
%   Octave alatt más a parancs, ezért megnézzük, melyikben fut a kód.
if exist('OCTAVE_VERSION', 'builtin')
    rand('twister', s); randn('state', s);  %#ok<RAND>
else
    % MATLAB: az rng egyszerre állítja a rand, randn és randi generátorát.
    rng(s);
end
end
