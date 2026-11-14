#!/usr/bin/env python3
"""Rasterize a small UI Chinese font and the string table that uses it.

The game font engine is a 256-slot 8-bit font. Codes 32-126 are ASCII so a
string that also contains printf text still draws. Codes 128+ are the
Chinese glyphs used by redalert/ios_text.cpp. Output is committed; the iOS
build does not need the source font installed.
"""

import os
import struct

from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"
CELL = 8
# id, utf-8 text. Keep printf conversions identical to the English original.
STRINGS = [
    (4, "出售"),
    (5, "出售建筑"),
    (6, "修复"),
    (7, "我方"),
    (8, "敌方"),
    (9, "摧毁建筑"),
    (10, "摧毁单位"),
    (11, "采集矿石"),
    (12, "得分:%d"),
    (13, "是"),
    (14, "否"),
    (15, "任务完成"),
    (16, "任务失败"),
    (17, "开始新游戏"),
    (18, "片头预告"),
    (19, "取消"),
    (23, "确定"),
    (35, "读取任务"),
    (36, "保存任务"),
    (37, "删除任务"),
    (38, "读取"),
    (39, "保存"),
    (40, "删除"),
    (41, "游戏控制"),
    (42, "声音控制"),
    (43, "继续任务"),
    (44, "画面控制"),
    (45, "放弃任务"),
    (46, "退出游戏"),
    (47, "选项"),
    (51, "亮度"),
    (52, "音乐音量"),
    (53, "音效音量"),
    (54, "色调"),
    (55, "对比度"),
    (56, "游戏速度"),
    (57, "卷屏速度"),
    (58, "颜色"),
    (59, "返回游戏"),
    (60, "敌方士兵"),
    (61, "敌方车辆"),
    (62, "敌方建筑"),
    (63, "轻型坦克"),
    (64, "重型坦克"),
    (65, "中型坦克"),
    (66, "猛犸坦克"),
    (67, "防空阵地"),
    (68, "突击吉普"),
    (69, "支奴干"),
    (70, "采矿车"),
    (71, "自行火炮"),
    (72, "步枪兵"),
    (73, "掷弹兵"),
    (74, "火箭兵"),
    (75, "喷火兵"),
    (76, "长弓直升机"),
    (77, "雌鹿直升机"),
    (78, "装甲运兵车"),
    (79, "警戒塔"),
    (80, "雷达站"),
    (81, "直升机场"),
    (82, "机场"),
    (83, "矿石仓库"),
    (84, "建造场"),
    (85, "矿石精炼厂"),
    (123, "炮塔"),
    (124, "炮艇"),
    (125, "基地车"),
    (126, "发电厂"),
    (127, "高级发电厂"),
    (128, "医院"),
    (129, "兵营"),
    (130, "油井"),
    (131, "油轮"),
    (132, "沙袋"),
    (133, "铁丝网"),
    (134, "混凝土墙"),
    (135, "铁丝围栏"),
    (136, "木栅栏"),
    (137, "战车工厂"),
    (138, "高级警戒塔"),
    (139, "研究所"),
    (140, "修理厂"),
    (141, "侧栏"),
    (142, "选项"),
    (143, "资料"),
    (145, "选项菜单"),
    (146, "停止"),
    (147, "播放"),
    (148, "随机"),
    (149, "重复"),
    (150, "音乐音量"),
    (151, "音效音量"),
    (152, "开"),
    (153, "关"),
    (154, "多人游戏"),
    (155, "没有存档"),
    (158, "恢复默认"),
    (159, "要放弃任务吗"),
    (160, "任务说明"),
    (172, "加快"),
    (173, "减慢"),
    (174, "空袭"),
    (179, "读不到任务"),
    (180, "读取失败"),
    (183, "保存失败"),
    (184, "删除这个存档"),
    (185, "空位"),
    (186, "选择多人游戏"),
    (191, "新建"),
    (192, "加入"),
    (193, "发送消息"),
    (194, "你的名字"),
    (195, "你的阵营"),
    (196, "你的颜色"),
    (399, "苏军科技中心"),
    (473, "盟军"),
    (474, "苏军"),
    (483, "选择阵营"),
]


def raster(font, ch):
    img = Image.new("L", (CELL, CELL), 0)
    draw = ImageDraw.Draw(img)
    bbox = font.getbbox(ch)
    w = max(1, bbox[2] - bbox[0])
    h = max(1, bbox[3] - bbox[1])
    x = (CELL - w) // 2 - bbox[0]
    y = (CELL - h) // 2 - bbox[1]
    draw.text((x, y), ch, font=font, fill=255)
    pixels = img.load()
    rows = []
    ink = 0
    for row in range(CELL):
        bits = []
        for col in range(CELL):
            on = 1 if pixels[col, row] > 96 else 0
            ink += on
            bits.append(on)
        rows.append(bits)
    return rows, ink


