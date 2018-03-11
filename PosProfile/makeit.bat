@echo off


\masm32\bin\ml /c /coff /nologo code.asm
\masm32\bin\lib /nologo /out:"PosProfile.lib" code.obj Ascii2Dword16.obj

pause
exit

