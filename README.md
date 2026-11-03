# Personal WM

Persoonlijke werkcheckout op basis van OmniWM, voorbereid voor een kleine fork.

De repo-naam geldt alleen voor deze werkmap. App-, bundle-, target- en CLI-namen blijven upstream. Er is geen hernoemde app gebouwd.

## Upstreambasis

- Repo: [OmniNull/OmniWM](https://github.com/OmniNull/OmniWM)
- Vastgezette basis: [`dfff63b775035d32efa04b7d500eb7d6008050c9`](https://github.com/OmniNull/OmniWM/commit/dfff63b775035d32efa04b7d500eb7d6008050c9)
- Branch: `personal-wm`; alleen remote `upstream`; volledige gitgeschiedenis.
- De oorspronkelijke upstream-README staat in [docs/upstream-README.md](docs/upstream-README.md).

## Status

De eerste WM-integratie voegt **Werkruimte** toe aan het menu en toont het dashboard bij heropenen. Live getest: verplaatsen, bronfocus, lege bron en automatische tabelverversing. De normale WM is na de proef teruggezet. Persoonlijke notities staan in [docs/personal-wm/](docs/personal-wm/README.md); de simulator staat in [poc/](poc/prototype.html).

Een geïsoleerd, read-only native dashboard is gebouwd en gestart. Het toont echte schermen en zichtbare vensters. De bestaande WM en configuratie zijn behouden; er zijn geen extra rechten verleend. De wijzigingen zijn lokaal en niet vastgelegd.

## Dashboard bouwen

```bash
./Scripts/build-dashboard.sh
open "dist/OmniWM Dashboard Dev.app"
```

Het losse Swift-package staat in `dashboard/` en laadt geen WM-code. De build start niets. De app gebruikt een eigen bundle-ID, zonder configuratiebestand of globale sneltoetsen. `Escape` verbergt het paneel; de menubalkknop opent het opnieuw. `⌘R` vernieuwt de gegevens.

```bash
~/.swiftly/bin/swiftly run swift test --package-path dashboard
```

Venstertitels kunnen ontbreken zonder schermopnametoestemming. Deze losse app bestuurt geen vensters.

De afzonderlijke WM-integratie staat in [native-integration.md](docs/personal-wm/native-integration.md). Bouw met `./Scripts/build-personal-wm-dev.sh`; dat start niets. Tijdelijk wisselen naar deze WM vereist eerst akkoord en controle van de geïsoleerde paden. Fysieke richtingsroutering is gebouwd en automatisch getest; de nieuwe versie vraagt nog een fysieke proef.

Voer `make run`, `dev-install` of `Scripts/omniwm-dev.sh install` niet uit voordat een geïsoleerde activatieroute klaarstaat. De upstream-installer kan een draaiende app stoppen.

## Navigatie

- [Handoff voor de volgende agent](HANDOFF.md)
- [Persoonlijke WM-notities](docs/personal-wm/README.md)
- [Native vervolgstappen](docs/personal-wm/native-next-steps.md)
- [Browserdemo](poc/prototype.html)
- [Brononderzoek](docs/personal-wm/omniwm-research.md)
- [Upstream-architectuur](docs/ARCHITECTURE.md)
- [Bijdragen aan upstream](CONTRIBUTING.md)
