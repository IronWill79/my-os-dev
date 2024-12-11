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

    ;; build a 4 level page table and switch to long mode
    mov ebx, 0x1000
    call build_page_table
    mov cr3, ebx            ; MMU finds the PML4 table in cr3

    ;; enable Physical Address Extension (PAE). This is needed to allow the switch
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ;; the EFER (Extended Feature Enable Register) MSR (Model-Specific Register) contains fields
    ;; related to IA-32e mode operation. Bit 8 if this MSR is the LME (long mode enable) flag
    ;; that enables IA-32e operation.
    mov ecx, 0xc0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ;; enable paging (PG flag in cr0, bit 31)
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    mov ebx, comp_mode_msg
    call print_string32

    ;; new GDT has the 64-bit segment flag set. This makes the CPU switch from
    ;; IA-32e compatibility mode to 64-bit mode.
    lgdt [gdt64_pseudo_descriptor]

    jmp CODE_SEG64:start_long_mode

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

;; builds a 4 level page table starting at the address that's passed in ebx.
build_page_table:
    pusha

    PAGE64_PAGE_SIZE equ 0x1000
    PAGE64_TAB_SIZE equ 0x1000
    PAGE64_TAB_ENT_NUM equ 512

    ;; initialize all four tables to 0. If the present flag is cleared, all other bits in any
    ;; entry are ignored. So by filling all entries with zeros, they are all "not present".
    ;; each repetition zeros four bytes at once. That's why a number of repetitions equal to
    ;; the size of a single page table is enough to zero all four tables.
    mov ecx, PAGE64_TAB_SIZE    ; ecx stores the number of repetitions
    mov edi, ebx                ; edi stores the base address
    xor eax, eax                ; eax stores the value
    rep stosd

    ;; link first entry in PML4 table to the PDP table
    mov edi, ebx
    lea eax, [edi + (PAGE64_TAB_SIZE | 11b)] ; set read/write and present flags
    mov dword [edi], eax

    ;; link first entry in PDP table to the PD table
    add edi, PAGE64_TAB_SIZE
    add eax, PAGE64_TAB_SIZE
    mov dword [edi], eax

    ;; link first entry in PD table to the page table
    add edi, PAGE64_TAB_SIZE
    add eax, PAGE64_TAB_SIZE
    mov dword [edi], eax

    ;; initialize only a single page on the lowest (page table) layer in
    ;; the four level page table.
    add edi, PAGE64_TAB_SIZE
    mov ebx, 11b
    mov ecx, PAGE64_TAB_ENT_NUM
set_page_table_entry:
    mov dword [edi], ebx
    add ebx, PAGE64_PAGE_SIZE
    add edi, 8
    loop set_page_table_entry

    popa
    ret

stage2_msg: db "Hello from stage 2", 13, 10, 0
protected_mode_msg: db "Hello from protected mode", 0

    [bits 64]

start_long_mode:
    hlt
    jmp start_long_mode

%include "include/gdt32.s"
%include "include/gdt64.s"

comp_mode_msg: db "Entered 64-bit compatibility mode", 0
