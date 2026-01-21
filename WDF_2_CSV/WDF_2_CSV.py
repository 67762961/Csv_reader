## (c) Copyright 2023 Yokogawa Test & Measurement Corporation
## Modified for PyInstaller packaging and batch CSV export
import os
import sys
from ctypes import *
from ctypes.wintypes import *
import csv
import numpy as np
from tkinter import Tk
from tkinter.filedialog import askdirectory
import time


# ==============================
# 🔧 带时间戳的日志函数
# ==============================
def log(message):
    """打印带 [HH:MM:SS] 前缀的消息"""
    current_time = time.strftime("%H:%M:%S")
    print(f"[{current_time}] {message}")


# ==============================
# 🔧 工具函数：兼容 PyInstaller 的资源路径
# ==============================
def get_dll_path(dll_filename):
    if getattr(sys, "frozen", False):
        base_dir = sys._MEIPASS
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base_dir, "DLL", "x64", dll_filename)


# ==============================
# 常量与结构体（保持不变）
# ==============================
MAX_WDF_TRACE_NAME = 17
MAX_WDF_V_UNIT = 17
MAX_WDF_H_UNIT = 17

OpenModeNormal = 0

DataTypeUINT16 = 0x10
DataTypeSINT16 = 0x11
DataTypeLOGIC16 = 0x14
DataTypeUINT32 = 0x20
DataTypeSINT32 = 0x21
DataTypeFLOAT = 0x22
DataTypeLOGIC32 = 0x24

WDFError = {
    1: "Invalid Handle",
    2: "Invalid Parameter",
    100: "File Open Error",
    101: "Memory Allocation Error",
    102: "File Access Error",
    105: "Not Dual Capture Error",
    200: "Unknown Version Error",
    201: "Illegal WDF Format Error",
    300: "Illegal acquiring parameter",
    901: "Data Value Exception",
    902: "Other error",
}


class WDFAccessParam(Structure):
    _fields_ = [
        ("version", c_uint),
        ("trace", c_uint),
        ("block", c_uint),
        ("start", c_int),
        ("count", c_int),
        ("ppRate", c_int),
        ("waveType", c_int),
        ("dataType", c_int),
        ("cntOut", c_int),
        ("dst", c_void_p),
        ("box", c_int),
        ("compMode", c_int),
        ("rsv1", c_int),
        ("rsv2", c_int),
        ("rsv3", c_int),
        ("rsv4", c_int),
    ]

    def __init__(self, trace, block, start, count, dst):
        self.version = 1
        self.trace = trace
        self.block = block
        self.start = start
        self.count = count
        self.ppRate = 512
        self.waveType = 0
        self.dataType = 0
        self.cntOut = 0
        self.dst = dst
        self.box = 0
        self.compMode = 0
        self.rsv1 = 0
        self.rsv2 = 0
        self.rsv3 = 0
        self.rsv4 = 0


# 全局缓存（放在函数外）
_DLL_CACHE = {}


