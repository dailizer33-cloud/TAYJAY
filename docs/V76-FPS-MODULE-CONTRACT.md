# V76 FPS External Module Contract (Phase 3)

Status: dependency inventory only. No FPS runtime code was moved or behavior changed in this phase.

Target branch: `v76/fps-module-phase1`

## Finding

`src/features/fps_booster.lua` is not yet a self-contained feature module. It currently executes inside the main script's isolated `task.spawn` scope and closes over several main-script locals. Extracting it directly into a separately downloaded Lua file would make those names resolve as globals (usually nil) and can break startup, UI styling, or cleanup.

## Dependencies observed

### Shared runtime / resource lifecycle

- `newCleanupOwner`, `newBag`, `ResourceManager`
- `TJ.Main` (shared module namespace)
- `trackConnection` (currently used for cross-UI integration connections)

### Roblox / executor runtime

- `Players`, `RunService`, `Lighting`, `workspace`, `game`, `task`
- Roblox constructors and types such as `Instance`, `Enum`, `UDim`, `UDim2`, `Color3`
- Executor FPS-cap functions `getfpscap` and `setfpscap` are optional and guarded by type checks

### Main UI theme / layout

- `SecureParentGui`
- `UI_LAYOUT`, `GREEN`, `WHITE_TEXT`, `TEXT_OUTLINE`
- `applyTayJayTextContrast`

### Main UI integration that must not remain hidden inside an external FPS module

- `screenGui`
- `styleDynamicObject`
- `isWindowLocked`
- `_G.TAYJAY_UI`
- `_G.TAYJAY_CLEAN_LOOK`

The current FPS source also creates a lock ScreenGui and hooks `screenGui.DescendantAdded`, then runs text/layout passes over the main `screenGui`. These are main-menu responsibilities, not FPS-only responsibilities. They must be moved to a small main-script integration adapter or removed from the FPS module only after equivalent behavior is preserved.

## Proposed boundary for the next implementation phase

The external FPS module should receive one explicit context table, not depend on undeclared lexical locals:

```lua
local fpsContext = {
    TJ = TJ,
    Players = Players,
    RunService = RunService,
    Lighting = Lighting,
    ResourceManager = ResourceManager,
    newCleanupOwner = newCleanupOwner,
    newBag = newBag,
    SecureParentGui = SecureParentGui,
    UI_LAYOUT = UI_LAYOUT,
    GREEN = GREEN,
    WHITE_TEXT = WHITE_TEXT,
    applyTayJayTextContrast = applyTayJayTextContrast,
}
```

This is a contract sketch, not executable integration code. The final context must be validated against every identifier in the complete FPS source before extraction. Main-menu-only hooks (`screenGui`, `styleDynamicObject`, `isWindowLocked`, `_G.TAYJAY_UI`, `_G.TAYJAY_CLEAN_LOOK`) should be handled by a main-script adapter and should not be passed into the external FPS module unless a specific FPS feature genuinely needs them.

## Required module API

Keep the Phase 1 API stable:

- `TJ.Main.FPS.SetVisible(boolean)`
- `TJ.Main.FPS.GetStatus()`
- `TJ.Main.FPS.Cleanup()`

The FPS Owner must remain registered with the shared ResourceManager under the stable owner key `FPS`. `STOP ALL` must continue to stop that owner and destroy the FPS GUI, restore changed graphics properties, and restore the FPS cap.

## Extraction gates

Do not create or switch the main script to a remote `TAYJAY FPS.lua` loader until all of these are true:

1. Every free identifier in the FPS source is classified as module-local, Roblox built-in, optional executor API, or explicit context dependency.
2. Main-menu styling and lock-bar side effects are separated into a main-script adapter without visual regression.
3. The external file exports the same API and handles load failure without preventing the main menu from starting.
4. Version compatibility and remote-load failure behavior are defined.
5. Build and Luau compile checks pass.
6. Delta Android runtime tests confirm FPS ON/OFF, preset restore, UI visibility, repeated execution, and STOP ALL.

## Scope protection

This phase changes documentation only. Combat, Warp, Fly, Player ESP, MM2, and their commands are untouched.


## Phase 4 implementation note

The first main-UI adapter extraction is now implemented:

- `src/ui/fps_main_ui_adapter.lua` owns the lock bar, main-menu text fitting/contrast passes, clean-look calls, dynamic descendant styling, shared theme pass, and main-window drag setup.
- The adapter is registered in `src/manifest.txt` before `boot/fps_scope_open.lua`, so it is defined in the main xpcall scope before the isolated FPS task starts.
- `src/features/fps_booster.lua` now requests the adapter through `TJ.Main.ApplyFPSMainUIAdapter(fpsGui, fpsPanel)`.
- Main window lock state is exposed through `TJ.Main.IsWindowLocked()`; the FPS launcher no longer reads `_G.TAYJAY_UI` directly.
- The FPS source no longer directly references `screenGui`, `mainFrame`, `styleDynamicObject`, `TAYJAY_UI`, `TAYJAY_CLEAN_LOOK`, `updateScreenScale`, `makeDraggable`, or the main-scope connection tracker.

This is an internal boundary improvement only. FPS still uses injected-by-lexical-scope Roblox/runtime and theme helpers such as `SecureParentGui`, `UI_LAYOUT`, `GREEN`, `WHITE_TEXT`, and `applyTayJayTextContrast`. These remain to be formalized into the external module context in a later phase. The external remote loader is still not enabled.
