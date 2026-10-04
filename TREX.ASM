; ==============================================================
;  T-REX  (Chrome dinosaur clone)  -  TASM 1.4 / DOSBox
;  Build:   TASM TREX.ASM
;           TLINK TREX.OBJ
;           TREX
;  Controls: SPACE / ENTER / UP = jump,  ESC = exit
;  Mode 13h (320x200, 256 colours). White background, black art.
; ==============================================================

.MODEL SMALL
.286
.STACK 200h

DINO_X      EQU 40          ; dinosaur left edge
DINO_TOP0   EQU 124         ; dinosaur top when standing (feet on ground)
DINO_MAXUP  EQU 44          ; highest top position while jumping
JUMP_STEP   EQU 5           ; pixels per frame up / down
GROUND_Y    EQU 160         ; ground line
CACT_Y      EQU 130         ; cactus top
COL_BG      EQU 15          ; white
COL_FG      EQU 0           ; black

.DATA
dino_y      dw DINO_TOP0
cact_x      dw 340
cact_w      dw 18           ; 18 = single cactus, 40 = double
dino_state  db 0            ; 0 = running, 1 = going up, 2 = going down
anim        db 0
score       dw 0
hi_score    dw 0
score_tick  db 0
game_over   db 0
quit_flag   db 0
jump_req    db 0
cur_col     db COL_FG
speed       dw 4
scroll_x    dw 0
rnd         dw 12345
psp_seg     dw 0
buf_seg     dw 0
txt_x       dw 0
txt_y       dw 0
txt_scale   dw 2
gx          dw 0
gy          dw 0
spr_x       dw 0
spr_y       dw 0
cur_x       dw 0
base_x      dw 0

msg_over    db 'GAME OVER$'
msg_restart db 'SPACE = RESTART$'
msg_exit    db 'ESC = EXIT$'
msg_hi      db 'HI$'
msg_nomem   db 'Not enough memory.$'
numbuf      db '00000$'

FONT_N      EQU 27
font_chars  db '0123456789HIGAMEOVRSPCT=X '
font_data LABEL BYTE
    db 00001110b, 00010001b, 00010011b, 00010101b, 00011001b, 00010001b, 00001110b          ; '0'
    db 00000100b, 00001100b, 00000100b, 00000100b, 00000100b, 00000100b, 00001110b          ; '1'
    db 00001110b, 00010001b, 00000001b, 00000010b, 00000100b, 00001000b, 00011111b          ; '2'
    db 00011110b, 00000001b, 00000001b, 00001110b, 00000001b, 00000001b, 00011110b          ; '3'
    db 00000010b, 00000110b, 00001010b, 00010010b, 00011111b, 00000010b, 00000010b          ; '4'
    db 00011111b, 00010000b, 00011110b, 00000001b, 00000001b, 00010001b, 00001110b          ; '5'
    db 00000110b, 00001000b, 00010000b, 00011110b, 00010001b, 00010001b, 00001110b          ; '6'
    db 00011111b, 00000001b, 00000010b, 00000100b, 00001000b, 00001000b, 00001000b          ; '7'
    db 00001110b, 00010001b, 00010001b, 00001110b, 00010001b, 00010001b, 00001110b          ; '8'
    db 00001110b, 00010001b, 00010001b, 00001111b, 00000001b, 00000010b, 00001100b          ; '9'
    db 00010001b, 00010001b, 00010001b, 00011111b, 00010001b, 00010001b, 00010001b          ; 'H'
    db 00001110b, 00000100b, 00000100b, 00000100b, 00000100b, 00000100b, 00001110b          ; 'I'
    db 00001110b, 00010001b, 00010000b, 00010111b, 00010001b, 00010001b, 00001111b          ; 'G'
    db 00001110b, 00010001b, 00010001b, 00011111b, 00010001b, 00010001b, 00010001b          ; 'A'
    db 00010001b, 00011011b, 00010101b, 00010101b, 00010001b, 00010001b, 00010001b          ; 'M'
    db 00011111b, 00010000b, 00010000b, 00011110b, 00010000b, 00010000b, 00011111b          ; 'E'
    db 00001110b, 00010001b, 00010001b, 00010001b, 00010001b, 00010001b, 00001110b          ; 'O'
    db 00010001b, 00010001b, 00010001b, 00010001b, 00010001b, 00001010b, 00000100b          ; 'V'
    db 00011110b, 00010001b, 00010001b, 00011110b, 00010100b, 00010010b, 00010001b          ; 'R'
    db 00001111b, 00010000b, 00010000b, 00001110b, 00000001b, 00000001b, 00011110b          ; 'S'
    db 00011110b, 00010001b, 00010001b, 00011110b, 00010000b, 00010000b, 00010000b          ; 'P'
    db 00001110b, 00010001b, 00010000b, 00010000b, 00010000b, 00010001b, 00001110b          ; 'C'
    db 00011111b, 00000100b, 00000100b, 00000100b, 00000100b, 00000100b, 00000100b          ; 'T'
    db 00000000b, 00000000b, 00011111b, 00000000b, 00011111b, 00000000b, 00000000b          ; '='
    db 00010001b, 00010001b, 00001010b, 00000100b, 00001010b, 00010001b, 00010001b          ; 'X'
    db 00000000b, 00000000b, 00000000b, 00000000b, 00000000b, 00000000b, 00000000b          ; ' '


