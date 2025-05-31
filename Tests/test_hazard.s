addi x1, x0, 5         # x1 = 5
addi x2, x0, 7         # x2 = 7
add  x3, x1, x2        # x3 = 12
sw   x3, 0(x3)
lw   x4, 0(x3)         # x4 = mem[12] = 12
addi x5, x4, 1         # x5 = x4 + 1 = 13
addi x6, x5, 1         # x6 = x5 + 1 = 14
lui  x11, 12           # x11 = 12 << 12 = 0x0000C000
addi x11, x11, 222     # x11 = 0x0000C000 + 222 = 0x0000C0DE