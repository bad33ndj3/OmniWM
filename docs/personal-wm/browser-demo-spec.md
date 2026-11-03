# Browserdemo — bouwspecificatie

**Status:** volledig ontwerp en browserdemo zijn goedgekeurd. De uitvoering staat in [poc/prototype.html](../../poc/prototype.html).

## Doel en oplevering

- Eén lokaal HTML-bestand zonder dependencies, backend of netwerkverkeer.
- Simuleer schermen, focus, verplaatsen, breedtes, dashboard en quake.
- Gebruik geen opslag, echte vensters of echte macOS-bediening.
- Alle zichtbare labels zijn Nederlands.

## Schermdiagram

Toon selecteerbare, fictieve schermen met label **Demo** en stabiele demo-ID’s.
Gebruik geen echte modelnamen of display-UUID’s.

| Opstelling | Fictieve plaatsing |
| --- | --- |
| Thuis-demo | Laptop linksonder; breed scherm rechts; verticaal portretscherm rechtsboven. |
| Kantoor-demo | Twee gelijke 16:9-landschapschermen raken elkaar boven de laptop. Linkerscherm staat links; laptop is onder de naad gecentreerd. |
| Laptop-demo | Alleen het laptopscherm. |

Toon per scherm de contextuele naam, actieve rand en scrollstrook op de hoofdas.
Thuis gebruikt een verticale strook op Portret; de andere schermen scrollen horizontaal.
Het kantoor gebruikt dezelfde stabiele scherm-ID's, met labels Linkerscherm en Rechterscherm.
Links/rechts geeft voorrang aan schermen met overlappende verticale omvang.
Omhoog/omlaag geeft voorrang aan schermen met overlappende horizontale omvang.
Zonder overlap kiest het dichtstbijzijnde scherm verderop; gelijke afstand breekt op scherm-ID.
Zonder doelscherm blijft de toestand gelijk en verschijnt korte feedback.

Bij wisselen gaan verdwijnende schermtegels naar Laptop.
Laptoptegels blijven vooraan; daarna volgen bronstroken op scherm-ID-volgorde.
Behoud de volgorde per strook. Herstel niets automatisch bij terugkeer.

## Vensters en bediening

- Toon appnaam, focus, scherm, primaire afmeting en korte actiefeedback.
- Landschapsstroken: `Option+Links/Rechts` focust; `Option+Shift+Links/Rechts` wisselt met de buur.
- Thuis-Portret: `Option+Omhoog/Omlaag` focust; `Option+Shift+Omhoog/Omlaag` wisselt met de buur.
- Afmetingen **⅓**, **½**, **⅔** en **volledig** gelden op de hoofdas; Portret verandert dus hoogte.
- `Hyper+Pijlen` gebruikt zichtbare richtingsknoppen; registreer geen globale shortcuts.
- Richtingsknoppen verplaatsen de focustegel naar het doelscherm.
- Slepen verplaatst tegels tussen schermen of herschikt ze binnen een strook.
- Zonder tegel of doel blijft de toestand gelijk; toon kort waarom.

Na verplaatsen blijft focus op het bron-scherm en de dichtstbijzijnde overgebleven tegel.
Als de bron leeg is, blijft het scherm geselecteerd zonder gefocuste tegel.
Na slepen of schermverplaatsing hervat hoverfocus pas na echte muisbeweging.

Afmetingen voor de focustegel: **⅓**, **½**, **⅔** en **volledig**.
Toon de gekozen breedte of hoogte direct in het schermdiagram.
Toetsen werken alleen met demo-focus en buiten tekstvelden.

## Dashboard en quake

- Een aparte zichtbare knop opent of sluit het dashboard.
- `Escape` sluit alleen het dashboard; hoverfocus pauzeert zolang het openstaat.
- Quake heeft een losse zichtbare knop met label `Hyper+T`.
- De knop voert de mockactie uit; `Hyper+T` blijft conceptuele bediening.
- De quakekaart toont vaste mocktekst, zonder shell of command-uitvoering.
- Achtergrondklik verbergt de quakekaart niet.

## Walkthroughs en vormgeving

- Bied drie walkthroughs: **Programmeren**, **Reviewen** en **Vergaderen**.
- Elke walkthrough toont voorbeeldapps, schermverdeling en zichtbare beginstaat.
- Walkthroughs zijn voorbeelden, geen opgeslagen profielen; acties wijzigen de zichtbare staat.
- Gebruik warm-neutrale achtergrond, monochrome schermen en één gedempte teal focuskleur.
- Houd het dashboard compact en functioneel; voeg geen marketing of decoratieve widgets toe.

## Acceptatie en grenzen

- Alle drie fictieve opstellingen zijn kiesbaar en tonen hun geometrie.
- Landschapsstroken scrollen horizontaal; thuis-Portret scrollt zichtbaar verticaal.
- Tegels focussen, herschikken, slepen en tonen primaire afmetingspreset.
- Kantoor toont twee even grote schermen die elkaar raken boven de gecentreerde laptop.
- Richtingsacties, bronfocusfallback, lege bron en ontbrekend doel tonen de beschreven uitkomst.
- Dashboard, quake en `Escape` werken los; achtergrondklik laat quake staan.
- Walkthroughs tonen voorbeelden; verdwijnende tegels volgen de bevestigde Laptop-regel.
- Geen echte vensters, Accessibility, monitorinventaris, globale shortcuts, terminal of opslag.
- Laptopverzameling en focusguard zijn goedgekeurde demo-afspraken.
- Deze specificatie is goedgekeurd voor prototypebouw.
- Browserresultaat bewijst geen native haalbaarheid of hardwaregedrag.
