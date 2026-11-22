-- =========================================================
-- WALK Dynamic Target: TargetService owns nearest-target selection
-- and the shared attack scheduler; legacy attack timing remains in Death Note.
if type(TargetService) == "table" then
   TargetService:EnsureCombatOwner()
end
