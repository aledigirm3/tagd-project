Rimuovere RefStation, aggiungere source e sink.
Source -> router.
router -> sink.

Burst (general):
interval-length distribution -> mean: tempo
value distribution -> lambda: tasso di richieste

La query più bilanciata sembra essere quella con valori di service demand:
CPU: 1.012455
DISK: 1.038430
Rapporto CPU/DISK: 0.974986
(Per completezza riporta anche il numero della query)

Aggiungere i Performance indices: 
- utilizzazione a livello globale (All classes).
- response time di ogni singola query a livello di sistema (non ci interessa il response time individuale di cpu e disco).

!!! Ricorda di modificare le prob. del router.


!!! Verificare che anche applicando il raid 5 accade la stessa cosa.

Idea: Partire con un numero molto alto di CPU e dischi e poi ridurre gradualmente. Una volta rispettato il vincolo di utilizzazione, pensiamo al vincolo sui tempi di risposta.
Idea: Partire con un numero molto alto di CPU e dischi e poi ridurre gradualmente (sicuraente non reggerà il carico con 1 cpu e 1 disco).

Con 100 cpu e 100 dischi (non raid):
Util. cpu: 0.0918
Util. disco: 0.0881

Con 15 cpu e 15 dischi (non raid):
Util. cpu: 0.61
Util. disco: 0.5985
R qa: 0.93
R qC: 2.3
R qd: 2.6

Con 15 cpu e 14 dischi (non raid):
util.cpu: 0.61
util.disco: 0.64
R qa: 0.94
R qc: 2.32
R qe: 2.6239

La configurazione che consente di rispettare i vincoli di utilizzazione è quella con 15 cpu e 14 dischi.
Bisogna però rispettare anche il vincolo dei tempi di risposta rispetto alla query più lunga a sistema scarico: analizzando le statistiche del file pg_stat_statements_1_2000s.csv si trova che la query più lunga impiega in media 10.9s ad essere eseguita. Però a noi interessa la più lunga tra le 3 query considerate, che è quella disk-intensive (2.523606 secondi), ora denominate query D ed E.
L'idea è di ridurre il service demand del disco di una quantità vicina al 4%. Con il 7% rientriamo nei requisiti, anche se in effetti il disco è utilizzato leggermente sotto al 60%. 

