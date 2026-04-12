[ORG 0x1000]

KERNEL:
    mov byte [device_id], dl

    call CLEAR

    mov si, hello_kernel
    call PRINT

    call SHELL_START

    jmp $

;--------------------------------;
;-           INCLUDES           -;
;--------------------------------;

%include "src/kernel/io/screen.asm"
%include "src/kernel/io/keyboard.asm"

%include "src/kernel/core/string.asm"

%include "src/kernel/shell/main.asm"

;--------------------------------;
;-             DATA              ;
;--------------------------------;

hello_kernel db "Hello world from Kernel!", 0
device_id db 0x0
