---@meta
-- Types for the plugin, for WoW Lua LS only: not in the .toc, not packaged. The parts of ElvUI the
-- plugin touches, as ElvUI's own code defines them, and the plugin's own tables.

---ElvUI's global: { E, L, V, P, G }; the plugin uses the engine (E), the profile defaults (P) and
---the global defaults (G).
---@class ElvUIGlobal
---@field [1] ElvUIEngine
---@field [4] table<string, AddonSettings>
---@field [5] table<string, {dev: AddonDevData}>

---@type ElvUIGlobal
ElvUI = nil

---ElvUI_Options' lists for its LibSharedMedia selects.
---@type {font: table<string, string>}
AceGUIWidgetLSMlists = nil

---@class ElvUIEngine
---@field db table<string, AddonSettings> the profile
---@field global table<string, {dev: AddonDevData}>
---@field oUF {objects: AddonFrame[]} ElvUI's oUF, with every frame it spawned
---@field LSM {Fetch: fun(self: table, kind: "font", name: string): string}
---@field TexCoords number[] how ElvUI crops its icons
---@field Abbreviate {short: table} ElvUI's number style, as options for the game's AbbreviateNumbers
---@field Options? {args: table<string, table>}
---@field GetModule fun(self: ElvUIEngine, name: "UnitFrames"): ElvUIUnitFrames
---@field NewModule fun(self: ElvUIEngine, name: string, ...: string): AddonModule
---@field RegisterModule fun(self: ElvUIEngine, name: string)

---@class ElvUIUnitFrames
---@field Configure_Portrait fun(self: ElvUIUnitFrames, frame: AddonFrame)

---The plugin's ElvUI module, with AceHook and AceEvent.
---@class AddonModule
---@field GetName fun(self: AddonModule): string
---@field SecureHook fun(self: AddonModule, object: table, method: string, handler: string)
---@field RegisterEvent fun(self: AddonModule, event: string, handler: string?)

---A value the client hides from addons (WoW: Forever in combat): it can be passed on, never
---compared or tested.
---@class AddonSecret

---The addon's namespace, the `...` every file gets.
---@class AddonNamespace
---@field NAME string the folder's name, which every name the game sees comes from
---@field IsSecret fun(value: string|number|boolean|table|nil): boolean
---@field units table<string, boolean> the unitframeTypes the plugin works on
---@field unitOrder string[]
---@field holders table<table, AddonHolder> the parts on each frame, by frame
---@field holderList AddonHolder[]
---@field schoolColors table<number, number[]>
---@field samples table[] test mode's events: event, flags, amount, school
---@field testing boolean?
---@field FALLBACK_SIZE number
---@field LOSS_LEVEL number
---@field PREVIEW_LEVEL number
---@field TEST_INTERVAL number
---@field PREVIEW_DURATION number
---@field db fun(): AddonSettings
---@field Spot fun(frame: AddonFrame): table, string, number
---@field Feedback fun(event: string|AddonSecret, flags: string|AddonSecret, amount: number|AddonSecret, school: number|AddonSecret): string?, (string|AddonSecret)?, number?, number?, number?, number?
---@field ShowText fun(holder: AddonHolder, event: string|AddonSecret, flags: string|AddonSecret, amount: number|AddonSecret, school: number|AddonSecret)
---@field HideText fun(holder: AddonHolder)
---@field IconFrame fun(holder: AddonHolder, level: number): AddonIconFrame
---@field BuildCC fun(holder: AddonHolder)
---@field LayoutCC fun(holder: AddonHolder, region: table, point: string, size: number)
---@field RefreshCC fun(holder: AddonHolder)
---@field ApplyCC fun(holder: AddonHolder)
---@field UpdateLoss fun()
---@field Layout fun(holder: AddonHolder)
---@field Attach fun(frame: AddonFrame)
---@field ApplyAll fun()
---@field SetTesting fun(on: boolean)
---@field InsertOptions fun()
---@field DevOptions? fun(): table

---@class AddonUnitSettings
---@field text boolean
---@field cc boolean

---@class AddonColor
---@field r number
---@field g number
---@field b number

---@class AddonTextColors
---@field physical AddonColor
---@field spell AddonColor
---@field heal AddonColor
---@field power AddonColor
---@field miss AddonColor

---@class AddonTextSettings
---@field font string a LibSharedMedia font name
---@field size number the text's height as a part of the spot's
---@field outline string
---@field crit number
---@field hold number seconds
---@field damage boolean
---@field heals boolean
---@field misses boolean
---@field energize boolean
---@field short boolean
---@field schools boolean
---@field colors AddonTextColors

---@class AddonCCSettings
---@field numbers boolean
---@field interrupts boolean

---The plugin's settings in ElvUI's profile.
---@class AddonSettings
---@field units table<string, AddonUnitSettings>
---@field text AddonTextSettings
---@field cc AddonCCSettings

---Development screenshots' saved data (Dev.lua), in ElvUI's global data.
---@class AddonDevData
---@field on boolean
---@field shots table<string, boolean>

---One of ElvUI's unit frames, the fields the plugin reads.
---@class AddonFrame: Button
---@field unit string
---@field unitframeType string
---@field isChild boolean?
---@field ORIENTATION "LEFT"|"RIGHT"|"MIDDLE"
---@field USE_PORTRAIT boolean
---@field USE_PORTRAIT_OVERLAY boolean
---@field Health StatusBar
---@field Portrait {backdrop: Frame} the portrait in use, 2D texture or 3D model, and its box
---@field RaisedElementParent Frame?

---Blizzard's custom aura container (Blizzard_AuraContainer), the methods the plugin calls.
---@class AddonAuraContainer: Frame
---@field SetEditModePreviewEnabled fun(self: AddonAuraContainer, enabled: boolean)
---@field AddAuraSlot fun(self: AddonAuraContainer, key: string, filter: string, options: table): Frame
---@field SetUnit fun(self: AddonAuraContainer, unit: string)
---@field GetUnit fun(self: AddonAuraContainer): string?
---@field SetEnabled fun(self: AddonAuraContainer, enabled: boolean)
---@field IsEnabled fun(self: AddonAuraContainer): boolean
---@field UpdateAllAuras fun(self: AddonAuraContainer)

---The game's aura button in a container's slot, the methods the plugin calls.
---@class AddonAuraButton: Frame
---@field SetIcon fun(self: AddonAuraButton, texture: Texture)
---@field SetDurationCooldown fun(self: AddonAuraButton, cooldown: Cooldown)

---An icon of the plugin's own: a texture and a countdown.
---@class AddonIconFrame: Frame
---@field icon Texture
---@field cooldown Cooldown

---The plugin's parts on a frame.
---@class AddonHolder: Frame
---@field frame AddonFrame
---@field key string the frame's unitframeType
---@field size number the spot's size (Spot.lua)
---@field started number when the text last showed
---@field text FontString
---@field cc Frame the icon's frame
---@field cooldowns Cooldown[]
---@field container AddonAuraContainer? Blizzard's custom aura container, nil on a client without one
---@field loss AddonIconFrame? the player's loss of control
---@field preview AddonIconFrame? test mode's sample icon
