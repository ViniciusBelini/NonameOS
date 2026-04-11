[ORG 0x2000]
[BITS 16]

db "NN", 5

PROGRAM:
    mov al, 256
    mov ah, 0xE
    int 10h

    ret
