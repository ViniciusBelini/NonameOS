[BITS 16]
[ORG 0x7C00]

START1:
    mov byte [device_id], dl

    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    jmp 0x0000:START2

START2:
    cld
    sti

    call clear

    mov si, starting
    call print

    xor cx, cx
    mov es, cx
    mov bx, 0x7E00

    mov ah, 02h
    mov al, 1
    mov dh, 0
    mov ch, 0
    mov cl, 2
    mov dl, [device_id]

    int 13h

    jmp 0x0000:0x7E00

print:
    pusha

    mov ah, 0xE
.loop:
    lodsb

    cmp al, 0
    je .done

    int 10h

    jmp .loop
.done:
    popa
    ret

clear:
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

starting db "Starting OS...", 0
device_id db 0x0

times 510-($-$$) db 0
dw 0AA55h
