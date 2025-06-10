# Initialize test values
addi x1, x0, 1            
addi x2, x0, 1            
addi x3, x0, 2           
addi x4, x0, -1           # x4 = 0xFFFFFFFF   

# BLTU: unsigned (1 < 0xFFFFFFFF → true)
bltu x1, x4, bltu_taken
addi x16, x0, 99           # SKIPPED
bltu_taken:
addi x9, x0, 9            

# BGEU: unsigned (0xFFFFFFFF >= 1)
bgeu x4, x1, bgeu_taken
addi x17, x0, 99          # SKIPPED
bgeu_taken:
addi x10, x0, 10          

# End signal
lui  x11, 0x0000C         # end signal
addi x11, x11, 0x0DE      
