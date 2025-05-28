# Immediate Arithmetic Test

addi  x1, x0, 5        # x1 = 5
addi  x2, x0, -3       # x2 = -3

slti  x3, x1, 10       # x3 = (5 < 10) signed => 1
slti  x4, x2, -2       # x4 = (-3 < -2) signed => 1

sltiu x5, x2, -1       # x5 = (0xFFFFFFFD < 0xFFFFFFFF) unsigned => 1
sltiu x6, x1, 2        # x6 = (5 < 2) unsigned => 0

xori  x7, x1, 0xF0     # x7 = 0x05 ^ 0xF0 = 0xF5
ori   x8, x1, 0x0A     # x8 = 0x05 | 0x0A = 0x0F
andi  x9, x1, 0x0A     # x9 = 0x05 & 0x0A = 0x00

slli  x10, x1, 2       # x10 = 5 << 2 = 20
srli  x11, x1, 1       # x11 = 5 >> 1 = 2
srai  x12, x2, 1       # x12 = -3 >> 1 = -2 (arithmetic shift)

lui   x13, 12          # end signal
addi  x13, x0, 222
