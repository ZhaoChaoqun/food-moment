#!/usr/bin/env python3
"""
生成 FoodMoment 应用图标
设计：深绿色背景 + 亮绿色圆形 + fork.knife 图标
"""

from PIL import Image, ImageDraw
import os
import math

# 颜色定义（从 SignInView.swift 中提取）
BACKGROUND_COLOR = (16, 34, 22)  # #102216
ACCENT_COLOR = (19, 236, 91)     # #13EC5B

# iOS 需要的图标尺寸
ICON_SIZES = [
    # iPhone
    (40, "AppIcon-40.png"),      # 2x Notification
    (60, "AppIcon-60.png"),      # 3x Notification
    (58, "AppIcon-58.png"),      # 2x Settings
    (87, "AppIcon-87.png"),      # 3x Settings
    (80, "AppIcon-80.png"),      # 2x Spotlight
    (120, "AppIcon-120.png"),    # 3x Spotlight, 2x App
    (180, "AppIcon-180.png"),    # 3x App
    # iPad
    (20, "AppIcon-20.png"),      # 1x Notification
    (29, "AppIcon-29.png"),      # 1x Settings
    (76, "AppIcon-76.png"),      # 1x App
    (152, "AppIcon-152.png"),    # 2x App
    (167, "AppIcon-167.png"),    # iPad Pro
    # App Store
    (1024, "AppIcon-1024.png"),  # App Store
]

def draw_fork(draw, center_x, top_y, bottom_y, scale, color):
    """绘制叉子"""
    handle_width = scale * 8
    tine_width = scale * 3
    tine_gap = scale * 5
    tine_height = scale * 25
    handle_top = top_y + tine_height + scale * 5

    # 叉子手柄
    draw.rounded_rectangle(
        [center_x - handle_width/2, handle_top,
         center_x + handle_width/2, bottom_y],
        radius=handle_width/2,
        fill=color
    )

    # 叉子齿（3个）
    for i in range(-1, 2):
        tine_x = center_x + i * tine_gap
        draw.rounded_rectangle(
            [tine_x - tine_width/2, top_y,
             tine_x + tine_width/2, handle_top + scale * 3],
            radius=tine_width/2,
            fill=color
        )

def draw_knife(draw, center_x, top_y, bottom_y, scale, color):
    """绘制刀子"""
    blade_width = scale * 10
    handle_width = scale * 7
    blade_height = scale * 30
    handle_top = top_y + blade_height

    # 刀柄
    draw.rounded_rectangle(
        [center_x - handle_width/2, handle_top,
         center_x + handle_width/2, bottom_y],
        radius=handle_width/2,
        fill=color
    )

    # 刀身（稍微宽一点，带有刀刃形状）
    blade_points = [
        (center_x - blade_width/3, top_y + scale * 5),  # 左上
        (center_x + blade_width/2, top_y),               # 右上尖端
        (center_x + blade_width/2, handle_top + scale * 5),  # 右下
        (center_x - blade_width/3, handle_top + scale * 5),  # 左下
    ]
    draw.polygon(blade_points, fill=color)

    # 刀身顶部圆角
    draw.ellipse(
        [center_x - blade_width/3 - scale, top_y + scale * 3,
         center_x + blade_width/2, top_y + scale * 8],
        fill=color
    )

def create_icon(size):
    """创建指定尺寸的应用图标"""
    # 创建图像
    img = Image.new('RGB', (size, size), BACKGROUND_COLOR)
    draw = ImageDraw.Draw(img)

    center = size / 2
    scale = size / 100  # 缩放因子

    # 绘制外圈（亮绿色带透明效果）
    outer_radius = size * 0.40
    outer_color = tuple(int(BACKGROUND_COLOR[i] * 0.85 + ACCENT_COLOR[i] * 0.15) for i in range(3))
    draw.ellipse(
        [center - outer_radius, center - outer_radius,
         center + outer_radius, center + outer_radius],
        fill=outer_color
    )

    # 绘制内圈（亮绿色实心）
    inner_radius = size * 0.32
    draw.ellipse(
        [center - inner_radius, center - inner_radius,
         center + inner_radius, center + inner_radius],
        fill=ACCENT_COLOR
    )

    # 图标参数
    icon_color = BACKGROUND_COLOR
    icon_top = center - size * 0.18
    icon_bottom = center + size * 0.18
    gap = size * 0.06  # 叉子和刀子之间的间距

    # 绘制叉子（左侧）
    draw_fork(draw, center - gap, icon_top, icon_bottom, scale, icon_color)

    # 绘制刀子（右侧）
    draw_knife(draw, center + gap, icon_top, icon_bottom, scale, icon_color)

    return img

def main():
    # 确定输出目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    output_dir = os.path.join(
        project_dir,
        "FoodMoment/Resources/Assets.xcassets/AppIcon.appiconset"
    )

    # 创建目录
    os.makedirs(output_dir, exist_ok=True)

    # 生成所有尺寸的图标
    for size, filename in ICON_SIZES:
        icon = create_icon(size)
        filepath = os.path.join(output_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Generated: {filename} ({size}x{size})")

    # 生成 Contents.json
    contents = {
        "images": [
            {"filename": "AppIcon-40.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
            {"filename": "AppIcon-60.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
            {"filename": "AppIcon-58.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
            {"filename": "AppIcon-87.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
            {"filename": "AppIcon-80.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
            {"filename": "AppIcon-120.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
            {"filename": "AppIcon-120.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
            {"filename": "AppIcon-180.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
            {"filename": "AppIcon-20.png", "idiom": "ipad", "scale": "1x", "size": "20x20"},
            {"filename": "AppIcon-40.png", "idiom": "ipad", "scale": "2x", "size": "20x20"},
            {"filename": "AppIcon-29.png", "idiom": "ipad", "scale": "1x", "size": "29x29"},
            {"filename": "AppIcon-58.png", "idiom": "ipad", "scale": "2x", "size": "29x29"},
            {"filename": "AppIcon-40.png", "idiom": "ipad", "scale": "1x", "size": "40x40"},
            {"filename": "AppIcon-80.png", "idiom": "ipad", "scale": "2x", "size": "40x40"},
            {"filename": "AppIcon-76.png", "idiom": "ipad", "scale": "1x", "size": "76x76"},
            {"filename": "AppIcon-152.png", "idiom": "ipad", "scale": "2x", "size": "76x76"},
            {"filename": "AppIcon-167.png", "idiom": "ipad", "scale": "2x", "size": "83.5x83.5"},
            {"filename": "AppIcon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1}
    }

    import json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"\nGenerated: Contents.json")
    print(f"\nAll icons saved to: {output_dir}")

if __name__ == "__main__":
    main()
