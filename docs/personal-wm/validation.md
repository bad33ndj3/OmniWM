# Controles

## Gecontroleerde liveproef — 2 november 2026

- Casper gaf akkoord voor de tijdelijke WM-wissel en expliciet voor beide macOS-rechten van de herbouwde ontwikkelapp.
- Toegankelijkheid moest opnieuw worden geregistreerd voor de actuele ad-hoc build; alleen uit/aan schakelen van de oude registratie volstond niet. Invoercontrole is voor de ontwikkelbundle toegevoegd. Schermopname is niet verleend.
- De nieuwe heropenroute toont **Je werkruimte** direct. De geïsoleerde socket antwoordt op `ping`; er draaide één WM-proces.
- Systeeminstellingen (PID 45714, venster 831) is via het dashboard verplaatst van laptopworkspace 1 naar de actieve workspace 6 van PL3493WQ.
- De echte AX-positie op het brede scherm is `2424, 1355 · 740 × 625`; de aparte IPC-teruglezing bevestigt dezelfde positie en doelworkspace.
- Na Escape kreeg Claude (venster 1055), de dichtstbijzijnde bronbuur op de laptop, daadwerkelijk focus.
- De eerste lege-bronmeting viel samen met gebruikersklikken en is geen geldige foutreproductie. Zonder tussentijdse klikken slaagt de herhaling: laptopworkspace 2 blijft current en zichtbaar, bevat nul vensters en er is geen gefocust managed venster.
- Er is geen leeg-bronfocusfix toegepast op basis van de verstoorde meting.
- Het testvenster is via dezelfde WM teruggezet naar workspace 1, exact op `261, 154 · 740 × 625`. De normale WM is daarna teruggezet en geeft `pong`; de bronsettingshash bleef gelijk.
- Wel reproduceerbaar: de WindowServer-inventaris liep achter op de AX-bevestiging, waardoor de tabel een oud scherm kon tonen tot Vernieuwen. Het dashboard herhaalt nu maximaal tien inventarislezingen met 100 ms tussenruimte. De verplaatsing wordt niet herhaald.
- Zeven dashboardtests slagen, waaronder vertraagde inventaris en begrensd stoppen bij een ontbrekend venster.
- De laatste UI-correctie is opnieuw fysiek getest: heen naar PL3493WQ en terug naar de laptop. Beide keren verandert de tabel automatisch naar het juiste scherm en worden de knoppen correct uitgeschakeld zonder Vernieuwen.
- Na deze eindproef zijn workspace en exact frame van Systeeminstellingen teruggelezen en gelijk aan het begin. Normale OmniWM draait weer als enige writer (PID 62626, `ping` = `pong`); bronconfig ongewijzigd.

Bewijs staat lokaal en Git-ignored in `.cache/personal-wm-probe-before.json`, `personal-wm-probe-moved.json`, `personal-wm-probe-focus.json` en `personal-wm-probe-empty-controlled.json`.

Nog niet afzonderlijk fysiek bevestigd: hoverfocus buiten het paneel, hervatten door uitsluitend echte muisbeweging en kantoor/laptop-hotplug.

## Heropenroute — 2 november 2026

- De ontwikkel-WM kreeg de vereiste rechten en antwoordde op de geïsoleerde socket. De normale WM was daarbij gestopt.
- Casper meldde dat het venster niet zichtbaar was. Computer-use vond alleen een lege eigen surface; de app had geen `applicationShouldHandleReopen`-route naar het dashboard.
- Regressietest `PersonalDashboardTests/testReopeningTheAppShowsTheDashboard` faalde vóór de wijziging met ontbrekende callback en ontbrekende dashboardlease.
- De nieuwe heropenroute toont het dashboard direct. Alle 35 gerichte WM-tests slagen, inclusief die regressietest.
- Tijdens herbouwen is de normale WM teruggezet; de bronconfiguratie bleef ongewijzigd.

## Proefstart na akkoord — 2 november 2026

- Casper gaf akkoord voor de tijdelijke wissel.
- De geïsoleerde bundle is gestart via de vastgelegde `use dev`-route. Alleen één OmniWM-proces draaide (ontwikkel-PID 45575).
- De zichtbare **OmniWM Permissions**-pagina toont Accessibility en Input Monitoring als **Not Granted**. WM-services zijn niet gestart; de dev-socket ontbrak.
- Geen rechten verleend en geen vensters verplaatst. De normale app is meteen teruggezet met `use release`.
- Terugkeer bevestigd: alleen normale OmniWM-PID 45798, CLI `ping` geeft `pong`; bronconfig heeft dezelfde SHA-256.
- Liveproef wacht op de twee macOS-rechten voor `com.barut.OmniWM.dev`. Start geen ontwikkel-WM naast de normale WM.

## Geïntegreerde ontwikkel-WM — bouwcontrole, 2 november 2026

