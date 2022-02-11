if [ ! -d build ]; then
    mkdir build
fi
dotnet publish -c Release -r linux-x64 VirtualGloomhavenBoard
cp VirtualGloomhavenBoard/bin/Release/publish/VirtualGloomhavenBoard build/vgb-linux-x64