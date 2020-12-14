format PE GUI 4.0
entry WinMain

include 'include/win32axp.inc'

BitmapId = 123

step.width = 32
step.height = 50
step.length = 85
step.aside = 28

skip.initial = 100 ; controls delay before the trace occurrence

CAPTUREBLT = 0x40000000

section '.data' data readable writeable
    is_right dd ?
    x dd ?
    y dd ?
    hStepDC dd ?
    hMemDC dd ?
    hScreenDC dd ?

screen:
    .width dd ?
    .height dd ?

section '.text' code readable executable

proc DrawFootprint
locals
    current_x dd ?
    inner_x dd ?
endl
    mov eax, [x]
    
    .if [is_right] <> 0
        sub eax, step.aside
        xor edx, edx
    .else
        add eax, step.aside
        mov edx, step.width
    .endif

    mov [current_x], eax
    mov [inner_x], edx
    invoke GetDC, HWND_DESKTOP
        mov [hScreenDC], eax
        invoke BitBlt, [hMemDC], 0, 0, step.width, step.height, \
                       [hScreenDC], [current_x], [y], CAPTUREBLT+MERGECOPY

        invoke BitBlt, [hMemDC], 0, 0, step.width, step.height, \
                       [hStepDC], [inner_x], 0, SRCINVERT

        invoke BitBlt, [hScreenDC], [current_x], [y], step.width, step.height, \
                       [hMemDC], 0, 0, SRCCOPY

    invoke ReleaseDC, HWND_DESKTOP, [hScreenDC]
    not [is_right]
    ret
endp

proc WinMain
locals
    hStep dd ?
    hMemBitmap dd ?
endl
    ; Get screen size
    invoke GetSystemMetrics, SM_CXSCREEN
    mov [screen.width], eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov [screen.height], eax
    
    ; Load image from resources
    invoke GetModuleHandle, 0
    invoke LoadBitmap, eax, BitmapId
    mov [hStep], eax
    
    ; Set timer
    invoke SetTimer, HWND_DESKTOP, 1, 500, NULL
    
    ; Create device contexts for drawing
    invoke GetDC, HWND_DESKTOP
        mov [hScreenDC], eax
        
        invoke CreateCompatibleDC, eax
        mov [hStepDC], eax
        
        invoke SelectObject, eax, [hStep]
        
        invoke CreateCompatibleDC, [hScreenDC]
        mov [hMemDC], eax
        
        invoke CreateCompatibleBitmap, [hScreenDC], step.width, step.height
        mov [hMemBitmap], eax
        
        invoke SelectObject, [hMemDC], eax
    invoke ReleaseDC, HWND_DESKTOP, [hScreenDC]
    
    ; srand(time(NULL))
    invoke time, 0
    invoke srand, eax
    
    call message_loop
    
    push eax
    invoke KillTimer, HWND_DESKTOP, 1
    invoke DeleteDC, [hMemDC]
    invoke DeleteDC, [hStepDC]
    invoke DeleteObject, [hStep]
    invoke DeleteObject, [hMemBitmap]
    pop eax
    ret
endp

; ---------------------------------------------------------------------------
proc message_loop
locals
    Msg MSG
    rect RECT
    first_step dd 1
    skip dd skip.initial
endl
.loop_start:
    invoke GetMessage, addr Msg, HWND_DESKTOP, 0, 0

    .if eax = 0
        mov eax, [Msg.wParam]
        ret
    .endif
    
    mov eax, [Msg.message]
    cmp eax, WM_TIMER
    jne .loop_start
    
    .if [skip]
        dec [skip]
        jmp .loop_start
    .endif
    
; ---------------------------------------------------------------------------
    .if [first_step]
        mov eax, [screen.height]
        mov [y], eax
        
        ; x = rand() % (screen.width-(step.width+10)*2) + step.width+10
        invoke rand
        mov ecx, [screen.width]
        sub ecx, (step.width+10)*2
        cdq
        idiv ecx
        add edx, step.width+10
        mov [x], edx
        
        not [first_step]
    .endif

    sub [y], step.length
    
    .if [y] < 0
        ; Clear the trace
        mov eax, [x]
        sub eax, step.width
        mov [rect.left], eax
        add eax, step.width*2
        mov [rect.right], eax
        xor eax, eax
        mov [rect.top], eax
        mov eax, [screen.height]
        mov [rect.bottom], eax
        invoke InvalidateRect, HWND_DESKTOP, addr rect, 0
        
        not [first_step]
        mov [skip], skip.initial
    .else
        call DrawFootprint
    .endif
    
    jmp .loop_start
endp

section '.idata' import data readable writeable

    library \
        kernel32, 'KERNEL32.DLL',\
        user32, 'USER32.DLL',\
        gdi32, 'GDI32.DLL',\
        msvcrt, 'MSVCRT.DLL'

    include 'include/api/kernel32.inc'
    include 'include/api/user32.inc'
    include 'include/api/gdi32.inc'

    import msvcrt, \
        srand, 'srand', \
        time, 'time', \
        rand, 'rand'

section '.rsrc' resource data readable

    directory RT_BITMAP, bitmaps
    resource bitmaps, BitmapId, LANG_NEUTRAL, step
    bitmap step, 'bigfoot.bmp'
