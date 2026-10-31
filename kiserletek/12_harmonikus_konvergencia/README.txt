KISERLET 12: HARMONIKUS-KONVERGENCIA MELEG INDITASSAL (v10)
  Kerdes: ha a Fourier-sor harmonikusszamat (H) noveljuk, es a GA mindig az
  elozo H legjobb megoldasabol indul, ugyanahhoz a megoldashoz konvergal-e?
  Ha a magasabb harmonikusok nem segitenek: a koltseg platora fut, az also
  rendu egyutthatok alig valtoznak, az uj harmonikusok amplitudoja ~0.
  (A temavezeto v29-es megjegyzese a 3.3 "A harmonikusok szama" reszhez.)

  A) Letapogatas (GA nelkul): az elozo optimumon minden mas egyutthatot
     rogzitve az uj harmonikus (a_H, b_H) sikja racson vegigszamolva.
  B) Lanc: H = 2 (a fo futas opt1-enek finomitasa) -> 3 -> 4 -> 5.
  Minden lepes: 8 inditas, a kezdo populacio 1. egyede az elozo optimum
  (az uj egyutthatok 0-val), a GA a regi egyutthatokat +-1, az ujat +-3 fokos
  ablakban keresi, korai leallas nelkul (300 generacio).
  Az elitizmus miatt egy lepes sem lehet rosszabb az elozonel.
  H = 6 felett 12 kulcspontnal nincs ertelme (sin(6*th) = 0 minden kulcspontban,
  a magasabb harmonikusok alacsonyabbakra kepezodnek le).

  Beallitas:  kozos\config_kis12.m  (H_lista, ablak_regi, ablak_uj)
  Futtatas:   k1_harmonikus_konvergencia.mlx
  Elotte kell: a fo futas 01_racs (CAND2.csv) es 02_ga_durva (opt_osszesites.csv)
  Kimenet:    eredmenyek\<tag>\  konvergencia.csv, amplitudok.csv,
              egyutthatok.csv, inditasok.csv, beallitasok.txt,
              abrak\k12_1..k12_4 (koltseg, amplitudok, gorbek, letapogatas)
  Futasi ido: kb. 4x a fo futas durva GA-ja (4 lepes x 8 inditas, 300 generacio).

  A fo mappak fajljait ez a kiserlet CSAK OLVASSA.
