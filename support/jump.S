add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
ji target_r3
addi $r1, $r1, 1
addi $r2, $r2, 1
target_r3:
addi $r3, $r3, 1
addi $r4, $r4, 1
addi $r5, $r5, 1
addi $r6, $r6, 1
ji .-8 #TODO Bugfix for assembler ver <= 0.0.2
addi $r7, $r7, 1
addi $r8, $r8, 1
addi $r9, $r9, 1
addi $r10, $r10, 1
addi $r11, $r11, 1
