# Ontwerpgesprek

Werkwijze: grilling, in rondes. Ronde 5 en het volledige demo-ontwerp zijn bevestigd.
De goedgekeurde browserdemo staat in [poc/prototype.html](../../poc/prototype.html).

## Beslisboom

1. Concrete problemen en gewenste uitkomst.
   - Voorbeeld van een mislukte monitorwissel.
   - Gewenste bestemming van vensters na aansluiten en loskoppelen.
   - Herstelgedrag na terugkeer naar een bekende opstelling.
2. Rol van de simpele UI.
   - Welke handeling moet zonder shortcuts kunnen?
   - Daarna: menubalk, overzicht, instellingen of combinatie.
3. Betekenis van quake.
   - Alleen terminal of ook andere apps?
   - Daarna: schermkeuze, focus, verbergen en behoud van sessies.
4. Succescriterium voor fase 1.
   - Eén volledige werksituatie aantoonbaar verbeteren.
   - Daarna: testapps, noodstop en praktijkscenario's.
5. Technische route.
   - Wacht op brononderzoek en antwoorden bij 1–4.
   - Vergelijk configuratie, kleine fork en eigen minimale manager.
   - Daarna: API-keuze, licentie, onderhoud en distributie.

## Ronde 1 — antwoorden ontvangen

- Thuis en kantoor hebben verschillende fysieke monitoropstellingen.
- `Hyper+Left` verplaatst daardoor niet betrouwbaar naar het bedoelde linkerscherm.
- De UI moet tonen waar apps staan, verplaatsen tussen schermen en herindelen.
- Quake moet met één commando boven andere vensters verschijnen en makkelijk vindbaar blijven.
- Het prototype moet een volledige werkronde en een simpele widget bevatten.

Dit beschrijft het ervaren probleem; de technische oorzaak is nog niet vastgesteld.
De upstream-code bevat wel ondersteuning voor meerdere monitoropstellingen.

### Oorspronkelijke vragen

1. Welke concrete monitorwissel gaat mis, en hoe moet die eindigen?
   Advies: begin met het vaakst voorkomende storende voorbeeld.
2. Welke handeling ontbreekt in een simpele UI?
   Advies: kies één dagelijkse handeling als eerste UI-doel.
3. Moet quake alleen een terminal oproepen, of ook willekeurige apps?
   Advies: begin met één bestaande terminal; bouw geen terminalemulator.
4. Welke geslaagde werksituatie maakt het prototype voor jou waardevol?
   Advies: verbind scrollen, shortcuts en een monitorwissel in één scenario.

## Ronde 2 — antwoorden ontvangen

- `Hyper+Left/Right` moet een app naar het fysiek aangrenzende scherm verplaatsen.
- Die richting moet betrouwbaar blijven bij verschillende schermopstellingen.
- Automatisch terugplaatsen is welkom, maar geen vereiste.
- Casper herverdeelt vensters afhankelijk van reviewen, programmeren of meetings.
- Een quake-achtig oproepbaar dashboard spreekt aan.
- OmniWM activeert momenteel vensters bij hover; actief scherm en muisscherm vallen daardoor samen.
- Dezelfde shortcut verbergt quake nu. Dit is vaak prettig, maar niet altijd.
- Casper vraagt of een browserprototype makkelijker is; keuze nog te bevestigen.

### Oorspronkelijke vragen

5. Moet links/rechts automatisch de schermposities uit macOS volgen?
   Advies: gebruik fysieke schermgeometrie; vermijd aparte handmatige richtingsprofielen.
6. Wat gebeurt er met vensters bij loskoppelen en opnieuw aansluiten?
   Advies: maak alles bereikbaar op overgebleven schermen; herstel bij terugkeer de eerdere verdeling.
7. Hoe open en bedien je de widget?
   Advies: een oproepbaar paneel met schermvlakken en vensters; klikken selecteert, slepen verplaatst.
8. Op welk scherm verschijnt quake?
   Advies: het scherm met het actieve venster, onafhankelijk van de muispositie.
9. Wanneer verdwijnt quake?
   Advies: dezelfde shortcut verbergt het; klikken elders laat het zichtbaar.

## Ronde 3 — antwoorden ontvangen

De antwoorden zijn op inhoud verwerkt; de vraagnummers liepen door elkaar.

