addi $r1, $zero, 1
addi $r2, $zero, -10
addi $r3, $r1, 9
add $r4, $r3, $r2   #R4 should be 0
addi $r5, $zero, 1  #R5 is 1
slli $r6, $r5, 1    #R6 is 2
sll $r7, $r6, $r6   #R7 is 8
or $r8, $r5, $r6    #R8 is 3
subi $r9, $r8, 2    #R9 is 1
xor $r10, $r8, $r9  #R10 is 2
sra $r11, $r10, $r9 #R11 is 1
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
