# Test SLT: signed comparison
addi x1, x0, -5       # x1 = -5
addi x2, x0, 3        # x2 = 3
slt  x3, x1, x2       # x3 = (x1 < x2) signed -> 1
                      # Expected: x3 = 1

# Test SLTU: unsigned comparison
addi x4, x0, -5       # x4 = 0xFFFFFFFB = unsigned 4294967291
addi x5, x0, 3        # x5 = 3
sltu x6, x4, x5       # x6 = (x4 < x5) unsigned -> 0
                      # Expected: x6 = 0

# Test SLTU where unsigned is true
addi x7, x0, 3        # x7 = 3
addi x8, x0, -5       # x8 = 0xFFFFFFFB
sltu x9, x7, x8       # x9 = (3 < 0xFFFFFFFB) unsigned -> 1
                      # Expected: x9 = 1

lui x11, 12           # end signal
addi x11, x11, 222
