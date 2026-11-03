# Native dashboardintegratie

De geïntegreerde versie voegt **Werkruimte** toe aan OmniWM's eigen menubalkmenu. Opnieuw openen van de draaiende ontwikkelapp toont het dashboard rechtstreeks, ook wanneer het menubalkicoon verborgen is. Selecteer daar een venster en een doelscherm. De losse `OmniWM Dashboard Dev` blijft read-only.

## Waarom binnen de WM

De geïnstalleerde OmniWM 0.7.6 (`3c078395`, protocol 19) ondersteunt gericht verplaatsen via IPC, maar heeft geen dashboardlease. Bovendien staat `focus.followsWindowToMonitor` aan. Het dashboard gebruikt daarom de bestaande WM-componenten rechtstreeks. Er is geen tweede framewriter, geen nieuwe IPC-route en geen wijziging aan de actieve instellingen nodig.

## Uitvoering

- `PersonalDashboardKit` deelt het bestaande schermdiagram en vensteroverzicht met de losse proefapp.
- `PersonalDashboardController` registreert het paneel als eigen WM-surface. Een aparte `personalDashboard`-focuslease blokkeert hoverfocus zolang het zichtbaar is.
- De verplaatsing controleert de actuele PID, venster-ID, bronworkspace, doelscherm en native fullscreenstatus.
- Het doelscherm gebruikt zijn momenteel actieve workspace. Richtingsroutering wordt niet aangepast.
- De dichtstbijzijnde geschikte bronbuur wordt gekozen op basis van echte framecentra; gelijke afstanden gebruiken PID en venster-ID. Onleesbare bronposities blokkeren de actie.
- `WorkspaceNavigationHandler.moveWindow` en `finishWorkspaceMove(..., .retainCurrent)` gebruiken het bestaande layout- en AX-framepad. De normale volginstelling blijft behouden voor overige acties.
- Na de commit leest het dashboard maximaal twee seconden de echte AX-positie terug. Een wijziging van scherm/workspace of een ontbrekende bevestiging geeft een waarschuwing. De actie wordt nooit automatisch herhaald.
- Omdat WindowServer-inventaris achter kan lopen op AX, leest de UI daarna maximaal tien keer met 100 ms tussenruimte opnieuw totdat het venster bij het doelscherm verschijnt. Alleen lezingen worden herhaald.
- Het paneel blijft tijdens de verplaatsing open. Bij sluiten keert focus terug naar de bronbuur of de lege bronworkspace.
- Voor het opheffen van de lease wordt het gecachte hoversample verwijderd. Een nieuwe muisbeweging levert het volgende sample.

## Bouwen en controleren

```bash
./Scripts/build-personal-wm-dev.sh
LIBRARY_PATH="$PWD/Frameworks/GhosttyKit.xcframework/macos-arm64" \
  ~/.swiftly/bin/swiftly run swift test --arch arm64 \
  --filter 'PersonalDashboardTests|WindowMoveIPCIntegrationTests|FocusPolicyWindowFrontingTests|FullyVisibleHoverFocusTests'
```

De build verpakt alleen. Hij start of installeert niets. De bestaande upstream-installer is niet uitgevoerd.

| Onderdeel | Ontwikkelroute |
| --- | --- |
| App | `dist/OmniWM Dev.app` |
| Bundle-ID | `com.barut.OmniWM.dev` |
| Configuratie | `.cache/personal-wm-dev/config/omniwm-dev/settings.toml` |
| Runtimegegevens | `.cache/personal-wm-dev/state/omniwm-dev/runtime-state.json` |
| Socket bij proef | `/tmp/omniwm-personal-$UID.sock` |
| Ondertekening | `LocalDevCert`; volledige bundle geverifieerd |

Config en runtimegegevens worden eenmalig gekopieerd. Bestaande ontwikkelgegevens worden bij herbouwen behouden. De mappen hebben modus 700, de gekopieerde bestanden 600; `.cache` en `dist` zijn Git-ignored. De actieve app en originele bestanden blijven behouden voor terugkeer.

### Vaste ontwikkelrechten

