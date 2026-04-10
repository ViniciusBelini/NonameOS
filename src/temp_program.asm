[ORG 0x2000]
[BITS 16]

db "NN", 5

; =============================================================
;  SNAKE GAME - x86 16-bit Real Mode
;  Assembler : NASM  (nasm -f bin snake.asm -o snake.com)
;  Origem    : ORG 0x2000  (flat binary)
;  Executar  : dosbox snake.com
;  Controles : Setas | ESC = sair | ENTER = reiniciar
; =============================================================

; BITS 16
; ORG  0x2000

; ─── Constantes ──────────────────────────────────────────────
BOARD_X   EQU  2
BOARD_Y   EQU  3
BOARD_W   EQU  58
BOARD_H   EQU  18
MAX_LEN   EQU  200
INIT_LEN  EQU  4
DELAY     EQU  4

C_BG    EQU  0x00
C_BDR   EQU  0x0B
C_HEAD  EQU  0x0E
C_BODY  EQU  0x0A
C_FOOD  EQU  0x0C
C_TXT   EQU  0x0F
C_SCORE EQU  0x0E
C_TITLE EQU  0x1E

D_UP    EQU  0
D_DOWN  EQU  1
D_LEFT  EQU  2
D_RIGHT EQU  3

SC_UP    EQU  0x48
SC_DOWN  EQU  0x50
SC_LEFT  EQU  0x4B
SC_RIGHT EQU  0x4D
SC_ESC   EQU  0x01
SC_ENTER EQU  0x1C

; =============================================================
;  PONTO DE ENTRADA
; =============================================================
_start:
    mov  ax, cs
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  sp, 0xFFFE
    mov  ax, 0x0003        ; modo texto 80x25
    int  0x10
    mov  ah, 0x01          ; ocultar cursor
    mov  cx, 0x2607
    int  0x10

; ─── Menu ────────────────────────────────────────────────────
menu:
    call cls
    call draw_menu
menu_wait:
    mov  ah, 0x00
    int  0x16
    cmp  ah, SC_ESC
    je   quit
    cmp  ah, SC_ENTER
    jne  menu_wait

; ─── Inicialização ───────────────────────────────────────────
init:
    call cls
    call draw_border
    mov  word [g_len],   INIT_LEN
    mov  word [g_score], 0
    mov  byte [g_dir],   D_RIGHT
    mov  byte [g_ndir],  D_RIGHT
    mov  byte [g_over],  0

    ; cobra: INIT_LEN segmentos horizontais no centro
    mov  cx, INIT_LEN
    mov  bx, 0
    mov  ax, BOARD_X + BOARD_W / 2
ipos:
    mov  word [g_sy + bx], BOARD_Y + BOARD_H / 2
    mov  [g_sx + bx], ax
    dec  ax
    add  bx, 2
    loop ipos

    call food_place
    call draw_all
    call score_draw

; ─── Loop principal ──────────────────────────────────────────
game_loop:
    call key_read
    mov  cx, DELAY
delay_loop:
    call tick_wait
    loop delay_loop
    mov  al, [g_ndir]
    mov  [g_dir], al
    call snake_move
    call col_check
    cmp  byte [g_over], 1
    je   gameover
    call food_check
    call draw_frame
    call score_draw
    jmp  game_loop

; ─── Game Over ───────────────────────────────────────────────
gameover:
    call draw_gameover
go_wait:
    mov  ah, 0x00
    int  0x16
    cmp  ah, SC_ESC
    je   quit
    cmp  ah, SC_ENTER
    je   init
    jmp  go_wait

; ─── Sair ────────────────────────────────────────────────────
quit:
    mov  ah, 0x01
    mov  cx, 0x0607
    int  0x10
    mov  ax, 0x0003
    int  0x10

    jmp 0x0000:0x1000

; =============================================================
;  SUBROTINAS
; =============================================================

; tick_wait: aguarda 1 tick do timer BIOS (~55ms)
tick_wait:
    push ax
    push es
    mov  ax, 0x0040
    mov  es, ax
    mov  ax, [es:0x006C]
tw_spin:
    cmp  ax, [es:0x006C]
    je   tw_spin
    pop  es
    pop  ax
    ret

