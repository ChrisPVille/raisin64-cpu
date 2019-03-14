.set LED_LADR, 0x00004000

.text
lui $r2, 0xFFFFC000
ori $r2, $r2, LED_LADR

lui $r1, 0x54545454
ori $r1, $r1, 0x54545454
loop:
sw $r1, ($zero)
s32 $r1, 8($zero)
s16 $r1, 16($zero)
s8 $r1, 24($zero)
lw $r1, ($zero)
l32 $r1, 8($zero)
l16 $r1, 16($zero)
l8 $r3, 24($zero)
sw $r3, ($r2)
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