Gebruik voor opeenvolgende builds hetzelfde geldige ondertekeningscertificaat en dezelfde bundle-ID. macOS koppelt privacyrechten aan de designated requirement van de app. Bij ad-hoc ondertekening hangt die requirement aan de specifieke codeversie; herbouwen verandert die identiteit. Zie [Apple TN3127](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

Het certificaat `LocalDevCert` is aangemaakt, geïmporteerd en vertrouwd. Maak het niet opnieuw aan voor volgende builds. Herstel bij verlies bij voorkeur hetzelfde certificaat inclusief private sleutel. Een nieuw certificaat vereist opnieuw TCC-toestemming. Voor een volledig nieuwe setup zijn de handmatige stappen 1–5 beschikbaar in [Optional Signing Certificate](../../CONTRIBUTING.md#optional-signing-certificate). Gebruik daarbij als naam `LocalDevCert` in plaats van `OmniWM Dev`. Hiervoor is geen betaald Apple-account nodig. De persoonlijke buildwrapper kiest dit certificaat standaard en stopt met een fout als het ontbreekt; hij valt niet terug op ad-hoc signing. Controleer vanuit deze repo:

```bash
security find-identity -v -p codesigning
./Scripts/build-personal-wm-dev.sh
codesign -d -r- "dist/OmniWM Dev.app"
```

De build moet `LocalDevCert` gebruiken, zonder melding over ad-hoc ondertekening. Activeer daarna uitsluitend via de geïsoleerde route hieronder. Geef de nieuw ondertekende app eenmaal Toegankelijkheid en Invoercontrole. Behoud vervolgens het certificaat, de private sleutel en de bundle-ID. Dit voorkomt normaal gesproken herregistratie na iedere build; macOS kan opnieuw toestemming vragen na identiteits- of beleidswijzigingen. Screen Recording blijft optioneel.

Een bestaand certificaat met een andere naam kan expliciet worden gekozen:

```bash
OMNIWM_SIGNING_IDENTITY="Naam van je certificaat" ./Scripts/build-personal-wm-dev.sh
```

Gebruik de override alleen wanneer je bewust een andere geldige identiteit wilt kiezen. Op 2 november 2026 is `LocalDevCert` geïmporteerd en vertrouwd. Geldige identiteit: `6FCE77CBEAE2179529EB04B641A28C737C2CC347`. De private sleutel staat alleen codesign toe via `/usr/bin/codesign`; tijdelijke PEM- en P12-bestanden zijn verwijderd. De testbuild is geslaagd: `codesign -dv --verbose=4` toont `Authority=LocalDevCert`, de bundle-ID is `com.barut.OmniWM.dev`, en `codesign --verify --deep --strict` slaagt. De designated requirement gebruikt de certificaatvingerafdruk in plaats van een codehash. Twee opeenvolgende builds slagen zonder tweede sleutelhangerprompt; hun designated requirement is identiek. Logs: `.cache/personal-wm-localdevcert-build.log`, `.cache/personal-wm-localdevcert-rebuild.log` en `.cache/personal-wm-localdevcert-verification.txt`. TCC-behoud zelf is nog niet live beproefd. Er is geen app gestart en geen TCC-recht verleend.

### Bouwvalkuil

De gewone SwiftPM-build accepteert de Nix-symlink voor GhosttyKit, maar de `swiftbuild`-route van de verplichte vertaalcontrole kon de module niet vinden. Dezelfde geverifieerde frameworkinhoud staat nu als echte lokale map onder `Frameworks/GhosttyKit.xcframework`; de oorspronkelijke link is bewaard in `.cache/ghosttykit-nix-link`. Geen dependencyversie of frameworkinhoud is gewijzigd.

## Tijdelijke activering — alleen na akkoord

Deze bestaande upstreamroute stopt de huidige OmniWM voordat de ontwikkelapp opent. Controleer eerst bundle-ID, geïsoleerde paden, de configuratiekopie en de huidige actieve instellingen. De ontwikkelapp kan eigen macOS-rechten nodig hebben.

Voer dit vanuit de repo-root uit:

```bash
OMNIWM_DEV_INSTALL_DIR="$PWD/dist" \
XDG_CONFIG_HOME="$PWD/.cache/personal-wm-dev/config" \
XDG_STATE_HOME="$PWD/.cache/personal-wm-dev/state" \
OMNIWM_SOCKET="/tmp/omniwm-personal-$UID.sock" \
  ./Scripts/omniwm-dev.sh use dev
```

Terug naar de bewaarde normale app, met haar bestaande configuratie:

```bash
./Scripts/omniwm-dev.sh use release
```

## Liveproef en resterende acceptatie

De ontwikkel-WM is na akkoord tijdelijk gestart. De twee vereiste rechten zijn na expliciet akkoord voor de actuele bundle geregistreerd; Screen Recording is niet verleend. De normale WM draait inmiddels weer.

- Geslaagd: direct dashboard bij heropenen van de ontwikkelapp.
- Geslaagd: fysieke verplaatsing van Systeeminstellingen naar het brede scherm, bevestigd door AX en aparte IPC-teruglezing.
- Geslaagd: echte bronfocus bij de dichtstbijzijnde buur na Escape.
- Geslaagd: een lege bron blijft current en zichtbaar zonder gefocust managed venster. De verstoorde eerste meting is zonder gebruikersklikken herhaald.
- Geslaagd: automatische tabelverversing in beide richtingen na de WindowServer-correctie.
- Geslaagd: testvenster exact terug op zijn beginframe en workspace; normale WM terug, bronconfiguratie onveranderd.

Nog afzonderlijk fysiek te controleren: hoverfocus buiten het paneel en hervatting door uitsluitend echte muisbeweging. Kantoor- en laptop-hotplug blijven buiten deze stap. Zie [het controleverslag](validation.md) voor bewijs en grenzen.
