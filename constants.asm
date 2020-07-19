; vim: filetype=rgbds

; Hardware register ddresses
rJOYPAD  EQU $ff00  ; Joypad comm register
rSOUNDON EQU $ff25  ; Sound general on/off (bit 7 only)
rLCDCTRL EQU $ff40  ; LCD Controls
rLCDSTAT EQU $ff41  ; LCD controller status
rSCROLLY EQU $ff42  ; Y scroll, in pixels 
rSCROLLX EQU $ff43  ; X scroll
rLCDYPOS EQU $ff44  ; Y coord being rendered
rOBJPAL0 EQU $ff48  ; Object pallet 0
rOBJPAL1 EQU $ff49  ; Object pallet 1
rIENABLE EQU $ffff  ; Interrup enable

; VRAM addresses
vBLOCK0 EQU $8000
vBLOCK1 EQU $8800
vBLOCK2 EQU $9000
vTILES0 EQU $9800
vTILES1 EQU $9c00

; Other addresses
_OAM EQU $fe00
_VSYNC_CALL EQU $0040
_EXEC_BEGIN EQU $0100

; Hardware constants
SCREEN_Y EQU 144  ; Screen Y size in pixels
SCREEN_X EQU 160  ; Screen X size in pixels

