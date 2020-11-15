if [ ! -d build ]; then
    mkdir build
fi
dotnet publish -c Release --self-contained true -r osx-x64 VirtualGloomhavenBoard
cp VirtualGloomhavenBoard/bin/Release/net5.0/osx-x64/publish/VirtualGloomhavenBoard build/vgb-osx-x64