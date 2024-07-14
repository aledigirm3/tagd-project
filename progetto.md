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

Viene ora utilizzato il modello simulativo per effettuare previsioni sulle prestazioni della macchina reale qualora si utilizzino 2 CPU e al variare del numero di query concorenti da 1 a 5.

A seguire una serie di schermate dell'analisi *What-If* condotta tramite JMT per la query *CPU-Intensive*. Vengono mostrati nell'ordine, unicamente per il collo di bottiglia (CPU), gli andamenti del numero medio di clienti nel centro, del throughput e dell'utilizzazione.

![](./image_1.png)
![](./image_3.png)
![](./image_4.png) 

Come atteso, superato un numero di *customers* pari a 2, la CPU va in saturazione: con 3 *customers* l'utilizzazione è circa pari al 100%. Il throughput aumenta rapidamente fino a 2 *customers* con un valore pari a $X = 2.3 \space req/s$, per poi salire di molto poco (di 0.1 circa) fino a completa saturazione all'ulteriore aumentare di job/customers nel sistema.

A seguire gli andamenti, rispetto al collo di bottiglia (Disco), nel caso della query *Disk-Intensive*.

![](./dimage_1.png)
![](./dimage_3.png)
![](./dimage_4.png) 

Il disco arriva a quasi saturazione con 3 *customers* (con utilizzazione del 97% circa) e un throughput che fino a 2 *customers* sale rapidamente fino a $X=0.56 \space req/s$ circa, per poi salire progressivamente in modo più lento, fino a raggiungere la saturazione con customers.

A verifica della bontà delle previsioni, vengono eseguiti ulteriori benchmark (di 300 secondi ciascuno) sul sistema reale. 

A seguire un resoconto del throughput e dello stato di utilizzazione del collo di bottiglia per la query *CPU-Intensive* con 2 e 5 job concorrenti:
- Con 2 job concorrenti:
    - $U_c = 99.4708954550472\%$
    - $X = 2.1860486094211584 \space req/s$
- Con 5 job concorrenti:
    - $U_c = 98.30228695699584\%$
    - $X = 2.2126251062282 \space req/s$

A seguire un resoconto analogo per la query *Disk-Intensive*:
- Con 2 job concorrenti: 
    - $U_d = 43.401358968800696\%$
    - $X = 0.43853842920049774 \space req/s$
- COn 5 job concorrenti:
    - $U_d = 99.99\%$
    - $X = 0.7541532588537293 \space req/s$

I files delle statistiche sono consultabili ai seguenti link:
- Benchmark CPU-Intensive con 2 job: [`pg_stat_statements_4_16_2_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics), [`CPUint_summary_4_2.json`](https://github.com/tontonialberto/tagd-project/statistics)
- Benchmark CPU-Intensive con 5 job: [`pg_stat_statements_4_16_5_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics), [`CPUint_summary_4_5.json`](https://github.com/tontonialberto/tagd-project/statistics)
- Benchmark Disk-Intensive con 2 job: [`pg_stat_statements_4_7_2_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics), [`DISKint_summary_4_2.json`](https://github.com/tontonialberto/tagd-project/statistics)
- Benchmark Disk-Intensive con 5 job: [`pg_stat_statements_4_7_5_300s.csv`](https://github.com/tontonialberto/tagd-project/statistics),[`DISKint_summary_4_5.json`](https://github.com/tontonialberto/tagd-project/statistics)

Possiamo dunque concludere confermando l'accuratezza del modello nei confronti del carico CPU-Intensive, mentre per il numero di job considerati esso si discosta in maniera non trascurabile dai risultati ottenuti in via sperimentale per il carico Disk-Intensive, sebbene tale discostamento sembri diminuire nel caso di 5 job concorrenti, soprattutto in termini di utilizzazione (vi è saturazione sia nel caso predetto sia nel caso reale).

### Punto 4a 

In questa sezione viene utilizzato il modello simulativo precedentemente sviluppato per far fronte ad ulteriori requisiti porgettuali: garantire un tempo di risposta medio inferiore a 30s, prevedere un numero di query concorrenti non superiore a 20 e nel contempo mantenere l'utilizzazione dei centri nel range 60-70%, avendo cura di implementare la ridondanza dei dischi tramite RAID 5.

Si è scelto di modellare il sottosistema di storage come un RAID 0 in quanto equivalente al RAID 5 a livello di variabili operazionali, avendo cura tuttavia di aggiungere - in produzione - un ulteriore disco agli N utilizzati in fase di modellazione al fine di ottenere prestazioni analoghe.

Per modellare tale soluzione tecnologica si è utilizzato il template "RAID 0" disponibile all'interno di JMT, avendo cura di specificare il service demand di ciascun disco nell'array (supponendo di avere N dischi) nel seguente modo:

$$
D'_{d} = \frac{D_{d}}{N}
$$

A questo punto, si è deciso di approcciare prima il carico Disk-Intensive con lo scopo di determinare un adeguato dimensionamento del disco, dimensionare eventualmente la CPU in accordo per poi applicare l'iter al workload CPU-Intensive.

Dopo un ristretto numero di tentativi, si è giunti ad una configurazione in grado di soddisfare le specifiche progettuali in termini di tempo di risposta per workload Disk-Intensive. Tale configurazione fa utilizzo di 20 CPU e 40 dischi RAID 0. A seguire le statistiche ottenute dal modello simulativo considerando 20 customers nel sistema:
- $U_d = 65\%$
- $U_c = 70.5\%$
- $X = 15.87 \space req/s$
- $T_r = 1.26s$

Come possiamo notare, il nuovo collo di bottiglia è ora la CPU, con un'utilizzazione leggermente superiore al 70.5%. Tuttavia dobbiamo ancora effettuare il dimensionamento circa il carico CPU-Intensive: le simulazioni condotte hanno consentito di verificare l'ottenimento di un buon risultato aumentando le CPU fino a 30.

In definitiva, l'utilizzo di 30 CPU e 40 dischi in configurazione RAID 0 consentono di soddisfare le specifiche di progetto. A seguire le statistiche per il carico CPU-Intensive con 20 customers nel sistema:
- $U_c = 66\%$
- $U_d = 0.008\%$
- $X = 23.6935 \space req/s$
- $T_r = 0.84s$

Per completezza si riportano anche le statistiche per il carico Disk-Intensive con 20 customers nel sistema:
- $U_d = 64\%$
- $U_c = 48\%$
- $X = 15.76 \space req/s$
- $T_r = 1.27s$
  
Il file del modello simulativo utilizzato è consultabile al seguente link: [`punto4.jmva.jsimg`](https://github.com/tontonialberto/tagd-project/models).


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