; key_read: lê teclado sem bloquear, atualiza g_ndir
key_read:
    push ax
    mov  ah, 0x01
    int  0x16
    jz   kr_done
    mov  ah, 0x00
    int  0x16
    cmp  ah, SC_ESC
    je   quit
    cmp  ah, SC_UP
    jne  kr_dn
    cmp  byte [g_dir], D_DOWN
    je   kr_done
    mov  byte [g_ndir], D_UP
    jmp  kr_done
kr_dn:
    cmp  ah, SC_DOWN
    jne  kr_lt
    cmp  byte [g_dir], D_UP
    je   kr_done
    mov  byte [g_ndir], D_DOWN
    jmp  kr_done
kr_lt:
    cmp  ah, SC_LEFT
    jne  kr_rt
    cmp  byte [g_dir], D_RIGHT
    je   kr_done
    mov  byte [g_ndir], D_LEFT
    jmp  kr_done
kr_rt:
    cmp  ah, SC_RIGHT
    jne  kr_done
    cmp  byte [g_dir], D_LEFT
    je   kr_done
    mov  byte [g_ndir], D_RIGHT
kr_done:
    pop  ax
    ret

; snake_move: desloca array para a frente e insere nova cabeca
snake_move:
    push ax
    push bx
    push cx
    push si
    push di
    ; calcula nova posicao da cabeca
    mov  ax, [g_sx]
    mov  bx, [g_sy]
    mov  cl, [g_dir]
    cmp  cl, D_UP
    jne  sm_dn
    dec  bx
    jmp  sm_mv
sm_dn:
    cmp  cl, D_DOWN
    jne  sm_lt
    inc  bx
    jmp  sm_mv
sm_lt:
    cmp  cl, D_LEFT
    jne  sm_rt
    dec  ax
    jmp  sm_mv
sm_rt:
    inc  ax
sm_mv:
    ; desloca: [i] -> [i+1], do fim para o inicio
    mov  cx, [g_len]
    dec  cx
    mov  si, cx
    shl  si, 1
sm_sh:
    mov  di, si
    add  di, 2
    push word [g_sx + si]
    pop  word [g_sx + di]
    push word [g_sy + si]
    pop  word [g_sy + di]
    sub  si, 2
    jns  sm_sh
    mov  [g_sx], ax
    mov  [g_sy], bx
    pop  di
    pop  si
    pop  cx
    pop  bx
    pop  ax
    ret

; col_check: verifica colisao com parede e corpo
col_check:
    push ax
    push bx
    push cx
    push si
    mov  ax, [g_sx]
    mov  bx, [g_sy]
    cmp  ax, BOARD_X
    jl   cc_hit
    cmp  ax, BOARD_X + BOARD_W - 1
    jg   cc_hit
    cmp  bx, BOARD_Y
    jl   cc_hit
    cmp  bx, BOARD_Y + BOARD_H - 1
    jg   cc_hit
    mov  cx, [g_len]
    dec  cx
    mov  si, 2
cc_bl:
    cmp  cx, 0
    je   cc_ok
    cmp  ax, [g_sx + si]
    jne  cc_bn
    cmp  bx, [g_sy + si]
    je   cc_hit
cc_bn:
    add  si, 2
    dec  cx
    jmp  cc_bl
cc_ok:
    jmp  cc_done
cc_hit:
    mov  byte [g_over], 1
cc_done:
    pop  si
    pop  cx
    pop  bx
    pop  ax
    ret

; food_check: verifica se comeu a comida
food_check:
    push ax
    push bx
    mov  ax, [g_sx]
    mov  bx, [g_sy]
    cmp  ax, [g_fx]
    jne  fc_no
    cmp  bx, [g_fy]
    jne  fc_no
    mov  ax, [g_len]
    cmp  ax, MAX_LEN - 1
    jge  fc_sk
    inc  word [g_len]
fc_sk:
    add  word [g_score], 10
    call food_place
fc_no:
    pop  bx
    pop  ax
    ret

; food_place: posiciona comida em celula aleatoria livre
food_place:
    push ax
    push bx
    push cx
    push dx
    push si
    push es
    mov  ax, 0x0040
    mov  es, ax