; cactus parts: x offset, y offset (from CACT_Y), width, height
cactus_parts dw 0,0,10,30
             dw -6,12,6,4
             dw -6,6,4,10
             dw 10,16,6,4
             dw 12,8,4,12

; dinosaur sprite: 16 pixels wide, every pixel is drawn 2x2
dino_body LABEL WORD
    dw 0000001111111100b          ; ......XXXXXXXX..
    dw 0000001101111111b          ; ......XX.XXXXXXX
    dw 0000001111111111b          ; ......XXXXXXXXXX
    dw 0000001111111111b          ; ......XXXXXXXXXX
    dw 0000001111100000b          ; ......XXXXX.....
    dw 0000001111100000b          ; ......XXXXX.....
    dw 1000001111111100b          ; X.....XXXXXXXX..
    dw 1000011111111100b          ; X....XXXXXXXXX..
    dw 1100111111111110b          ; XX..XXXXXXXXXXX.
    dw 1111111111111110b          ; XXXXXXXXXXXXXXX.
    dw 0111111111111110b          ; .XXXXXXXXXXXXXX.
    dw 0011111111111110b          ; ..XXXXXXXXXXXXX.
    dw 0001111111111100b          ; ...XXXXXXXXXXX..
    dw 0000111111111000b          ; ....XXXXXXXXX...

leg_a LABEL WORD
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001100000000b          ; ......XX........
    dw 0000001110000000b          ; ......XXX.......

leg_b LABEL WORD
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000000000110000b          ; ..........XX....
    dw 0000000000111000b          ; ..........XXX...

leg_air LABEL WORD
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001100110000b          ; ......XX..XX....
    dw 0000001110111000b          ; ......XXX.XXX...


.CODE

; ==============================================================
main PROC
    mov ax, @data
    mov ds, ax
    mov psp_seg, es             ; ES = PSP at program start

    mov bx, ss                  ; shrink our memory block to what we need
    sub bx, psp_seg
    mov ax, sp
    add ax, 15
    mov cl, 4
    shr ax, cl
    add bx, ax
    inc bx
    mov ah, 4Ah
    int 21h
    mov ah, 48h                 ; allocate 64000 bytes for the back buffer
    mov bx, 0FA0h
    int 21h
    jnc mem_ok
    mov dx, offset msg_nomem
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h
mem_ok:
    mov buf_seg, ax
    mov es, ax                  ; ES = back buffer (all drawing goes here)

    mov ax, 0013h               ; graphics mode 13h
    int 10h
    cld

new_game:
    call reset_game

game_loop:
    call poll_keys
    cmp byte ptr quit_flag, 1
    jne gl_go
    jmp quit_game
gl_go:
    call update_game
    call render                 ; draw into the back buffer
    call wait_frame             ; wait for the retrace
    call flip                   ; copy to the screen
    cmp byte ptr game_over, 1
    jne game_loop
    call do_game_over           ; AL = 1 restart, 0 exit
    cmp al, 1
    je new_game

quit_game:
    mov ax, 0003h               ; back to text mode
    int 10h
    mov ax, 4C00h
    int 21h
main ENDP

; ==============================================================
reset_game PROC
    push ax
    push dx
    mov word ptr dino_y, DINO_TOP0
    mov byte ptr dino_state, 0
    mov byte ptr anim, 0
    mov word ptr score, 0
    mov byte ptr score_tick, 0
    mov byte ptr game_over, 0
    mov byte ptr quit_flag, 0
    mov byte ptr jump_req, 0
    mov word ptr speed, 4
    mov word ptr scroll_x, 0
    mov ah, 00h                 ; seed random generator from the clock
    int 1Ah
    mov word ptr rnd, dx
    call spawn_cactus
    call flush_keys
    pop dx
    pop ax
    ret
