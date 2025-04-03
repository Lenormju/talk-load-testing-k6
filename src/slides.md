# Load Testing avec k6

---

# Le problème

* gros client signé 🎉  <!-- .element: class="fragment" -->
* tenir la charge 😱  <!-- .element: class="fragment" -->
* spoiler : non  <!-- .element: class="fragment" -->
* savoir par quoi commencer  <!-- .element: class="fragment" -->

---

# Le contexte

![](./archi_simple.excalidraw.png)

---

![](./archi_charge.excalidraw.png)

---

# Le plan

* quelle est notre archi ?  <!-- .element: class="fragment" -->
* qu'est-ce qu'on suspecte qui va péter ?  <!-- .element: class="fragment" -->
* qu'est-ce qu'on veut tester ? (fonctionnel / SLA)  <!-- .element: class="fragment" -->
* quels besoins techniques pour les tests ?  <!-- .element: class="fragment" -->
  * VMs + script de provisionnement ?  <!-- .element: class="fragment" -->
  * outil de load testing ?  <!-- .element: class="fragment" -->
  * données réalistes ?  <!-- .element: class="fragment" -->
  * débit ?  <!-- .element: class="fragment" -->

---

# k6

* "Grafana k6 is an open-source, developer-friendly, and extensible load testing tool."  <!-- .element: class="fragment" -->
* "k6 allows you to prevent performance issues and proactively improve reliability."  <!-- .element: class="fragment" -->
* orienté HTTP (ou browser)  <!-- .element: class="fragment" -->
* juste un binaire (Go) == installation facile  <!-- .element: class="fragment" -->
* v1.0 toute récente  <!-- .element: class="fragment" -->
* Javascript 😱 (ou TypeScript 🥸)  <!-- .element: class="fragment" -->
  * transpilé en Go 🦫  <!-- .element: class="fragment" -->
* exécuter une fonction en parallèle + en boucle  <!-- .element: class="fragment" -->
* stats pendant et à la fin  <!-- .element: class="fragment" -->

---

## Script minimal

```javascript
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  iterations: 10,
};

export default function () {
  http.get('https://quickpizza.grafana.com');
  sleep(1);
}
```

---

```shell
$ k6 run script_minimal.js
```

[...]

```
data_received..................: 32 kB  2.8 kB/s
data_sent......................: 1.0 kB 92 B/s
http_req_blocked...............: avg=26.35ms  min=400ns    med=651ns    max=263.49ms p(90)=26.35ms  p(95)=144.92ms
http_req_connecting............: avg=10.96ms  min=0s       med=0s       max=109.69ms p(90)=10.96ms  p(95)=60.33ms
http_req_duration..............: avg=108.97ms min=107.43ms med=108.62ms max=111.04ms p(90)=110.91ms p(95)=110.98ms
  { expected_response:true }...: avg=108.97ms min=107.43ms med=108.62ms max=111.04ms p(90)=110.91ms p(95)=110.98ms
http_req_failed................: 0.00%  0 out of 10
http_req_receiving.............: avg=157.2µs  min=82.8µs   med=123.01µs max=294.46µs p(90)=274.06µs p(95)=284.26µs
http_req_sending...............: avg=376.97µs min=56.42µs  med=182.76µs max=2.03ms   p(90)=753.35µs p(95)=1.39ms
http_req_tls_handshaking.......: avg=11.14ms  min=0s       med=0s       max=111.43ms p(90)=11.14ms  p(95)=61.28ms
http_req_waiting...............: avg=108.44ms min=107.06ms med=108.27ms max=110.52ms p(90)=109.19ms p(95)=109.86ms
http_reqs......................: 10     0.879973/s
iteration_duration.............: avg=1.13s    min=1.1s     med=1.1s     max=1.37s    p(90)=1.13s    p(95)=1.25s
iterations.....................: 10     0.879973/s
vus............................: 1      min=1       max=1
vus_max........................: 1      min=1       max=1
```

---

## Cycle de vie d'un test

* init (js)  <!-- .element: class="fragment" -->
* setup (JSON)  <!-- .element: class="fragment" -->
* run  <!-- .element: class="fragment" -->
* teardown  <!-- .element: class="fragment" -->

![https://grafana.com/media/docs/k6-oss/lifecycle.png](./k6_lifecycle.png)  <!-- .element: class="fragment" -->

---

## Virtual Users (VU)

* "The simulated users that run separate and concurrent iterations of your test script."  <!-- .element: class="fragment" -->
* exécuté en parallèle (go routines)  <!-- .element: class="fragment" -->
* jouent tous le même scénario qu'on leur donne  <!-- .element: class="fragment" -->

---

## Scénarios, executors, iterations

* scénario : modélisation d'une workload (nombre de VUs au cours du temps)  <!-- .element: class="fragment" -->
* un executor se charge de scheduler les VUs pour le scenario  <!-- .element: class="fragment" -->
* open/closed model : lier durée d'itération avec durée/débit du test ?  <!-- .element: class="fragment" -->
* disponibles :  <!-- .element: class="fragment" -->
  * Shared iterations  <!-- .element: class="fragment" -->
  * Per-VU iterations  <!-- .element: class="fragment" -->
  * Constant VUs  <!-- .element: class="fragment" -->
  * Ramping VUs  <!-- .element: class="fragment" -->
  * Constant arrival rate  <!-- .element: class="fragment" -->
  * Ramping arrival rate  <!-- .element: class="fragment" -->
  * Externally controlled (REST / CLI)  <!-- .element: class="fragment" -->
* stages  <!-- .element: class="fragment" -->

---

## Ramping VUs

![https://grafana.com/media/docs/k6-oss/ramping-vus.png](./ramping-vus.png)

---

## Ramping arrival rate

![https://grafana.com/media/docs/k6-oss/ramping-arrival-rate.png](./ramping-arrival-rate.png)

---

## Metrics, checks, thresholds

* built-in (vus précédemment)
* custom :
  * counter
  * gauge
  * rate
  * trend
* real-time ou summary à la fin

---

# Mise en application

script actuel :
* config par type de device
* calcul de débit que le test va exercer (en fonction du nombre de devices, de la config, ...)
* setup identifiants
* vu pour simuler un Edge via son testId
* setup en JSON
* sleep pour mix vu+constant
* metriques +rates custom
* quelques métrics + rates (429, total de données envoyées, ...)
* de la config pour paramétrer nos runners selon cibles de débit

* aucun executor pour notre use-case : couplage VU-device + sleep-itérations
choix executor : ramping vu + sleep pour obtenir : constant arrival rate par vu

bug counters pour le real-time
extension k6, bidouille dans les dashboards Grafana (compliqué), ou just Pandas (Python yay!)

VM Azure : bastion, network, IPv6, NAT, group sec, ...

---

## TODO

---

## Sources

* moi
* [la doc bien foutue de Grafana k6](https://grafana.com/docs/k6/)
  * [breakpoint testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/breakpoint-testing/)
  * [JavaScript compatibility mode](https://grafana.com/docs/k6/latest/using-k6/javascript-typescript-compatibility-mode/)
