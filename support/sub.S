.data
stack: .space 16*8
stack_init_head:

.text
addi $sp, $zero, stack_init_head+16*8 #TODO Looks like assembler doesn't pick up on label
addi $r1, $zero, 1
addi $r2, $zero, 1
addi $r3, $zero, 1
jali sub
addi $r4, $zero, 1
addi $r5, $zero, 1
addi $r6, $zero, 1
addi $r7, $zero, 1
addi $r8, $zero, 1
ji .-8 #TODO Fix for assemblers offset from .

sub:
addi $sp, $sp, -4
sw $lr, ($sp)
addi $r8, $zero, 1
addi $r9, $zero, 1
addi $r10, $zero, 1
lw $lr, ($sp)
addi $sp, $sp, 4
j $lr
