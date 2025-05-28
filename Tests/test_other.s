# LUI test
lui x1, 0x12345       # x1 = 0x12345000

# AUIPC Test 
auipc x2, 0x10        # x2 = PC + 0x00010000 (depends on PC, assume PC = 0x0 → x2 = 0x00010000)

lui  x11, 0x0000C     # end signal
addi x11, x11, 0x0DE   