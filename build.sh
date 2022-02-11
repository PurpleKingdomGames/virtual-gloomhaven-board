if [ ! -d build ]; then
    mkdir build
fi
dotnet publish -c Release -r osx-x64 VirtualGloomhavenBoard
cp VirtualGloomhavenBoard/bin/Release/publish/VirtualGloomhavenBoard build/vgb-osx-x64