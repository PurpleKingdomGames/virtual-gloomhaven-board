if [ ! -d build ]; then
    mkdir build
fi
dotnet publish -c Release --self-contained true -r linux-x64 VirtualGloomhavenBoard
cp VirtualGloomhavenBoard/bin/Release/netcoreapp3.1/linux-x64/publish/VirtualGloomhavenBoard build/vgb-linux-x64