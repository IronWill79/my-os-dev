; src/stage2.s

    section .stage2

    [bits 16]

    mov bx, stage2_msg
    call print_string

end:
    hlt
    jmp end

print_string:
    pusha
    mov ah, 0x0e ; BIOS "display character" function

print_string_loop:
    cmp byte [bx], 0
    je print_string_return

    mov al, [bx]
    int 0x10 ; BIOS video services

    inc bx
    jmp print_string_loop

print_string_return:
    popa
    ret

stage2_msg: db "Hello from stage 2", 13, 10, 0
