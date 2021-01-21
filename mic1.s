/* 
jammon17@georgefox.edu
George Fox University
CSIS 360 Computer Architecture and Assembly Language
*/

.data

.balign 4
fmt: .asciz "%d\n"

.balign 4
file: .word 0

.balign 4
fileMode: .asciz "r"

.balign 4
return: .word 0

.balign 4
error: .asciz "Error opening the file."

memory: .skip 4096

.text
.extern fgetc
.extern puts
.extern fopen
.extern fclose
.extern printf
.extern __aeabi_idiv
.global main

m1OPC .req r2
m1MBRU .req r3
m1MBR .req r4
m1TOS .req r5
m1SP .req r6
m1MDR .req r7
m1MAR .req r8
m1PC .req r9
m1LV .req r10
m1CPP .req r11
m1H .req r12

.macro _WRITE_
    /* load memory address in r1 */
    ldr r1, =memory
    /* stores the what's in the MDR at the address of the MAR */
    str m1MDR, [r1, +m1MAR]
.endm

.macro _READ_
    /* load memory address in r1 */
    ldr r1, =memory
    /* load the MDR with what's in memory at the address of the MAR */
    ldr m1MDR, [r1, +m1MAR]
.endm

.macro _FETCH_
    /* load memory address in r1 */
    ldr r1, =memory
    /* load the MBR and the MDRU with with the PC */
    /* this fetches the next instruction */
    ldrsb m1MBR, [r1, +m1PC]
    ldrb m1MBRU, [r1, +m1PC]
.endm

main:
    push {lr}

    /* check that 2 parameters were given */
    cmp r0, #2
    /* else print and error and exit */
    beq openFile
    ldr r0, =error
    bl puts
    b end

