# Native vervolgstappen

**Status:** read-only dashboard en eerste WM-integratie zijn gebouwd en live beproefd. De normale WM draait weer; zie [native-integration.md](native-integration.md) en [controleverslag](validation.md).

## Voorbereid

- Volledige OmniWM-checkout op branch `personal-wm`, gebaseerd op `dfff63b775035d32efa04b7d500eb7d6008050c9`.
- Alleen de `upstream`-remote; er is niets gepusht.
- Persoonlijk brononderzoek, ontwerp en controleverslag staan in `docs/personal-wm/`; de POC staat in `poc/`.

## Read-only dashboard

- Build: `./Scripts/build-dashboard.sh`; start apart met `open "dist/OmniWM Dashboard Dev.app"`.
- Tests: `~/.swiftly/bin/swiftly run swift test --package-path dashboard`.
- Het aparte package `dashboard/` heeft geen dependencies en importeert geen OmniWM-code.
- Eigen bundle-ID: `com.barut.OmniWM.dashboard.dev`; de upstream-identiteiten blijven behouden.
- Geen configuratiebestand, opslag, Accessibility-writes, globale shortcuts of IPC-commando's.
- `CGWindowListCopyWindowInfo` leest alleen zichtbare normale vensters; geminimaliseerde vensters en andere Spaces ontbreken.
- `NSScreen` levert namen; `CGDisplayBounds` en vensterbounds delen het coördinatenstelsel met oorsprong linksboven.
- Zoeken en schermfilters werken; `⌘R` vernieuwt, `Escape` verbergt, de menubalkknop opent opnieuw.
- Titels kunnen ontbreken zonder schermopnametoestemming. De app vraagt die toestemming niet aan.
- De normale WM draait weer. Framebesturing en bronfocus van de ontwikkel-WM zijn live beproefd; hoverhervatting vraagt nog een aparte fysieke controle.

## Gereedheid en activatiegrens

- macOS 27.2 en Xcode 27.2 zijn live bevestigd.
- Swift `main-snapshot-2026-10-11` (6.5-dev), GhosttyKit en de vastgelegde format/linttools zijn geïnstalleerd.
- `~/.swiftly/bin/swiftly run make doctor` slaagt. Voer Swift-commando's via Swiftly uit; shellprofielen zijn niet aangepast.
- Het losse dashboard is ad-hoc ondertekend. De geïntegreerde ontwikkel-WM gebruikt het geïnstalleerde `LocalDevCert`.
- `make run` loopt via `dev-install` en `Scripts/omniwm-dev.sh install`; die route kan de actieve app stoppen.
- De geïsoleerde bundle, configmap en activatieroute zijn gereed. Bouwen start de app niet.

## Volgorde voor native werk

1. Inspecteer upstreams vensterlees- en schrijfpad. Lees na elke toegestane framewijziging de werkelijke positie terug.
2. Maak een aparte ontwikkelbundle en configuratiemap. Raak de bestaande app en configuratie niet aan.
3. Wijs één WM-component aan als enige schrijver van vensterposities. Laat dashboardacties via die schrijver lopen.
4. Integreer eerst het dashboard om apps, schermen en vensterposities te tonen. Begin met read-only gedrag.
5. Lees thuis-, kantoor- en laptopgeometrie op de Mac terug. Leg die exact vast en controleer de reproductie vóór wijziging van richtingsroutering.
6. Behoud upstream app-, bundle-, target- en CLI-namen. Bespreek hernoemen apart.

## Scheiding van status

**Voorbereid:** upstreambron, branch, onderzoek, browserdemo en vervolgstappen.

**Gebouwd en gestart:** aparte dashboardbundle, schermdiagram en zichtbaar vensteroverzicht. Vijf tests slagen; zoeken, schermfilters en vernieuwen zijn in de UI gecontroleerd.

**Gebouwd en live beproefd:** ontwikkel-WM met bronselectie, hoverfocuslease, expliciet doelscherm en AX-teruglezing. Gerichte WM-suite: 35 tests. Los dashboard: zeven tests. Verplaatsen, bronbuur, lege bron, heropenen en tabelverversing zijn in de echte app gecontroleerd.

**Nog niet live bevestigd:** hoverfocus buiten het paneel en hervatting met uitsluitend echte muisbeweging. Fysieke richtingsroutering is nu geïmplementeerd en met geometriegevallen getest. Kantoor/laptop-hotplug en fysieke acceptatie blijven open.