- `./Scripts/build-personal-wm-dev.sh` slaagt: volledige ARM64-build, vertaalcontrole, verpakking en ad-hoc signatureverificatie.
- Gerichte WM-tests: 34 geslaagd. Deze omvatten bronbuur, lege bron, behoud van bronworkspace ondanks volginstelling, leaselevensduur en wissen van het hoversample bij sluiten.
- De vijf losse dashboardtests blijven groen na het delen van view/paneelcode.
- Bundle-ID `com.barut.OmniWM.dev` is uit de gebouwde plist teruggelezen.
- De geïsoleerde config is bytegelijk aan de actieve bronconfig; config en runtimebestand zijn 600, hun mappen 700. Beide staan onder Git-ignored `.cache/personal-wm-dev`.
- De bestaande OmniWM-PID is nog 14965; de actieve settingshash bleef `942f264eaad4bc1c25d55922b7413d968ab1c3660e02a4820e1ce4248e78fca3`.
- GhosttyKit is als inhoudelijk identieke lokale directory klaargezet, omdat de vertaalbuild de Nix-symlink niet kon importeren. De preflight blijft slagen.
- De nieuwe WM is niet gestart. Fysieke frameverplaatsing, echte native bronfocus, hotplug en hoverhervatting wachten op een toegestane liveproef.

Zie [native-integration.md](native-integration.md) voor de concrete activerings- en terugkeerroute.

## Native read-only dashboard — 2 november 2026

- `./Scripts/build-dashboard.sh` slaagt; plist en ad-hoc codesign-verificatie slagen.
- `~/.swiftly/bin/swiftly run swift test --package-path dashboard`: vijf tests, nul fouten.
- Tests dekken negatieve schermposities, portretverhouding, grootste vensteroverlap, ongeldige bounds, eigen vensters, overlays, Escape en `⌘R`.
- SwiftFormat-lint van het losse package en `bash -n Scripts/build-dashboard.sh` slagen.
- De app is echt geopend. UI-snapshot toont drie schermen: Built-in Retina Display, PL3493WQ en PL2492H.
- Zoeken op Slack toont één venster; filter PL2492H toont ChatGPT en Slack. `⌘R` vernieuwt de inventaris.
- Visuele controle leidde tot een aparte legenda: labels passen niet leesbaar in kleine schermrechthoeken.
- De directe paneeltest bevestigt dat Escape `isVisible` op false zet. Computer-use-inspectie van de verborgen app toont het paneel opnieuw; dit bewijst geen handmatige verberg/heropenacceptatie.
- De bestaande OmniWM heeft vóór en na dezelfde PID (14965). De actieve settings-SHA-256 bleef `942f264eaad4bc1c25d55922b7413d968ab1c3660e02a4820e1ce4248e78fca3`.
- Geen upstream-WM-code of bestaande installatie gewijzigd; geen extra rechten verleend.

Grenzen: alleen zichtbare vensters; titels zijn afgeschermd zonder schermopnametoestemming. Geen WM-schrijver, hoverfocuspauze, globale shortcuts, kantoor/laptop-hotplug of richtingcorrectie getest. Eigenaaracceptatie blijft open.

## Browserdemo — eerdere controle

Gecontroleerd op 2 november 2026 door de hoofdagent, na Luna Max' implementatie.

## Geslaagd

- De ingebouwde zelfcontrole slaagt: negentien controles voor richting, oriëntatie, focus en behoud van vensters.
- Echt slepen herschikt dashboardtegels en verplaatst ze tussen schermen, ook naar een schermkop.
- Een lege bron behoudt schermselectie zonder gefocust venster.
- Wisselen naar laptop verzamelt elk venster één keer; opnieuw aansluiten herstelt niets automatisch.
- Zonder doelscherm blijven de vensters ongewijzigd.
- Liggend gebruikt focus `Option+Links/Rechts`; portret gebruikt `Option+Omhoog/Omlaag`.
- Met `Shift` erbij herschikken dezelfde toetsen de strook op de betreffende as.
- Breedte wijzigen behoudt toetsenbordfocus op de bedieningsknop.
- Toetsenbordfocus op een verborgen tegel scrolt die tegel in beeld.
- Het dashboard krijgt initiële toetsenbordfocus en maakt de achtergrond tijdelijk inert.
- Quake blijft zichtbaar na achtergrondklik en na het sluiten van het dashboard met `Escape`.
- Visuele controle op 1440×900, 1280×800 en 390×844; bediening past zonder horizontale pagina-overloop.

## Aanvullende correctiecontrole

- Portret heeft aantoonbaar verticale overflow; toetsenbordfocus scrolt het volgende venster in beeld.
- Verticale herschikking werkt met `Option+Shift+Omlaag`.
- Kantoor toont twee even grote liggende schermen met gelijke bovenrand, direct naast elkaar.
- De laptop staat gecentreerd onder beide kantoorschermen.
- Schermverplaatsing naar links en rechts werkt in beide richtingen op kantoor.
- De drie kantoorschermen gebruiken horizontale stroken.

## Grenzen

- Dit bewijst uitsluitend browsergedrag met fictieve schermen en apps.
- Echte schermdetectie, macOS-shortcuts, Accessibility en terminalsessies zijn niet getest.
- De schermkaart wordt klein op telefoons; het dashboard blijft de praktische bediening.
- Caspers beoordeling van de workflow volgt nog; het prototype is geen gekozen native architectuur.

## Opnieuw controleren

Open `poc/prototype.html?selftest=1` via een lokale server, of gebruik `demo.selfTest()` in de browserconsole.
De zelfcontrole gebruikt aparte voorbeeldstatus en wijzigt de huidige demo-indeling niet.
Herlaad de pagina na een codewijziging voordat je browserresultaten beoordeelt.
