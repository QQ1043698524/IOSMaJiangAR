# ==============================================================================
# YOLOv8 模型导出脚本 (仅导出，不训练)
# ==============================================================================
# 
# 适用场景：您已经训练过模型，现在只想重新导出 (例如修复了 export 参数报错后)
# 前提：您的 Colab 环境中必须还保留着之前训练的权重文件 (runs/detect/mahjong_yolov8n/weights/best.pt)
#
# 使用指南：
# 1. 将本脚本内容复制到 Colab
# 2. 运行脚本
# 3. 下载生成的 zip 文件
# ==============================================================================

import os
import shutil
from ultralytics import YOLO

# 1. 检查权重文件是否存在
weights_path = "runs/detect/mahjong_yolov8n/weights/best.pt"
if not os.path.exists(weights_path):
    print(f"❌ 错误：找不到权重文件 {weights_path}")
    print("如果您重启了 Colab Runtime，之前的训练结果可能已被清空。")
    print("请重新运行完整的训练脚本 (train_mahjong_colab.py)。")
else:
    print(f"✅ 找到权重文件：{weights_path}")
    
    # 2. 导出 Core ML
    print("🍎 正在重新导出为 Core ML 格式...")
    model = YOLO(weights_path)
    # 注意：nms=True, 且不使用 layers 参数
    model.export(format='coreml', nms=True)

    # 3. 打包下载
    print("📦 正在打包模型文件...")
    output_folder = "MahjongYOLOv8n.mlmodelc"
    
    # YOLO 导出 CoreML 可能会生成 .mlpackage 或 .mlmodel
    # 我们优先查找 .mlpackage，因为它是新格式
    source_mlpackage = f"runs/detect/mahjong_yolov8n/weights/best.mlpackage"
    
    # 如果找不到 mlpackage，可能生成的是旧版 .mlmodel
    # 注意：.mlmodel 需要 Xcode 编译才能变成 .mlmodelc，这里我们尽量找 .mlpackage
    
    # 清理旧的输出
    if os.path.exists(output_folder):
        shutil.rmtree(output_folder)
        
    if os.path.exists(source_mlpackage):
        print(f"✅ 找到模型包：{source_mlpackage}")
        # 将 .mlpackage 移动并重命名为 .mlmodelc (虽然技术上它们结构不同，但在某些简单的部署场景下，或者后续让用户用 Xcode 编译)
        # 更稳妥的做法是提示用户下载后用 Xcode 编译
        # 但为了方便，我们尝试直接打包
        
        # 修正：直接打包 .mlpackage，让用户下载后改名或编译
        # 或者我们尝试查找 ultralytics 是否生成了编译好的 .mlmodelc (通常在 Mac 上才会自动编译)
        
        # 在 Colab (Linux) 上，通常只能得到 .mlpackage
        # 我们将其重命名为 MahjongYOLOv8n.mlpackage 打包
        
        target_name = "MahjongYOLOv8n.mlpackage"
        if os.path.exists(target_name):
            shutil.rmtree(target_name)
        shutil.move(source_mlpackage, target_name)
        
        # 压缩
        zip_filename = "MahjongYOLOv8n"
        shutil.make_archive(zip_filename, 'zip', target_name)

        print("\n" + "="*50)
        print("🎉🎉🎉 导出完成！ 🎉🎉🎉")
        print(f"请在左侧文件栏刷新，找到 '{zip_filename}.zip' 并下载。")
        print("注意：下载解压后得到的是 .mlpackage 文件。")
        print("请将其拖入 Xcode 项目中，Xcode 会自动处理它。")
        print("或者在 Mac 终端运行：xcrun coremlcompiler compile MahjongYOLOv8n.mlpackage .")
        print("然后将生成的 .mlmodelc 文件夹替换到项目中。")
        print("="*50)
    else:
        # 备选：查找是否生成了其他名称
        print(f"❌ 未找到预期输出文件：{source_mlpackage}")
        print("请检查 runs/detect/mahjong_yolov8n/weights/ 目录下生成了什么文件。")
