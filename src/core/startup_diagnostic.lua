-- TAYJAY STARTUP DIAGNOSTIC: must be the first executable statement.
print("[TAYJAY BOOT] File entered; startup sequence begins.")

print("[TAYJAY SHADOW HUNTER + DEATH NOTE WARP] Starting initialization...")
if not game:IsLoaded() then 
   pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.1); LocalPlayer = Players.LocalPlayer end
local PlaceId = game.PlaceId

