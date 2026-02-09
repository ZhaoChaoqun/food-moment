#!/bin/bash

# 自动截图脚本
# 用法: ./scripts/capture_screenshots.sh [设备名称]

set -e

# 默认设备
DEVICE="${1:-iPhone 16 Pro}"
SCHEME="FoodMoment"
OUTPUT_DIR="$HOME/Desktop/FoodMomentScreenshots"

echo "📸 FoodMoment 自动截图工具"
echo "=========================="
echo "设备: $DEVICE"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 重新生成项目（如果使用 XcodeGen）
if command -v xcodegen &> /dev/null; then
    echo "🔧 正在生成 Xcode 项目..."
    xcodegen generate
fi

# 运行截图测试
echo "🚀 正在运行截图测试..."
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -only-testing:FoodMomentUITests/ScreenshotTests \
    -resultBundlePath "$OUTPUT_DIR/TestResults.xcresult" \
    | xcbeautify || xcpretty || cat

# 提取截图到输出目录
echo "📦 正在提取截图..."

# 从 Documents 目录复制截图
DOCS_DIR="$HOME/Library/Developer/CoreSimulator/Devices"
SCREENSHOT_FOLDER="FoodMomentScreenshots"

# 查找最新的模拟器 Documents 目录中的截图
find "$DOCS_DIR" -name "$SCREENSHOT_FOLDER" -type d 2>/dev/null | while read dir; do
    if [ -d "$dir" ]; then
        echo "找到截图目录: $dir"
        cp -r "$dir"/* "$OUTPUT_DIR/" 2>/dev/null || true
    fi
done

# 从测试结果中提取截图附件
if [ -d "$OUTPUT_DIR/TestResults.xcresult" ]; then
    echo "📎 正在从测试结果提取附件..."
    xcrun xcresulttool get --path "$OUTPUT_DIR/TestResults.xcresult" --format json > "$OUTPUT_DIR/results.json" 2>/dev/null || true
fi

echo ""
echo "✅ 截图完成！"
echo "📂 输出目录: $OUTPUT_DIR"
echo ""

# 打开输出目录
open "$OUTPUT_DIR"
