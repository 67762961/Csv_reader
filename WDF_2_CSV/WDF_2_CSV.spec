# WDF_2_CSV.spec
# 兼容 PyInstaller 打包，避免 __file__ 错误

import os
import sys

# 获取 spec 文件所在目录（安全方式）
# 方法：使用 sys.argv[0] 的目录，或当前工作目录
try:
    spec_dir = os.path.dirname(os.path.abspath(__file__))
except NameError:
    # __file__ 不存在时（如某些 PyInstaller 调用环境）
    spec_dir = os.path.abspath(os.getcwd())

# 主程序入口（确保 sample.py 在 spec 同目录）
main_script = 'WDF_2_CSV.py'

# DLL 目录（相对于 spec 文件）
dll_x64_dir = os.path.join(spec_dir, 'DLL', 'x64')

# 检查 DLL 是否存在（可选，用于提前报错）
required_dlls = ['DLM3000.dll', 'DLM3000HD.dll', 'DLM5000.dll', 'DLM5000HD.dll']
for dll in required_dlls:
    if not os.path.exists(os.path.join(dll_x64_dir, dll)):
        print(f"⚠️ 警告: DLL 未找到: {dll}")
        # 不中断，因为可能只用其中部分

# 构建 binaries 列表
binaries = []
for dll in required_dlls:
    src = os.path.join(dll_x64_dir, dll)
    if os.path.exists(src):
        binaries.append((src, 'DLL/x64'))

a = Analysis(
    [os.path.join(spec_dir, main_script)],
    pathex=[spec_dir],
    binaries=[
        (os.path.join(spec_dir, 'DLL', 'x64', 'DLM3000.dll'), 'DLL/x64'),
        (os.path.join(spec_dir, 'DLL', 'x64', 'DLM3000HD.dll'), 'DLL/x64'),
        (os.path.join(spec_dir, 'DLL', 'x64', 'DLM5000.dll'), 'DLL/x64'),
        (os.path.join(spec_dir, 'DLL', 'x64', 'DLM5000HD.dll'), 'DLL/x64'),
    ],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='WDF2CSV',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,          # 设为 False 可隐藏黑窗口
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None
)