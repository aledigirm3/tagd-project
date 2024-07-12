# Punto 1

Fattore di scala: 2.

Time: 900

Limitazione a 1 del numero di CPU.

Senza <time>, esegue ogni query 2 volte. Con time, esegue il benchmark per tot tempo.

Scaricare le statistiche in csv da pg_stat_statements.

excel:
file -> opzioni -> impostaz. avanzate -> utilizza sep. di sistema (dec. punto, migli. virgola)

dati -> testo / csv [NON RILEVARE I TIPI DI DATI]

colonne:
query
calls (num di chiamate alla query)
    -> filtra solo query con valore sensato (quelle a 1 non fanno parte del benchmark)
    non contare DROP VIEW revenue;

total_exec_time (ms)
min|max|mean_exec_time

mean_exec_time = tempo di risposta (cpu + disco)

blk_read_time (ms)
blk_write_time (ms)
sono entrambi totali

ipotizziamo 1 visita ad ogni centro.

aggiungiamo D_CPU, D_DISK

D_CPU: = mean_tot - ((blk read + write) / calls)
D_DISK = mean_tot - D_CPU

Obiettivo è identificare la query più disk intensive e quella più cpu intensive e caratterizziamo solo due classi.

Faccio rapporto D cpu/disk, cpu-i = max, disk-i = min.

prima di fare il modello simulativo, fai il modello analitico.
!! Fare la conversione in secondi. 

Risolvere per una classe, guardare throughput.
Rieseguire benchmark con solo una query specifica.

Per trovare la query: in folder queries: grep <qualcosa> *

Crea un nuovo file di configurazione, cambia i weights. Tieni solo 1. Nei transactiontypes tieni solo la query.

Guarda il summary e cerca il throughput. (Goodput: conta anche i job non terminati)

Prova anche togliendo min e max. 

Salva il modello analitico e aprilo con modello simulativo.

----

Calcolato tempo di risposta medio totale usando media che esclude min e max.

I valori sono in secondi.

CPU intensive: Query 16
D_CPU: 0.9169211302	
D_DISK: 0.01629483482

DISK intensive: Query 20
D_CPU: 0.4541428367
D_DISK: 0.8298549731

Creazione modello analitico query CPU intensive:
Throughput: 1.0716

Modello analitico entrambe le query:
Throughput sistema: 1.3617720433125422
Throughput cpu-intensive: 0.7886079100343513
Throughput Disk-intensive: 0.573164133278191

Utilizzazione:
- CPU: 0.9833896415350118
    - Classe cpu-int: 0.7230912561533572
    - Classe disk-int: 0.26029838538165456
- DISK: 0.4884933420352132
    - Classe cpu-int: 0.012850235631755174
    - Classe disk-int: 0.475643106403458

Tempo di risposta:
- cpuint: 1.268057278244192
- diskint: 1.7447009363278492

Ottenuti i valori del modello simulativo, rieseguiamo il benchmark con soltanto le due query e un tempo di 60 secondi utilizzando il file sample_tpch_16_20_config.xml

Analizzando il file pg_stat_statements_16_20.csv i service demand risultano simili al precedente benchmark. I tempi di risposta invece si discostano da quanto calcolato dal modello analitico.


------

Punto 0: individuazione della query CPU-Intensive e della query Disk-Intensive.

File: pg_stat_statements_1_2000s.csv
Durata benchmark con tutte le query: 2000 secondi

Query CPU intensive 16
CPU Service demand 0.8418712777657399
DISK Service demand 0.01474560369767442

Query disk intensive 7
CPU Service demand 0.8933116159835509
DISK Service demand 1.630294817162791

------

Punto 1: calcolo delle metriche del sistema
- tempi di servizio
- tempo di esecuzione delle query
- utilizzazione di cpu e disco

Per fare ciò eseguiamo 2 benchmark, 1 per ogni classe di workload.

Query CPU intensive 16
File: pg_stat_statements_1_16_300s.csv, CPUint_summary.json
Throughput (goodput): 1.1428574273565018
Service Demand CPU (D_CPU): 0.873331
Service Demand Disk (D_DISK): 0.003121
Utilizzazione CPU (D_CPU * throughput): 0.998092819890681
Utilizzazione Disco: 0.003566858030779642
Tempo di esecuzione (adj_mean_exec_time): 0.876452

Query disk intensive 7
File: pg_stat_statements_1_7_300s.csv, DISKint_summary.json
Throughput (goodput): 0.4119602231342898
D_CPU: 0.900671	
D_DISK: 1.54916
Utilizzazione CPU: 0.900671 * 0.4119602231342898 = 0.3710406261305839
Utilizzazione Disk: 1.54916 * 0.4119602231342898 = 0.6381922992707164
Tempo di esecuzione: 2.449831

Tempi di servizio: corrispondenti ai service demand. Noti dalle statistiche di postgres.
Tempo di esecuzione delle query: noti anche questi dalle statistiche.
Utilizzazione: calcolabile con la service demand law (util = throughput del sistema * service demand)

------

Punto 2: modello simulativo e confronto con metriche ottenute al punto 1

Modello simulativo

Query CPU intensive 16
Throughput: 1.1669
Utilizzazione CPU: 0.9831
Utilizzazione Disco: 0.0172

Query DISK intensive 7
Throughput: 0.3956
Utilizzazione CPU: 0.3570
Utilizzazione Disco: 0.6484

-----

Punto 3:


--- CPU INTENSIVE ---
Ci aspettiamo che per la query CPU intensive praticamente non ci sia aumento del throughput in quanto l'util.CPU è già al 98.3%.

Modello:
Throughput: 1.1865
Util. CPU: 0.9998 (saturo)
Util. Disco: 0.0176 (quasi uguale a prima)
Numero medio di clienti CPU: 1.9819
Tempo di risposta (N_i / X_i): 1.9819 / 1.1865 = 1.6703750526759376

Benchmark:
file: CPUint_summary_3.json, pg_stat_statements_3_16_300s.csv
Throughput (goodput): 1.1295683704661714 (potrebbe essere thrashing)
Util. CPU: 100% (saturo)
Util. Disco: 0.006344785536908484
Tempo di risposta: 1.773663

--- DISK INTENSIVE ---
Ci aspettiamo un aumento del throughput. Il disco andrà in saturazione? Secondo noi sì.

Modello: 
Throughput: 0.5152
Util. CPU: 0.4590
Util. Disco: 0.8385
Numero medio di clienti Disco: 1.3712
Tempo di risposta: 1.3712 / 0.5152 = 2.6614906832298137

Benchmark:
file: DISKint_summary_3.json, pg_stat_statements_3_7_300s.csv
Throughput (goodput): 0.6445184367217778
Util. CPU:
Util. Disco:
Tempo di risposta: 3.111039

Dal benchmark risulta che la query 7 sia passata da disk intensive a cpu intensive soltanto aumentando il numero di job nel sistema.

Mettendo i job da 2 a 3 si ha il throughput seguente: 0.8 mentre il modello predice: 0.56.