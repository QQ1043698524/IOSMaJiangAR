@echo off
setlocal

echo ===================================================
echo   Checking Python environment...
echo ===================================================

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Python is not installed or not in your PATH.
    echo.
    echo Please install Python from https://www.python.org/downloads/
    echo OR
    echo Use the Direct Download method described in README.md (Recommended)
    echo.
    pause
    exit /b 1
)

echo Python found. Checking pip...
python -m pip --version >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] pip is not installed.
    echo Please install pip or reinstall Python.
    echo.
    pause
    exit /b 1
)

echo.
echo ===================================================
echo   Installing required Python library (ultralytics)...
echo ===================================================
python -m pip install ultralytics

echo.
echo ===================================================
echo   Generating generic YOLOv8n Core ML model...
echo ===================================================
python ModelTraining/create_demo_model.py

echo.
echo ===================================================
echo   Done! Check the output folder.
echo ===================================================
pause
