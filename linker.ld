# linker.ld

MEMORY
{
    boot_sector (rwx) : ORIGIN = 0x7c00, LENGTH = 512
}

ENTRY(__start)
SECTIONS
{
    .boot_sector : { *(.boot_sector); } > boot_sector
    .bootsign (0x7c00 + 510) :
    {
        BYTE(0x55)
        BYTE(0xaa)
    } > boot_sector
}
