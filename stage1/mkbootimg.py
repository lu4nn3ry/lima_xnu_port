#!/usr/bin/env python3
"""
mkbootimg.py - Simple Android Boot Image v2 generator for MT6771 Stage 1
"""
import struct
import sys
import os

def pad(data, page_size):
    rem = len(data) % page_size
    if rem != 0:
        data += b"\x00" * (page_size - rem)
    return data

def main():
    if len(sys.argv) < 3:
        print("Usage: python mkbootimg.py <kernel_bin> <output_boot_img> [ramdisk]")
        sys.exit(1)

    kernel_path = sys.argv[1]
    out_path = sys.argv[2]
    ramdisk_path = sys.argv[3] if len(sys.argv) > 3 else None

    with open(kernel_path, "rb") as f:
        kernel_data = f.read()

    ramdisk_data = b""
    if ramdisk_path and os.path.exists(ramdisk_path):
        with open(ramdisk_path, "rb") as f:
            ramdisk_data = f.read()

    page_size = 2048
    kernel_size = len(kernel_data)
    ramdisk_size = len(ramdisk_data)
    kernel_addr = 0x40008000
    ramdisk_addr = 0x55000000
    second_size = 0
    second_addr = 0x40F00000
    tags_addr = 0x54000000
    header_version = 2
    os_version = 0x1400015A # Android 10, Oct 2021

    # Header structure: 1660 bytes in v2
    hdr = bytearray(page_size)
    
    # BOOT_MAGIC: 8 bytes
    hdr[0:8] = b"ANDROID!"
    
    # 9 uint32s: kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size, second_addr, tags_addr, page_size, header_version
    struct.pack_into("<9I", hdr, 8,
                     kernel_size, kernel_addr,
                     ramdisk_size, ramdisk_addr,
                     second_size, second_addr,
                     tags_addr, page_size, header_version)
    
    # os_version (uint32 at offset 44)
    struct.pack_into("<I", hdr, 44, os_version)
    
    # name (16 bytes at offset 48)
    hdr[48:48+16] = b"LIMA_STAGE1\x00".ljust(16, b"\x00")
    
    # cmdline (512 bytes at offset 64)
    cmdline = b"console=ttyS0,921600n1 bootopt=64S3,32S1,32S1 buildvariant=user printk.disable_uart=0"
    hdr[64:64+len(cmdline)] = cmdline
    
    # dtb_size and dtb_addr (uint32, uint64 at offset 1608)
    # v2: dtb_size=0, dtb_addr=0
    struct.pack_into("<IQ", hdr, 1608, 0, 0)

    # Output file
    with open(out_path, "wb") as f:
        f.write(hdr)
        f.write(pad(kernel_data, page_size))
        if ramdisk_size > 0:
            f.write(pad(ramdisk_data, page_size))

    print(f"[MKBOOTIMG] Gerado {out_path} ({os.path.getsize(out_path)} bytes)")
    print(f"  Kernel:  {kernel_size} bytes @ {hex(kernel_addr)}")
    print(f"  Ramdisk: {ramdisk_size} bytes @ {hex(ramdisk_addr)}")
    print(f"  Page:    {page_size} bytes")

if __name__ == "__main__":
    main()