openFile:
    /* load the filename into r0 */
    ldr r0, [r1, #4]

    /* load r1 wth the fopen file mode */
    ldr r1, =fileMode

    /* call fopen to open the file */
    bl fopen

    /* load and save file pointer address */
    ldr r2, =file
    str r0, [r2]

    /* if the file != null then branch to initialize */
    cmp r0, #0
    bne initialize

    /* else output an error */
    ldr r0, =error
    bl puts
    b end

initialize:
    /* load file pointer address into r0 */
    ldr r0, =file
    ldr r0, [r0]

    /* call fgetc */
    bl fgetc

    /* store result in LV */
    mov m1LV, r0

    /* load file pointer address into r0 */
    ldr r0, =file
    ldr r0, [r0]

    /* call fgetc */
    bl fgetc

    /* shift r0 and OR with the LV */
    orr m1LV, r0, m1LV, LSL #8

    /* set PC to 0 */
    mov m1PC, #0

    /* set SP to the PC */
    mov m1SP, m1PC

    /* set CPP to 0 */
    mov m1CPP, #0

readFile:
    /* load file pointer address */
    ldr r0, =file
    ldr r0, [r0]

    /* call fgetc */
    bl fgetc

    /* store result in memory */
    ldr r1, =memory
    strb r0, [r1, +m1SP]

    /* increment the SP */
    add m1SP, m1SP, #1

    /* check */
    cmp r0, #-1

    /* if not branch to loop */
    bne readFile

    /* load file pointer address */
    ldr r0, =file
    ldr r0, [r0]

    /* close the file */
    bl fclose

    /* init SP and LV */
    mov r1, m1SP

    /* SP = (LV * 4) + SP */      @ add m1SP, m1SP, m1LV, LSL #2
    mov r0, #4
    mul m1LV, r0
    add m1SP, m1LV

    mov m1LV, r1

    /* load first instruction into MBR */
    _FETCH_


main1:

    mov r0, m1MBRU

    /* increment the PC counter */
    add m1PC, m1PC, #1
    _FETCH_

    /* goto iadd instruction */
    cmp r0, #0x60
    beq iadd

    /* goto isub instruction */
    cmp r0, #0x64
    beq isub

    /* goto iand instruction */
    cmp r0, #0x7E
    beq iand

    /* goto ior instruction */
    cmp r0, #0x80
    beq ior

    /* goto imul instruction */
    cmp r0, #0x68
    beq imul

    /* goto idiv instruction */
    cmp r0, #0x6C
    beq idiv
    
    /* goto bipush instruction */
    cmp r0, #0x10
    beq bipush

    /* goto dup instruction */
    cmp r0, #0x59
    beq dup

    /* goto pop instruction */
    cmp r0, #0x57
    beq pop

    /* goto swap instruction */
    cmp r0, #0x5F
    beq swap

    /* goto iload instruction */
    cmp r0, #0x15
    beq iload

    /* goto istore instruction */
    cmp r0, #0x36
    beq istore

    /* goto iinc instruction */
    cmp r0, #0x84
    beq iinc

    /* goto ifreq instruction */
    cmp r0, #0x99
    beq ifeq

    /* goto icmpeq instruction */
    cmp r0, #0x9F
    beq icmpeq

    /* goto goto instruction */
    cmp r0, #0xA7
    beq goto

    /* goto nop instruction */
    cmp r0, #0x00
    beq nop

    /* goto jsr instruction */
    cmp r0, #0xA8
    beq jsr

    /* goto ret instruction */
    cmp r0, #0xA9
    beq ret

iadd:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* TOS = MDR and H */
    add m1TOS, m1H, m1MDR

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1

ior:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* TOS = MDR or H */
    orr m1TOS, m1MDR, m1H

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


isub:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* TOS = MDR - H */
    sub m1TOS, m1MDR, m1H

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


imul:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* TOS = MDR * H */
    mul m1TOS, m1H, m1MDR

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


idiv:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* TOS = MDR / H */
    mov r0, m1MDR
    mov r1, m1H
    push {lr}
    bl __aeabi_idiv
    pop {lr}
    
    mov m1TOS, r0

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


iand:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* H = TOS */
    mov m1H, m1TOS

    /* MDR = TOS = MDR AND H */
    and m1TOS, m1MDR, m1H
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


bipush:
    /* SP = MAR = SP + 1 */
    add m1MAR, m1SP, #4
    mov m1SP, m1MAR

    /* PC = PC + 1; fetch */
    mov r0, m1MBR
    add m1PC, m1PC, #1
    _FETCH_

    /* MDR = TOS = MBR; wr; goto main1 */
    mov m1TOS, r0
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


dup:
    /* MAR = SP = SP + 1 */
    add m1SP, m1SP, #4
    mov m1MAR, m1SP

    /* MDR = TOS */
    mov m1MDR, m1TOS
    _WRITE_

    /* branch to main1 */
    b main1


pop:
    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* nop */
    mov r0, r0

    /* TOS = MDR */
    mov m1TOS, m1MDR

    /* branch to main1 */
    b main1


swap:
    /* MAR = SP - 1 */
    sub m1MAR, m1SP, #4
    _READ_

    /* MAR = SP */
    mov m1MAR, m1SP

    /* H = MDR */
    mov m1H, m1MDR
    _WRITE_

    /* MDR = TOS */
    mov m1MDR, m1TOS

    /* MAR = SP - 1 */
    sub m1MAR, m1SP, #4
    _WRITE_

    /* TOS = H */
    mov m1TOS, m1H

    /* branch to main1 */
    b main1


iload:
    /* H = LV */
    mov m1H, m1LV

    /* MAR = MBRU + H; rd */
    add m1MAR, m1MBRU, m1H
    _READ_

    /* MAR = SP = SP + 1 */
    add m1SP, m1SP, #4
    mov m1MAR, m1SP

    /* PC = PC + 1; fetch; wr */
    add m1PC, m1PC, #1

    _FETCH_
    _WRITE_
    mov m1TOS, m1MDR

    /* branch to main1 */
    b main1


istore:
    /* H = LV */
    mov m1H, m1LV

    /* MAR = MBRU + H */
    add m1MAR, m1MBRU, m1H

    mov m1MDR, m1TOS
    _WRITE_

    /* SP = MAR = SP − 1; wr */
    sub m1MAR, m1SP, #4
    mov m1SP, m1MAR
    _READ_

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* TOS = MDR */
    mov m1TOS, m1MDR

    /* branch to main1 */
    b main1


iinc:
    /* H = LV */
    mov m1H, m1LV

    /* MAR = MBRU + H; rd */
    add m1MAR, m1MBRU, m1H
    _READ_

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* H = MDR */
    mov m1H, m1MDR
    mov r0, m1MBR

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* MDR = MBR + H; wr */
    add m1MDR, r0, m1H
    _WRITE_

    /* branch to main1 */
    b main1


goto:
    /* OPC = PC - 1 */
    sub m1OPC, m1PC, #1
    mov r0, m1MBR

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* H = MBR << 8 */
    mov m1H, r0, LSL #8

    /* H = MBRU OR H */
    orr m1H, m1MBRU, m1H

    /* PC = OPC + H; fetch */
    add m1PC, m1OPC, m1H
    _fetch_

    /* branch to main1 */
    b main1


ifeq:
    /* MAR = SP = SP - 1; rd */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* OPC = TOS */
    mov m1OPC, m1TOS

    /* TOS = MDR */
    mov m1TOS, m1MDR

    /* Z = OPC; if (z) goto T; else goto F */
    cmp m1OPC, #0
    beq goto
    b f


iflt:
    /* MAR = SP = SP - 1; rd */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* OPC = TOS */
    mov m1OPC, m1TOS

    /* TOS = MDR */
    mov m1TOS, m1MDR

    /* N = OPC; if (N) goto T; else goto F */
    cmp m1OPC, #0
    blt goto
    b f


icmpeq:
    /* MAR = SP = SP - 1; rd */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    _READ_

    /* MAR = SP = SP - 1 */
    sub m1SP, m1SP, #4
    mov m1MAR, m1SP
    
    /* H = MDR; rd */
    mov m1H, m1MDR
    _READ_

    /* OPC = TOS */
    mov m1OPC, m1TOS

    /* TOS = MDR */
    mov m1TOS, m1MDR

    /* Z = OPC - H; if (z) goto T; else goto F */
    sub m1H, m1OPC, m1H
    cmp m1H, #0
    beq goto
    b f


f:
    add m1PC, m1PC, #1
    add m1PC, m1PC, #1
    _FETCH_

    b main1


nop: 
    /* branch to main1 */
    b main1


jsr:
    /* SP = SP + MBRU + 1 */
    add m1MBRU, m1MBRU, #1
    add m1SP, m1SP, m1MBRU

    /* MDR = CPP */
    mov m1MDR, m1CPP

    /* MAR = CPP = SP; wr */
    mov m1CPP, m1SP
    mov m1MAR, m1CPP
    _WRITE_

    /* MDR = PC + 4 */
    add m1MDR, m1PC, #4

    /* MAR = SP = SP + 1; wr */
    add m1SP, m1SP, #4
    mov m1MAR, m1SP
    _WRITE_

    /* MDR = LV */
    mov m1MDR, m1LV

    /* MAR = SP = SP + 1; wr */
    add m1SP, m1SP, #4
    mov m1MAR, m1SP
    _WRITE_

    /* LV = SP - 2 - MBRU */
    sub m1LV, m1SP, #8

    sub m1LV, m1LV, m1MBRU

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* NOP */

    /* LV = LV - MBRU */
    sub m1LV, m1LV, m1MBRU

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* NOP */

    /* H = MBR << 8 */
    mov m1H, m1MBR, LSL #8

    /* PC = PC + 1; fetch */
    add m1PC, m1PC, #1
    _FETCH_

    /* NOP */

    /* PC = PC - 4 + (H OR MBRU); fetch */
    orr r0, m1MBRU, m1H
    sub m1PC, m1PC, #4
    add m1PC, m1PC, r0
    _FETCH_

    /* goto Main1 */
    b main1


ret:

    /* check for ret from main cpp==0 then exit */
    cmp m1CPP, #0
    beq done

    mov m1MAR, m1CPP
    _READ_

    /* nop */

    /* restore CPP (old link ptr) */
    mov m1CPP, m1MDR

    /* get PC */
    add m1MAR, m1MAR, #4
    _READ_

    /* nop */

    /* restore PC & get opcode */
    mov m1PC, m1MDR
    _FETCH_

    /* get LV */
    add m1MAR, m1MAR, #4
    _READ_

    /* drop local stack */
    mov m1MAR, m1LV
    mov m1SP, m1MAR

    /* restore LV */
    mov m1LV, m1MDR

    /* push return value */
    mov m1MDR, m1TOS
    _WRITE_

    /* return control */
    b main1


done:
    /* print the top of stack and exit */
    mov r1, m1TOS
    ldr r0, =fmt
    bl printf
    pop {lr}
    bx lr