- Quake opent en sluit voorlopig uitsluitend met `Hyper+T`.
- Klikken achter quake verbergt het niet; de terminal moet zichtbaar kunnen blijven.
- `Hyper+Pijlen` verplaatst een venster tussen fysieke schermen.
- `Option+Shift+Pijlen` verplaatst een venster binnen één scherm, in de Niri-scrollindeling.
- `Option+Pijlen` verplaatst focus.
- Focus verhuist niet mee bij verplaatsen naar een ander scherm.
- Hoverfocus blijft behouden, maar pauzeert tijdens dashboardbediening.
- De browserdemo is nog niet expliciet bevestigd.

### Oorspronkelijke vragen

10. Eerst een browserdemo voor dashboard en logica, daarna een native technische proef?
    Advies: ja. Een browserdemo bestuurt geen echte apps of monitoren.
11. Welke onhandige situatie vraagt om ander verberggedrag?
    Advies: dezelfde shortcut blijft toggle; Escape sluit alleen het dashboard.
12. Moet een schermverplaatsing de focus meenemen?
    Advies: ja, zodat volgende opdrachten bij hetzelfde venster blijven.
13. Moet hover ook in de eigen variant focus activeren?
    Advies in het gesprek: behoud hoverfocus; pauzeer tijdens dashboardbediening. Overgenomen.

## Ronde 4 — bevestigd

- Eerst een browserdemo van het dashboard en de vensterlogica.
- Zonder scherm in de gevraagde richting blijft het venster staan; korte feedback verklaart waarom.
- Het dashboard toont per scherm geordende, versleepbare apptegels.
- Slepen kan tussen schermen en binnen de scrollvolgorde.

### Oorspronkelijke vragen

14. Beginnen we met een browserdemo van het dashboard en de vensterlogica?
    Advies: ja; echte macOS-bediening volgt in een aparte technische proef.
15. Wat gebeurt er als er geen scherm in de gevraagde richting staat?
    Advies: niets verplaatsen; laat kort zien dat er geen scherm is.
16. Mag het dashboard ook de volgorde binnen een scrollstrook wijzigen?
    Advies: ja, toon per scherm een geordende vensterstrook met versleepbare apptegels.

## Open na ronde 4 — afgehandeld in ronde 5

- Ronde 4 liet focusfallback, dashboardbediening, schermrichting, breedtes en walkthroughs open.
- De volgende ronde legde daarvoor browserdemo-afspraken vast.

## Ronde 5 — antwoorden bevestigd

| Vraag | Bevestigd browsergedrag |
| --- | --- |
| 17. Focus na schermverplaatsing? | Blijf op bron-scherm; kies daar de dichtstbijzijnde tegel. |
| 17. Bron-scherm leeg? | Behoud het scherm, zonder gefocuste tegel. |
| 18. Dashboard tonen en sluiten? | Zichtbare dashboardknop; `Escape` sluit alleen het dashboard. |
| 18. Quake bedienen? | Losse mockknop met label `Hyper+T`; achtergrondklik laat hem staan. |
| 19. Scherm in fysieke richting kiezen? | Eerst overlappende schermranden; anders dichtstbijzijnde vooruit. |
| 20. Breedtes? | `⅓`, `½`, `⅔` en volledig. |
| 21. Walkthroughs? | Programmeren, reviewen en vergaderen; geen opgeslagen profielen. |

Deze afspraken gelden voor de browserdemo. De [bouwspecificatie](browser-demo-spec.md) beschrijft alle interacties.

## Correctie na ronde 5 — schermoriëntatie

- De eerste demo-aanname van één horizontale rij per scherm is vervallen.
- Thuis-Portret scrollt verticaal; Option-pijlen en afmetingen volgen die as.
- Kantoor toont twee gelijke 16:9-landschapschermen die elkaar raken boven de gecentreerde laptop.
- Het stabiele ID `portrait` krijgt op kantoor de contextuele naam Rechterscherm.
- De correctie vervangt de eerdere horizontale-only afspraken voor de demo.

## Bevestigde demo-afspraken

- Bij verdwijnende schermen gaan tegels naar Laptop, eerst bestaande Laptoptegels, daarna bronstroken op scherm-ID.
- De volgorde blijft per strook behouden; terugkeer herstelt niets automatisch.
- Na slepen of schermverplaatsing hervat hoverfocus pas na echte muisbeweging.
- Deze afspraken gelden voor de browserdemo; native gedrag blijft onbewezen.

## Besluiten voor een latere native proef

- Kies later de globale shortcut voor het dashboard.
- Bevestig echte thuis-, kantoor- en laptopmonitorposities.
- Toets Accessibility, globale shortcuts, monitor-hotplug en quake met echte apps.
- Kies daarna pas OmniWM-configuratie, fork of eigen bouw.
- Native werk wacht op een aparte technische keuze en echte hardwaretests.
