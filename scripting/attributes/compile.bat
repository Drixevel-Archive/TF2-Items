@ECHO OFF
CD ..
IF EXIST "compile.dat" ( del /A compile.dat )
spcomp attributes/%~n1.sp -o../plugins/attributes/%~n1.smx
PAUSE