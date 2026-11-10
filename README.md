# ElvUI Portrait FX

Combat text and a crowd control icon on the portraits of ElvUI's unit frames, for WoW: Forever.
The default unit frames show what happens to a unit on its portrait (damage, heals, misses) and
Blizzard's own frames can show crowd control there; ElvUI's frames do neither. This plugin adds both.

## What it does

- **Combat text** on the portrait of the player, target, focus, pet and party: damage, heals,
  misses, dodges, blocks, absorbs and immunities, optionally power gains. Critical hits are bigger,
  glancing ones smaller, as on Blizzard's frames. Spell damage can be coloured by its school.
- **A crowd control icon** over the portrait, with a countdown swipe and numbers: stuns, fears,
  polymorphs and the like, and the game's loss of control (also interrupts, silences and roots).
  Without crowd control it shows a big defensive (Divine Shield, Ice Block) or an external one
  (Blessing of Protection).
- **Portrait styles:** with the portrait beside the bars both sit on the portrait. With the
  portrait as an overlay on the health bar, or without a portrait, the text sits in the middle of
  the health bar and the icon at the health bar's portrait end.
- **Test mode** shows sample text and a sample icon on every frame.

## Settings

ElvUI's options (`/ec`) → Plugins → **Portrait FX**:

- **Frames:** per frame, combat text and the icon on or off; the strata and level of both (the
  text is always above the icon); how much goes to OAP Debug and _DebugLog.
- **Combat text:** font, size (as a part of the portrait's height), outline, critical size, time
  shown, which kinds of event, short numbers (in ElvUI's number style), colour by school, the
  colours.
- **Crowd control:** countdown numbers, interrupts, defensives.

## Requirements

- WoW: Forever (interface 16001)
- ElvUI

## Technical part

### Files

| File | What it does |
| --- | --- |
| `Core.lua` | The ElvUI module: settings in ElvUI's profile, the unit changes it passes on |
| `Debug.lua` | The bridge to OAP Debug and _DebugLog |
| `Spot.lua` | Where on a frame the text and the icon go, per portrait style |
| `CombatText.lua` | UNIT_COMBAT to text: words, sizes, colours, the fade |
| `CrowdControl.lua` | The aura container's slot, the player's loss of control |
| `Holder.lua` | The plugin's parts on each frame: made once, laid out and stacked on each Configure_Portrait, its unit events |
| `Test.lua` | Test mode |
| `Dev.lua` | Development screenshots (repository copies only) |
| `Options.lua` | The page in ElvUI's options |

### How it hooks into ElvUI

ElvUI runs `UF:Configure_Portrait(frame)` for every unit frame on every settings change. The plugin
hooks it: the first time it makes its parts on the frame, afterwards it lays them out again. The
parts sit on the frame's `RaisedElementParent`, above the 3D portrait (a PlayerModel placed above
the health bar) and the frame's texts, by default 5 levels up, below ElvUI's auras at 10. Bottom to
top: the icon's frame, the aura container (external, big defensive, crowd control slot), the loss of
control, test mode's sample icon, the text.

Each frame registers `UNIT_COMBAT` and the loss of control events for its own unit
(`RegisterUnitEvent`, as Blizzard's unit frames do), again when a party frame shows another unit.

ElvUI's own flags say where the portrait is: `USE_PORTRAIT` and `USE_PORTRAIT_OVERLAY`. Beside the
bars the spot is the portrait's backdrop, which keeps its size whatever the portrait style. As an
overlay ElvUI fits the portrait into the health bar's filled part (unless "full overlay" is on), so
the portrait itself changes size with the health; the health bar is the spot then.

### Secret values

WoW: Forever hides some values from addons in combat (secret values). They can be passed to the
game, never compared or tested. So:

- **Combat text:** Blizzard's own functions for portrait text (`CombatFeedback_OnCombatEvent`)
  compare the event's values, which an addon may not do, so they cannot be borrowed. Their data
  can: the words (`CombatFeedbackText`) and timings (`COMBATFEEDBACK_*TIME`). A hidden amount only
  goes to `BreakUpLargeNumbers` or `AbbreviateNumbers` (ElvUI's own `E:ShortValue` does arithmetic
  and cannot take one) and then to `FontString:SetFormattedText`. With a hidden amount the flags
  decide: ABSORB, BLOCK or RESIST is shown as the word, anything else as the number.
- **Crowd control:** Blizzard's custom aura container (`CustomAuraContainerTemplate`) picks the
  auras and draws them, so the plugin never reads aura data: three `AddAuraSlot`s per frame,
  `HARMFUL|CROWD_CONTROL`, `HELPFUL|BIG_DEFENSIVE` and `HELPFUL|EXTERNAL_DEFENSIVE` (filter parts
  all have to hold, hence a slot each). The loss of control comes from `C_LossOfControl` per unit,
  as Blizzard's nameplates read it (`GetActiveLossOfControlDataByUnit`); hidden times come as a
  duration object (`GetActiveLossOfControlDuration`, `SetCooldownFromDurationObject`).

### Debugging in game

With OAP Debug (`/oapd`) or _DebugLog installed the plugin sends lines there; Frames tab → OAP Debug
sets how much. Normal: how many frames it took on at login, an aura container it could not make
(with the game's error), each loss of control shown. Detailed adds every combat event on a frame
(event, flags, unit, amount or "hidden") and why one showed nothing. Metrics counts both.

### Tests

`lua tests/check.lua` runs StyLua, WoW Lua LS (100% type coverage) and the busted specs with a 100%
line coverage check. `tests/wow.lua` simulates the client and ElvUI. Set up locally with
`tests/setup-lua.ps1`.

### Screenshots while testing in game

A copy straight from the repository (the game folder's worktree) has `Dev.lua`; the packager
comments it out of every release. Frames tab → Development → **Dev screenshots** switches it on.
The first time each kind of moment from the in-game checks happens (combat text per frame and
portrait style, a hidden amount, the loss of control, test mode), a grey `[ElvUI_PortraitFX dev]`
chat line names it and one screenshot follows, at most one every two seconds. "Forget the
screenshots taken" starts over.

### Renaming

Every name the game and ElvUI see comes from the folder's name (module, profile key, options
page). A rename is the folder, the .toc, the rockspec and the CI files' comments.

## Licence

MIT
