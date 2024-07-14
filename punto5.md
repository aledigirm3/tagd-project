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

Idea: Partire con un numero molto alto di CPU e dischi e poi ridurre gradualmente (sicuraente non reggerà il carico con 1 cpu e 1 disco).

Con 100 cpu e 100 dischi (non raid):
Util. cpu: 0.0392
Util. disco: 0.0390
R qA: 0.8474
R qB: 0.8565
R qC: 2.0488
R qD: 2.5314
R qE: 2.5282

Con 6 cpu e 100 dischi (non raid):
Util. cpu: 0.6616
Util. disco: 0.0395
R qA: 1.2666
R qB: 1.2620
R qC: 3.0131 (non è giunto a convergenza. min: 2.8138, max: 3.2124)
R qD: 2.9285
R qE: 2.9205

Con 6 cpu e 6 dischi (non raid):
Util. cpu: 0.6373
Util. disco: 0.6076
R qA: 1.0672
R qB: 1.0683
R qC: 2.4930 (non è giunto a convergenza. min: 2.3795, max: 2.6066)
R qD: 2.5974
R qE: 2.6003

Con 6 cpu e 5 dischi (non raid):
Util. cpu: 0.6138
Util. disco: 0.6692

Con 5 cpu e 5 dischi (non raid):
Util. cpu: 0.7273 (non rispetta i vincoli progettuali)
Util. disco: 0.6677

Conclusioni: la configurazione che consente di rispettare i vincoli progettuali a livello di utilizzazione è quella con 6 cpu e 6 dischi. Bisogna però rispettare anche il vincolo dei tempi di risposta rispetto alla query più lunga a sistema scarico: analizzando le statistiche del file pg_stat_statements_1_2000s.csv si trova che la query più lunga impiega in media 10.9s ad essere eseguita. Però a noi interessa la più lunga tra le 3 query considerate, che è quella disk-intensive (2.523606 secondi).

!!! Verificare che anche applicando il raid 5 accade la stessa cosa.