def pack_glyph(rows):
    data = bytearray()
    for bits in rows:
        col = 0
        while col < CELL:
            lo = bits[col]
            hi = bits[col + 1] if col + 1 < CELL else 0
            data.append(lo | (hi << 4))
            col += 2
    return data


def main():
    font = ImageFont.truetype(FONT_PATH, CELL)
    reserved = {10, 13}  # newline and carriage return are controls, not glyphs
    chars = []
    for _, text in STRINGS:
        for ch in text:
            if ord(ch) < 128:
                if ch != "\0":
                    reserved.add(ord(ch))
            elif ch not in chars:
                chars.append(ch)
    free = [code for code in range(1, 256) if code not in reserved]
    if len(chars) > len(free):
        raise SystemExit("too many CJK glyphs: %d free %d" % (len(chars), len(free)))
    seen = {ch: free[i] for i, ch in enumerate(chars)}

    widths = [0] * 256
    glyphs = [b""] * 256
    for code in sorted(reserved):
        if code in (10, 13):
            continue
        rows, ink = raster(font, chr(code))
        glyphs[code] = pack_glyph(rows)
        widths[code] = 4 if code == 32 else CELL
    for ch, code in seen.items():
        rows, ink = raster(font, ch)
        glyphs[code] = pack_glyph(rows)
        widths[code] = CELL

    info = 0x10
    offset_block = 0x14
    width_block = offset_block + 256 * 2
    height_block = width_block + 256
    data_block = height_block + 256 * 2

    blob = bytearray(data_block)
    cursor = data_block
    offsets = [0] * 256
    heights = [0] * 256
    for code in range(256):
        g = glyphs[code]
        if not g:
            g = bytes(CELL * ((CELL + 1) // 2))
        offsets[code] = cursor
        # ypos in low byte, line count in high byte
        heights[code] = (CELL << 8) | 0
        blob += g
        cursor += len(g)

    total = len(blob)

    def put16(at, value):
        blob[at : at + 2] = struct.pack("<H", value & 0xFFFF)

    put16(0, total)
    blob[2] = 0
    blob[3] = 5
    put16(4, info)
    put16(6, offset_block)
    put16(8, width_block)
    put16(10, data_block)
    put16(12, height_block)
    put16(14, 0x1012)
    blob[16] = 0
    blob[17] = 255
    blob[18] = CELL
    blob[19] = CELL
    for code in range(256):
        put16(offset_block + code * 2, offsets[code])
        blob[width_block + code] = widths[code]
        put16(height_block + code * 2, heights[code])

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    font_path = os.path.join(root, "common", "ios_cjk_data.inc")
    text_path = os.path.join(root, "redalert", "ios_text_data.inc")

    def c_bytes(data, per=16):
        lines = []
        for i in range(0, len(data), per):
            chunk = data[i : i + per]
            lines.append("    " + ", ".join("%d" % b for b in chunk) + ",")
        return "\n".join(lines)

    with open(font_path, "w", encoding="utf-8") as out:
        out.write("// Generated by scripts/gen-ios-cjk.py from Droid Sans Fallback (Apache-2.0).\n")
        out.write("// 8x8 UI font. Not a Red Alert game asset.\n")
        out.write("static const unsigned char ios_cjk_font[] = {\n")
        out.write(c_bytes(blob))
        out.write("\n};\n")
        out.write("static const unsigned char ios_cjk_width[256] = {\n")
        out.write(c_bytes(widths))
        out.write("\n};\n")

    encoded = []
    for sid, text in STRINGS:
        raw = bytearray()
        for ch in text:
            if ord(ch) < 128:
                raw.append(ord(ch))
            else:
                raw.append(seen[ch])
        encoded.append((sid, bytes(raw)))

    with open(text_path, "w", encoding="utf-8") as out:
        out.write("// Generated by scripts/gen-ios-cjk.py. Bytes outside ASCII index the CJK font.\n")
        out.write("static const struct { int id; const char* text; } ios_zh_lines[] = {\n")
        for sid, raw in encoded:
            escapes = "".join("\\x%02x" % b for b in raw)
            out.write('    {%d, "%s"},\n' % (sid, escapes))
        out.write("};\n")

    print("glyphs", len(chars), "font", total, "strings", len(encoded))


if __name__ == "__main__":
    main()
