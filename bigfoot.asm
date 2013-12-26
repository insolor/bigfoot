format PE GUI 4.0
entry WinMain

include 'win32ax.inc'

BitmapId = 123

step.width = 40
step.height = 50
step.length = 85

skip.initial = 10

section '.data' data readable writeable
    skip        dd skip.initial
    flag        dd 0
    right       dd 0
    X           dd ?
    Y           dd ?
    hScreenDC   dd ?
    hMemDC      dd ?

screen:
    .width      dd ?
    .height     dd ?

section '.text' code readable executable

proc MakeStep
    invoke  GetDC, HWND_DESKTOP
    mov     [hScreenDC], eax
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
    ; BOOL BitBlt(hdcDest, nXDest, nYDest, nWidth, nHeight, hdcSrc, nXSrc, nYSrc, dwRop);
    invoke  BitBlt, [hScreenDC], eax, [Y], step.width, step.height, [hMemDC], edx, 0, SRCINVERT
    invoke  ReleaseDC, HWND_DESKTOP, [hScreenDC]
    not     [right]
    retn
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
    push    eax
    invoke  CreateCompatibleDC, eax
    mov     [hMemDC], eax
    invoke  SelectObject, eax, [hStep]
    pop     eax
    invoke  ReleaseDC, HWND_DESKTOP, eax
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
    invoke  DeleteObject, [hStep]
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