reset_game ENDP

; ==============================================================
flush_keys PROC
    push ax
fk_next:
    mov ah, 01h
    int 16h
    jz fk_done
    mov ah, 00h
    int 16h
    jmp fk_next
fk_done:
    pop ax
    ret
flush_keys ENDP

; ==============================================================
poll_keys PROC
    push ax
pk_next:
    mov ah, 01h
    int 16h
    jz pk_done
    mov ah, 00h
    int 16h
    cmp al, 27                  ; ESC
    je pk_quit
    cmp al, 20h                 ; SPACE
    je pk_jump
    cmp al, 0Dh                 ; ENTER
    je pk_jump
    cmp al, 0
    jne pk_next
    cmp ah, 48h                 ; UP arrow
    je pk_jump
    jmp pk_next
pk_jump:
    mov byte ptr jump_req, 1
    jmp pk_next
pk_quit:
    mov byte ptr quit_flag, 1
    jmp pk_next
pk_done:
    pop ax
    ret
poll_keys ENDP

; ==============================================================
wait_vsync PROC
    push ax
    push dx
    mov dx, 3DAh
wv_a:
    in al, dx
    test al, 8
    jnz wv_a
wv_b:
    in al, dx
    test al, 8
    jz wv_b
    pop dx
    pop ax
    ret
wait_vsync ENDP

wait_frame PROC                 ; two retraces = about 35 frames/second
    call wait_vsync
    call wait_vsync
    ret
wait_frame ENDP

; ==============================================================
spawn_cactus PROC
    push ax
    push bx
    push dx
    mov ax, rnd                 ; rnd = rnd * 25173 + 13849
    mov bx, 25173
    mul bx
    add ax, 13849
    mov rnd, ax
    mov al, ah                  ; random extra distance 0..127
    xor ah, ah
    and ax, 127
    add ax, 330
    mov cact_x, ax
    mov word ptr cact_w, 18
    test word ptr rnd, 4000h    ; sometimes a double cactus
    jz sc_done
    mov word ptr cact_w, 40
sc_done:
    pop dx
    pop bx
    pop ax
    ret
spawn_cactus ENDP

; ==============================================================
update_game PROC
    push ax
    push bx
    push dx

    ; ---- jump request ----
    cmp byte ptr jump_req, 1
    jne ug_nojr
    mov byte ptr jump_req, 0
    cmp byte ptr dino_state, 0
    jne ug_nojr
    mov byte ptr dino_state, 1
ug_nojr:

    ; ---- dinosaur physics ----
    cmp byte ptr dino_state, 1
    je ug_up
    cmp byte ptr dino_state, 2
    je ug_down
    jmp ug_cactus
ug_up:
    sub word ptr dino_y, JUMP_STEP
    cmp word ptr dino_y, DINO_MAXUP
    jg ug_cactus
    mov word ptr dino_y, DINO_MAXUP
    mov byte ptr dino_state, 2
    jmp ug_cactus
ug_down:
    add word ptr dino_y, JUMP_STEP
    cmp word ptr dino_y, DINO_TOP0
    jl ug_cactus
    mov word ptr dino_y, DINO_TOP0
    mov byte ptr dino_state, 0

    ; ---- cactus movement ----
ug_cactus:
    mov ax, speed
    sub cact_x, ax
    add scroll_x, ax
    cmp word ptr cact_x, -50
    jge ug_noresp
    call spawn_cactus
ug_noresp:

    ; ---- score every 5 frames, speed grows with score ----
    inc byte ptr score_tick
    cmp byte ptr score_tick, 5
    jb ug_noscore
    mov byte ptr score_tick, 0
    inc word ptr score
    mov ax, score
    xor dx, dx
    mov bx, 30
    div bx
    add ax, 4
    cmp ax, 8
    jbe ug_spd
    mov ax, 8
ug_spd:
    mov speed, ax
ug_noscore:

    inc byte ptr anim
    call check_collision

    pop dx
    pop bx
    pop ax
    ret
update_game ENDP

; ==============================================================
check_collision PROC
    push ax
    push bx
    mov ax, cact_x
    sub ax, 4                   ; cactus hit box left
    mov bx, cact_x
    add bx, cact_w
    sub bx, 4                   ; cactus hit box right
    cmp ax, DINO_X+28
    jge cc_none
    cmp bx, DINO_X+6
    jle cc_none
    mov ax, dino_y
    add ax, 34                  ; dinosaur feet
    cmp ax, CACT_Y
    jle cc_none
    mov byte ptr game_over, 1
    mov ax, score               ; update the high score before the last frame
    cmp ax, hi_score
    jbe cc_none
    mov hi_score, ax
