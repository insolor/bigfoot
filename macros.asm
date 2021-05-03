; Usage: get_screen_size [width_varible], [height_varible]
macro get_screen_size width, height {
    invoke GetSystemMetrics, SM_CXSCREEN
    mov width, eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov height, eax
}


; Usage: delete_dcs [hdcFirst], [hdcSecond]
macro delete_dcs [hdc] {
    forward
        invoke DeleteDC, hdc
}


; Usage: delete_objects [hFirst], [hSecond]
macro delete_objects [object] {
    forward
        invoke DeleteObject, object
}
