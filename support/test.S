add $r0, $zero, $lr
jump:
add $r27, $r10, $r63
sra $r1, $r2, $r32
beq $r1, $r10, jump
beq $r1, $r10, 0 #test
lw $r1, ($r2)
sw $r1, -10($r2)
#blab
lui $r4, 0x12345678
j $zero
ji 1024
andi $r26, $r41, -100
ji 72057594037927935
ji 0xFFFFFFFFFFFFFF
