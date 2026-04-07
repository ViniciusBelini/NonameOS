SHELL_START:
;     inc dh
;     mov dl, 00h
;     call CURSOR
    call NEW_LINE

    mov si, cmd_layout
    call PRINT

    mov di, command_buffer
    mov cx, 64
    mov bl, 1
    call READ_LINE

    mov si, command_buffer
    call CMD_RUN

    jmp $

CMD_RUN:
;     inc dh
;     mov dl, 00h
;     call CURSOR
    call NEW_LINE

    mov di, cmd_hello

    call STRCMP
    je COMMAND_HELLO

    mov si, not_found
    call PRINT

    jmp SHELL_START

COMMAND_HELLO:
    call CLEAR

    jmp SHELL_START

command_buffer db 64 dup(0)
cmd_hello db "hello", 0
hello_world db "Executed!", 0
cmd_layout db "super > ", 0
not_found db "Command not found!", 0
