-- Publish the shared API table before yielding to the isolated FPS task.
-- This prevents Quick Visibility / STOP ALL from capturing a nil module during startup.
TJ = TJ or {}
TJ.Main = TJ.Main or {}
TJ.Main.FPS = TJ.Main.FPS or {}
task.spawn(function()
