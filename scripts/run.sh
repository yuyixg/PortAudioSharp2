#!/usr/bin/env bash
# Copyright (c)  2023  Xiaomi Corporation

set -ex

mkdir -p macos-x64 macos-arm64 ios-arm64 linux linux-arm64 windows all
rm -rf packages

cp -v ./libportaudio.dylib ./macos-x64
cp -v ./libportaudio.dylib ./macos-arm64
cp -v ./libportaudio.a ./ios-arm64
cp -v ./libportaudio.so ./linux
cp -v ./libportaudio.so ./linux-arm64  # 添加这行以支持 linux arm64
cp -v ./portaudio.dll ./windows

./generate.py

pushd linux
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd linux-arm64  # 添加这段代码以支持 linux arm64
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd macos-x64
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd macos-arm64
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd ios-arm64
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd windows
dotnet build -c Release
dotnet pack -c Release -o ../../PortAudioSharp/packages
popd

pushd ../PortAudioSharp
dotnet build -c Release
dotnet pack -c Release -o ./packages
popd

mv ../PortAudioSharp/packages .
