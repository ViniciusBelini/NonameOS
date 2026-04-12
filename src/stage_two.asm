[ORG 0x7E00]

STAGE_TWO:
    mov byte [device_id], dl

    mov ah, 02h
    mov bh, 0
    mov dx, 0100h

    int 10h

    mov si, starting_stage_two
    call print

    ; FINALLY LOADING KERNEL

    xor cx, cx
    mov es, cx
    mov bx, 0x1000

    mov ah, 02h
    mov al, 2
    mov dh, 0
    mov ch, 0
    mov cl, 3
    mov dl, [device_id]

    int 13h

    jmp 0x0000:0x1000

print:
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

starting_stage_two db "Starting stage two...", 0
device_id db 0x0
