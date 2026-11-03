# OmniWM: onderzoeksnotitie voor persoonlijke WM-planning

**Peildatum: 2 november 2026.** Ik heb upstream-code en de lokale OmniWM-config gelezen.
Dit is onderzoek voor overleg; het kiest geen ontwerp en wijzigt geen configuratie.

## Versie en bron

- Upstream is [`OmniNull/OmniWM`](https://github.com/OmniNull/OmniWM).
- `main` stond op commit [`dfff63b`](https://github.com/OmniNull/OmniWM/commit/dfff63b775035d32efa04b7d500eb7d6008050c9).
- Stabiel was `v0.7.6`, commit [`3c07839`](https://github.com/OmniNull/OmniWM/commit/3c0783954604eaa9110d0bdb61fa29f953e738ee).
- `main` bevat nieuwere, mogelijk nog niet uitgebrachte wijzigingen.

## Hoe OmniWM werkt

- Het is een SwiftPM-app met AppKit en SwiftUI ([Package.swift](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Package.swift)).
- De bron noemt twaalf productie-targets, een CLI en een testtarget ([architectuur](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md#L16)).
- GhosttyKit is ingebed; er zijn ook C-, C++- en Objective-C-targets.
- De hoofdlijn verwerkt events, werkt één wereldstatus bij en plant framewijzigingen ([architectuur](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md)).
- Layout berekent vensterframes; Accessibility schrijft en controleert ze ([code](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Ax/AXWindowService%2BFrameWrites.swift#L31)).
- Vensters combineren proces-ID en WindowServer-ID; handles bewaren layoutidentiteit bij hercreatie ([uitleg](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md#L359)).

## Aansluiting op jouw wensen

### Scrollen, verplaatsen en vergroten

- Niri gebruikt scrollbare kolommen; de primaire as volgt de [schermoriëntatie](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md#L627).
- Op een portretscherm scrollen rijen verticaal; vensters staan naast elkaar.
- De viewport en selectie zijn per workspace opgeslagen.
- De engine berekent spans; Accessibility zet frames en controleert resultaten ([code](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Ax/AXWindowService%2BFrameWrites.swift#L31)).
- Carbon-hotkeys roepen acties aan; instellingen kunnen toetsen opnemen ([UI-code](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/UI/HotkeyBindingRow.swift#L12)).

### Verschillende monitoropstellingen

- OmniWM verwerkt scherm-aansluitingen, verwijderingen en wijzigingen ([observer](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Monitor/DisplayConfigurationObserver.swift#L30)).
- Meerdere indelingen zijn mogelijk; een kleinere schermset kan een grotere match hergebruiken ([routing](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Monitor/MonitorRouting.swift#L13)).
- Workspaces bewaren UUID’s en kiezen hoofdscherm, tweede scherm of een specifiek scherm ([config](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Config/WorkspaceConfig.swift#L25)).
- Scherm-UUID heeft voorrang; zonder UUID gebruikt de code scherm-ID en naam ([identiteit](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Monitor/OutputId.swift#L7)).
- Dit past bij wisselen tussen docks, maar echte scherm-ID’s en fallbacks moeten op jouw Mac worden nagekeken.

### Eenvoudige instellingen en quake-terminal

- De SwiftUI-instellingen bevatten schermformulieren en sneltoetsopname ([venster](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/UI/SettingsView.swift#L7), [schermen](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/UI/MonitorSettingsTab.swift#L7), [toetsen](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/UI/HotkeyBindingRow.swift#L12)).
- Quake ondersteunt Ghostty, Kitty en foot ([providers](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Config/QuakeTerminalProvider.swift#L4)).
- Kitty en foot hebben aparte adapters ([Kitty](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/QuakeTerminal/KittyQuickAccessTerminal.swift#L7), [foot](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/QuakeTerminal/FootQuickAccessTerminal.swift#L7)).
- De selectiecode kiest aparte controllers; ik vond geen generiek terminalprotocol ([besturing](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/Controller/WMController%2BAuxiliaryWindows.swift#L86)).
- **Inschatting:** een vierde terminal vraagt waarschijnlijk een eigen besturingsadapter.

## Lokale uitgangspositie

- De huidige config staat in `/Users/casper.spruit@energyzero.nl/dotfiles/config/omniwm/settings.toml`; die bewaart twee monitorindelingen en blijvende workspace-UUID’s.
- Focus gebruikt `Option`-pijlen; verplaatsen gebruikt `Option+Shift`-pijlen.
- `Hyper+Left/Right` verplaatst expliciet tussen schermen.
- Vergroten/verkleinen heeft al bindings voor kolom- en vensterspans.
- Quake gebruikt `Hyper+T`; zie ook `/Users/casper.spruit@energyzero.nl/dotfiles/config/omniwm/AGENTS.md`.

**Let op:** de lokale notitie zegt dat Niri niet past op portret. Upstream ondersteunt daar verticale Niri-scroll. Dat zegt nog niet of het prettig werkt op jouw PL2492H.

## Technische grenzen

- Accessibility en Input Monitoring zijn vereist; Screen Recording ondersteunt thumbnails en drag-previews ([vereisten](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md#L217)).
- OmniWM gebruikt privé-SkyLight-symbolen voor WindowServer-events en vensterbeheer ([loader](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/Sources/OmniWM/Core/SkyLight/SkyLightSymbolResolver.swift#L7)).
- De upstream-gids waarschuwt dat privé-API’s tussen macOS-versies kunnen breken ([richtlijn](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/website/src/content/docs/developers/architecture.md#L1189)).
- De officiële app vereist volgens [README](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/README.md) geen uitschakeling van SIP.

## Licentie

- De code valt onder GPL-2.0-only. Privé aanpassen mag zonder openbaarmaking.
- Bij verspreiding van een gewijzigde versie gelden GPL-voorwaarden en broncodeverplichtingen.
- Zie [licentie](https://github.com/OmniNull/OmniWM/blob/dfff63b775035d32efa04b7d500eb7d6008050c9/LICENSE) en [GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#GPLRequireSourcePostedPublic).

## Bespreekbare prototyperoutes

- **Config-first:** eerst de bestaande GUI, sneltoetsen en monitorindelingen beoordelen.
- **Kleine native proef:** SwiftUI-instellingen plus één layout en beperkte schermondersteuning.
- **OmniWM-fork:** hergebruikt veel gedrag, maar neemt GPL- en privé-API-onderhoud mee.
- Dit zijn opties voor het gesprek, geen gekozen richting.

## Grenzen van dit onderzoek

- Ik heb de app niet gebouwd of op fysieke schermen getest.
- Ik heb geen instellingen geschreven of bestaande wijzigingen aangepast.
- De monitorfallback en prettige portretbediening blijven onbevestigd.
