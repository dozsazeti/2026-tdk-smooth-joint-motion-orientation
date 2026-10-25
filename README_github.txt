Szerszámorientáció optimalizálása zárt körpályán
FANUC R-2000iB/210F, Fourier-sor és genetikus algoritmus (BME TDK, 2026)
=========================================================================

A tároló a TDK-dolgozathoz készült MATLAB- és KAREL-programokat, a RoboGuide-ban futtatott robotprogramokat, a szimulációs naplókat és az eredményeket tartalmazza. A részletes leírás és a futtatási útmutató a README.txt fájlban található.

Letöltés és előkészítés
-----------------------

A tároló tartalma méretkorlát miatt két zip-fájlban került feltöltésre:

  2026-tdk-smooth-joint-motion-orientation-1.zip
  2026-tdk-smooth-joint-motion-orientation-2.zip

A használathoz mindkét zip-fájlt le kell tölteni, és ugyanabba a mappába kell kicsomagolni. A két zip ugyanannak a mappaszerkezetnek két részét tartalmazza, ezért kicsomagolás után az almappák egyesülnek, és egy közös gyökérmappában látszik a teljes projekt. Ha a kicsomagoló rákérdez, hogy egy már létező mappába írjon-e, a válasz igen (egyesítés).

A futtatás előtt a MATLAB aktuális mappája a gyökérmappa vagy annak egy almappája legyen, mert a szkriptek innen keresik meg a kozos/config.m fájlt.

A nagy, újragenerálható köztes fájlok (CAND.TXT, CAND.csv, CAND2.csv) nincsenek feltöltve, ezeket a 01_racs és a 03_kor2_finom lépései állítják elő.

Mappaszerkezet
--------------

