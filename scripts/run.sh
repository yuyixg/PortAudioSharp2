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
    pushd ../PortAudioSharp
    
    # 创建临时项目文件，只包含 net6.0 和 net7.0 目标框架
    TEMP_PROJ="PortAudioSharp.Linux.csproj"
    echo "创建临时项目文件 $TEMP_PROJ，排除 iOS 目标框架"
    
    # 使用 grep 和 sed 创建不包含 iOS 目标的临时项目文件
    cat PortAudioSharp.csproj | grep -v "ios" > $TEMP_PROJ
    
    # 使用临时项目文件构建和打包
    dotnet build -c Release $TEMP_PROJ
    dotnet pack -c Release $TEMP_PROJ -o ../scripts/packages
    
    # 清理临时文件
    rm $TEMP_PROJ
    
    popd
  fi
fi
