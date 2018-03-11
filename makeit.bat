@echo off

if exist code.asm \masm32\bin\ml /c /coff /nologo code.asm
if exist rsrc.rc \masm32\bin\porc /v rsrc.rc
if exist code.obj if exist rsrc.res \masm32\bin\link /subsystem:windows /nologo code.obj rsrc.res
if exist code.obj if not exist rsrc.res \masm32\bin\link /subsystem:windows /nologo code.obj

pause
exit
