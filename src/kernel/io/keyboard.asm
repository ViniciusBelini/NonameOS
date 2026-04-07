;--------------------------------;
;-          READ KEY            -;
;- OUT => AL hex key etc        -;
;--------------------------------;
READ_KEY:
    mov ah, 0h
    int 16h

    ret

;--------------------------------;
;-          READ LINE           -;
;- IN => DI -> buffer to store  -;
;- CX -> buffer size            -;
;- BL -> 1 print char - 0 dont  -;
;--------------------------------;
READ_LINE:
    push bx
    mov bh, 0
.read_line:
    call READ_KEY

    cmp al, 08h
    jne .continue_backspace

    cmp bh, 0
    je .read_line

    dec bh
    dec di
    inc cx
    mov byte [di], 0

    mov ah, 0xE
    int 10h
    mov al, 0
    int 10h
    mov al, 08h
    int 10h

    jmp .read_line

.continue_backspace:
    cmp cx, 0
    je .read_line

    cmp al, 0Dh
    je .done

    inc bh

    test bl, bl
    jz .continue_print

    mov ah, 0xE
    int 10h
.continue_print:
    dec cx
    stosb
    jmp .read_line
.done:
    pop bx
    mov byte [di], 0
    ret
