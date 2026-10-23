# API

## Window

`CreateWindow` creates the menu. `Title` sets the name in the header; `Accent` sets the UI color. Both are optional.

```lua
local UI = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL"))()
local window = UI:CreateWindow({Title = "posipaka.cc", Accent = Color3.fromRGB(205, 113, 145)})
local tab = window:Tab("visuals")
local panel = tab:Section({Name = "players", Side = 1})
```

`Tab` adds a tab, `Section` adds a panel. Use `Side = 1` for the left column or `2` for the right. RightShift toggles the menu.

## Controls

A checkbox can have a bind and one or more color pickers next to it.

```lua
local toggle = panel:Toggle({Name = "enabled", Flag = "enabled", Bind = true})
toggle:Colorpicker({Flag = "color", Default = Color3.new(1, 1, 1)})
toggle:Keybind({Default = Enum.KeyCode.E, Mode = "Hold"})
```

Bind modes: `Hold`, `Toggle`, `Always`. For a separate picker or bind, use `panel:Colorpicker({...})` or `panel:Keybind({...})`.

`Settings` creates a smaller gray panel inside a section. It takes the same controls as a regular panel.

```lua
local settings = panel:Settings()
settings:Slider({Name = "size", Flag = "size", Min = 1, Max = 50, Default = 12, Step = 1})
```

`Dropdown` takes a list of items. With `Multi = true`, more than one item can be selected.

```lua
panel:Dropdown({Name = "outline", Flag = "outline", Items = {"inner", "outer"}, Default = {"outer"}, Multi = true})
```

Other controls:

| Method | Use |
|---|---|
| `Button({Name, Callback})` | Runs the callback when clicked. |
| `Textbox({Name, Flag, Default})` | Text input. |
| `Text("text")` | Plain label. |
| `List({Flag, Items, Height})` | Selection list with its own scroll area. |

Give each control a unique `Flag`. Read it through `window.Flags.flag`, or add `Callback = function(value) ... end` to handle changes. `control:SetValue(value)` changes a value from code; lists also have `SetItems(items)`.

## Title and accent

These update the current window. Changing the accent leaves the HSV colors alone.

```lua
window:SetWatermarkTitle("name.cc")
window:SetAccent(Color3.fromRGB(120, 170, 255))
```

`SetTitle` also changes the header name. To set defaults for new windows, use `UI:SetDefaultTitle(title)` and `UI:SetDefaultAccent(color)`.

## Configs

`window:Configs()` adds the save/load panels. Files go in `Posipaka/UI` inside the executor's workspace. Pass `ConfigFolder` to `CreateWindow` to use another folder.

```lua
window:Configs()
window:SaveConfig("default")
window:LoadConfig("default")
```

`window:Destroy()` removes the menu and disconnects its listeners.
