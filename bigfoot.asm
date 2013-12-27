format PE GUI 4.0
entry WinMain

include 'win32axp.inc'

BitmapId = 123

step.width = 40
step.height = 50
step.length = 85

skip.initial = 10

CAPTUREBLT = 0x40000000

section '.data' data readable writeable
    skip        dd skip.initial
    flag        dd 0
    right       dd 0
    X           dd ?
    Y           dd ?
    hStepDC     dd ?
    hMemDC      dd ?
    hMemBitmap  dd ?
    hScreenDC   dd ?

screen:
    .width      dd ?
    .height     dd ?

section '.text' code readable executable

proc MakeStep
locals
    current_X   dd ?
    inner_X     dd ?
endl
    mov     ecx, [right]
    test    ecx, ecx
    mov     eax, [X]
    jnz     .right
.left:
    sub     eax, 20
    xor     edx, edx
    jmp @f
.right:
    add     eax, 20
    mov     edx, step.width
@@:
    mov     [current_X], eax
    mov     [inner_X], edx
    invoke  GetDC, HWND_DESKTOP
        mov     [hScreenDC], eax
        ; BOOL BitBlt(hdcDest, nXDest, nYDest, nWidth, nHeight, hdcSrc, nXSrc, nYSrc, dwRop);
        invoke  BitBlt, [hMemDC], 0, 0, step.width, step.height, \
                        [hScreenDC], [current_X], [Y], CAPTUREBLT+MERGECOPY
        invoke  BitBlt, [hMemDC], 0, 0, step.width, step.height, \
                        [hStepDC], [inner_X], 0, SRCINVERT
        invoke  BitBlt, [hScreenDC], [current_X], [Y], step.width, step.height, \
                        [hMemDC], 0, 0, SRCCOPY
    invoke  ReleaseDC, HWND_DESKTOP, [hScreenDC]
    not     [right]
    ret
endp

proc WinMain
locals
    Msg         MSG
    hStep       dd ?
    rect        RECT
endl
    invoke  GetSystemMetrics, SM_CXSCREEN
    mov     [screen.width], eax
    invoke  GetSystemMetrics, SM_CYSCREEN
    mov     [screen.height], eax
    invoke  GetModuleHandle, 0
    invoke  LoadBitmap, eax, BitmapId
    mov     [hStep], eax
    invoke  SetTimer, HWND_DESKTOP, 1, 500, NULL
    invoke  GetDC, HWND_DESKTOP
        mov     [hScreenDC], eax
        invoke  CreateCompatibleDC, eax
        mov     [hStepDC], eax
        invoke  SelectObject, eax, [hStep]
        ; HDC memDC = CreateCompatibleDC ( hDC );
        ; HBITMAP memBM = CreateCompatibleBitmap ( hDC, nWidth, nHeight );
        ; SelectObject ( memDC, memBM );
        invoke  CreateCompatibleDC, [hScreenDC]
        mov     [hMemDC], eax
        invoke  CreateCompatibleBitmap, [hScreenDC], step.width, step.height
        mov     [hMemBitmap], eax
        invoke  SelectObject, [hMemDC], eax
    invoke  ReleaseDC, HWND_DESKTOP, [hScreenDC]
; ---------------------------------------------------------------------------
.message_loop:
    invoke  GetMessage, addr Msg, HWND_DESKTOP, 0, 0
    test    eax, eax
    jz      .leave
    
    mov     eax, [Msg.message]
    cmp     eax, WM_TIMER
    jnz     .message_loop
    mov     edx, [skip]
    test    edx, edx
    jz      @f
    dec     [skip]
    jmp     .message_loop
; ---------------------------------------------------------------------------

@@:
    mov     ecx, [flag]
    test    ecx, ecx
    jnz     @f
; first step
    mov     eax, [screen.height]
    mov     [Y], eax
; X = rand%(screen.width-100)+50 {
    invoke  rand
    mov     ecx, [screen.width]
    sub     ecx, (step.width+10)*2
    cdq
    idiv    ecx
    add     edx, step.width+10
    mov     [X], edx
; }
    mov     [flag], 1

@@:
    sub     [Y], step.length
    call    MakeStep
    mov     ecx, [Y]
    test    ecx, ecx
    jge     .message_loop

; Clear the trace
    mov     eax, [X]
    sub     eax, step.width
    mov     [rect.left], eax
    add     eax, step.width*2
    mov     [rect.right], eax
    xor     eax, eax
    mov     [rect.top], eax
    mov     eax, [screen.height]
    mov     [rect.bottom], eax
    ; BOOL InvalidateRect(hWnd, lpRect, bErase);
    invoke  InvalidateRect, HWND_DESKTOP, addr rect, 0
    xor     eax, eax
    mov     [flag], eax
    mov     [skip], skip.initial
    jmp     .message_loop

.leave:
    invoke  KillTimer, HWND_DESKTOP, 1
    invoke  DeleteDC, [hMemDC]
    invoke  DeleteDC, [hStepDC]
    invoke  DeleteObject, [hStep]
    invoke  DeleteObject, [hMemBitmap]
    mov     eax, [Msg.wParam]
    ret
endp

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
  user32,'USER32.DLL',\
  gdi32,'GDI32.DLL',\
  msvcrt,'MSVCRT.DLL'

include 'api\kernel32.inc'
include 'api\user32.inc'
include 'api\gdi32.inc'

import msvcrt, rand, 'rand'

section '.rsrc' resource data readable

directory RT_BITMAP, bitmaps
resource bitmaps, BitmapId, LANG_NEUTRAL, step
bitmap step, 'bigfoot.bmp'
