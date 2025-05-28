addi x1, x0, -56     # x1 = 0xFFFFFFC8 = -56 (two's complement)
addi x2, x0, 3       
sra  x3, x1, x2      # Expected x3 = 0xFFFFFFF9 = -7
lui  x11, 12         # end signal
addi x11, x11, 222