cc_none:
    pop bx
    pop ax
    ret
check_collision ENDP

; ==============================================================
render PROC
    call clear_screen
    call draw_ground
    call draw_cacti
    call draw_dino
    call draw_score
    ret
render ENDP

clear_screen PROC
    push ax
    push cx
    push di
    xor di, di
    mov ax, 0F0Fh               ; two white pixels
    mov cx, 32000
    rep stosw
    pop di
    pop cx
    pop ax
    ret
clear_screen ENDP

; ==============================================================
; fill_rect : AX = x, BX = y, CX = width, DX = height (signed, clipped)
; colour = cur_col, drawn into ES:(back buffer)
fill_rect PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    cmp ax, 0                   ; clip left
    jge fr_x1
    add cx, ax
    xor ax, ax
fr_x1:
    cmp cx, 0
    jle fr_exit
    mov si, ax                  ; clip right
    add si, cx
    cmp si, 320
    jle fr_x2
    mov cx, 320
    sub cx, ax
    cmp cx, 0
    jle fr_exit
fr_x2:
    cmp bx, 0                   ; clip top
    jge fr_y1
    add dx, bx
    xor bx, bx
fr_y1:
    cmp dx, 0
    jle fr_exit
    mov si, bx                  ; clip bottom
    add si, dx
    cmp si, 200
    jle fr_y2
    mov dx, 200
    sub dx, bx
    cmp dx, 0
    jle fr_exit
fr_y2:
    mov di, bx                  ; di = y*320 + x
    shl di, 8
    shl bx, 6
    add di, bx
    add di, ax
    mov al, cur_col
    mov bx, dx                  ; rows
    mov si, cx                  ; width
fr_row:
    mov cx, si
    push di
    rep stosb
    pop di
    add di, 320
    dec bx
    jnz fr_row
fr_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
fill_rect ENDP

; flip : copy the back buffer to video memory
flip PROC
    push ax
    push cx
    push si
    push di
    push ds
    push es
    mov ax, buf_seg
    mov ds, ax
    mov ax, 0A000h
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
flip ENDP

; ==============================================================
draw_ground PROC
    push ax
    push bx
    push cx
    push dx
    push si
    mov byte ptr cur_col, COL_FG
    mov ax, 0
    mov bx, GROUND_Y
    mov cx, 320
    mov dx, 1
    call fill_rect
    mov si, 0                   ; moving ground specks
dg_loop:
    mov ax, si
    mov bx, 53
    mul bx
    add ax, scroll_x
    xor dx, dx
    mov bx, 320
    div bx                      ; DX = remainder
    mov ax, 319
    sub ax, dx
    mov bx, si
    and bx, 1
    shl bx, 2
    add bx, GROUND_Y+5
    mov cx, 3
    mov dx, 1
    call fill_rect
    inc si
    cmp si, 6
    jb dg_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_ground ENDP

; ==============================================================
; draw_rows : SI = table of words, CX = rows, uses spr_x / spr_y
draw_rows PROC
    push ax
    push bx
    push cx
    push dx
    push si
dr_row:
    push cx
    mov dx, [si]
    add si, 2
    mov ax, spr_x
    mov cur_x, ax
    mov cx, 16
dr_bit:
    test dx, 8000h
    jz dr_skip
    push cx
    push dx
    mov ax, cur_x
    mov bx, spr_y
    mov cx, 2
    mov dx, 2
    call fill_rect
    pop dx
    pop cx
dr_skip:
    shl dx, 1
    add word ptr cur_x, 2
    loop dr_bit
    add word ptr spr_y, 2
    pop cx
    loop dr_row
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_rows ENDP

draw_dino PROC
    push ax
    push cx
    push si
    mov byte ptr cur_col, COL_FG
    mov word ptr spr_x, DINO_X
    mov ax, dino_y
    mov spr_y, ax
    mov si, offset dino_body
    mov cx, 14
    call draw_rows              ; body (spr_y moves down by itself)
    cmp byte ptr dino_state, 0
    jne dd_air
    test byte ptr anim, 4
    jz dd_a
    mov si, offset leg_b
    jmp dd_legs
dd_a:
    mov si, offset leg_a
    jmp dd_legs
dd_air:
    mov si, offset leg_air
dd_legs:
    mov cx, 4
    call draw_rows
    pop si
    pop cx
    pop ax
    ret
draw_dino ENDP

