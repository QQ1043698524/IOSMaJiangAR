from ultralytics import YOLO
import os

# 1. 准备数据集
# 请确保你有一个包含麻将标注数据的 data.yaml 文件
# 如果没有数据集，可以使用 Roboflow 公开数据集：
# https://universe.roboflow.com/test-wmo8i/mahjong_yolo

# 2. 加载预训练模型 (YOLOv8 nano 版本，轻量级适合移动端)
model = YOLO('yolov8n.pt')

# 3. 训练模型 (需要 GPU 环境，否则非常慢)
# 如果你在本地没有 GPU，建议将此脚本和数据集上传到 Google Colab 运行
print("开始训练...")
results = model.train(
    data='mahjong_dataset/data.yaml', # 替换为你的数据集路径
    epochs=50,                        # 训练轮数
    imgsz=640,                        # 图像大小
    batch=16,
    name='mahjong_yolov8n'
)

# 4. 导出为 Core ML 格式
print("导出 Core ML 模型...")
model.export(
    format='coreml', 
    nms=True,                         # 包含非极大值抑制(NMS)后处理
    layers=True                       # 尽可能保留 Core ML 层结构
)

print("完成！请将生成的 'best.mlpackage' 或 'best.mlmodelc' 放入 iOS 项目中。")
print("注意：iOS 项目需要的是编译后的 .mlmodelc 文件夹。")
print("如果是 .mlpackage，请在 Xcode 中打开并编译，或使用 'xcrun coremlcompiler compile' 命令转换。")
