# iOS 麻将实时识别与胡牌计算 (IOSMaJiangAR)

基于 iOS AVFoundation + Core ML (YOLOv8) 实现的实时麻将识别与听牌计算器。

## ⚠️ 重要说明：模型文件缺失与生成指南

由于 Git 仓库大小限制及模型版权原因，本项目仓库中包含的 `MahjongYOLOv8n.mlmodelc` 仅为占位符。

**您需要自行生成或下载模型文件，否则 App 无法识别麻将牌。**

### 如何获取模型文件

我们在 `ModelTraining` 目录下提供了一个 Python 脚本，您可以使用它来训练自己的模型或从公开数据集导出。

**推荐步骤（使用 Google Colab）：**

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
