Szerszámorientáció optimalizálása zárt körpályán
FANUC R-2000iB/210F, Fourier-sor és genetikus algoritmus (BME TDK, 2026)
=========================================================================

A tároló a TDK-dolgozathoz készült MATLAB- és KAREL-programokat, a RoboGuide-ban futtatott robotprogramokat, a szimulációs naplókat és az eredményeket tartalmazza. A részletes leírás és a futtatási útmutató a README.txt fájlban található.

Megjegyzés a kód készítéséről és az ábrákról
--------------------------------------------

A programkód mesterséges intelligencia segítségével, a Claude Opus 5.5 nyelvi modellel közös munkában (coworking) készült. A módszert, a beállításokat és a dolgozatban szereplő eredményeket a szerző határozta meg, a feltöltött kód azonban nem minden része került ellenőrzésre.

A szkriptek futás közben számos ábrát (PNG, PDF) automatikusan mentenek, ezek közül nem mindegyik került ellenőrzésre. Ezért a tárolóban lehetnek olyan ábrák, amelyek hibásak, vagy amelyekből más következtetés vonható le, mint ami a dolgozatban szerepel. A szerző által vállalt eredmények és állítások kizárólag a dolgozatban szereplők. Azok az ábrák és kimenetek, amelyek a dolgozatban nem szerepelnek, nem részei a dolgozat eredményeinek, és nem tekinthetők a szerző állításának.

Letöltés és előkészítés
-----------------------

A tároló a teljes mappaszerkezetet tartalmazza, a fájlok közvetlenül a GitHubon is böngészhetők. A helyi futtatáshoz a tárolót le kell tölteni (Code, majd Download ZIP), vagy git clone paranccsal le kell másolni, és a mappaszerkezetet változatlanul kell hagyni.

A futtatás előtt a MATLAB aktuális mappája a gyökérmappa vagy annak egy almappája legyen, mert a szkriptek innen keresik meg a kozos/config.m fájlt.

A nagy, újragenerálható köztes fájlok (CAND.TXT, CAND.csv, CAND2.csv) nincsenek feltöltve, ezeket a 01_racs, a 03_kor2_finom és a valos_futtatas/02_rezges_athelyezett lépései állítják elő. A valós roboton mért nyers rezgésjelek a méretük miatt szintén nincsenek a tárolóban.

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
├── kiserletek/                    kiegészítő vizsgálatok (a fő futás mappáit csak olvassák)
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
    ├── 10_ido_ivhossz/            ívhossz és idő szerinti kiértékelés megfeleltetése
    │                              i1_ido_ivhossz.mlx, eredmenyek/
    └── 12_harmonikus_konvergencia/  harmonikusszám növelése meleg indítással (H = 2..5)
                                   k1_harmonikus_konvergencia.mlx, kozos/config_kis12.m, eredmenyek/

└── valos_futtatas/                kipróbálás valós roboton, rezgésméréssel
    ├── 01_rezges/                 a rezgésméréshez készült első változat
    └── 02_rezges_athelyezett/     ugyanaz az eljárás áthelyezett körön
        ├── a0..a5 *.mlx           rács, GA (hat súlyozás), LS programok
        ├── a6_rezges_kiertekeles.mlx  a rezgésmérés kiértékelése (5°-os szakaszok)
        ├── a7_alap_vs_l235.mlx    Alap és l235 összevetése
        ├── a8_roboguide_koltseg.mlx  RoboGuide-ban mért költség vs. GA-becslés
        ├── kozos/config_athelyezett.m
        ├── ls/, ls_karel/         RA_ és RAK_ programok, KAREL-naplók
        ├── eredmenyek/, meres_kiertekeles/
        └── mert_adatok/           sorrend.txt (a nyers mérési fájlok méret miatt nincsenek feltöltve)