fp_try:
    mov  ax, [es:0x006C]
    xor  dx, dx
    mov  cx, BOARD_W - 2
    div  cx
    add  dx, BOARD_X + 1
    mov  [g_fx], dx
    mov  ax, [es:0x006C]
    add  ax, 53
    xor  dx, dx
    mov  cx, BOARD_H - 2
    div  cx
    add  dx, BOARD_Y + 1
    mov  [g_fy], dx
    mov  cx, [g_len]
    mov  si, 0
fp_ck:
    cmp  cx, 0
    je   fp_ok
    mov  ax, [g_sx + si]
    cmp  ax, [g_fx]
    jne  fp_nx
    mov  ax, [g_sy + si]
    cmp  ax, [g_fy]
    je   fp_try
fp_nx:
    add  si, 2
    dec  cx
    jmp  fp_ck
fp_ok:
    pop  es
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; put_char: escreve AL em DL=col DH=lin BL=attr
put_char:
    push ax
    push bx
    push cx
    push dx
    mov  ah, 0x02
    mov  bh, 0
    int  0x10
    mov  ah, 0x09
    mov  bh, 0
    mov  cx, 1
    int  0x10
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; put_str: escreve string SI (term=0) em DL=col DH=lin BL=attr
put_str:
    push ax
    push si
ps_lp:
    lodsb
    cmp  al, 0
    je   ps_dn
    call put_char
    inc  dl
    jmp  ps_lp
ps_dn:
    pop  si
    pop  ax
    ret

; print_word: imprime AX decimal em DL=col DH=lin BL=attr
print_word:
    push ax
    push cx
    push si
    mov  [pw_col], dl
    mov  [pw_row], dh
    mov  si, pw_buf + 5
    mov  byte [si], 0
    cmp  ax, 0
    jne  pw_cv
    dec  si
    mov  byte [si], '0'
    jmp  pw_pr
pw_cv:
    mov  cx, 10
pw_lp:
    cmp  ax, 0
    je   pw_pr
    xor  dx, dx
    div  cx
    add  dl, '0'
    dec  si
    mov  [si], dl
    jmp  pw_lp
pw_pr:
    mov  dl, [pw_col]
    mov  dh, [pw_row]
pw_pc:
    mov  al, [si]
    cmp  al, 0
    je   pw_dn
    call put_char
    inc  dl
    inc  si
    jmp  pw_pc
pw_dn:
    pop  si
    pop  cx
    pop  ax
    ret

; cls: limpa tela
cls:
    push ax
    push bx
    push cx
    push dx
    mov  ah, 0x06
    mov  al, 0
    mov  bh, C_BG
    xor  cx, cx
    mov  dx, 0x184F
    int  0x10
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; draw_border: borda dupla + painel lateral
draw_border:
    push ax
    push bx
    push cx
    push dx

    mov  bl, C_BDR

    ; linha de topo
    mov  dh, BOARD_Y - 1
    mov  dl, BOARD_X - 1
    mov  al, 0xC9
    call put_char
    inc  dl
db_tp:
    cmp  dl, BOARD_X + BOARD_W
    jg   db_tpd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  db_tp
db_tpd:
    mov  al, 0xBB
    call put_char

    ; linha de base
    mov  dh, BOARD_Y + BOARD_H
    mov  dl, BOARD_X - 1
    mov  al, 0xC8
    call put_char
    inc  dl
db_bt:
    cmp  dl, BOARD_X + BOARD_W
    jg   db_btd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  db_bt
db_btd:
    mov  al, 0xBC
    call put_char

    ; lateral esquerda
    mov  dl, BOARD_X - 1
    mov  dh, BOARD_Y
db_lf:
    cmp  dh, BOARD_Y + BOARD_H
    jge  db_lfd
    mov  al, 0xBA
    call put_char
    inc  dh
    jmp  db_lf
db_lfd:

    ; lateral direita
    mov  dl, BOARD_X + BOARD_W
    mov  dh, BOARD_Y
db_rg:
    cmp  dh, BOARD_Y + BOARD_H
    jge  db_rgd
    mov  al, 0xBA
    call put_char
    inc  dh
    jmp  db_rg
db_rgd:

    ; preenche interior com preto
    mov  dh, BOARD_Y
db_fr:
    cmp  dh, BOARD_Y + BOARD_H
    jge  db_frd
    mov  dl, BOARD_X
