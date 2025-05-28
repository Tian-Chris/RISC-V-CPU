# Initialize test values
addi x1, x0, 1            
addi x2, x0, 1            
addi x3, x0, 2           
addi x4, x0, -1           # x4 = 0xFFFFFFFF

# BEQ: should branch
beq x1, x2, beq_taken     # 1 == 1 → branch
addi x5, x0, 99           # SKIPPED
beq_taken:
addi x5, x0, 5            

# BNE: should branch
bne x1, x3, bne_taken     # 1 != 2 → branch
addi x6, x0, 99           # SKIPPED
bne_taken:
addi x6, x0, 6            

# BLT: should branch (1 < 2)
blt x1, x3, blt_taken
addi x7, x0, 99           # SKIPPED
blt_taken:
addi x7, x0, 7            

# BGE: should branch (2 >= 1)
bge x3, x1, bge_taken
addi x8, x0, 99           # SKIPPED
bge_taken:
addi x8, x0, 8            

# BLTU: unsigned (1 < 0xFFFFFFFF → true)
bltu x1, x4, bltu_taken
addi x9, x0, 99           # SKIPPED
bltu_taken:
addi x9, x0, 9            

# BGEU: unsigned (0xFFFFFFFF >= 1)
bgeu x4, x1, bgeu_taken
addi x10, x0, 99          # SKIPPED
bgeu_taken:
addi x10, x0, 10          

# End signal
lui  x11, 0x0000C         # end signal
addi x11, x11, 0x0DE      
