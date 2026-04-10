SHELL_START:
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

    call SET_ARGS

    ; COMMAND CLEAR
    mov si, command_buffer
    mov di, cmd_clear
    call STRCMP
    je CMD_CLEAR_SHELL

    ; COMMAND ECHO
    mov si, command_buffer
    mov di, cmd_echo
    call STRCMP
    je CMD_ECHO_SHELL

    ; COMMAND HELP
    mov si, command_buffer
    mov di, cmd_help
    call STRCMP
    je CMD_HELP_SHELL

    ; COMMAND RUN
    mov si, command_buffer
    mov di, cmd_run
    call STRCMP
    je CMD_RUN_SHELL

    mov si, not_found
    call PRINT

    jmp SHELL_START

SET_ARGS:
    pusha

    mov si, command_buffer
.loop:
    lodsb

    cmp al, 20h
    je .save

    cmp al, 0
    je .done

    jmp .loop
.save:
    mov [command_args], si
    mov byte [si-1], 0x00
.done:
    popa
    ret

; SHELL COMMANDS

; CLEAR
CMD_CLEAR_SHELL:
    call CLEAR

    mov dx, 0000h
    dec dh
    call CURSOR

    jmp SHELL_START

; ECHO
CMD_ECHO_SHELL:
    mov si, [command_args]
    call PRINT

    jmp SHELL_START

; HELP
CMD_HELP_SHELL:
    mov si, cmd_help_helper
    call PRINT

    jmp SHELL_START

; RUN
CMD_RUN_SHELL:
    mov si, [command_args]
    lodsb

    sub al, '0'

    xor cx, cx
    mov es, cx
    mov bx, 0x2000

    mov cl, al

    mov ah, 02h
    mov al, 1
    mov dh, 0
    mov ch, 0

    int 13h

    push cx

    mov al, [0x2000]
    cmp al, "N"
    jne .error_file

    mov al, [0x2000+1]
    cmp al, "N"
    jne .error_file

    mov al, [0x2000+2]

    xor cx, cx
    mov es, cx
    mov bx, 0x2000

    pop cx
    mov ah, 02h
    mov dh, 0
    mov ch, 0

    int 13h

    pusha
    call 0x0000:0x2000+3
    popa

    jmp SHELL_START
.error_file:
    mov si, cmd_run_ferror
    call PRINT

    jmp SHELL_START

; required vars for shell

command_buffer db 64 dup(0)
command_args db 16 dup(0)
cmd_layout db "super > ", 0
not_found db "Command not found!", 0

; shell commands

cmd_clear db "clear", 0
cmd_echo db "echo", 0
cmd_help db "help", 0
cmd_run db "run", 0

; commands vars helpers

cmd_help_helper db "Command list: 'clear', 'echo <args>', 'help', 'run <sector>'", 0
cmd_run_ferror db "Invalid file format.", 0
