# TAYJAY

สคริปต์ Luau สำหรับ Roblox executor (ทดสอบบน Delta Android Tablet)

## ไฟล์ใน repo

| ไฟล์ | สถานะ | รายละเอียด |
|---|---|---|
| `TAYJAY MAIN.lua` | หลัก (ไฟล์ build) | สร้างจาก `src/` ด้วย `tools/build.py` ห้ามแก้ไฟล์นี้โดยตรง สคริปต์รวม: Bootstrap/Diagnostic, Resource Manager V1, Cleanup Core (ResourceManager → Owner → Bag), WARP / Death Note Shadow Hunter, Auto-Dodge, Rapid Bite, WALK2, FPS Booster V72, Quick Visibility Controls + STOP ALL |
| `Tayjay Farm.lua` | หลัก | Ant Evolution Radar **V26.2** (Delta Tablet Fixed) |
| `archive/Tayjay Farm V25.lua` | เก็บถาวร | Ant Evolution Radar V25 (Tablet Pure) ไม่พัฒนาต่อ |

## วิธีโหลด

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dailizer33-cloud/TAYJAY/main/TAYJAY%20MAIN.lua"))()
```

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dailizer33-cloud/TAYJAY/main/Tayjay%20Farm.lua"))()
```

## โครงสร้างโค้ด MAIN

`TAYJAY MAIN.lua` แยกเป็นโมดูลใน `src/` และรวมกลับเป็นไฟล์เดียวตามลำดับใน `src/manifest.txt`

```
src/
  boot/      ตัวเปิด/ปิด scope (xpcall, FPS scope) + early bootstrap
  core/      diagnostic, GUI parenting, utils, Resource Manager, Cleanup, state, logic
  features/  blacklist, noclip, fly, death note, warp, monster warp, rapid bite, walk2, ESP, MM2, FPS booster
  ui/        layout, widgets, main menu, server selector, theme, quick visibility
  manifest.txt
tools/build.py
```

ทุกโมดูลรันอยู่ใน scope เดียวกัน (local ที่ประกาศในไฟล์ก่อนหน้าใช้ได้ในไฟล์ถัดไป) ดังนั้นลำดับใน `manifest.txt` สำคัญ และแต่ละไฟล์ไม่ใช่สคริปต์ที่รันเดี่ยวได้

### วิธีแก้โค้ด

1. แก้ไฟล์ใน `src/` (แก้บนเว็บ GitHub หรืออัปโหลดไฟล์โมดูลได้เลย)
2. push/commit เข้า branch ใดก็ได้
3. GitHub Actions (`Build`) จะสร้าง `TAYJAY MAIN.lua` ใหม่และ commit กลับให้อัตโนมัติ (`github-actions[bot]`) ภายในประมาณ 1 นาที

ถ้ามีเครื่องที่มี Python จะรัน `python3 tools/build.py` เองก่อน commit ก็ได้ ผลลัพธ์เหมือนกัน

**ห้ามแก้หรืออัปโหลด `TAYJAY MAIN.lua` ทับโดยตรง** ถ้าไฟล์นี้ไม่ตรงกับ `src/` workflow จะขึ้นสีแดงและ**ไม่เขียนทับ** การแก้ไขนั้น ให้ย้ายการแก้ไขไปไว้ในโมดูลที่ถูกต้องใน `src/` แล้วรัน build ใหม่

### หาตำแหน่ง error

error ในเกมจะบอกเลขบรรทัดของ `TAYJAY MAIN.lua` ใช้ `tools/where.py` แปลงเป็นโมดูล:

```
$ python3 tools/where.py "TAYJAY MAIN.lua:4329: attempt to index nil"
MAIN:4329 -> src/features/mm2.lua:135

$ python3 tools/where.py --map      # ดูช่วงบรรทัดของทุกโมดูล
```

### ตรวจ Luau และข้อจำกัด 200 local

Luau จำกัด register (local + ค่าชั่วคราว) ไว้ที่ 200 ต่อฟังก์ชัน และ MAIN เก็บ state เป็น local ใน scope ใหญ่ scope เดียว workflow `Luau` จะ:

- คอมไพล์ไฟล์ build และ `Tayjay Farm.lua` ที่ -O1 (fail ถ้าคอมไพล์ไม่ผ่าน พร้อมบอกโมดูล:บรรทัด)
- วัดว่า main scope และ FPS scope ยังเหลือ register ว่างกี่ตัว และขึ้น **warning** ถ้าเหลือน้อยกว่า 30
- รายงานผล -O0 เป็นข้อมูลเท่านั้น (ตอนนี้ -O0 คอมไพล์ไม่ผ่านอยู่แล้ว)

รันเองได้ด้วย `python3 tools/check_locals.py --luau-compile /path/to/luau-compile`

## เวอร์ชัน

| Tag | ไฟล์ |
|---|---|
| `main-v1` | `TAYJAY MAIN.lua` (Resource Manager V1 + Cleanup Core V1 + FPS Booster V72) |
| `farm-v26.2` | `Tayjay Farm.lua` |

## แนวทางการพัฒนา

- ใช้ข้อความ commit ที่บอกว่าแก้อะไร เช่น `Fix FPS owner restore callback scope` แทน `Add files via upload`
- ทุก loop / connection ใหม่ควรลงทะเบียนผ่าน Cleanup Owner/Bag เพื่อให้ STOP ALL ล้างได้ครบ
- ระวังข้อจำกัด Luau 200 local ต่อ scope: เก็บ state ไว้ในตารางแทนการประกาศ local ระดับบนสุดเพิ่ม
- ตรวจ syntax ก่อน push: `python3 tools/build.py && luau-compile --null "TAYJAY MAIN.lua"`

## Roadmap

1. จัด repo: README, archive, `.gitattributes`, tag เวอร์ชัน
2. แยก `TAYJAY MAIN.lua` เป็นโมดูล (`src/core`, `src/features`, `src/ui`) + build script รวมเป็นไฟล์เดียว
3. ทำให้ทุก loop ผ่าน Cleanup Bag และให้ Resource Manager จำกัด loop ได้จริง
4. GitHub Actions: `luau-compile`, `selene`, `stylua`
