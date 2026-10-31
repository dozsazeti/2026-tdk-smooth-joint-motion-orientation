VALÓS FUTTATÁS / 02_rezges_athelyezett
======================================

Rezgésmérés a valós roboton, áthelyezett körrel. A módszer a fő futáséval
(01_v10) minden tekintetben azonos: ugyanaz a rács (12 kulcspont 30°-onként,
±45° / 3°), ugyanaz a Fourier-GA (H = 2, 8 indítás, ugyanazok a seedek),
ugyanaz a 'korlat' normálás és ugyanaz az LS-sablon (UF 0 / UT 3,
'N U T, 0, 0, 0', 100 mm/sec, CNT100). A számoló függvények a fő futás
kozos\lib mappájából jönnek, ezért a kódjuk is ugyanaz.

Eltérés a 01_rezges-hez képest: a kör középpontja máshová kerül, ezért a
RoboGuide IK-rácsot is újra le kell kérni (saját racs mappa). Csak az 1.
kör (durva GA, opt1) fut, a 2. kör nem.

BEÁLLÍTÁS
  kozos\config_athelyezett.m   a fő kozos\config.m teljes másolata
                               - cfg.cella.nullpont: IDE KELL ÍRNI AZ ÚJ KÖZÉPPONTOT
                               - cfg.rez.esetek: a lambda-súlyok és a programnevek
                                 (RA_ALAP, RA_235, RA_100, RA_010, RA_001, RA_055)
  kozos\cfg_elteres.m          kiírja, miben tér el a beállítás a fő futásétól
  kozos\ga_kor1.m              az 1. kör GA-ja (a 01_rezges\kozos\ga_kor1.m másolata)
  karel\ik_batch.txt           a RoboGuide IK KAREL programja (a 01_racs-é, változatlan)

FUTTATÁSI SORREND
  0. a0_kor_alap.mlx        összevetés a fő beállítással + ls\RA_ALAP.LS az új
                            középponttal. Ezt érdemes a RoboGuide-ban (és a
                            cellában) kipróbálni, mielőtt a rács lekérése indul.
  1. a1_cand_generalas.mlx  racs\roboguide_be\CAND.TXT, CAND.csv
     RoboGuide:             CAND.TXT -> UD1:, ik_batch futtatása UF 0 / UT 3
                            mellett, a JOINTS.CSV -> racs\roboguide_vissza
  2. a2_cand2_osszefuz.mlx  racs\CAND2.csv (a GA bemenete), kiírja az Alap
                            csuklószögeit kulcspontonként (J5 ne legyen 0 közelében)
  3. a3_ga_sulyozas.mlx     GA esetenként -> eredmenyek\<eset>\ és
                            eredmenyek\osszesites_esetek.csv
  4. a4_ls_generalas.mlx    ls\RA_*.LS (+ _pontok.csv), LOG_ALL nélkül
  5. a5_ls_karel.mlx        ugyanezek a programok KAREL-naplózással (F[1] / RUN
                            LOG_ALL a mozgás körül) -> ls_karel\RAK_*.LS; a LOG_ALL
                            kimenetei a program nevére átnevezve -> ls_karel\log
  Mérés:                    a valós roboton a RA_ (naplózás nélküli) programok futottak,
                            a rezgésmérő szenzor fájljai a mert_adatok mappába kerültek
                            (test_N.csv, ismétlések: test_N_1.csv, test_N_2.csv; melyik
                            program és melyik szenzorirány: mert_adatok\...\sorrend.txt).
                            A nyers mérési fájlok a méretük miatt nincsenek a tárolóban.
  6. a6_rezges_kiertekeles.mlx  a mért rezgés kiértékelése: a KAREL-naplóból ismert
                            futásidővel a kör 0..360°-os szakaszának kivágása, 5°-os
                            szakaszonként effektív érték (RMS) és csúcsérték, átlagolás
                            az ismétlésekre, összevetés irányonként -> meres_kiertekeles\
  7. a7_alap_vs_l235.mlx    csak az Alap és az l235 (0.2 / 0.3 / 0.5) összevetése,
                            a kiugró szakaszokkal és nélkülük -> meres_kiertekeles\alap_vs_l235\
  8. a8_roboguide_koltseg.mlx  a RAK_ naplókból ugyanaz a költség, mint a fő futás
                            04_roboguide_osszevetes lépésében (RoboGuide-ban mért vs.
                            GA-becslés) -> eredmenyek\roboguide_koltseg.csv

HA A KÖZÉPPONT VÁLTOZIK
  A rács a kör helyéhez tartozik, ezért a nullpont minden módosítása után az
  a0 -> a1 -> RoboGuide IK -> a2 -> a3 -> a4 (-> a5) sort elölről kell futtatni.
