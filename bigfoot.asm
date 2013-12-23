format PE GUI 4.0
entry WinMain

include 'win32ax.inc'

BitmapId equ 123

section '.data' data readable writeable
    skip        dd 100
    flag        dd 0

section '.text' code readable executable

proc WinMain uses ebx
locals
    Msg         MSG
    screen.height dd ?
    screen.width  dd ?
    hStep       dd ?
    X           dd ?
    Y           dd ?
    hScreenDC   dd ?
    hMemDC      dd ?
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
    mov     ebx, eax
    invoke  CreateCompatibleDC, eax
    mov     [hMemDC], eax
    invoke  SelectObject, eax, [hStep]
    invoke  ReleaseDC, HWND_DESKTOP, ebx
    jmp     .get_message
; ---------------------------------------------------------------------------

.message_loop:
    mov     eax, [Msg.message]
    cmp     eax, WM_TIMER
    jnz     .get_message
    mov     edx, [skip]
    test    edx, edx
    jz      @f
    dec     [skip]
    jmp     .get_message
; ---------------------------------------------------------------------------

@@:
    mov     ecx, [flag]
    test    ecx, ecx
    jnz     @f
    mov     eax, [screen.height]
    mov     [Y], eax
; X = rand%(screen.width-100)+50 {
    invoke  rand
    cdq ; расширить бит знака eax на edx
    mov     ecx, [screen.width]
    sub     ecx, 100
    idiv    ecx ; делим edx:eax на ecx с учетом знака
    add     edx, 50
    mov     [X], edx
; }
    mov     [flag], 1
@@:
    sub     [Y], 85
    invoke  GetDC, HWND_DESKTOP
    mov     ebx, eax
    mov     ecx, [Y]
    test    ecx, 1
    mov     eax, [X]
    jnz     .draw_right
.draw_left:
    sub     eax, 20
    xor     edx, edx
    jmp @f
.draw_right:
    add     eax, 20
    mov     edx, 40
@@:
    invoke  BitBlt, ebx, eax, ecx, 40, 50, [hMemDC], edx, 0, SRCINVERT
    invoke  ReleaseDC, 0, ebx
    mov     edx, [Y]
    test    edx, edx
    jge     .get_message
; erase
    mov     ecx, [screen.height]
    mov     [Y], ecx
    invoke  GetDC, HWND_DESKTOP
    mov     [hScreenDC], eax
    jmp     .erase

.erase_loop:
    sub     [Y], 85
    mov     ecx, [Y]
    test    ecx, 1
    mov     eax, [X]
    jnz     .erase_right
.erase_left:
    sub     eax, 20
    xor     edx, edx
    jmp @f
.erase_right:
    add     eax, 20
    mov     edx, 40
@@:
    invoke  BitBlt, [hScreenDC], eax, ecx, 40, 50, [hMemDC], edx, 0, SRCINVERT
.erase:
    mov     ecx, [Y]
    test    ecx, ecx
    jg      .erase_loop
    invoke  ReleaseDC, HWND_DESKTOP, [hScreenDC]
    xor     eax, eax
    mov     [flag], eax
    mov     [skip], 100

.get_message:
    invoke  GetMessage, addr Msg, 0, 0, 0
    test    eax, eax
    jnz     .message_loop
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
