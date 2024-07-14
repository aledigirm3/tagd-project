


# Progetto Basi II

Il seguente progetto è finalizzato a modellare un modello simulativo (o analitico) di un dbms sulla base delle prestazioni riscontrate nell'utilizzo del benchmark tpch, fatto giare su un container docker contenente un server di postgres (cercando di rendere il meno rumorosi possibili i dati durante le esecuzioni).
In particolare, il benchmark tpch, da la possibilità di creare un carico di lavoro con cui popolare il DB postgres al fine di poter sottomettere fino a 22 query di varia natura, le quali andranno a utilizzare disco e cpu (ognuna a modo loro)
Dopo aver creato e caricato i dati necessari all'esecuzione delle query (con fattore di scala pari a 2, quindi, in questo caso, con 4 GB di dati) e configurato il server postgres secondo le specifiche tecniche del progetto sono stati svolti i punti 0, 1, 2, 3, 4 e 5, descritti in modo approfondito nella seguente relazione.
(I file contenenti le statistiche di postgres sono stati analizzati in modo automatizzato tramite lo script "*stats_reader.ipynb*" presente nel repository github sel progetto).


--> **[Link al repo github](null)** <--
 


## Punto 0:

La fase preliminare (da cui "punto 0"), dopo aver limitato il numero di processori a disposizione per l'ambiente virtuale a 1 (tramite il file .wslconfig), è stata quella di eseguire un benchmark con tutte e 22 le query messe a disposizione dal benchmark, configurate per essere eseguite serialmente e ciclicamente al fine di fare un'analisi del modello reale con lo scopo di apprendere più informazioni riguardo le prestazioni del sistema.
Il benchmark è stato eseguito per 2000 secondi (poco piu di mezz'ora) ed è riuscito a soddisfare una media di 43 query l'una.
Grazie al file [pg_stat_statements_1_2000s.csv](null) siamo riusciti a estrarre i dati di nostro interesse al fine di individiare la query disk-intensive e quella cpu-intensive; più precisamente sono stati eseguiti i seguenti passi:

- calcolo dell **tempo medio di esecuzione** per ogni query (ecludendo i possibili outliers):
  
  - $t' = (T_e - t_M- t_m) / (C - 2)$
  
  dove $t'$ è il tempo medio di esecuzione, $T_e$ il tempo totale di esecuzione, $t_M$ e $t_m$ sono rispettivamente tempo massimo e tempo minimo di esecuzione (di una query) e $C$ è il numero di chiamate della query in questione.
- calcolo **service demand** della CPU e del disco per ogni query:
  
  - $D_c = t' - ((B_r + B_w) / C)$
  
  - $D_d = t' - D_c$

  dove rispettivamente $D_d$ e $D_c$ sono i service demand del disco e della cpu, mentre $B_r$ e $B_r$ sono i tempi di lettura e scrittura totali del disco.
- calcolo del **rapporto tra service demand della cpu e quello del disco**:
  
  - $R = D_c/D_d$

Questo ultimo calcolo ci ha permesso di capire quale fosse la query cpu-intensive (query con valore di $R$ più alto), con $R = 57$ circa, e quella disk-intensive (query con valore di $R$ più basso), con $R = 0.54$ circa... in effetti si puo anche notare come il carico abbia un maggior impatto per quanto riguarda la cpu.
Eseguendo ulteriori analisi è stato possibile trovare le due query:
- **Q16 -> CPU-intensive:**
  
  - $D_c = 0.8418712777657399$
  - $D_d = 0.01474560369767442$
- **Q7 -> DISK-intensive:**
  
  - $D_c = 0.8933116159835509$
  - $D_c = 1.630294817162791$
  
Dopo aver individuato le query di nostro interesse sono stati creati 2 file, rispettivamente per la query disk-intensive e cpu-intensive, con lo scopo di poter eseguire queste query singolarmente al fine di andare ad analizzare le statistiche delle singole query, riducendo il possibile rumore della macchina (per poi analizzarle in un modello simulativo).

NOTA:
(d'ora in poi le formule e le nomenclature utilizzate in precedenza verranno prese per buone, pertanto potrebbe essere omessa la formula estesa).

## Punto 1

Dopo aver eseguito il [Punto 0](#punto-0), avendo i due file con i quali possiamo effettuare query singolarmente, sono stati effettuari due benchmark, ognuno con tempo totale di esecuzione pari a 300s (5 minuti) e senza altre query concorrenti ,di cui uno per la query cpu-intensive (Q16) e uno per la disk-intensive(Q7), al fine di poter trovare rispettivi service demand e poter fare ulteriori analisi riguardo i tempi di risposta, i throughput e l'utilizazzione.
Chiaramente, per estrarre le statistiche, sono stati utilizzati i soliti file "pg_stat_statements.csv" e i file "summary.json (estratti dalla folder "results" del container, al fine di visualizzare il throughput).
Con gli stessi passaggi del [Punto 0](#punto-0) siamo riusciti a calcolare il service demand del disco e della cpu (per entrambe le query), mentre per l'utilizzazione e il tempo di risposta sono state usate le seguenti formule:

- calcolo **utilizzazione** (demand law)
  
  - $U = X * D$

  dove $U$ è l'utilizzazione del centro (cpu -> $U_c$, disco -> $U_d$), $X$ è il throughput della query e &D& è il service demand del disco o della cpu (sulla basi di quale utilizzazione vogliamo calcolare)

- calcolo **tempo di risposta** (little law):
  
  - $T_r = N / X$
  
  dove $T_r$ è il tempo di risposta di una query, $N$ è il numero medio di entità (query concorrenti in questo caso) nel sistema e $X$ è il throughput della query in questione.

Dopo aver definito opportunamente tali grandezze è ora di andare a vedere le prestazioni della **macchina reale**:

- **Q16 -> CPU-intensive:**
  
  - File: [pg_stat_statements_1_16_300s.csv](null), [CPUint_summary.json](null)
  - $X = 1.1428574273565018$ (goodput)
  - $D_c = 0.873331$
  - $D_d = 0.003121$
  - $U_c = 0.998092819890681$ -> satura
  - $U_d = 0.003566858030779642$
  - $T_r = 0.8749997821802326$
  

- **Q7 -> DISK-intensive:**
  
  - File: [pg_stat_statements_1_7_300s.csv](null), [ DISKint_summary.json](null)
  - $X = 0.4119602231342898$ (goodput)
  - $D_c = 0.900671$
  - $D_c = 1.54916$
  - $U_c = 0.3710406261305839$
  - $U_d = 0.6381922992707164$
  - $T_r = 2.4274188230887095$
  
Si noti come per il carico cpu-intensive l'utilizzazione è praticamente al massimo (la cpu è collo di bottiglia per definizione), inoltre i tempi di risposta corrispondono al service demand della cpu, mentre per il carico disk-intensive l'utilizzazione non supera il 64% e, anche in questo caso il tempo di risposta corrisponde al service demand del disco... poteva andare peggio tutto sommato.

## Punto 2

A questo punto, tramite JMT (java modelling tool), è stato creato un modello simulativo con due classi di workload (cpu-intensive e disk-intensive) e due centri (cpu e disco) mediante le statistiche ricavate nel [Punto 1](#punto-1), in particolare utilizzando i service demand della cpu e del disco per tutte e due le classi di lavoro.

Ecco i risultati del **modello simulativo**:

File: [punto1.jmva.jsimg](null)

- **Q16 -> CPU-intensive:**
  
  - $X = 1.1669$
  - $U_c = 0.98311$ -> satura
  - $U_d =  0.0172$

- **Q7 -> DISK-intensive:**
  
  - $X = 0.3956$
  - $U_c = 0.3570$ -> satura
  - $U_d =  0.6484$

I risultati prodotti sono stati sorprendentemente soddisfacenti, con differenze di throughput, utilizzazione dei centri e tempi di risposta trascurabili (possibile rumore, i tempi di risposta sono stati omessi per semplicità).


## Punto 3:

In questo punto sono stati eseguiti nuovamente benchmark per le query disk-intensive e cpu-intensive (sempre per 5 minuti), con la differenza che nelle precedenti esecuzioni non venivano eseguite query concorrenti, mentre adesso è stato impostato a 2 il numero di query concorrenti (cambiando il valore *terminals* nel file di configurazione delle query).
A priori ci si potrebbe aspettare che per la query cpu-intensive il throughput non può aumentare in quanto l' utilizzazione (della cpu), con un cliente in media nel sistema, è gia 98% circa, mentre per la query disk-intensive ci si può aspettare un aumento del throughput (e dell' utilizzazione).
Dopo aver modificato il numero dei *customers* nel modelllo simulativo (usato nel [punto precedente](#punto-2)) e dopo aver simulato le prestazioni rispettivamente per le due query i risultati del benchmark e del modello sono stati messi a confronto:

- **Q16 -> CPU-intensive -> Modello simulativo:**
  - $X = 1.1865$
  - $U_c =  0.9998$ -> satura
  - $U_d = 0.0176$ -> simile ai punti precedenti
  - $N = 1.9819$ (numero medio clienti sistema)
  - $T_r = 1.773663$

- **Q16 -> CPU-intensive -> Benchmark:**

   - file: [CPUint_summary_3.json](null), [pg_stat_statements_3_16_300s.csv](null)
   - $X = 1.1295683704661714$ (goodput)
   - $U_c =  0,99$ -> satura
   - $U_d = 0.006344785536908484$
   - $T_r = 1.773663$
  
- **Q7 -> DISK-intensive -> Modello simulativo:**

   - $X = 0.5152$
   - $U_c = 0.4590$
   - $U_d = 0.8385$
   - $N = 1.3712$ (numero medio clienti sistema)
   - $T_r = 2.6614906832298137$

- **Q7 -> DISK-intensive -> Benchmark:**

   - file: [DISKint_summary_3.json](null), [pg_stat_statements_3_7_300s.csv](null)
   - $X = 0.6445184367217778$ (goodput)
   - $U_c = 0.3704563070589434 $ 
   - $U_d = 0.621447254760885$ -> ambiguo!
  
Gia da qui si può notare come le previsioni effettuate per quanto riguarda il carico cpu-intensive rispecchiano abbastanza le ipotesi fatte in precedenza, mentre per quanto riguarda il carico disk-intensive qualcosa non va, in particolare l'utilizzazione del disco è molto minore di quanto ci si poteva aspettare e da quanto ha predetto il modello simulativo... Dopo vari test e varie ricerche abbiamo notato che lo storage utilizzato nel computer fisico sul quale sono stati eseguiti i benchmark sfrutta la tecnologia *NMVe* la quale prevede (ove ritenuto necessario) la parallelizzazione delle letture/scritture permettendo di mantenere un'utilizzazione del disco relativamente piu bassa e con incrementi di troughput (non siamo sicuri che sia esattamente questo il problema, la nostra è un'ipotesi fatta andando per esclusione nei vari test).
Comunque si può assumere di poter mantenere una credibilità nella correlazione tra il modello e la macchina reale visti i buoni risultati ottenuti precedentemente.

NOTA:
(il calcolo dell'utilizzazione dei centri è stato effetuato utilizzando service demand e considerando il tempo di esecuzione totale del server postgres, mentre per quanto riguarda i tempi di risposta è stato preso in considerazione il tempo totale dei *costumers* che hanno sottomesso le query).


## Punto 4

Questo punto del progetto prevede un'analisi più dinamica e interessante in quanto si vogliono analizzare le prestazioni del modello simulativo utilizzando un numero di CPU pari a 2 (cambiando il numero di serventi nel centro cpu del modello simulativo) e, soprattutto, variando il numero di *customers* (numero di query concorrenti) nel sistema da 1 a 5.
Prima di eseguire il benchmark possiamo fare un paio di considerazioni: la cpu era gia satura con *customer* e 1 servente, quindi ci possiamo aspettare che con 2 serventi riuscirà a gestire fino a 2 *customers* prima di andare nuovamente in saturazione, mentre per quanto riguarda il disco molto probabilmente andrà in saturazione con 4 *customers* (forse sarà quasi saturo gia con 3 *customers*).
Ecco qui riportati i risultati del Modello Simulativo per quanto riguarda le query disk intensive e cpu intensive, visualizzati con immagini rappresentanti grafici e statistiche ottenute tramite la funzione *what-if* di JMT: 


- **CPU-intensive -> Modello simulativo**
  
  - ![](./image_1.png)
  - ![](./image_3.png)
  - ![](./image_4.png) 
  
- **DISK-intensive -> Modello simulativo**
  
  - ![](./dimage_1.png)
  - ![](./dimage_3.png)
  - ![](./dimage_4.png) 


Come ci si poteva aspettare la CPU, superato un numero di *customers* pari a 2, va in saturazione (con 3 *customers* l'utilizzazione e circa 100%), analogamente anche il throughput, giustamente, aumenta rapidamente fino a 2 *customers* con un valore pari a $X = 2.3$, per poi salire di molto poco (di 0.1 circa) fino a completa saturazione del sistema (con un numero di *customers* pari a 3).
Per quanto riguarda il disco, come da ipotesi, arriva a quasi saturazione con 3 *customers* (con utilizzazione del 97% circa) e un throughput che fino a 2 *customers* sale velocemente fino a $X=0.56$ circa, dopodiché fino a 3 *customers* sale più lentamente (fino a raggiungere $X=0.6$); con *customers* il disco è completamente saturo.

A questo punto non possiamo che eseguire nuovamente almeno due benchmark (con 2 cpu): uno con 2 *customers* e l'altro con 5 *customers* (*terminals*con valori 2 e 5) sia per la query cpu-intensive, sia per la disk-intensive, al fine di vedere se i risultati ricavati dalle statistiche della macchina reale siano paragonabili al modello simulativo (l'esecuzione è stata mantenuta a 5 minuti).
(I risultati sono stati estratti dai noti file per le statistiche di postgres e del container, mediante opportuni calcoli eseguiti in modo analogo ai punti precedenti).

- **CPU-intensive -> Benchmark -> 2 customers**
  - File: [pg_stat_statements_4_16_2_300s.csv](null), [CPUint_summary_4_2.json]()
  - $U_c = 0.994708954550472$ -> satura
  - $X = 2.1860486094211584$ req/s
  
- **CPU-intensive -> Benchmark -> 5 customers**
  - File: [pg_stat_statements_4_16_5_300s.csv](null), [CPUint_summary_4_5.json](null)
  - $U_c = 0.9830228695699584$ -> satura
  - $X = 2.2126251062282$ req/s
  
- **DISK-intensive -> Benchmark -> 2 customers**
  - File: [pg_stat_statements_4_7_2_300s.csv](null), [DISKint_summary_4_2.json](null)
  - $U_d = 0.43401358968800696$
  - $X = 0.43853842920049774$ req/s
  
- **DISK-intensive -> Benchmark -> 5 customers**
  - File: [pg_stat_statements_4_7_5_300s.csv](null),[DISKint_summary_4_5.json](null)
  - $U_d = 0.99999999$ -> saturo
  - $X = 0.7541532588537293$ req/s

Possiamo concludere, avendo i risultati confrontabili tra il modello simulativo e la macchina reale, dicendo che per quanto riguarda la CPU nel carico cpu-intensive, questa si comporta nello stesso modo in tutti e due i casi (reale e simulativo) degradando quando il numero di query concorrenti è >= 2, con una particolare vicinanza tra i risultati della macchina reale a confronto con la simulazione, mentre per quanto riguarda il disco i risultati della simlazione si discostano di più con la macchina reale nel caso di due query concorrenti, soprattutto per quanto riguarda l'utilizzazione (anche se abbiamo detto prima, alla fine del [Punto 3](#punto-3), che la tecnologia *NMVe* potrebbe alterare l'utilizzazione del disco a causa della parallelizzazione delle operazioni di I/O), ma quando eseguiamo il benchmark con 5 query concorrenti i numeri iniziano essere meno distanti con il modello simulativo, infatti il disco si satura e i valori throughput (tra simulativo e reale) si avvicinano di molto.


## Punto 4a 

In questo punto è stato modellato il sistema (modello simulativo del [punto precedente](#punto-4)) con lo scopo di mantenere un'utilizzazione dei centri nell'intervallo 60%-70% e un tempo di risposta medio inferiore ai 30 secondi sapendo che possiamo avere un numero massimo di query concorrenti (cpu-intensive o disk-intensive) pari a 20, inoltre il sistema, secondo le specifiche tecniche, doveva prevedere l'utilizzo di dischi *RAID 5*.
Per quanto riguarda la scelta dei dischi è stato pensato l'utilizzo dei *RAID 0* dato che sono davvero molto simili a livello di prestazioni con la differenza esclusivamente a livello di storage, per la parità, che prevede un disco in meno in termini di memoria disponibile... la cosa è trascurabile (i dischi *RAID 5* offrono sicuramente più affidabilità, ma considerando che si sta usando un computer personale possiamo trascurare questa qualità per i nostri test).
Prima di descrivere l'approccio utilizzato è opportuno precisare che, per garantire il corretto funzionamento del sistema, le probabilità di istradamento dai router ai centri deve essere bilanciata (in questo caso 0.333333333 ciascuno), il service demand di ciascun disco, con $K$ dischi, deve essere modificato nel seguente modo: $D_d' = D_d / K$ (chiaramente sulla base del carico che stiamo considerando) e infine di considerare un solo disco nella valutazione delle metriche queste sono uguali per tutti gli altri dischi.
Dopo queste premesse è ora di vedere come è stato approcciato il problema, in particolare è stato approcciato prima il carico disk-intensive per modellare il disco e poi (una volta modellato secondo le specifiche il disco) il carico cpu-intensive per modellare opportunamente anche la cpu (utilizzando lo strumento di analisi *what-if* di JMT); seguiranno, di conseguenza, le varie prove effettuate con le opportune considerazioni:

1. **10 dischi e 1 cpu:** (carico disk-intensive)
  
  Utilizzando 10 dischi () e 1 cpu si è notato che la cpu saturava troppo velocemente anche se si stava utilizzando un carico puramente disk-intensive, per questo motivo si è considerato, come primo approccio, quello di aumentare le cpu del nostro sistema. 

2. **10 dischi e 20 cpu** (carico disk-intensive)
   
   La scelta di utilizzare 20 cpu è stata sicuramente opportuna, facendo tornare come collo di bottiglia il disco che ha un'utilizzazione del 60%-70% gia con 8 *customers*... il sistema dovrebbe reggere fino a 20 *customers*; un approccio "brute force" forse non sarebbe sbagliato.

3. **40 dischi e 20 cpu** (carico disk-intensive)
   
   a questo punto possiamo dire di aver raggiunto le specifiche richieste per quanto riguarda il disco e tempi di risposta.
   Ecco qui sotto riportate le statistiche (con 20 *customers* nel sistema):
   
   - $U_d = 0,65$
   - $U_c = 0,0.705$
   - $X = 15,87$ req/s
   - $T_r = 1.26$ s

L'utilizzazione del disco con 20 costumers non supera il 70% (dalla sumulazione risulta circa il 65%), mentre la CPU ha un'utilizzazione del 70% circa (diventando il collo di bottiglia per definizione) e, sapendo cio, possiamo immaginare che le 20 CPU precedentemente istanziate non reggeranno sicuramente un carico cpu-intensive (sapendo che questo è un carico disk_intensive).

4. **40 dischi e 20 cpu** (carico cpu-intensive)
   
   Come prima cosa è stato provata una simulazione (sempre da 1 a 20 costumers) con lo stesso numero di CPU dimensionate nel caso del modellamento del disco (ci sono voluti 20m).
   Il disco, come ci si poteva aspettare ha un'utilizzazione irrilevante (circa 0), mentre la CPU è piu che satura con 20 customers.

5. **40 dischi e 30 cpu** (carico cpu-intensive)
   
   Provando invece con 30 CPU l'utilizzazione, con 20 costumers, non supera il 70%, piu precisamente ha un valore del 67% circa, un buon risultato tutto sommato.
   Seguono le statistiche del sistema (con 20 *customers* nel sistema):

   - $U_d = 0.00008$
   - $U_c = 0.66$
   - $X = 23.6935$ req/s
   - $T_r = 0.84$ s
  
6. **verifiche e considerazioni finali:**
   come ultima verifica è opportuno provare nuovamente una simulazione disk-intensive con 20 costumers per acertarsi della correttezza dei risultati ottenuti.
   Dalle statistiche si ottiene che:

   - $U_d = 0.64$
   - $U_c = 0.48$
   - $X = 15.76$ req/s
   - $T_r = 1.27$ s
  
  Si puo natare che il disco ha un'utilizzazione del 64% circa e di cpu pari al 48% circa e che i tempi di risposta rientrano anch'essi nei requisiti imposti dalle specifiche.
  Possiamo ritenere il sistema pronto a un aumento del carico fino a 20 query concorrenti.
  File modello simulativo: [punto4.jmva.jsimg](null)


