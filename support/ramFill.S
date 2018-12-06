.text
lui $r1, 0x01234567
ori $r1, $r1, 0x89abcdef
sw $r1, ($zero)
sw $r1, 8($zero)
sw $r1, 16($zero)
sw $r1, 24($zero)
ji .-8 #TODO Offset fixed for assembler bug
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
add $zero, $zero, $zero
