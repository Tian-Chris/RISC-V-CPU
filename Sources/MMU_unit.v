module MMU_unit( 
    input  wire clk,
    input  wire rst,
    input  wire [3:0]  hazard_signal,
    input  wire [31:0] VPC,         
    input  wire [31:0] csr_satp,    
    input  wire [1:0]  priv,    
    input  wire        valid,
    input  wire        LFM_resolved,
    input  wire [31:0] LFM_word,
    input  wire        MMU_hand_shake,


    //exception    
    input  wire        sstatus_sum, //bit 18
    input  wire        access_is_load, access_is_store, access_is_inst,
    output wire        instr_fault_mmu, load_fault_mmu, store_fault_mmu,
    output wire [31:0] faulting_va,
    output reg         stall,
    output reg         MMU_busy,
    output reg  [31:0] LFM,
    output reg         LFM_enable,

    output reg  [31:0] PC          
);
`include "csr_defs.v"
`include "inst_defs.v"
wire [33:0] base_addr = {csr_satp[21:0], 12'b0};
wire [9:0]  vpn1   = VPC[31:22];
wire [9:0]  vpn0   = VPC[21:12];
wire [11:0] offset = VPC[11:0];
reg  [31:0] l1_pte;      
reg  [31:0] l0_pte;
wire [33:0] l1_addr = base_addr + (vpn1 << 2);
wire [33:0] l0_addr = {l1_pte[31:10], 12'b0} + (vpn0 << 2);

//exception
reg         exception;

//FSM
localparam [2:0] IDLE   = 3'b000;
localparam [2:0] LFM1   = 3'b001;
localparam [2:0] READL1 = 3'b010;
localparam [2:0] LFM0   = 3'b011;
localparam [2:0] READL0 = 3'b100;
localparam [2:0] DONE   = 3'b101;
reg        [2:0] STATE;

 

always @(posedge clk) begin
    `ifdef DEBUG_MMU
        $display("===========  MMU  ===========");
        $display("MMU => State: %h, Stall: %h, priv: %h, except: %h, ", STATE, stall, priv, exception);
    `endif
    if(rst || hazard_signal == `FLUSH_ALL) begin
        exception   <= 0;
        STATE       <= IDLE;
        PC          <= 32'hDEAD_BEEF;
        LFM_enable  <= 0; 
        MMU_busy    <= 0;
    end
    else begin
    case(STATE)
        IDLE: begin
            if(hazard_signal != `FLUSH_ALL)
                stall       <= 0;
            exception   <= 0;
            MMU_busy    <= 0;
            if (csr_satp[31] && priv != `PRIV_MACHINE) begin
                stall       <= 1;
                MMU_busy    <= 1;
                STATE       <= LFM1;
            end
        end
        LFM1: begin
            LFM_enable  <= 1;
            LFM         <= l1_addr; //load from memory
            if(LFM_resolved) begin
                LFM_enable  <= 0;
                l1_pte  <= LFM_word;
                STATE   <= READL1;
            end
        end
        READL1: begin
            if (^l1_pte === 1'bx) begin
                exception <= 1'b1;
                PC        <= 32'hDEAD_0001;
                STATE     <= DONE;
            end
            //check priv
            // else if(l1_pte[4] == 0 && priv == `PRIV_USER) begin
            //     exception   <= 1;
            //     PC          <= 32'hDEAD_0002;
            //     STATE       <= DONE;
            // end 
            else if(l1_pte[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
                exception   <= 1;
                PC          <= 32'hDEAD_0003;
                STATE       <= DONE;
            end
            // check l1 validity
            else if (l1_pte[0] == 0) begin
                exception   <= 1'b1;
                PC          <= 32'hDEAD_0004;
                STATE       <= DONE;
            end 
            else if ((l1_pte[1] == 0) && (l1_pte[2] == 0)) begin //if neither read and write or exec its not a superleaf
                LFM_enable  <= 1;
                LFM         <= l0_addr; //load from memory
                STATE       <= LFM0;
            end
            else begin
                if ( (access_is_inst && (l1_pte[3] == 0)) ||
                    (access_is_load  && (l1_pte[1] == 0))  ||
                    (access_is_store && (l1_pte[2] == 0 || l1_pte[7] == 0)) ) begin //checks dirty bit as well
                    // if dirty bit = 0 except -> trap -> os -> sets db to 1
                    exception   <= 1'b1;
                    PC          <= 32'hDEAD_0005;
                    STATE       <= DONE;
                end else begin
                    $display("SuperLeaf");
                    $display("VPC: %h", VPC);
                    $display("PC: %h", {l1_pte[31:20], vpn0, VPC[11:0]});
                    PC          <= {l1_pte[31:20], vpn0, VPC[11:0]};
                    STATE       <= DONE;
                end  
            end
        end
        LFM0: begin
            if(LFM_resolved) begin
                LFM_enable  <= 0;
                l0_pte  <= LFM_word;
                STATE   <= READL0;
            end
        end
        READL0: begin
            if (^l0_pte === 1'bx) begin
                exception <= 1'b1;
                PC        <= 32'hDEAD_BEEF;
                STATE     <= DONE;
            end
            else if(l0_pte[4] == 0 && priv == `PRIV_USER) begin
                exception   <= 1;
                PC          <= 32'hDEAD_BEEF;
                STATE       <= DONE;
            end else if(l0_pte[4] == 1 && priv == `PRIV_SUPER && sstatus_sum == 0) begin
                exception   <= 1;
                PC          <= 32'hDEAD_BEEF;
                STATE       <= DONE;
            end

            //check l0 valididty
            if (l0_pte[0] == 0) begin
                exception   <= 1;
                PC          <= 32'hDEAD_BEEF;
                STATE       <= DONE;
            end 
            else if ( (access_is_inst && (l0_pte[3] == 0)) ||
                (access_is_load  && (l0_pte[1] == 0))       ||
                (access_is_store && (l0_pte[2] == 0 || l0_pte[7] == 0)) ) begin //checks dirty bit as well
                // if dirty bit = 0 except -> trap -> os -> sets db to 1
                exception   <= 1;
                PC          <= 32'hDEAD_BEEF;
                STATE       <= DONE;
            end 
            else begin
                PC          <= {l0_pte[31:10], VPC[11:0]};
                STATE       <= DONE;
            end
        end
        DONE: begin
            MMU_busy <= 0;
            if(MMU_hand_shake == 0) begin
                STATE <= IDLE;
                stall <= 0;
            end
        end
        default: begin
            STATE <= IDLE;
        end
    endcase
    end
end

//exception
assign faulting_va     = VPC;
assign instr_fault_mmu = exception && valid && access_is_inst;
assign load_fault_mmu  = exception && valid && access_is_load;
assign store_fault_mmu = exception && valid && access_is_store;

endmodule
