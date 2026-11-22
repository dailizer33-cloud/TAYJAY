-- 👻 NOCLIP: ปุ่มวงกลมลอย (แยกออกจากความเร็ว) กดเปิด/กดปิด ลากย้ายได้เมื่อปลดล็อก
do
   local noclipCircle = Instance.new("TextButton", screenGui)
   noclipCircle.Name = "TayJayNoclipCircle"
   noclipCircle.AnchorPoint = Vector2.new(0.5, 0.5)
   noclipCircle.Size = UDim2.fromOffset(UI_LAYOUT.NoclipSize, UI_LAYOUT.NoclipSize)
   noclipCircle.Position = UI_LAYOUT.NoclipCenter
   noclipCircle.RichText = true; noclipCircle.Font = Enum.Font.GothamBlack
   noclipCircle.TextSize = 14; noclipCircle.TextColor3 = WHITE_TEXT
   noclipCircle.AutoButtonColor = true; noclipCircle.Active = true
   Instance.new("UICorner", noclipCircle).CornerRadius = UDim.new(1, 0)
   local ring = Instance.new("UIStroke", noclipCircle)
   ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Color = UI_LAYOUT.Accent.Noclip; ring.Thickness = 3
   makeDraggable(noclipCircle)
   local function refresh()
      local on = states.Noclip == true
      noclipCircle.BackgroundColor3 = on and GREEN.on or GREEN.off
      noclipCircle.Text = '<font size="26">👻</font>\n<font size="13">NOCLIP</font>\n<font size="11">' .. (on and "ON" or "OFF") .. '</font>'
   end
   refresh()
   trackConnection(noclipCircle.Activated:Connect(function() syncButtonState("Noclip", not states.Noclip) end))
   registerUiSync("Noclip", refresh)
end

end -- [/TAYJAY LOCAL-LIMIT FIX 3/8]

end -- [/TAYJAY LOCAL-LIMIT FIX 3/8]
