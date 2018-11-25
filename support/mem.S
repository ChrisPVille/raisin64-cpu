.data
data:  .long 0x80808080
       .quad 0x0123456789abcdef
space: .space 244

.text
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
lw $r1, 4($zero)
l32 $r2, 4($zero)
l16 $r3, 4($zero)
l8  $r4, 4($zero)
lui $r5, 0xfefefefe
l32s $r6, ($zero)
l16s $r6, ($zero)
l8s $r6, ($zero)
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
