# Initialize base address
addi x1, x0, 0x010    # x1 = 0x0010

# Store word
addi x2, x0, 0x123   # x2 = 0x0000123
sw   x2, 0(x1)        # store word at 0x1000

# Load word
lw   x3, 0(x1)        # x3 = 0x0000123

# Store byte
addi x4, x0, 0xAB     # x4 = 0x000000AB
sb   x4, 4(x1)        # store byte at 0x0014

# Load signed byte
lb   x5, 4(x1)        # x5 = 0xFFFFFFAB = -85 (signed)

# Load unsigned byte
lbu  x6, 4(x1)        # x6 = 0x000000AB = 171 (unsigned)

# Store halfword
addi x7, x0, 0x7F7   # x7 = 0x000007F7
sh   x7, 6(x1)        # store halfword at 0x1006

# Load signed halfword
lh   x8, 6(x1)        # x8 = 0x000007F7

# Load unsigned halfword
lhu  x9, 6(x1)        # x9 = 0x000007F7

# End signal
lui  x11, 12
addi x11, x11, 222
