ml /Fl 8080em.asm 
if errorlevel 1 goto exit
copy 8080em.exe 8080em.bin
symdeb 8080em.bin < 8080.pat
:exit
