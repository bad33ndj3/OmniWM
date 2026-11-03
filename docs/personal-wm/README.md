# Persoonlijke windowmanager

Status: ontwerp en browserdemo goedgekeurd, 2 november 2026. Eerste geïsoleerde native read-only dashboard gebouwd en gestart; zie [native vervolgstappen](native-next-steps.md).

## Doel

Een persoonlijke macOS-windowmanager onderzoeken vanuit Caspers dagelijkse werk.
OmniWM dient als referentie. Forken, uitbreiden of zelf bouwen blijft open.

## Wat Casper wil behouden

- Vensters scrollen op de hoofdas van elk scherm.
- Duidelijke shortcuts voor focus, verplaatsen en afmetingen.
- Vensters verplaatsen tussen schermen en binnen de scrollstrook.
- Quake: een venster snel oproepen en verbergen; geen vaste terminal vereist.

## Wat moet verbeteren

- Wisselen tussen thuis, kantoor en alleen het laptopscherm.
- Een simpele UI om apps te vinden en vensters te herverdelen.

### Verduidelijking uit het gesprek

- `Hyper+Left` moet naar het fysiek bedoelde linkerscherm verplaatsen.
- Thuis en kantoor hebben verschillende schermposities.
- De widget moet vensters lokaliseren, tussen schermen verplaatsen en herindelen.
- Quake moet met één commando boven andere vensters verschijnen.
- Een volledige werkronde met simpele widget is het gewenste prototypebewijs.

### Verdere verduidelijking

- Het dashboard mag als quake boven de werkruimte verschijnen.
- Vensterverdeling wisselt met de taak: reviewen, programmeren of meetings.
- Automatisch herstellen na aansluiten is optioneel.
- Hoverfocus pauzeert in het dashboard en hervat na echte muisbeweging.
- Browserdemo is gebouwd; echt monitor- en macOS-gedrag vraagt later een aparte proef.

### Bevestigde bediening

| Actie | Bediening |
| --- | --- |
| Quake openen/sluiten | Uitsluitend `Hyper+T`; klikken elders verbergt niet. |
| Venster naar ander scherm | `Hyper+Pijlen`, volgens fysieke richting. |
| Venster binnen landschapsstrook verplaatsen | `Option+Shift+Links/Rechts`. |
| Focus binnen landschapsstrook verplaatsen | `Option+Links/Rechts`. |
| Venster binnen thuis-portretstrook verplaatsen | `Option+Shift+Omhoog/Omlaag`. |
| Focus binnen thuis-portretstrook verplaatsen | `Option+Omhoog/Omlaag`. |
| Focus na verplaatsing naar ander scherm | Niet met het verplaatste venster meegaan. |
| Hoverfocus | Behouden, tijdelijk pauzeren tijdens dashboardbediening. |

Na een schermverplaatsing blijft focus op de dichtstbijzijnde tegel op het bron-scherm.
Een lege bron houdt het scherm geselecteerd zonder gefocuste tegel.
Thuis gebruikt het portretscherm een verticale strook; afmetingen wijzigen daar de hoogte.
Kantoor toont twee gelijke 16:9-schermen naast elkaar, boven de gecentreerde laptop.
Quake blijft zichtbaar na achtergrondklik; alleen de demo-knop simuleert `Hyper+T`.
Het dashboard heeft een aparte knop; `Escape` sluit alleen het dashboard.
Zie de [browserdemo-specificatie](browser-demo-spec.md) voor de bevestigde interacties.

De laptopverzamelregel en muisfocusguard zijn bevestigd voor deze demo.

De technische oorzaak van het richtingsprobleem is nog niet vastgesteld.
Upstream ondersteunt meerdere opstellingen; lokale configuratie bevat er al twee.

## Documenten

- [Ontwerpgesprek](design-tree.md): beslissingen, vragen en afhankelijkheden.
- [Prototypeplan](prototype-plan.md): voorlopige scope en bewijscriteria.
- [Browserdemo-specificatie](browser-demo-spec.md): goedgekeurde demo-scope.
- [POC](../../poc/prototype.html): lokaal, zonder installatie of opslag.
- [Native vervolgstappen](native-next-steps.md): geïsoleerde voorbereiding en live-gates.
- [Controleverslag](validation.md): browsercontroles en beperkingen.
- [OmniWM-onderzoek](omniwm-research.md): brononderzoek is afgerond.

## Demo lokaal

Open [de POC](../../poc/prototype.html) rechtstreeks in een browser.
Open [de zelfcontrole](../../poc/prototype.html?selftest=1) voor de ingebouwde logica-controle.

## Grenzen

- Geen wijzigingen aan de actieve windowmanager of configuratie.
- De demo bestuurt geen echte vensters of macOS-shortcuts.
- Native taal, fork en API blijven open tot de latere technische proef.

## Lokale observaties

Bron: `/Users/casper.spruit@energyzero.nl/dotfiles/config/omniwm/settings.toml`, gelezen op 2 november 2026.
Dit zijn configuratiegegevens, geen bevestigde runtime-resultaten.

- Er bestaan twee aangepaste monitoropstellingen met display-UUID's.
- Quake gebruikt het scherm van het gefocuste venster.
- Quake staat gecentreerd, op 75% breedte en 80% hoogte.
- Automatisch verbergen staat uit.
- `Option+Arrow` bedient de focus.

`/Users/casper.spruit@energyzero.nl/dotfiles/config/omniwm/AGENTS.md` beschrijft oudere thuisschermen.
De actuele fysieke opstellingen en storingen moeten nog bevestigd worden.