class WDFAPI:
    def __init__(self, dllfile):
        if dllfile not in _DLL_CACHE:
            _DLL_CACHE[dllfile] = windll.LoadLibrary(dllfile)
        self.dll = _DLL_CACHE[dllfile]

    def OpenFile(self, fileName):
        self.handle = HANDLE()
        result = self.dll.WdfOpenFile(pointer(self.handle), c_char_p(fileName.encode("shift_jis")), c_int(OpenModeNormal))
        if result != 0:
            raise Exception(WDFError[result])

    def CloseFile(self):
        self.dll.WdfCloseFile(pointer(self.handle))

    def GetTraceNumber(self):
        traceNumber = c_int()
        result = self.dll.WdfGetTraceNumber(self.handle, pointer(traceNumber))
        if result != 0:
            raise Exception(WDFError[result])
        return traceNumber.value

    def GetTraceName(self, trace):
        traceName = create_string_buffer(MAX_WDF_TRACE_NAME)
        result = self.dll.WdfGetTraceName(self.handle, c_uint(trace), pointer(traceName))
        if result != 0:
            raise Exception(WDFError[result])
        return traceName.value.decode("shift_jis").rstrip()

    def GetTraceBlockNumber(self, trace):
        blockNumber = c_uint()
        result = self.dll.WdfGetTraceBlockNumber(self.handle, c_uint(trace), pointer(blockNumber))
        if result != 0:
            raise Exception(WDFError[result])
        return blockNumber.value

    def GetVDataType(self, trace, block):
        vDataType = c_uint()
        result = self.dll.WdfGetVDataType(self.handle, c_uint(trace), c_uint(block), pointer(vDataType))
        if result != 0:
            raise Exception(WDFError[result])
        return vDataType.value

    def GetVOffset(self, trace, block):
        vOffset = c_double()
        result = self.dll.WdfGetVOffset(self.handle, c_uint(trace), c_uint(block), pointer(vOffset))
        if result != 0:
            raise Exception(WDFError[result])
        return vOffset.value

    def GetVResolution(self, trace, block):
        vResolution = c_double()
        result = self.dll.WdfGetVResolution(self.handle, c_uint(trace), c_uint(block), pointer(vResolution))
        if result != 0:
            raise Exception(WDFError[result])
        return vResolution.value

    def GetVUnit(self, trace, block):
        vUnit = create_string_buffer(MAX_WDF_V_UNIT)
        result = self.dll.WdfGetVUnit(self.handle, c_uint(trace), c_uint(block), pointer(vUnit))
        if result != 0:
            raise Exception(WDFError[result])
        return vUnit.value.decode("shift_jis").rstrip()

    def GetHOffset(self, trace, block):
        hOffset = c_double()
        result = self.dll.WdfGetHOffset(self.handle, c_uint(trace), c_uint(block), pointer(hOffset))
        if result != 0:
            raise Exception(WDFError[result])
        return hOffset.value

    def GetHResolution(self, trace, block):
        hResolution = c_double()
        result = self.dll.WdfGetHResolution(self.handle, c_uint(trace), c_uint(block), pointer(hResolution))
        if result != 0:
            raise Exception(WDFError[result])
        return hResolution.value

    def GetHUnit(self, trace, block):
        hUnit = create_string_buffer(MAX_WDF_H_UNIT)
        result = self.dll.WdfGetHUnit(self.handle, c_uint(trace), c_uint(block), pointer(hUnit))
        if result != 0:
            raise Exception(WDFError[result])
        return hUnit.value.decode().rstrip()

    def GetBlockSize(self, trace, block):
        blockSize = c_int()
        result = self.dll.WdfGetBlockSize(self.handle, c_uint(trace), c_uint(block), pointer(blockSize))
        if result != 0:
            raise Exception(WDFError[result])
        return blockSize.value

    def GetScaleWave(self, trace, block, start, count, dst):
        param = WDFAccessParam(trace, block, start, count, dst)
        result = self.dll.WdfGetScaleWave(self.handle, pointer(param))
        if result != 0:
            raise Exception(WDFError[result])
        return param.cntOut