db_fc:
    cmp  dl, BOARD_X + BOARD_W
    jge  db_fcn
    mov  bl, C_BG
    mov  al, ' '
    call put_char
    inc  dl
    jmp  db_fc
db_fcn:
    inc  dh
    jmp  db_fr
db_frd:

    ; painel lateral
    mov  bl, C_TITLE
    mov  dh, 1
    mov  dl, BOARD_X + BOARD_W + 3
    mov  si, s_title
    call put_str

    mov  bl, C_SCORE
    mov  dh, BOARD_Y + 1
    mov  dl, BOARD_X + BOARD_W + 3
    mov  si, s_lbl_pts
    call put_str

    mov  dh, BOARD_Y + 4
    mov  dl, BOARD_X + BOARD_W + 3
    mov  si, s_lbl_len
    call put_str

    mov  bl, C_TXT
    mov  dh, BOARD_Y + 8
    mov  dl, BOARD_X + BOARD_W + 3
    mov  si, s_ctrl1
    call put_str

    mov  dh, BOARD_Y + 9
    mov  dl, BOARD_X + BOARD_W + 3
    mov  si, s_ctrl2
    call put_str

    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; draw_all: desenha cobra completa + comida (usado no init)
draw_all:
    push ax
    push bx
    push cx
    push dx
    push si
    mov  cx, [g_len]
    mov  si, 0
da_lp:
    cmp  cx, 0
    je   da_fd
    mov  dl, [g_sx + si]
    mov  dh, [g_sy + si]
    cmp  si, 0
    je   da_hd
    mov  bl, C_BODY
    mov  al, 0xDB
    call put_char
    jmp  da_nx
da_hd:
    mov  bl, C_HEAD
    mov  al, 0xDB
    call put_char
da_nx:
    add  si, 2
    dec  cx
    jmp  da_lp
da_fd:
    mov  dl, [g_fx]
    mov  dh, [g_fy]
    mov  bl, C_FOOD
    mov  al, 0x04
    call put_char
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; draw_frame: atualizacao diferencial (apaga cauda, desenha cabeca)
draw_frame:
    push ax
    push bx
    push dx
    push si

    ; apaga antiga cauda
    mov  si, [g_len]
    shl  si, 1
    mov  dl, [g_sx + si]
    mov  dh, [g_sy + si]
    mov  bl, C_BG
    mov  al, ' '
    call put_char

    ; segmento 1 passa a ser corpo
    mov  dl, [g_sx + 2]
    mov  dh, [g_sy + 2]
    mov  bl, C_BODY
    mov  al, 0xDB
    call put_char

    ; nova cabeca
    mov  dl, [g_sx]
    mov  dh, [g_sy]
    mov  bl, C_HEAD
    mov  al, 0xDB
    call put_char

    ; comida (repintar caso seja apagada)
    mov  dl, [g_fx]
    mov  dh, [g_fy]
    mov  bl, C_FOOD
    mov  al, 0x04
    call put_char

    pop  si
    pop  dx
    pop  bx
    pop  ax
    ret

; score_draw: atualiza painel de pontuacao e comprimento
score_draw:
    push ax
    push bx
    push cx
    push dx

    ; limpa campo de pontos
    mov  bl, C_BG
    mov  dh, BOARD_Y + 2
    mov  dl, BOARD_X + BOARD_W + 3
    mov  cx, 7
sd_c1:
    mov  al, ' '
    call put_char
    inc  dl
    loop sd_c1

    mov  bl, C_SCORE
    mov  dh, BOARD_Y + 2
    mov  dl, BOARD_X + BOARD_W + 3
    mov  ax, [g_score]
    call print_word

    ; limpa campo de tamanho
    mov  bl, C_BG
    mov  dh, BOARD_Y + 5
    mov  dl, BOARD_X + BOARD_W + 3
    mov  cx, 7
sd_c2:
    mov  al, ' '
    call put_char
    inc  dl
    loop sd_c2

    mov  bl, C_SCORE
    mov  dh, BOARD_Y + 5
    mov  dl, BOARD_X + BOARD_W + 3
    mov  ax, [g_len]
    call print_word

    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; draw_menu: tela de titulo
