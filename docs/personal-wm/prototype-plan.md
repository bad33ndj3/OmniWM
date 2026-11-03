# Fase 1 — prototype

Volledig ontwerp en browserdemo zijn goedgekeurd. De demo staat in [poc/prototype.html](../../poc/prototype.html).
Een native proef volgt later en vereist een aparte technische keuze.

## Onderzoeksvraag

Kunnen we Caspers scrollworkflow behouden en monitorwissels voorspelbaar maken?
De concrete gewenste uitkomst volgt uit het ontwerpgesprek.

## Voorstel: twee opeenvolgende proeven

De browserdemo is de volgende proef. De scope staat in de
[browserdemo-specificatie](browser-demo-spec.md).

### Fase 1a — browserdemo

Vraag: voelt het oproepbare dashboard logisch tijdens een werkronde?

- Simuleer schermen, vensters, scrollvolgorde en focus met voorbeelddata.
- Toon schermposities ruimtelijk; laat vensters tussen schermvlakken slepen.
- Simuleer links/rechts verplaatsen, inclusief wisselen van monitoropstelling.
- Toon de actuele verdeling na iedere actie.
- Simuleer openen en sluiten van dashboard en quake-venster.

Gebruik één eenvoudig lokaal HTML-bestand zonder backend of opslag.
Browsertoetsen zijn alleen demo-interacties; globale macOS-shortcuts blijven onbewezen.
Ook echte windowfocus, schermdetectie en altijd-bovenop werken zijn hiermee niet bewezen.
De strookrichting volgt de schermstand: thuis-portret verticaal, landschapschermen horizontaal.
Option-focus en herschikken gebruiken de bijbehorende pijlen; afmetingen volgen die as.

### Fase 1b — native technische proef

Vraag: werkt dezelfde afspraak met echte macOS-vensters en schermwissels?

Toets echte richting, focus, globale shortcuts, quake en aansluiten/loskoppelen.
Kies de technische route pas na de browserdemo en het ontwerpgesprek.
Een geslaagde browserdemo is geen acceptatie van dagelijks windowmanagergebruik.

## Voorgestelde minimale scope

Dit zijn latere native voorstellen, geen onderdeel van de bevestigde browserdemo.

- Scrollindelingen waarvan de richting de schermstand volgt.
- Eén afgesproken overgang tussen monitoropstellingen.
- Eén simpele UI-handeling die Casper nu mist.
- Eén quake-venster met een bestaande terminal.
- Een direct bereikbare stopactie en terugkeer naar OmniWM.

Elke regel blijft bespreekbaar. Schrap onderdelen die het gekozen scenario niet nodig heeft.

## Bewijs voor acceptatie

| Onderdeel | Te toetsen resultaat |
| --- | --- |
| Scrollen | Focus en verplaatsen houden de afgesproken volgorde aan. |
| Afmetingen | De presets blijven bruikbaar langs de primaire as van elk scherm. |
| Loskoppelen | Alle beheerde vensters blijven bereikbaar. |
| Aansluiten | Vensters volgen de gezamenlijk gekozen herstelregel. |
| Quake | Alleen `Hyper+T` toggelt; elders klikken behoudt zichtbaarheid en terminalsessie. |
| UI | Casper voert de gekozen handeling zonder shortcut uit. |
| Stoppen | Het prototype laat vensters bereikbaar achter. |

Herstel van de eerdere schermverdeling is optioneel, volgens Caspers antwoord.
De harde eis is bereikbaarheid en betrouwbare richting; herschikken moet mogelijk blijven.
Welke herstelregel we testen, blijft open tot daarover expliciet is besloten.

## Bevestigde interactievoorwaarden

- Schermverplaatsing gebruikt zichtbare richtingsknoppen; focus blijft op het bron-scherm.
- Landschapsstroken gebruiken `Option+Links/Rechts` voor focus en `Option+Shift+Links/Rechts` voor herschikken.
- De thuis-portretstrook gebruikt `Option+Omhoog/Omlaag` en `Option+Shift+Omhoog/Omlaag`.
- Hoverfocus pauzeert tijdens dashboardbediening.
- Een browserdemo simuleert deze toetsen; het kan systeemtoetsen niet betrouwbaar overnemen.
- Zie de [browserdemo-specificatie](browser-demo-spec.md) voor focus na verplaatsen.

## Aanvullend bevestigd

- Begin met de browserdemo, voordat native implementatie wordt overwogen.
- Bij ontbreken van een scherm in de gevraagde richting: geen verplaatsing, korte feedback.
- Versleepbare apptegels tonen de volgorde per scherm.
- Het dashboard ondersteunt herschikken binnen een scherm en verplaatsen tussen schermen.

Automatische logica-controles bewijzen geen fysiek monitorgedrag.
Monitorwissels vereisen tests met Caspers echte schermen.

## Volgorde na ontwerpbevestiging

1. Kies de kleinste technische route op basis van brononderzoek.
2. Leg één scenario met beginstaat en eindstaat vast.
3. Bouw uitsluitend wat dit scenario nodig heeft.
4. Controleer logica en stopgedrag; test daarna echte monitorwissels.
5. Bespreek de uitkomst voordat uitbreiding begint.

## Voorlopig buiten scope

Een eigen terminalengine, algemene pluginarchitectuur en publieke distributie.
Ook brede appcompatibiliteit en dagelijks gebruik zijn nog geen prototypebelofte.