def process_wdf_file(wdf_path: str):
    log(f"[PROC] 处理: {os.path.basename(wdf_path)}")

    with open(wdf_path, "rb") as f:
        f.seek(32)
        model = f.read(8).rstrip(b"\x00").decode("ascii", errors="ignore")
        f.seek(40)
        hd_bytes = f.read(2)
        hd_flag = hd_bytes == b"HD"

    if model == "DLM5000":
        dll_filename = "DLM5000HD.DLL" if hd_flag else "DLM5000.DLL"
    elif model == "DLM3000":
        dll_filename = "DLM3000HD.DLL" if hd_flag else "DLM3000.DLL"
    else:
        log(f"[WARN] 不支持的设备型号: '{model}'")
        return False

    dll_path = get_dll_path(dll_filename)
    if not os.path.exists(dll_path):
        log(f"[ERROR] DLL 未找到: {dll_path}")
        return False

    try:
        wdf = WDFAPI(dll_path)
        wdf.OpenFile(wdf_path)

        ch_x = []
        ch_y = []
        ch_names = []
        h_unit = ""

        trace_num = wdf.GetTraceNumber()
        for trace in range(trace_num):
            trace_name = wdf.GetTraceName(trace)
            x_all, y_all = [], []

            block_num = wdf.GetTraceBlockNumber(trace)
            for block in range(block_num):
                vDataType = wdf.GetVDataType(trace, block)
                vOffset = wdf.GetVOffset(trace, block)
                vResolution = wdf.GetVResolution(trace, block)
                hOffset = wdf.GetHOffset(trace, block)
                hResolution = wdf.GetHResolution(trace, block)
                h_unit = wdf.GetHUnit(trace, block)
                blockSize = wdf.GetBlockSize(trace, block)

                malloc = cdll.msvcrt.malloc
                malloc.restype = c_void_p
                buff = malloc(blockSize * sizeof(c_int))
                cntOut = wdf.GetScaleWave(trace, block, 0, blockSize, buff)

                if vDataType == DataTypeSINT16:
                    buff = cast(buff, POINTER(c_short))
                elif vDataType in [DataTypeUINT16, DataTypeLOGIC16]:
                    buff = cast(buff, POINTER(c_ushort))
                elif vDataType == DataTypeSINT32:
                    buff = cast(buff, POINTER(c_int))
                elif vDataType in [DataTypeUINT32, DataTypeLOGIC32]:
                    buff = cast(buff, POINTER(c_uint))
                else:
                    buff = cast(buff, POINTER(c_int))

                for i in range(cntOut):
                    x = i * hResolution + hOffset
                    raw = buff[i]
                    if vDataType in [DataTypeSINT16, DataTypeSINT32, DataTypeUINT16, DataTypeUINT32, DataTypeFLOAT]:
                        y = raw * vResolution + vOffset
                    else:
                        y = raw
                    x_all.append(x)
                    y_all.append(y)

                cdll.msvcrt.free(buff)

            ch_x.append(np.array(x_all))
            ch_y.append(np.array(y_all))
            ch_names.append(trace_name)

        wdf.CloseFile()

        if not ch_x:
            log("  [WARN] 无有效通道数据")
            return False

        # [OK] 优化：DLM5000 多通道时间轴一致，直接按索引对齐
        master_time = ch_x[0]  # 所有通道时间轴相同，取第一个即可
        num_points = len(master_time)

        rows = []
        header = ["Time (" + h_unit + ")"] + ch_names
        rows.append(header)

        for i in range(num_points):
            row = [master_time[i]]
            for j in range(len(ch_x)):
                # 直接取同索引的 y 值（假设所有通道长度 >= num_points）
                if i < len(ch_y[j]):
                    row.append(ch_y[j][i])
                else:
                    row.append("")
            rows.append(row)

        csv_path = os.path.splitext(wdf_path)[0] + "_00000.csv"
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(rows)

        log(f"[OK] 已保存: {os.path.basename(csv_path)} ({len(ch_names)} 通道)")
        return True

    except Exception as e:
        log(f"[ERROR] 处理失败: {e}")
        return False


def main():
    root = Tk()
    root.withdraw()
    folder = askdirectory(title="请选择包含 .WDF 文件的文件夹")
    if not folder:
        print("未选择文件夹，退出。")
        return

    wdf_files = [os.path.join(folder, f) for f in os.listdir(folder) if f.lower().endswith(".wdf")]
    if not wdf_files:
        print("该文件夹中没有 .WDF 文件。")
        return

    print(f"找到 {len(wdf_files)} 个 WDF 文件，开始转换...\n")

    success = 0
    for wdf_file in wdf_files:
        if process_wdf_file(wdf_file):
            success += 1

    print(f"\n[DONE] 完成！成功转换 {success}/{len(wdf_files)} 个文件。\n")

    if success > 0:
        print("[FILE] 正在打开输出文件夹...\n")
        os.startfile(folder)

    input("按回车键退出...")


if __name__ == "__main__":
    main()
