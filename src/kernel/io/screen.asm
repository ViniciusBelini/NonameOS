;--------------------------------;
;-            PRINT             -;
;- IN => SI to print            -;
;--------------------------------;
PRINT:
    pusha
.loop:
    lodsb

    cmp al, 0
    je .done

    mov ah, 0xE

    int 10h

    jmp .loop
.done:
    popa
    ret

;--------------------------------;
;-            CLEAR             -;
;--------------------------------;
CLEAR:
    pusha

    mov ah, 06h
    mov al, 00h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh

    int 10h

    mov ah, 02h
    mov bh, 0
    xor dx, dx

    int 10h

    popa
    ret

;--------------------------------;
;-            CURSOR            -;
;- IN => DH -> ROW | DL -> COL  -;
;--------------------------------;
CURSOR:
    pusha

    mov ah, 02h
    mov bh, 0

    int 10h

    popa
    ret

;--------------------------------;
;-            NEW LINE          -;
;--------------------------------;
NEW_LINE:
    pusha

    mov ah, 03h
    mov bh, 0

    int 10h

    cmp dh, 24
    je .scroll_up

    mov dl, 0
    mov ah, 02h
    inc dh

    int 10h

    popa
    ret
.scroll_up:
    mov dl, 0
    mov ah, 02h
    int 10h

    mov ax, 0601h
    mov bh, 07h
    xor cx, cx
    mov dx, 184Fh
    int 10h

    popa
    ret
