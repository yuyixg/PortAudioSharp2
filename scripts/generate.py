#!/usr/bin/env python3
# Copyright (c)  2023  Xiaomi Corporation

import argparse
import re
import os
from pathlib import Path

import jinja2


def get_version():
    return "1.0.4"


def read_proj_file(filename):
    # Check if the template file exists
    if not os.path.exists(filename):
        print(f"Error: Template file {filename} not found!")
        return None
    
    with open(filename) as f:
        content = f.read()
        
    # Replace .NET 7.0 with .NET 6.0 in the template
    content = content.replace('net7.0', 'net6.0')
    print("Updated target framework from net7.0 to net6.0")
    
    return content


def get_dict():
    version = get_version()
    return {
        "version": get_version(),
    }


def process_linux(s, arch="x64"):
    if s is None:
        print(f"Error: Cannot process Linux {arch} - template is empty")
        return False
        
    libs = "libportaudio.so"
    
    # 确保目录存在
    os.makedirs(f"./linux-{arch}", exist_ok=True)

    d = get_dict()
    d["dotnet_rid"] = f"linux-{arch}"
    d["libs"] = libs

    environment = jinja2.Environment()
    template = environment.from_string(s)
    s = template.render(**d)
    
    output_file = f"./linux-{arch}/portaudio.runtime.csproj"
    with open(output_file, "w") as f:
        f.write(s)
    
    print(f"Created project file: {output_file}")
    return True


# Similar modifications for other process functions
def process_macos(s, arch):
    if s is None:
        print(f"Error: Cannot process macOS {arch} - template is empty")
        return False
        
    libs = "libportaudio.dylib"
    
    # 确保目录存在
    os.makedirs(f"./macos-{arch}", exist_ok=True)

    d = get_dict()
    d["dotnet_rid"] = f"osx-{arch}"
    d["libs"] = libs

    environment = jinja2.Environment()
    template = environment.from_string(s)
    s = template.render(**d)
    
    output_file = f"./macos-{arch}/portaudio.runtime.csproj"
    with open(output_file, "w") as f:
        f.write(s)
    
    print(f"Created project file: {output_file}")
    return True


def process_ios(s):
    if s is None:
        print("Error: Cannot process iOS - template is empty")
        return False
        
    libs = "libportaudio.a"
    
    # 确保目录存在
    os.makedirs("./ios-arm64", exist_ok=True)

    d = get_dict()
    d["dotnet_rid"] = f"ios-arm64"
    d["libs"] = libs

    environment = jinja2.Environment()
    template = environment.from_string(s)
    s = template.render(**d)
    
    output_file = "./ios-arm64/portaudio.runtime.ios.csproj"
    with open(output_file, "w") as f:
        f.write(s)
    
    print(f"Created project file: {output_file}")
    return True


def process_windows(s):
    if s is None:
        print("Error: Cannot process Windows - template is empty")
        return False
        
    libs = "portaudio.dll"
    
    # 确保目录存在
    os.makedirs("./windows", exist_ok=True)

    d = get_dict()
    d["dotnet_rid"] = "win-x64"
    d["libs"] = libs

    environment = jinja2.Environment()
    template = environment.from_string(s)
    s = template.render(**d)
    
    output_file = "./windows/portaudio.runtime.csproj"
    with open(output_file, "w") as f:
        f.write(s)
    
    print(f"Created project file: {output_file}")
    return True


def main():
    template_file = "./portaudio.csproj.runtime.in"
    print(f"Reading template from: {template_file}")
    s = read_proj_file(template_file)
    
    if s is None:
        print("Error: Failed to read template file. Exiting.")
        return
    
    process_macos(s, "x64")
    process_macos(s, "arm64")
    process_linux(s, "x64")
    process_linux(s, "arm64")  
    process_windows(s)
    process_ios(s)
    
    # Create symbolic links from linux to linux-x64 and linux-arm64
    if not os.path.exists("./linux/portaudio.runtime.csproj"):
        print("Creating symbolic link for linux directory")
        if os.path.exists("./linux-x64/portaudio.runtime.csproj"):
            os.symlink("../linux-x64/portaudio.runtime.csproj", "./linux/portaudio.runtime.csproj")
            print("Created symbolic link from linux-x64 to linux")


if __name__ == "__main__":
    main()
