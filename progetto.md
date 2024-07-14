# Progetto di Capacity Planning - Tecnologie e Architetture per la Gestione dei Dati

## Introduzione

In questo documento viene presentato il lavoro svolto in merito al progetto di capacity planning per il corso di Tecnologie e Architetture per la Gestione dei Dati, anno accademico 2023-2024.

Il lavoro qui presente è stato svolto dagli studenti:
- Alessandro Di Girolamo
- Alberto Tontoni

Le attività svolte hanno previsto l'utilizzo degli strumenti Java Modeling Tools (JMT) e Benchbase per il dimensionamento di un DBMS PostgreSQL. E' stato utilizzato un computer fisso al fine di eseguire numerosi benchmark tramite Benchbase, utilizzando un fattore di scala pari a 2, i cui risultati sono stati confrontati con quanto predetto da modelli simulativi realizzati tramite JMT. Di seguito sono riportate le specifiche tecniche della macchina utilizzata:
- CPU: AMD Ryzen 7 5800X 8-Core Processor
- RAM: 16 GB, DDR4 3200 MHz
- Unità disco: SSD 1TB NVMe 1.4 PCIe con velocità di lettura fino a 7300MB/s
- Sistema operativo: Windows 10

Al fine di rendere più agevole lo sviluppo dei punti del progetto, sono stati realizzati degli script di utilità per determinare, ad esempio e nel modo più automatizzato possibile, i workload rispettivamente CPU-intensive e Disk-intensive. Tali script sono disponibili per la consultazione insieme ai file contenenti le statistiche dei benchmark al'indirizzo di seguito specificato.

**Link al repository github**: https://github.com/tontonialberto/tagd-project

## Punto 0

