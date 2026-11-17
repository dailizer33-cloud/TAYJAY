-- =========================================================
-- 🚫 BLACKLIST: รายชื่อผู้เล่นที่ WARP จะไม่เลือกเป็นเป้าหมาย
-- ใส่ Username ในรายการด้านล่างได้เลย (ไม่สนตัวพิมพ์เล็ก-ใหญ่)
-- หรือกดปุ่ม "ข้าม" ในสมุดสั่งตาย ระบบจะเพิ่ม/ลบชื่อให้เอง
-- ถ้า executor รองรับ writefile ระบบจะบันทึกลงไฟล์ TAYJAY_blacklist.json
-- =========================================================
_G.TAYJAY_BLACKLIST_DEFAULT = {
   -- "ตัวอย่างชื่อ1", "ตัวอย่างชื่อ2",
}
_G.TAYJAY_BL = {}
do
   local HttpService = game:GetService("HttpService")
   local FILE = "TAYJAY_blacklist.json"
   local names = {} -- key = ชื่อตัวพิมพ์เล็ก, value = ชื่อที่บันทึกไว้
   local BL = _G.TAYJAY_BL

   function BL.has(name)
       return name ~= nil and names[string.lower(name)] ~= nil
   end

   function BL.list()
       local out = {}
       for _, original in pairs(names) do table.insert(out, original) end
       table.sort(out, function(a, b) return string.lower(a) < string.lower(b) end)
       return out
   end

   function BL.save()
       pcall(function()
           if writefile then writefile(FILE, HttpService:JSONEncode(BL.list())) end
       end)
   end

   function BL.set(name, on)
       if not name then return end
       local key = string.lower(name)
       if on then names[key] = name else names[key] = nil end
       BL.save()
   end

   for _, name in ipairs(_G.TAYJAY_BLACKLIST_DEFAULT) do names[string.lower(name)] = name end
   pcall(function()
       if readfile and isfile and isfile(FILE) then
           for _, name in ipairs(HttpService:JSONDecode(readfile(FILE))) do names[string.lower(name)] = name end
       end
   end)
   print("[TAYJAY] Blacklist loaded: " .. #BL.list() .. " ชื่อ")
end