<gyökérmappa>/
├── README.txt                     részletes leírás és futtatási útmutató
├── README_github.txt              ez a fájl (a GitHub-oldal leírása)
├── .gitignore
│
├── kozos/                         közös beállítások és függvénytár
│   ├── config.m                   minden beállítás egy helyen
│   ├── karel/
│   │   ├── LOG_ALL.txt            KAREL naplózó program (idő, J1..J6, X Y Z W P R)
│   │   └── LOG_ALL_magyarazott.txt
│   └── lib/                       MATLAB függvények (30 db), pl. cand_beolvas.m,
│                                  wpr_joints.m, deriv_ops.m, koltseg.m, ga_run.m,
│                                  ga_fitness.m, fourier_eval.m, log_beolvas.m,
│                                  ivhossz_derivalt.m, ido_derivalt.m, ls_iras.m
│
├── 00_korpalya/                   a körpálya és az Alap program
│   ├── kor_generalas.mlx
│   └── ls/                        ALAP.LS, ALAP_pontok.csv
│
├── 01_racs/                       az inverz kinematikai rács (1. kör, ±45°, 3°)
│   ├── r1_cand_generalas.mlx      -> roboguide_be/CAND.TXT, CAND.csv
│   ├── r2_cand2_osszefuz.mlx      -> CAND2.csv
│   ├── karel/ik_batch.txt         KAREL IK-program a RoboGuide-hoz
│   ├── roboguide_be/              (CAND.TXT, CAND.csv: újragenerálható)
│   └── roboguide_vissza/          JOINTS.CSV (a RoboGuide IK-eredménye)
│
├── 02_ga_durva/                   1. optimalizálási kör (H = 2, 12 kulcspont)
│   ├── g1_ga_durva.mlx            Fourier-GA, 8 indítás -> opt1..opt5
│   ├── g2_abra_ga.mlx             ábrák
│   ├── g3_elemzes_ivhossz.mlx     pálya menti és csuklónkénti elemzés
│   ├── g4_ls_generalas.mlx        LS programok (ALAP_L, OPT1_L)
│   ├── g5_fourier_gorbek.mlx      Fourier-ábrák
│   ├── g6_fourier_3d.mlx          3D ábrák
│   ├── ls/                        ALAP_L.LS, OPT1_L.LS (+ _pontok.csv)
│   └── eredmenyek_korlat/
│       ├── 01_ga/                 opt_osszesites.csv, opt1..5_kulcspontok.csv,
│       │   │                      opt1..5_LS_WPR.csv, ALAP_WPR000.csv
│       │   └── fourier/           f1..f7 ábrák, fourier_egyutthatok.csv
│       ├── 02_elemzes/            pontonkent_*.csv, szektorok.csv, szektor_csuklo.csv
│       └── abrak/                 ga_1..ga_3, el_1..el_4 ábrák
│
├── 03_kor2_finom/                 2. optimalizálási kör (H = 3, 24 kulcspont, ±10°, 1°)
│   ├── k1_cand_generalas.mlx      -> roboguide_be/CAND.TXT
│   ├── k2_ga_finom.mlx            GA az opt1 körül
│   ├── k3_ls_generalas.mlx        -> ls/OPT2_L.LS
│   ├── ls/                        OPT2_L.LS (+ _pontok.csv)
│   ├── roboguide_be/              (CAND.TXT, CAND.csv: újragenerálható)
│   ├── roboguide_vissza/          JOINTS.CSV
│   └── eredmenyek_korlat/         k2_osszesites.csv, jelolt1_*.csv, szektorok.csv,
│                                  abrak/ (k2_1, k2_2)
│
├── 04_roboguide_osszevetes/       a RoboGuide-futások kiértékelése
│   ├── osszehasonlitas.mlx
│   ├── roboguide_log/             alap.CSV, opt1.CSV, opt2.CSV (LOG_ALL naplók)
│   └── eredmenyek_korlat/         osszeg_csuklonkent.csv, hozzajarulas_csuklonkent.csv,
│                                  szektorok.csv, pontonkent_*.csv, ido_vs_ivhossz_*.csv,
│                                  futasok.txt, m_1..m_8 ábrák
│
└── kiserletek/                    kiegészítő vizsgálatok (a fő futás mappáit csak olvassák)
    ├── 01_gyorsitas_teszt/        csuklónkénti sebesség-, gyorsulás-, rántáskorlát mérése
    │                              t1_ls_generalas.mlx, t2_kiertekeles.mlx, PARAM.CSV,
    │                              karel/PARAM_LEK.txt, ls/, log/, eredmenyek/
    ├── 02_modell_pontossag/       a GA-modell pontossága (négy kiértékelési szint)
    │                              m1_ik_bemenet.mlx, m2_kiertekeles.mlx,
    │                              m3_racs_kihagyasos.mlx, roboguide_be/, roboguide_vissza/,
    │                              eredmenyek/
    ├── 03_fourier_harmonikusok/   tájékozódó próba (H = 3 / H = 4), nem része a végleges futásnak
    │                              k1..k6 *.mlx, kozos/config_kis03.m
    ├── 04_cnt/                    a CNT-érték hatása (CNT1, 25, 50, 75, 100)
    │                              k1_ls_generalas.mlx, k2_kiertekeles.mlx,
    │                              k3_kiegeszito_abrak.mlx, ls/, roboguide_log/, eredmenyek/
    ├── 05_allando_wpr/            a legjobb állandó orientáció (konst1, konst2)
    │                              k1_allando_racs.mlx, k2_kiertekeles.mlx, ls/,
    │                              roboguide_log/, eredmenyek/
    ├── 06_kulcspont_visszateszt/  interpolált vs pontos IK a kulcspontokban
    │                              k1_cand_kulcspontok.mlx, k2_kiertekeles.mlx,
    │                              roboguide_be/, roboguide_vissza/, eredmenyek/
    ├── 07_spline_mintavetel/      a spline mintavételezése (5°, 3°, 1°)
    │                              s1_spline_teszt.mlx, eredmenyek/
    ├── 08_harmonikus_tartomany/   tájékozódó próba, nem része a végleges futásnak
    │                              k1_ga_harmonikus.mlx, kozos/config_kis08.m
    ├── 09_ga_konvergencia/        a durva GA konvergenciája generációnként
    │                              k1_ga_konvergencia.mlx, eredmenyek/
    └── 10_ido_ivhossz/            ívhossz és idő szerinti kiértékelés megfeleltetése
                                   i1_ido_ivhossz.mlx, eredmenyek/
