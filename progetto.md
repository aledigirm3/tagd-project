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