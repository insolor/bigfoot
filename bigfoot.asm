format PE GUI 4.0
entry WinMain

include 'include/win32axp.inc'

include 'constants.asm'

section '.data' data readable writeable
    is_right dd ?
    x dd ?
    y dd ?
    hStepDC dd ?
    hMemDC dd ?
    hScreenDC dd ?
    hMemBitmap dd ?
    hStep dd ?

screen:
    .width dd ?
    .height dd ?


section '.text' code readable executable

macro get_screen_size width, height {
    invoke GetSystemMetrics, SM_CXSCREEN
    mov [width], eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov [height], eax
}


macro init_device_contexts {
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
}


macro cleanup {
    push eax
    invoke KillTimer, HWND_DESKTOP, timer.id
    invoke DeleteDC, [hMemDC]
    invoke DeleteDC, [hStepDC]
    invoke DeleteObject, [hStep]
    invoke DeleteObject, [hMemBitmap]
    pop eax
}


proc WinMain
    get_screen_size screen.width, screen.height
    
    ; Load image from resources
    invoke GetModuleHandle, 0
    invoke LoadBitmap, eax, BitmapId
    mov [hStep], eax
    
    ; Set timer
    invoke SetTimer, HWND_DESKTOP, timer.id, timer.delay, NULL
    
    init_device_contexts

    ; srand(time(NULL))
    invoke srand, <invoke time, 0>
    
    call message_loop
    
    cleanup

    ret
endp


proc message_loop
locals
    Msg MSG
    rect RECT
    step_counter dd 0 ; actually it is a flag, 0 means that this is the first step
    skip dd skip.initial
endl
    xor eax, eax
    mov [is_right], eax
    
.loop_start:
    invoke GetMessage, addr Msg, HWND_DESKTOP, 0, 0

    .if eax = 0
        mov eax, [Msg.wParam]
        ret
    .endif
    
    mov eax, [Msg.message]
    cmp eax, WM_TIMER
    jne .loop_start
    
    .if [skip] > 0
        dec [skip]
        jmp .loop_start
    .endif
    
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
        
        inc [step_counter]
        ; step_counter is used only to know if it is the first step,
        ; so it's not necessary increment it every step
    .endif

    sub [y], step.length
    
    .if [y] >= 0
        call DrawFootprint
        jmp .loop_start
    .endif
    
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
    
    jmp .loop_start
endp


proc DrawFootprint
locals
    current_x dd ? ; x coordinate of the current footprint on the screen
    picture_x dd ? ; x coordinate of the corresponding footprint image (left or right) on the image from resources
endl
    mov eax, [x]
    
    .if [is_right] <> 0
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
