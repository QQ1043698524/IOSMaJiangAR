from ultralytics import YOLO
import os

# 这个脚本会下载官方的 YOLOv8n (Nano) 预训练模型
# 并将其导出为 Core ML 格式。
# 
# 用途：虽然这个模型只能识别 COCO 数据集（人、车、猫狗等），无法识别麻将，
# 但它可以用来测试 App 是否能正常运行而不崩溃。
# 如果你只是想先看看 App 的界面效果，可以用这个生成的模型先顶替一下。

def create_demo_model():
    print("正在下载 YOLOv8n 官方模型...")
    model = YOLO('yolov8n.pt')
    
    print("正在导出为 Core ML 格式...")
    # 导出时开启 NMS (非极大值抑制) 以便直接输出最终检测结果
    # 注意：最新版 ultralytics 已移除 layers 参数，只需 nms=True
    model.export(format='coreml', nms=True)
    
    print("\n" + "="*50)
    print("导出成功！")
    print("请查找当前目录下的 'yolov8n.mlpackage' 或 'yolov8n.mlmodelc' 文件夹。")
    print("1. 将其重命名为 'MahjongYOLOv8n.mlmodelc'")
    print("2. 替换项目中的 'IOSMaJiangAR/MahjongYOLOv8n.mlmodelc' 文件夹")
    print("3. 重新运行 App")
    print("="*50)

if __name__ == "__main__":
    create_demo_model()
