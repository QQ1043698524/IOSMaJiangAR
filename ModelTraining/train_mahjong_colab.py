# ==============================================================================
# YOLOv8 麻将模型云端训练脚本 (Google Colab 专用)
# ==============================================================================
#
# 使用指南：
# 1. 打开 Google Colab: https://colab.research.google.com/
# 2. 点击 "新建笔记本" (New Notebook)
# 3. 将本文件的所有内容复制粘贴到 Colab 的代码框中
# 4. 替换下方的 API_KEY 为您的 Roboflow API Key
#    (获取 Key：注册 Roboflow -> Settings -> API Keys -> Copy Private Key)
# 5. 点击运行按钮 (Play icon)
# 6. 等待运行完成，下载生成的 'MahjongYOLOv8n.zip'
# ==============================================================================

# ---------------- 配置区域 ----------------
# 请替换为您自己的 Roboflow API Key
# 注册地址：https://app.roboflow.com/login
API_KEY = "7NVInnzDTnMF3hXFbCpQ" 
# ------------------------------------------

import os
import shutil
from IPython.display import clear_output

# 1. 安装依赖
print("🚀 正在安装依赖...")
!pip install ultralytics roboflow
clear_output()
print("✅ 依赖安装完成")

# 2. 下载数据集
print("📦 正在下载麻将数据集...")
from roboflow import Roboflow
rf = Roboflow(api_key=API_KEY)
project = rf.workspace("test-wmo8i").project("mahjong_yolo")

# 尝试下载不同版本（优先尝试 v4，失败则尝试 v1）
dataset = None
try:
    print("尝试下载版本 v4...")
    version = project.version(4)
    dataset = version.download("yolov8")
except Exception as e:
    print(f"⚠️ 版本 v4 下载失败: {e}")
    print("尝试下载版本 v1...")
    try:
        version = project.version(1)
        dataset = version.download("yolov8")
    except Exception as e2:
        print(f"❌ 数据集下载失败: {e2}")
        print("请检查 API Key 是否正确，或手动确认 Roboflow 项目版本。")
        raise e2

# 3. 训练模型
print("🔥 开始训练 YOLOv8n 模型...")
from ultralytics import YOLO

# 加载预训练模型
model = YOLO('yolov8n.pt')

# 开始训练 (快速模式：10轮)
# 如果想要更好的效果，可以将 epochs 改为 50 或 100
results = model.train(
    data=f"{dataset.location}/data.yaml",
    epochs=10,
    imgsz=640,
    name='mahjong_yolov8n'
)

# 4. 导出为 Core ML
print("🍎 正在导出为 Core ML 格式...")
# 加载训练好的最佳权重
best_model = YOLO(f"runs/detect/mahjong_yolov8n/weights/best.pt")
# 导出 (开启 NMS)
# 注意：最新版 ultralytics 已移除 layers 参数，只需 nms=True
best_model.export(format='coreml', nms=True)

# 5. 打包下载
print("📦 正在打包模型文件...")
output_folder = "MahjongYOLOv8n.mlmodelc"
source_folder = f"runs/detect/mahjong_yolov8n/weights/best.mlmodelc"

if os.path.exists(output_folder):
    shutil.rmtree(output_folder)
shutil.move(source_folder, output_folder)

# 压缩
shutil.make_archive("MahjongYOLOv8n", 'zip', output_folder)

print("\n" + "="*50)
print("🎉🎉🎉 全部完成！ 🎉🎉🎉")
print("请在左侧文件栏刷新，找到 'MahjongYOLOv8n.zip' 并下载。")
print("解压后替换 iOS 项目中的同名文件夹即可。")
print("="*50)
