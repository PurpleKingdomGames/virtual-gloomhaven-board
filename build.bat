dotnet publish -c Release --self-contained true -r win-x64  VirtualGloomhavenBoard
copy VirtualGloomhavenBoard\bin\Release\net5.0\win-x64\publish\VirtualGloomhavenBoard.exe build\vgb-win-x64.exe

dotnet publish -c Release --self-contained true -r win-x86  VirtualGloomhavenBoard
copy VirtualGloomhavenBoard\bin\Release\net5.0\win-x86\publish\VirtualGloomhavenBoard.exe build\vgb-win-x86.exe