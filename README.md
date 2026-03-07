# iOS 麻将实时识别与胡牌计算 (IOSMaJiangAR)

基于 iOS AVFoundation + Core ML (YOLOv8) 实现的实时麻将识别与听牌计算器。

## ⚠️ 重要说明：模型文件缺失与生成指南

由于 Git 仓库大小限制及模型版权原因，本项目仓库中包含的 `MahjongYOLOv8n.mlmodelc` 仅为占位符。

**您需要自行生成或下载模型文件，否则 App 无法识别麻将牌。**

### 如何获取模型文件

由于您本地可能没有 Python 环境，且 Roboflow 下载可能受限，我们推荐使用 **Google Colab** 云端生成模型。

**⚡️ 方案一：生成通用测试模型 (无需任何配置，最快)**

此模型**无法识别麻将**（只能识别猫狗、人等），但能让 App **正常启动不闪退**，方便您测试 UI 和横屏效果。

1.  打开 [Google Colab](https://colab.research.google.com/)。
2.  新建笔记本，复制以下代码并运行：
    ```python
    !pip install ultralytics
    from ultralytics import YOLO
    import shutil
    import os
    
    # 下载通用模型并转换
    model = YOLO('yolov8n.pt') 
    model.export(format='coreml', nms=True)
    
    # 重命名并打包
    if os.path.exists('MahjongYOLOv8n.mlmodelc'):
        shutil.rmtree('MahjongYOLOv8n.mlmodelc')
    shutil.move('yolov8n.mlmodelc', 'MahjongYOLOv8n.mlmodelc')
    shutil.make_archive('MahjongYOLOv8n', 'zip', 'MahjongYOLOv8n.mlmodelc')
    ```
3.  下载生成的 `MahjongYOLOv8n.zip`，解压替换项目中的文件夹。

**🔥 方案二：在线训练真实麻将模型 (推荐)**

如果您需要**真实的麻将识别能力**，可以使用我们提供的专用训练脚本。

1.  在项目目录 `ModelTraining/` 下找到 `train_mahjong_colab.py` 文件。
2.  打开 [Google Colab](https://colab.research.google.com/)。
3.  将 `train_mahjong_colab.py` 的内容**全部复制粘贴**到 Colab 中。
4.  **关键步骤**：去 [Roboflow 注册](https://app.roboflow.com/) 一个免费账号，获取 API Key，替换脚本中的 `YOUR_ROBOFLOW_API_KEY`。
5.  点击运行。脚本会自动下载麻将数据集、训练模型并导出为 Core ML 格式。
6.  下载生成的 zip 文件。
7.  **重要**：解压后得到的是 `MahjongYOLOv8n.mlpackage`。
8.  请将其拖入您的 Xcode 项目中（Xcode 会自动编译它），**或者**在 Mac 终端运行以下命令手动编译：
    ```bash
    xcrun coremlcompiler compile MahjongYOLOv8n.mlpackage .
    ```
    然后将生成的 `MahjongYOLOv8n.mlmodelc` 文件夹替换项目中的同名文件夹。

**💡 提示：如果训练已完成但导出报错**

如果您已经在 Colab 中跑完了训练（耗时 30 分钟），但最后一步导出报错了，**不需要重新训练**！

1.  请复制 `ModelTraining/export_only.py` 的内容。
2.  粘贴到 Colab 的新代码框中运行。
3.  它会直接利用您刚才训练好的权重文件进行重新导出。

## 功能特性

## 功能特性

1.  将 `ModelTraining` 文件夹上传到 Google Colab 或您的本地 GPU 环境。
2.  安装依赖：`pip install -r requirements.txt`
3.  运行脚本：`python train_and_export.py`
4.  脚本会自动下载公开的麻将数据集（需 Roboflow 账号）并开始训练。
5.  训练完成后，您将获得 `best.mlpackage` 或 `best.mlmodel`。
6.  使用 Xcode 打开该模型，或使用 `xcrun coremlcompiler compile best.mlpackage .` 将其编译为 `MahjongYOLOv8n.mlmodelc` 文件夹。
7.  将编译后的文件夹替换掉项目中的占位文件夹。

**如果您有现成的 Core ML 麻将模型：**

直接将其重命名为 `MahjongYOLOv8n.mlmodelc` 并替换 `IOSMaJiangAR/MahjongYOLOv8n.mlmodelc` 即可。

## 功能特性

*   **实时识别**：支持万、条、筒、风、字、花牌全量识别。
*   **胡牌计算**：内置国标、四川、广东麻将规则，自动计算听牌与番数。
*   **离线运行**：完全本地运算，无网络请求，保护隐私。
*   **巨魔兼容**：支持导出为无签名的 IPA，通过 TrollStore 安装。

## 环境要求

*   Xcode 14.0+
*   iOS 16.0+
*   Swift 5.0

## 编译指南

### 使用 GitHub Actions 云端编译

1. Fork 或 Push 本项目到 GitHub。
2. 进入 Actions 页面，选择 "iOS Build"。
3. 点击 "Run workflow"。
4. 编译完成后下载 Artifacts 中的 `IOSMaJiangAR-unsigned.ipa`。

### 本地编译

1. 确保已安装 Xcode。
2. 打开 `IOSMaJiangAR.xcodeproj`。
3. 选择 `IOSMaJiangAR` Scheme 和目标设备（Generic iOS Device）。
4. 运行 Product -> Archive。

## 目录结构

*   `IOSMaJiangAR/`: 源代码目录
    *   `CameraManager.swift`: 相机控制
    *   `MahjongDetector.swift`: Core ML 识别封装
    *   `MahjongCalculator.swift`: 胡牌算法
*   `.github/workflows/`: GitHub Actions 配置

## 许可证

MIT
