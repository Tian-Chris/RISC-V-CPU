module MMU_unit( 
    input  wire [31:0] VPC,         
    input  wire [31:0] csr_satp,    
    input  wire [1:0]  priv,    

    //exception    
    input  wire        sstatus_sum, //bit 18
    input  wire        access_is_load,
    input  wire        access_is_store,
    input  wire        access_is_inst,
    output wire        instr_fault_mmu,
    output wire        load_fault_mmu,
    output wire        store_fault_mmu,
    output wire [31:0] faulting_va,

    output reg  [31:0] PC          
);
`include "csr_defs.v"
wire [31:0] base_addr = {csr_satp[21:0], 12'b0};
wire [9:0]  vpn1 = VPC[31:22];
wire [9:0]  vpn0 = VPC[21:12];

//level 1
reg  [31:0] l1_addr;      
reg  [31:0] l1_pte;      

//level 0
reg  [31:0] l0_addr;  
reg  [31:0] l0_pte;

//exception
reg         exception;

//read
output wire        DMEM_en;
output wire [31:0] DMEM_addr;
input wire        DMEM_return;
input wire [31:0] DMEM_out;
function [31:0] DMEM_read;
    input [31:0] addr;
    begin
        DMEM_en = 1;
        DMEM_addr = addr;
        if(DMEM_return)
            DMEM_read = DMEM_out;
    end
endfunction


always @(*) begin
    exception = 1'b0;
    if (csr_satp[31:30] == 2'b01) begin
        l1_addr = base_addr + (vpn1 << 2);
        l1_pte = DMEM_read(l1_addr);

        //check priv
        if(l1_pte[4] == 0 && priv == `PRIV_USER) begin
            exception = 1;
            PC = 32'hDEAD_BEEF;
        end else if(l1_pte[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
            exception = 1;
            PC = 32'hDEAD_BEEF;
        end

        // check l1 validity
        else if (l1_pte[0] == 0) begin
            exception = 1'b1;
            PC = 32'hDEAD_BEEF;
        end 

        else if ((l1_pte[1] == 0) && (l1_pte[2] == 0)) begin //if neither read and write or exec its not a superleaf
            l0_addr = {l1_pte[31:10], 12'b0} + (vpn0 << 2);
            l0_pte = DMEM_read(l0_addr);

            //check priv
            if(l0_pte[4] == 0 && priv == `PRIV_USER) begin
                exception = 1;
                PC = 32'hDEAD_BEEF;
            end else if(l0_pte[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
                exception = 1;
                PC = 32'hDEAD_BEEF;
            end

            //check l0 valididty
            if (l0_pte[0] == 0) begin
                exception = 1'b1;
                PC = 32'hDEAD_BEEF;
            end 
            else if ( (access_is_inst && (l0_pte[3] == 0)) ||
                (access_is_load  && (l0_pte[1] == 0))       ||
                (access_is_store && (l0_pte[2] == 0 || l0_pte[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception = 1'b1;
                PC = 32'hDEAD_BEEF;
            end 
            else begin
                PC = {l0_pte[31:12], VPC[11:0]};
            end
        end 

        else begin
            if ( (access_is_inst && (l1_pte[3] == 0)) ||
                (access_is_load  && (l1_pte[1] == 0))  ||
                (access_is_store && (l1_pte[2] == 0 || l1_pte[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception = 1'b1;
                PC = 32'hDEAD_BEEF;
            end else begin
                PC = {l1_pte[31:10], VPC[21:0]};
            end 
        end
    end 
    else
        PC = VPC;
end

//exception
assign faulting_va     = VPC;
assign instr_fault_mmu = exception ? (access_is_inst ? 1'b1 : 1'b0) : 1'b0;
assign load_fault_mmu  = exception ? (access_is_load  ? 1'b1 : 1'b0) : 1'b0;
assign store_fault_mmu = exception ? (access_is_store ? 1'b1 : 1'b0) : 1'b0;

endmodule