draw_menu:
    push bx
    push dx

    ; borda da caixa central
    mov  bl, C_BDR
    mov  dh, 6
    mov  dl, 22
    mov  al, 0xC9
    call put_char
    inc  dl
mn_tp:
    cmp  dl, 57
    jg   mn_tpd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  mn_tp
mn_tpd:
    mov  al, 0xBB
    call put_char

    mov  dh, 17
    mov  dl, 22
    mov  al, 0xC8
    call put_char
    inc  dl
mn_bt:
    cmp  dl, 57
    jg   mn_btd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  mn_bt
mn_btd:
    mov  al, 0xBC
    call put_char

    mov  dl, 22
    mov  dh, 7
mn_sd:
    cmp  dh, 17
    jge  mn_sdd
    mov  al, 0xBA
    call put_char
    mov  dl, 57
    call put_char
    mov  dl, 22
    inc  dh
    jmp  mn_sd
mn_sdd:

    mov  bl, C_TITLE
    mov  dh, 8
    mov  dl, 29
    mov  si, s_menu_title
    call put_str

    mov  bl, C_BODY
    mov  dh, 10
    mov  dl, 27
    mov  si, s_art
    call put_str

    mov  bl, C_TXT
    mov  dh, 13
    mov  dl, 28
    mov  si, s_enter
    call put_str

    mov  bl, 0x08
    mov  dh, 15
    mov  dl, 30
    mov  si, s_esc
    call put_str

    pop  dx
    pop  bx
    ret

; draw_gameover: tela de game over
draw_gameover:
    push bx
    push dx

    mov  bl, C_FOOD
    mov  dh, 9
    mov  dl, 24
    mov  al, 0xC9
    call put_char
    inc  dl
go_tp:
    cmp  dl, 55
    jg   go_tpd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  go_tp
go_tpd:
    mov  al, 0xBB
    call put_char

    mov  dh, 16
    mov  dl, 24
    mov  al, 0xC8
    call put_char
    inc  dl
go_bt:
    cmp  dl, 55
    jg   go_btd
    mov  al, 0xCD
    call put_char
    inc  dl
    jmp  go_bt
go_btd:
    mov  al, 0xBC
    call put_char

    mov  dl, 24
    mov  dh, 10
go_sd:
    cmp  dh, 16
    jge  go_sdd
    mov  al, 0xBA
    call put_char
    mov  dl, 55
    call put_char
    mov  dl, 24
    inc  dh
    jmp  go_sd
go_sdd:

    mov  bl, C_FOOD
    mov  dh, 11
    mov  dl, 30
    mov  si, s_gameover
    call put_str

    mov  bl, C_SCORE
    mov  dh, 13
    mov  dl, 27
    mov  si, s_final
    call put_str

    mov  bl, C_TXT
    mov  dh, 13
    mov  dl, 42
    mov  ax, [g_score]
    call print_word

    mov  dh, 15
    mov  dl, 26
    mov  si, s_replay
    call put_str

    pop  dx
    pop  bx
    ret

; =============================================================
;  AREA DE DADOS
; =============================================================
g_sx    times MAX_LEN dw 0
g_sy    times MAX_LEN dw 0
g_len   dw INIT_LEN
g_dir   db D_RIGHT
g_ndir  db D_RIGHT
g_over  db 0
g_fx    dw 0
g_fy    dw 0
g_score dw 0

pw_col  db 0
pw_row  db 0
pw_buf  times 8 db 0

s_title      db ' SNAKE 1.0 ', 0
s_lbl_pts    db 'PONTOS:', 0
s_lbl_len    db 'TAMANHO:', 0
s_ctrl1      db 'Setas = mover', 0
s_ctrl2      db 'ESC   = sair', 0
s_menu_title db '  >> S N A K E <<  ', 0
s_art        db 0xDB,0xDB,0xDB,0xDB,0xDB,' ',0xDB,0xDB,0xDB,' ',0xDB,0xDB,0xDB,0xDB,0xDB,0
s_enter      db 'ENTER  =  Iniciar', 0
s_esc        db 'ESC  =  Sair', 0
s_gameover   db 'G A M E   O V E R', 0
s_final      db 'Pontuacao:', 0
s_replay     db 'ENTER=Novo  ESC=Sair', 0
