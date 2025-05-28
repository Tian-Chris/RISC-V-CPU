# JAL Test 

addi x1, x0, 0        
jal x1, jal_target    # jump to jal_target and save return address in x1
addi x2, x0, 123      # skip if jal works

jal_target:
addi x2, x0, 42       # x2 = 42

# JALR Test 
addi x3, x0, 100       
addi x4, x0, 0         
addi x5, x0, 0        

# Put jump address in x6 (target is jalr_target)
auipc x6, 0            # x6 = current PC
addi x6, x6, 16        # x6 = PC + 16 

jalr x4, 0(x6)         # jump to jalr_target, save return addr to x4
addi x5, x0, 999       # skip if jalr works

jalr_target:
addi x5, x0, 55        # x5 = 55

lui  x11, 0x0000C       # x11 = 0x0000C000
addi x11, x11, 0x0DE    # x11 = 0x0000C0DE
