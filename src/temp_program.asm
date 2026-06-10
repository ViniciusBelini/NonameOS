[ORG 0x2000]
[BITS 16]

db "NF", 1

PROGRAM:
    mov si, hello
    call print

    ret

print:
    pusha

    mov ah, 0xE
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

hello db "Hello world from program one!", 0
