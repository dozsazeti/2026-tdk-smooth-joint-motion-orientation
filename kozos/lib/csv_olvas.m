function [M, hdr] = csv_olvas(fname)
% CSV_OLVAS  Fejléces, vesszővel tagolt CSV beolvasása.
%   [M, hdr] = csv_olvas(fname)
%   M   - a számadatok mátrixa (a fejléc nélkül)
%   hdr - az oszlopnevek cellatömbje (az első sorból)
fid = fopen(fname, 'r');
% Ha a fájl nem létezik, a fid -1, ezért érthető hibával megállunk.
assert(fid > 0, 'Nem található: %s', fname);
% Az első sor a fejléc: vesszőnél szétvágva, a szóközök levágva.
hdr = strtrim(strsplit(fgetl(fid), ','));
fclose(fid);
% A számok beolvasása a 2. sortól (1 sor kihagyása), vesszővel tagolva.
M = dlmread(fname, ',', 1, 0);
end
