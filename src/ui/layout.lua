-- =========================================================
-- 📐 DEFAULT UI LAYOUT  (ตำแหน่งเริ่มต้นหลังกดรันสคริปต์)
-- วัดจากภาพหน้าจอจริง เก็บเป็นสัดส่วนหน้าจอ (0-1) ให้ตรงกันทุกความละเอียด
-- อยากขยับ UI ไหน แก้เลขตรงนี้ที่เดียว
--   X = ซ้าย→ขวา , Y = บน→ล่าง
-- =========================================================
local UI_LAYOUT = {
   MainMenu     = UDim2.fromScale(0.0762, 0.1667), -- เมนูหลัก TAYJAY ตามตำแหน่งในภาพ
   PlayerList   = UDim2.fromScale(0.3242, 0.4600), -- ตาราง "ผู้เล่นทั้งหมด"
   TargetPanel  = UDim2.fromScale(0.3219, 0.8370), -- กรอบ Select target / TARGET
   FlyBottom    = UDim2.fromScale(0.6263, 1.0000), -- FLY CONTROL มุมขวาล่าง
   WarpCenter   = UDim2.fromScale(0.1550, 0.6000), -- ปุ่มวงกลม WARP
   WalkCenter   = UDim2.fromScale(0.2050, 0.6420), -- ปุ่มวงกลม WALK
   RapidBiteCenter = UDim2.fromScale(0.4310, 0.8540), -- ปุ่ม RAPID ด้านล่างกึ่งกลาง
   MonsterTargetPanel = UDim2.fromScale(0.4820, 0.7300), -- ตาราง Monster/NPC ด้านล่างกึ่งกลาง
   MM2Dock      = UDim2.fromScale(0.8350, 0.4630), -- กรอบปุ่มดาบ/สมุด (MM2)
   PanelW       = 224, -- ความกว้างมาตรฐานของหน้าต่างหลัก (เท่ากันหมด; ไม่กว้างกว่านี้เพราะจะชนกับ NOCLIP/FLYในภาพ)
   FlyH         = 224, -- ความสูงกล่อง FLY (ดีไซน์ใหม่)
   NoclipCenter = UDim2.fromScale(0.0980, 0.6250), -- ปุ่มวงกลม NOCLIP ตรงตำแหน่งในภาพ
   SpeedStep    = 2, -- ปุ่มบวก/ลบความเร็วเดิน ครั้งละกี่หน่วย
   PanelH       = 300, -- ความสูงมาตรฐานของหน้าต่างใหญ่ (เมนู/รายชื่อ/FPS)
   -- สีประจำแต่ละหน้าต่าง (ขอบและไฮไลต์) ปรับได้ที่นี่
   Accent = {
       Main = Color3.fromRGB(73, 211, 235),  -- TAYJAY เมนูหลัก: ฟ้าไซเบอร์
       Players = Color3.fromRGB(168, 120, 255), -- ผู้เล่นทั้งหมด: ม่วง
       Target = Color3.fromRGB(255, 96, 132),  -- เป้าหมาย: ชมพูแดง
       Noclip = Color3.fromRGB(255, 130, 60),  -- NOCLIP: อำพัน
      Speed   = Color3.fromRGB(255, 211, 58),  -- SPEED: เหลืองทอง
       Fly = Color3.fromRGB(72, 230, 186),  -- FLY: มิ้นต์
       FPS = Color3.fromRGB(150, 235, 80),  -- FPS BOOSTER: เขียวมะนาว
       Server = Color3.fromRGB(90, 170, 255),  -- หาเซิร์ฟว่าง: ฟ้าน้ำเงิน
       Stay    = Color3.fromRGB(72, 222, 242),  -- ปุ่ม WARP ไป (ไม่กลับ): ฟ้าอ่อน
   },
   FPSPanel     = UDim2.fromScale(0.7309, 0.0430), -- กรอบ TAYJAY FPS BOOSTER
   FPSLauncher  = UDim2.fromScale(0.9217, 0.3631), -- ปุ่ม ⚡ เขียว เปิด/ปิด FPS Booster
   ToggleSize   = 68,  -- เส้นผ่านศูนย์กลางปุ่ม ⚡ เมนูหลัก (เดิม 48)
   ActionSize   = 59,  -- ลดปุ่มวงกลมทั้งหมดลงประมาณ 10%
   NoclipSize   = 65,  -- คงขนาดปุ่ม NOCLIP เดิม
}

