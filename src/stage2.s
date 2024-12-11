; src/stage2.s

    section .stage2

    [bits 16]

    mov bx, stage2_msg
    call print_string

    ;; load GDT and switch to protected mode

    cli ; can't have interrupts during the switch
    lgdt [gdt32_pseudo_descriptor]

    ;; setting cr0.PE (bit 0) enables protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ;; the far jump into the code segment from the new GDT flushes
    ;; the CPU pipeline removing any 16-bit decoded instructions
    ;; and updates the cs register with the new code segment.
    jmp CODE_SEG32:start_prot_mode

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

    [bits 32]
start_prot_mode:
    ;; old segments are now meaningless
    mov ax, DATA_SEG32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebx, protected_mode_msg
    call print_string32

print_string32:
    pusha

    VGA_BUF equ 0xb8000
    WB_COLOR equ 0xf

    mov edx, VGA_BUF

print_string32_loop:
    cmp byte [ebx], 0
    je print_string32_return

    mov al, [ebx]
    mov ah, WB_COLOR
    mov [edx], ax

    add ebx, 1 ; next character
    add edx, 2 ; next VGA buffer cell
    jmp print_string32_loop

print_string32_return:
    popa
    ret

stage2_msg: db "Hello from stage 2", 13, 10, 0
protected_mode_msg: db "Hello from protected mode", 0

%include "include/gdt32.s"
