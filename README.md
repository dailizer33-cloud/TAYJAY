# TAYJAY

สคริปต์ Luau สำหรับ Roblox executor (ทดสอบบน Delta Android Tablet)

## ไฟล์ใน repo

| ไฟล์ | สถานะ | รายละเอียด |
|---|---|---|
| `TAYJAY MAIN.lua` | หลัก | สคริปต์รวม: Bootstrap/Diagnostic, Resource Manager V1, Cleanup Core (ResourceManager → Owner → Bag), WARP / Death Note Shadow Hunter, Auto-Dodge, Rapid Bite, WALK2, FPS Booster V72, Quick Visibility Controls + STOP ALL |
| `Tayjay Farm.lua` | หลัก | Ant Evolution Radar **V26.2** (Delta Tablet Fixed) |
| `archive/Tayjay Farm V25.lua` | เก็บถาวร | Ant Evolution Radar V25 (Tablet Pure) ไม่พัฒนาต่อ |

## วิธีโหลด

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dailizer33-cloud/TAYJAY/main/TAYJAY%20MAIN.lua"))()
```

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dailizer33-cloud/TAYJAY/main/Tayjay%20Farm.lua"))()
```

## เวอร์ชัน

| Tag | ไฟล์ |
|---|---|
| `main-v1` | `TAYJAY MAIN.lua` (Resource Manager V1 + Cleanup Core V1 + FPS Booster V72) |
| `farm-v26.2` | `Tayjay Farm.lua` |

## แนวทางการพัฒนา

- ใช้ข้อความ commit ที่บอกว่าแก้อะไร เช่น `Fix FPS owner restore callback scope` แทน `Add files via upload`
- ทุก loop / connection ใหม่ควรลงทะเบียนผ่าน Cleanup Owner/Bag เพื่อให้ STOP ALL ล้างได้ครบ
- ระวังข้อจำกัด Luau 200 local ต่อ scope: เก็บ state ไว้ในตารางแทนการประกาศ local ระดับบนสุดเพิ่ม
- ตรวจ syntax ก่อน push: `luau-compile --null "TAYJAY MAIN.lua"`

## Roadmap

1. จัด repo: README, archive, `.gitattributes`, tag เวอร์ชัน
2. แยก `TAYJAY MAIN.lua` เป็นโมดูล (`src/core`, `src/features`, `src/ui`) + build script รวมเป็นไฟล์เดียว
3. ทำให้ทุก loop ผ่าน Cleanup Bag และให้ Resource Manager จำกัด loop ได้จริง
4. GitHub Actions: `luau-compile`, `selene`, `stylua`
