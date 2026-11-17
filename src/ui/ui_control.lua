-- =========================================================
-- 🔒 UI CONTROL: ล็อกตำแหน่งหน้าต่าง / ปิดเอฟเฟกต์ภาพ
-- locked = true: หน้าต่างอยู่กับที่ (ปลดเพื่อลากด้วยการสัมผัส)
-- effects = false: ไม่มีแสง สีไล่ระดับ การกระพริบ หรือแอนิเมชัน
-- =====================================================================
_G.TAYJAY_UI = { locked = true, effects = false }
_G.TAYJAY_CLEAN_LOOK = function(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UIGradient") then obj.Enabled = _G.TAYJAY_UI.effects == true end
        if obj:IsA("UIStroke") and obj.Thickness > 2 then obj.Thickness = 1.6 end
    end
end

