;--------------------------------;
;-            STRCMP            -;
;- IN => SI -> string one       -;
;- DI -> string two             -;
;- OUT => ZF 1 equal 0 not      -;
;- (USES AX)                    -;
;--------------------------------;
STRCMP:
    lodsb

    cmp al, byte [di]
    jne .not_equal

    cmp al, 0
    je .done

    inc di
    jmp STRCMP
.not_equal:
    mov ax, 1
    test ax, ax
    ret
.done:
    xor ax, ax
    ret