Dopo aver configurato il database Postgres e l'ambiente WSL come richiesto, è stato possibile lanciare l'esecuzione di un benchmark comprensivo di tutte le 22 query offerte da quest'ultimo. La configurazione utilizzata ha previsto l'esecuzione seriale per 2000 secondi (circa mezz'ora) concludendosi con una media di 43 query eseguite per ciascuna tipologia.

Tramite l'ausilio del notebook [`stats_reader.ipynb`](https://github.com/tontonialberto/tagd-project/scripts) è stato possibile analizzare le statistiche contenute nel file [`pg_stat_statements_1_2000s.csv`](https://github.com/tontonialberto/tagd-project/statistics) al fine di individuare i workload CPU-Intensive e Disk-Intensive. L'individuazione delle query di interesse ha richiesto i seguenti passaggi:
- calcolo del **tempo medio di esecuzione** per ogni query, escludendo gli outliers in una certa misura:
  $$
  \bar{T} = (T_e - t_M- t_m) / (C - 2)
  $$
  dove $\bar{T}$ è il tempo medio di esecuzione, $T_e$ il tempo totale di esecuzione, $t_M$ e $t_m$ sono rispettivamente tempo massimo e tempo minimo di esecuzione, $C$ è il numero di invocazioni della query in questione nell'intervallo temporale considerato;
- calcolo del **service demand** della CPU e del disco per ogni query:
    $$
    D_c = \bar{T} - ((B_r + B_w) / C)\\
    $$

    $$
    D_d = \bar{T} - D_c
    $$

  dove rispettivamente $D_d$ e $D_c$ sono i service demand del disco e della cpu, mentre $B_r$ e $B_r$ sono i tempi di lettura e scrittura totali del disco;
- calcolo del **rapporto tra service demand della cpu e quello del disco**:
  
  $$
  R = D_c/D_d
  $$
    
    Questo ultimo calcolo ci ha permesso di individuare come query CPU-Intensive quella con il massimo valore di $R$ (nel nostro caso, $R = 57$ circa), e come Disk-Intensive quella con il valore minimo ($R = 0.54$ circa).

Detto ciò, vengono riportate le due query così individuate:
- **CPU-Intensive**:
    - Nome: Q16
    - $D_c = 0.8418712777657399s$
    - $D_d = 0.01474560369767442s$
- **Disk-Intensive**:
    - Nome: Q7
    - $D_c = 0.8933116159835509s$
    - $D_d = 1.630294817162791s$

## Punto 1

A questo punto, è stato eseguito un benchmark separato per ciascuna delle due query individuate. E' stato considerato un tempo di esecuzione di 300 secondi per ciascun benchmark e le statistiche sul throughput sono state estratte dal file JSON "summary" prodotto da Benchbase, mentre le altre statistiche sono state estratte dalla vista `pg_stat_statements`.

> Nota: è stato considerato il goodput, anzichè il throughput, di suddetto file "summary".

A partire da service demand $D$ e throughput $X$ così ottenuti, e sapendo che il numero medio di job $N$ nel sistema è pari a 1, è stato possibile derivare l'utilizzazione $U$ e il tempo di risposta $T_r$ tramite le formule seguenti:
- Legge del service demand: $U = X \cdot D$
- Legge di Little: $T_r = \frac{N}{X}$

Per ciascuna delle query in questione riportiamo le rispettive grandezze.

Query *CPU-Intensive*:
- $X = 1.1428574273565018 \space req/s$
- $D_c = 0.873331s$
- $D_d = 0.003121s$
- $U_c = 99.8\%$
- $U_d = 0.35\%$
- $T_r = 0.8749997821802326s$
- Files delle statistiche per consultazione: [`pg_stat_statements_1_16_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics), [`CPUint_summary.json`](https://github.com/tontonialberto/tagd-project/statistics)
  
Query *Disk-Intensive*:
- $X = 0.4119602231342898 \space req/s$
- $D_c = 0.900671s$
- $D_d = 1.54916s$
- $U_c = 37.1\%$
- $U_d = 63.8\%$
- $T_r = 2.4274188230887095s$
- Files delle statistiche per consultazione: [`pg_stat_statements_1_7_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics), [`DISKint_summary.json`](https://github.com/tontonialberto/tagd-project/statistics)

E' scontato che la CPU e il disco siano il collo di bottiglia, rispettivamente, per la query CPU-Intensive e per quella Disk-Intensive. Tuttavia è possibile fare delle considerazioni più accurate: l'utilizzazione della CPU è quasi al massimo nella query CPU-Intensive, dunque il sistema è in saturazione. Cio' non si verifica per il carico Disk-Intensive, in quanto l'unità disco è utilizzata solo al 64%, un livello accettabile di utilizzazione delle risorse.

## Punto 2

Tramite JMT è stato realizzato un modello simulativo concernente le due classi di workload individuate. Per la modellazione di suddetta rete chiusa sono stati utilizzati i service demand presentati al Punto 1.

A seguire delle tabelle di comparazione dei risultati tra il sistema reale e il modello utilizzante un singolo job per ciascuna classe di workload.

Per la query *CPU-Intensive*:
|                                | Modello simulativo | Sistema reale |
| ------------------------------ | ------------------ | ------------- |
| Throughput del sistema (req/s) | 1.1669             | 1.142         |
| Utilizzazione CPU (%)          | 98.31              | 99.8          |
| Utilzzazione Disco  (%)        | 1.72               | 0.35          |

Per la query *Disk-Intensive*:
|                                | Modello simulativo | Sistema reale |
| ------------------------------ | ------------------ | ------------- |
| Throughput del sistema (req/s) | 0.3956             | 0.4119        |
| Utilizzazione CPU (%)          | 35.7               | 37.1          |
| Utilzzazione Disco  (%)        | 64.8               | 63.8          |

Possiamo dunque ritenere il modello sufficientemente accurato e rappresentativo del sistema reale considerato finora. Il file di suddetto modello è consultabile accedendo al repository del progetto: [`punto1.jmva.jsimg`](https://github.com/tontonialberto/tagd-project/models).

## Punto 3

Impostando il parametro `terminals` pari a 2 nel file di configurazione di benchbase, sono stati eseguiti nuovamente, per 300 secondi ciascuno, i benchmark relativi alle due classi di workload, al fine di valutare le prestazioni con un numero di query concorrenti pari a 2.

Le nostre considerazioni a priori ci fanno supporre che il throughput del carico CPU-Intensive non possa aumentare per via delle considerazioni fatte ai Punti 1 e 2. Invece dal carico Disk-Intensive ci si potrebbe aspettare un aumento del throughput in quanto l'attuale collo di bottiglia, il disco, non è ancora giunto a saturazione.

A seguire le tabelle di comparazione tra il sistema reale e il modello simulativo precedentemente sviluppato, con un numero di customers pari a 2.

Per la query *CPU-Intensive*:
|                                   | Modello simulativo | Sistema reale |
| --------------------------------- | ------------------ | ------------- |
| Throughput del sistema (req/s)    | 1.1865             | 1.1295        |
| Utilizzazione CPU (%)             | 99.98              | 99            |
| Utilzzazione Disco  (%)           | 1.76               | 0.63          |
| Tempo di risposta del sistema (s) | 1.7736             | 1.7705        |

Per la query *Disk-Intensive*:
|                                   | Modello simulativo | Sistema reale |
| --------------------------------- | ------------------ | ------------- |
| Throughput del sistema (req/s)    | 0.5152             | 0.6445        |
| Utilizzazione CPU (%)             | 45.9               | 37            |
| Utilzzazione Disco  (%)           | 83.85              | 62.1          |
| Tempo di risposta del sistema (s) | 2.6615             | 3.1031        |

Come atteso, le previsioni del modello confermano la saturazione preannunciata per il workload CPU-Intensive (il throughput aumenta in modo trascurabile rispetto al caso con un solo job) e l'apprezzabile incremento di throughput per il carico Disk-Intensive (con il collo di bottiglia che passa da un'utilizzazione del 64.8% con un solo job all'83.85% con due job).

Si può notare come le previsioni per il carico CPU-Intensive continuino ad essere accurate, mentre ciò non accade per il carico Disk-Intensive: con 2 job, infatti, l'utilizzazione reale del disco è oltre 20 punti percentuali inferiore a quanto predetto dal modello. Riteniamo che ciò sia ritenuto alla tecnologia NVMe utilizzata dall'unità disco del sistema reale, la quale è in grado di ottimizzare alcune operazioni di lettura/scrittura permettendo di mantenere un'utilizzazione del disco relativamente bassa. Tuttavia questa è un'ipotesi per esclusione a seguito di diversi esperimenti e ricerche.

Ad ogni modo, riteniamo che il modello simulativo sia da ritenersi affidabile per lo svolgimento dei punti successivi; cio' è principalmente motivato dall'accuratezza dei risultati ottenuti nelle sezioni precedenti.

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


## Punto 5

-------------------------------------------PUNTO5--------------------------------------------

utilizzati i service time del Punto 0.

query bilanciata con D_CPU/D_DISCK = 0.974986 (D_CPU=1.012455; D_DISK=1.038430)

il sistema base è stato modellato con 12 cpu e 10 dischi raid, mantenendo un'utilizzazione pari al 76% per la cpu e 88% per il disco al fine di avere più "spazio" nel modellamento di tali risorse; in effetti l'idea è stata quella di aumentare la "frequenza di clock" delle cpu e aumentare la "velocità di I/O" del disco tramite la variazione dei service demand.

lo stesso modello è stato testato come sistema scarico, ossia una query alla volta, ed ha portato i seguenti risultati riguardo i tempi di risposta:

          .query A/B -> tempo risposta = 0.8436 circa   (CPU-int)
          .query C -> tempo risposta = 1.64         (BALANCED) -> da non superare
          .query D/E -> tempo risposta =  1.55     (DISK-int) 

effettivamente i tempi di risposta con tutte le query circolanti nel sistema erano eccessivamente piu alti di quelli a sistema scarico (con un massimo di 5.3820s).

Dopo vari tentativi siamo riusciti a combinare opportunamente i service demand con decrementi mirati in percentuale.

Ecco qui riportate le specifiche di tale soluzione:
-  CPU 
    - 12 cpu utilizzate, con "frequenza di clock" aumentata del 20% (moltiplicato service demand per 0.8)
    - utilizzazione: 61% circa

- DISCO (raid 0)
    - 10 dischi utilizzati, con "velocità di operazioni I/O" aumentate del 35% (moltiplicato service demand per 0.65)
    - utilizzazione: 57.5% circa  

Possiamo concludere dicendo che i requisiti temporali e di utilizzazione della cpu sono stati rispettati anche se l' utilizzazione del disco non rispetta tali specifiche di un 2.5% circa, in effetti questa soluzione è stata fondamentale per garantire un trade-off tra utilizzazione e tempi di risposta dato che la query bilanciata ha creato non pochi problemi; si è deciso di dare priorità al rispetto delle specifiche per quanto riguarda i tempi di risposta piuttosto che per l'utilizzazione (l'utente è soddisfatto, il proprietario dell'hardware un po' meno ;), resta il fatto che il discostamento tra utilizzazione del disco nei requisiti e quello nel modello creato può essere considerato trascurabile.



