# iOS 麻将实时识别与胡牌计算 (IOSMaJiangAR)

基于 iOS AVFoundation + Core ML (YOLOv8) 实现的实时麻将识别与听牌计算器。

## ⚠️ 重要说明：模型文件缺失

由于 Git 仓库大小限制及模型版权原因，本项目仓库中包含的 `MahjongYOLOv8n.mlmodelc` 仅为占位符。

**在编译或运行前，您必须：**

1. 准备好转换后的 Core ML 模型文件夹 `MahjongYOLOv8n.mlmodelc`。
2. 将该文件夹替换掉项目目录 `IOSMaJiangAR/MahjongYOLOv8n.mlmodelc` 中的占位内容。
3. 确保替换后的文件夹内包含 `coremldata.bin` 等模型数据文件。

如果未替换模型文件，App 启动后进入相机识别模式时将会崩溃。

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
