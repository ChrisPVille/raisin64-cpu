.set SW_LADR, 0x00008000
.set LED_LADR, 0x00004000

.text
#Load the sign-extended upper portion of the IO space in R1
lui $r1, 0xFFFFC000

sw_loop:
ori $r2, $r1, SW_LADR  #Load the switch address in R2
lw $r3, ($r2)          #and read into R3
ori $r2, $r1, LED_LADR #Now load LED address into R2
sw $r3, ($r2)          #And store R3 into *R2
ji sw_loop             #Repeat

add $r0, $r0, $r0      #NOP (not a delay slot) TODO Fix for assembler frag misalignment
