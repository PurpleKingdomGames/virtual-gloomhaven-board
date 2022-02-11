dotnet publish -c Release -r win-x64  VirtualGloomhavenBoard
copy VirtualGloomhavenBoard\bin\Release\publish\VirtualGloomhavenBoard.exe build\vgb-win-x64.exe

dotnet publish -c Release -r win-x86  VirtualGloomhavenBoard
copy VirtualGloomhavenBoard\bin\Release\publish\VirtualGloomhavenBoard.exe build\vgb-win-x86.exe