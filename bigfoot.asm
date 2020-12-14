format PE GUI 4.0
entry WinMain

include 'include/win32axp.inc'

BitmapId = 123

foot.width = 32
foot.length = 50

step.width = 56
step.length = 85

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
        
        invoke CreateCompatibleBitmap, [hScreenDC], foot.width, foot.length
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
    step_counter dd 0 ; actually it is a flag, 0 means that it's the first step
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
    .if [step_counter] = 0
        mov eax, [screen.height]
        mov [y], eax
        
        ; x = rand() % (screen.width-(foot.width+step.width))
        invoke rand
        mov ecx, [screen.width]
        sub ecx, foot.width+step.width
        cdq
        idiv ecx
        mov [x], edx
        
        inc [step_counter] ; step_counter is used
    .endif

    sub [y], step.length
    
    .if [y] < 0
        ; Clear the trace
        mov eax, [x]
        sub eax, foot.width
        mov [rect.left], eax
        add eax, foot.width + step.width
        mov [rect.right], eax
        xor eax, eax
        mov [rect.top], eax
        mov eax, [screen.height]
        mov [rect.bottom], eax
        invoke InvalidateRect, HWND_DESKTOP, addr rect, 0
        
        xor eax, eax
        mov [step_counter], eax
        
        mov [skip], skip.initial
    .else
        call DrawFootprint
    .endif
    
    jmp .loop_start
endp

proc DrawFootprint
locals
    current_x dd ? ; x coordinate of the current footprint on the screen
    picture_x dd ? ; x coordinate of the corresponding footprint image (left or right) on the image from resources
endl
    mov eax, [x]
    
    .if [is_right]
        add eax, step.width
        mov edx, foot.width
    .else
        xor edx, edx
    .endif

    mov [current_x], eax
    mov [picture_x], edx
    invoke GetDC, HWND_DESKTOP
        mov [hScreenDC], eax
        invoke BitBlt, [hMemDC], 0, 0, foot.width, foot.length, \
                       [hScreenDC], [current_x], [y], CAPTUREBLT+MERGECOPY

        invoke BitBlt, [hMemDC], 0, 0, foot.width, foot.length, \
                       [hStepDC], [picture_x], 0, SRCINVERT

        invoke BitBlt, [hScreenDC], [current_x], [y], foot.width, foot.length, \
                       [hMemDC], 0, 0, SRCCOPY

    invoke ReleaseDC, HWND_DESKTOP, [hScreenDC]
    not [is_right]
    ret
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
