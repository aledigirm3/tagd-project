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
Tempo di risposta (N_0 / X_0): 2 / 1.1865 = 1.6703750526759376

Benchmark:
file: CPUint_summary_3.json, pg_stat_statements_3_16_300s.csv
Throughput (goodput): 1.1295683704661714 (potrebbe essere thrashing)
Util. CPU: 100% (saturo)
Util. Disco: 0.006344785536908484
Tempo di risposta:  1.773663

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
Tempo di risposta:

DA RICONTROLLARE

NOTA: I valori dell'utilizzazione e del tempo di risposta sono ottenuti dalle statistiche di postgres, nelle quali abbiamo diviso per 2 il total_exec_time. Il throughput è invece ottenuto dal summary prodotto da benchbase.

Dal benchmark risulta che la query 7 sia passata da disk intensive a cpu intensive soltanto aumentando il numero di job nel sistema.
Mettendo i job da 2 a 3 si ha il throughput seguente: 0.8 mentre il modello predice: 0.56.

? Disk intensive: il tempo totale è il doppio con 2 job.

Tentativo con max_parallel_workers_per_gather
query 7
jobs 2

ci aspettiamo che il blk_read_time raddoppi rispetto al caso con 1 job. Non è andata così. il blk_read_time è rimasto quasi uguale al caso con 1 job. l'utilizzazione di entrambi i centri continua a discostarsi dal modello simulativo.
(NVME)

-------

Punto 4:

MODELLO

CPU Intensive 
Già con 2 job si satura la CPU.

DISK Intensive
Il disco va in saturazione al 5o job.

(Aggiungere immagini)
![](./dimage_1.png)

BENCHMARK



Punto 4 - dimensionamento con raid

- mettere 0.33 alle prob. del router
- con 10 dischi, dividere per 10 i service demand dei dischi trovati all'inizio
- su jmt misuriamo le metriche solo per un disco a caso tra questi 10, per gli altri è uguale
- una volta aggiunto il raid 0 e fatta what if analysis con 20 query, bisogna aumentare a questo punto anche il numero di cpu dato che all' aumentare dei job il collo di bottiglia diventa proprio la CPU anche se il carico risulta essere disk intensive
- l'idea è quella di utilizzare 20 cpu dato che inizialmente la cpu si saturava anche con solo query sequenziali nel sistema

10 dischi:
CPU Intensive:
DISK Service demand 0.001474560369767442

DISK Intensive:
DISK Service demand 0.1630294817162791


40 dischi:
CPU Intensive:
DISK Service demand 0.0003686400924418605

DISK Intensive:
DISK Service demand 0.040757370429069774

20 cpu e 40 dischi:
DISK Intensive (con 20 job)
Util. disco: 65%
Util. cpu: 70.5%
Throughput: 15.87 req/s
Tempo di risposta: circa 1.26s

CPU Intensive (con 20 job)
La cpu ha un'utilizzazione oltre il 70%.
Il disco è utilizzato allo 0.008% circa.

[02:24] ALESSANDRO DI GIROLAMO
Con 8 costumers abbiamo che il la risorsa è utilizzata al 60%/70% circa... con 20 il disco è abbondantemente saturo
 
[02:24] ALESSANDRO DI GIROLAMO
e se usassimo 15 dischi? ancora una volta il risultato non è soddisfacente (al 70% di utilizzazione abbiamo circa 10 customers)

[02:24] ALESSANDRO DI GIROLAMO
a questo punto un approccio "brute force" non sarebbe una cattiva idea, proviamo con 40 dischi.

[02:31] ALESSANDRO DI GIROLAMO
L'utilizzazione del disco con 20 costumers non supera il 70% (dalla sumulazione risulta circa il 65%), mentre la CPU 
un'utilizzazione del 70% circa (diventando il collo di bottiglia per definizione) e, sapendo cio, possiamo immaginare che le 20 CPU precedentemente istanziate nonn reggeranno sicuramente un carico cpu-intensive (sapendo che questo è un carico disk_intensive).

Come prima cosa è stato provata una simulazione (sempre da 1 a 20 costumers) con lo stesso numero di CPU dimensionate nel caso del modellamento del disco (ci sono voluti 20m).
Il disco, come ci si poteva aspettare ha un'utilizzazione irrilevante (circa 0), mentre la CPU è piu che satura con 20 customers.

Provando invece con 30 CPU l'utilizzazione, con 20 costumers, non supera il 70%, piu precisamente ha un valore del 67% circa, un buon risultato tutto sommato.

30 cpu, 40 dischi
CPU Intensive (con 20 job)
Util. disco: 0.008%
Util. cpu: 66%
Throughput: 23.6935 req/s
Tempo di risposta: circa 0.84s

DISK Intensive (con 20 job)
Util. disco: 64%
Util. cpu: 48%
Throughput: 15.76 req/s
Tempo di risposta: circa 1.27s

verifiche e considerazioni finali:
come ultima verifica è opportuno provare nuovamente una simulazione disk-intensive con 20 costumers per acertarsi della correttezza dei risultati ottenuti. Si puo natare che il disco ha un'utilizzazione del 64% circa e di cpu pari al 48% circa.
Possiamo ritenere il sistema pronto a un aumento del carico fino a 20 query concorrenti.

