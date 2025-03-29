#!/usr/bin/env bash
# Copyright (c)  2023  Xiaomi Corporation

set -ex

mkdir -p macos-x64 macos-arm64 ios-arm64 linux linux-arm64 windows all
rm -rf packages
mkdir -p packages

# 检查操作系统类型并复制相应的库文件
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" == "Darwin" ]; then
  # macOS 环境
  if [ -f "./libportaudio.dylib" ]; then
    cp -v ./libportaudio.dylib ./macos-x64
    cp -v ./libportaudio.dylib ./macos-arm64
  fi
  if [ -f "./libportaudio.a" ]; then
    cp -v ./libportaudio.a ./ios-arm64
  fi
elif [ "$OS_TYPE" == "Linux" ]; then
  # Linux 环境
  if [ -f "./libportaudio.so" ]; then
    cp -v ./libportaudio.so ./linux
    cp -v ./libportaudio.so ./linux-arm64
  fi
else
  # 假设是 Windows 环境
  if [ -f "./portaudio.dll" ]; then
    cp -v ./portaudio.dll ./windows
  fi
fi

./generate.py

# 根据操作系统类型决定编译哪些平台
if [ "$OS_TYPE" == "Darwin" ]; then
  # macOS 环境编译 macOS 和 iOS 相关包
  pushd macos-x64
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd

  pushd macos-arm64
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd

  pushd ios-arm64
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd
elif [ "$OS_TYPE" == "Linux" ]; then
  # Linux 环境编译 Linux 相关包
  pushd linux
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd

  pushd linux-arm64
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd
else
  # 假设是 Windows 环境
  pushd windows
  dotnet build -c Release
  dotnet pack -c Release -o ../packages
  popd
fi

# 编译主项目，如果设置了 SKIP_IOS 环境变量则跳过
if [ -z "$SKIP_IOS" ]; then
  pushd ../PortAudioSharp
  dotnet build -c Release
  dotnet pack -c Release -o ../scripts/packages
  popd
else
  echo "Skipping iOS build due to SKIP_IOS environment variable"
  
  # 在 Linux 环境下，我们需要创建临时项目文件来排除 iOS 目标
  if [ "$OS_TYPE" == "Linux" ]; then
    # 在 Linux 环境下，我们只生成 Linux 相关的包，跳过 PortAudioSharp 的构建
    echo "在 Linux 环境下跳过 PortAudioSharp 的构建，只使用已生成的 runtime 包"
    
    # 我们不需要创建元包，因为 runtime 包已经成功生成
    echo "Runtime 包已成功生成，跳过元包创建"
    
    # 列出已生成的包
    ls -la ./packages/
  fi
fi