; ==============================================================
; draw_cactus : AX = x
draw_cactus PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov base_x, ax
    mov si, offset cactus_parts
    mov di, 5
dc_loop:
    mov ax, [si]
    add ax, base_x
    mov bx, [si+2]
    add bx, CACT_Y
    mov cx, [si+4]
    mov dx, [si+6]
    call fill_rect
    add si, 8
    dec di
    jnz dc_loop
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_cactus ENDP

draw_cacti PROC
    push ax
    mov byte ptr cur_col, COL_FG
    mov ax, cact_x
    call draw_cactus
    cmp word ptr cact_w, 40
    jne dcs_done
    mov ax, cact_x
    add ax, 22
    call draw_cactus
dcs_done:
    pop ax
    ret
draw_cacti ENDP

; ==============================================================
; built-in 5x7 font text. SI = string ending with '$'
; position = txt_x / txt_y, size = txt_scale
draw_text PROC
    push ax
    push bx
    push dx
    push si
dt_next:
    mov al, [si]
    cmp al, '$'
    je dt_end
    inc si
    call draw_glyph
    mov ax, txt_scale
    mov bx, 6
    mul bx
    add txt_x, ax
    jmp dt_next
dt_end:
    pop si
    pop dx
    pop bx
    pop ax
    ret
draw_text ENDP

; draw_glyph : AL = character
draw_glyph PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor bx, bx
dg_find:
    cmp al, [font_chars+bx]
    je dg_found
    inc bx
    cmp bx, FONT_N
    jb dg_find
    jmp dg_exit
dg_found:
    mov ax, bx
    mov dx, 7
    mul dx
    add ax, offset font_data
    mov si, ax
    mov ax, txt_y
    mov gy, ax
    mov di, 7                   ; 7 rows
dg_row:
    mov dl, [si]
    inc si
    mov ax, txt_x
    mov gx, ax
    mov cx, 5                   ; 5 columns
dg_col:
    test dl, 10h
    jz dg_skip
    push cx
    push dx
    mov ax, gx
    mov bx, gy
    mov cx, txt_scale
    mov dx, txt_scale
    call fill_rect
    pop dx
    pop cx
dg_skip:
    shl dl, 1
    mov ax, txt_scale
    add gx, ax
    loop dg_col
    mov ax, txt_scale
    add gy, ax
    dec di
    jnz dg_row
dg_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_glyph ENDP

; num_to_str : AX = number -> numbuf (5 digits)
num_to_str PROC
    push ax
    push bx
    push cx
    push dx
    push si
    mov cx, 5
    mov si, 4
nts_loop:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'
    mov [numbuf+si], dl
    dec si
    loop nts_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
num_to_str ENDP

draw_score PROC
    push ax
    push si
    mov byte ptr cur_col, COL_FG
    mov word ptr txt_scale, 2
    mov word ptr txt_y, 8
    mov word ptr txt_x, 126     ; HI
    mov si, offset msg_hi
    call draw_text
    mov ax, hi_score
    call num_to_str
    mov word ptr txt_x, 156
    mov si, offset numbuf
    call draw_text
    mov ax, score
    call num_to_str
    mov word ptr txt_x, 250
    mov si, offset numbuf
    call draw_text
    pop si
    pop ax
    ret
draw_score ENDP

; ==============================================================
do_game_over PROC               ; returns AL = 1 restart, AL = 0 exit
    push cx
    push si
    mov ax, score
    cmp ax, hi_score
    jbe go_nohi
    mov hi_score, ax
go_nohi:
    mov byte ptr cur_col, COL_FG
    mov word ptr txt_scale, 3
    mov word ptr txt_x, 79
    mov word ptr txt_y, 60
    mov si, offset msg_over
    call draw_text
    mov word ptr txt_scale, 2
    mov word ptr txt_x, 70
    mov word ptr txt_y, 92
    mov si, offset msg_restart
    call draw_text
    mov word ptr txt_x, 100
    mov word ptr txt_y, 110
    mov si, offset msg_exit
    call draw_text
    call flip                   ; show the finished picture
    mov cx, 30                  ; short pause so a held key is not taken
go_wait:
    call wait_vsync
    loop go_wait
    call flush_keys
go_key:
    mov ah, 00h
    int 16h
    cmp al, 27
    je go_exit
    cmp al, 20h
    je go_restart
    cmp al, 0Dh
    je go_restart
    jmp go_key
go_restart:
    mov al, 1
    jmp go_end
go_exit:
    mov al, 0
go_end:
    pop si
    pop cx
    ret
do_game_over ENDP

END main