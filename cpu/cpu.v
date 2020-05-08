`timescale 1ps/1ps

module branch(input clk, input [15:0]pc, output [15:0] target, output taken, output valid,
             input wen, input [15:0] hist_addr, input [15:0] branch, input branch_taken);
    
    reg[15:0] branch_target[0:1023]; //Stores target for input location

    reg[1:0] history[0:1023]; //Internal

    reg[1023:0] branch_valid = 1024'b0; //Is data for a given history loc valid

    reg [4:0] tag[0:1023]; // Branch tag


    wire[15:0] target; // fetch target
    wire taken;
    wire valid;
    wire [9:0] hash_index = pc[10:1];
    wire[9:0] write_index = hist_addr[10:1];

    reg[1:0] read_history;
    reg[15:0] read_target;
    reg[4:0] read_tag;
    reg read_valid = 0;
    reg[15:0]prev_pc;

    assign valid = read_valid && (read_tag == prev_pc[15:11]);

    assign taken = valid && (read_history == 2'h2 || read_history == 2'h3);

    assign target = (valid && taken) ? read_target : prev_pc + 2;

    wire diff_target = !branch_valid[write_index] || ( branch != branch_target[write_index]);

    wire[1:0] write_history = diff_target ? {1'b0,branch_taken} : ((branch_taken && (history[write_index] == 2'h0)) ? 2'h1 :
                              (branch_taken && (history[write_index] == 2'h1)) ? 2'h2 :
                              (branch_taken && (history[write_index] == 2'h2)) ? 2'h3 :
                              (!branch_taken && (history[write_index] == 2'h1)) ? 2'h0 :
                              (!branch_taken && (history[write_index] == 2'h2)) ? 2'h1 :
                              (!branch_taken && (history[write_index] == 2'h3)) ? 2'h2 :
                              history[write_index]);



    always @(posedge clk) begin
        prev_pc <= pc;
        read_history <= history[hash_index];
        read_target <= branch_target[hash_index];
        read_tag <= tag[hash_index];
        read_valid <= branch_valid[hash_index];

        if(wen) begin
            history[write_index] <= write_history;
            branch_target[write_index] <= branch;
            branch_valid[write_index] <= 1'b1;
            tag[write_index] <= hist_addr[15:11];
        end
    end
endmodule

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);

    reg halt = 0;

    counter ctr(halt,clk);

    wire flush;

    // PC
    reg [15:0]pc = 16'h0000;

    //branch branch(input clk, input [15:0]pc, output [15:0] target, output taken, output valid,
    //         input wen, input [15:0] hist_addr, input [15:0] branch, input branch_taken);
    
    wire[15:0] pred_target;
    wire pred_taken;
    wire pred_valid;
    wire bp_wen;
    wire[15:0] bp_write_addr;
    wire[15:0] bp_write_branch;
    wire bp_write_taken;
    wire[15:0] faddr;
    branch branch(clk, faddr,pred_target,pred_taken,pred_valid,bp_wen,bp_write_addr,bp_write_branch,bp_write_taken);


    // read from memory
    wire [15:0]ins;
    reg[15:0] saved_faddr;
    reg[2:0] stall_f1 = 3'h0;
    
    assign faddr = (next_stall_f1 && !flush) ? saved_faddr : (pred_taken && pred_valid && !flush_wb) ? pred_target : pc;
    wire [15:0]laddr;
    wire [15:0]ldata;
    wire[15:0]waddr;
    wire[15:0]wdata;
    wire[15:0]saddr;
    wire[15:0]sdata;
    wire writeen;
    wire temp_writeen = writeen | store_ex;
    // memory
    wire[15:0] temp_laddr = load_ex ? laddr_ex : laddr;
    wire[15:0] temp_saddr = store_ex ? saddr_ex : saddr;
    wire[15:0] temp_sdata = store_ex ? sdata_ex : sdata;


    mem mem(clk,faddr[15:1],ins,temp_laddr[15:1],ldata,temp_writeen,temp_saddr[15:1],temp_sdata);


    

    
    //---FETCH1---
    reg[15:0]faddr_f1;
    reg valid_f1 = 0;
    reg valid_f1_ = 1;
    reg[15:0] pred_pc_f1;
    reg pred_valid_f1;
    reg pred_taken_f1;
    wire[2:0] next_stall_f1 = next_stall_f2;
    always @(posedge clk) begin
        stall_f1 <= flush ? 0 : next_stall_f1;
        saved_faddr <= faddr;
        valid_f1_ <= 1;
        valid_f1 <= !flush && valid_f1_;
        if(!next_stall_f1) begin
            pred_pc_f1 <= pred_target;
            pred_valid_f1 <= pred_valid;
            pred_taken_f1 <= pred_taken;
            faddr_f1 <= faddr;
        end

    end

    //---FETCH2---
    reg[15:0]faddr_f2;
    reg valid_f2=0;
    reg[2:0] stall_f2 = 3'h0;

    reg[15:0] pred_pc_f2;
    reg pred_valid_f2;
    reg pred_taken_f2;
    wire[2:0] next_stall_f2 = next_stall_d;
    always @(posedge clk) begin
        valid_f2 <= valid_f1 && !flush;
        stall_f2 <= flush ? 0 : next_stall_f2;

        if(valid_f1) begin
            if(!next_stall_f2) begin
                faddr_f2 <= faddr_f1;
                pred_pc_f2 <= pred_target;
                pred_valid_f2 <= pred_valid && !flush_wb;
                pred_taken_f2 <= pred_taken;
            end
        end
    end

    //---DECODE---
    
    reg[2:0] stall_d = 3'h0;
    wire[2:0] next_stall_d = next_stall_e | {1'b0,raw_hazard};
    wire[15:0] used_ins = stall_d ? saved_ins : ins;

    wire[3:0]opcode = used_ins[15:12];
    wire[3:0]xop = used_ins[7:4];
    reg[15:0] pc_d;
    reg valid_d=0;


    reg[15:0] saved_ins;
    
    reg[15:0] pred_pc_d;
    reg pred_valid_d;
    reg pred_taken_d;

    reg isSub_d;
    reg isMovl_d;
    reg isMovh_d;
    reg isJz_d;
    reg isJnz_d;
    reg isJs_d;
    reg isJns_d;
    reg isLd_d;
    reg isSt_d;
    reg isMov_d;
    reg isAdd_d;
    reg isMul_d;
    wire isDefined;
    wire updatesRegs;
    reg[7:0] i;
    reg[3:0] rt;
    reg[3:0] ra;
    reg[3:0] rb;

    wire[3:0] read_ra;
    wire[3:0] read_rb;
    wire[3:0] read_rt;
    wire[3:0] write_rt;

    reg isDefined_d;
    reg updatesRegs_d;

    wire isSub = (opcode == 0);
    wire isMovl = (opcode == 8);
    wire isMovh = (opcode == 9);
    wire isJz = (opcode == 4'he) & (xop == 0);
    wire isJnz = (opcode == 4'he) & (xop == 1);
    wire isJs = (opcode == 4'he) & (xop == 2);
    wire isJns = (opcode == 4'he) & (xop == 3);
    wire isLd = (opcode == 4'hf) & (xop == 0);
    wire isSt = (opcode == 4'hf) & (xop == 1);
    wire isMov = (opcode == 4'hb);
    wire isAdd = opcode == 1;
    wire isMul = opcode == 2;


    wire a_read_ops = (isSub | isJz | isJnz | isJs | isJns | isLd | isSt | isAdd | isMul | isMov);
    wire b_read_ops = isSub | isAdd | isMul;
    wire t_read_ops = isJz | isJnz | isJs | isJns | isSt;
    wire t_write_ops = isSub | isMovl | isMovh | isLd | isAdd | isMul | isMov;

    assign read_ra = used_ins[11:8];
    assign read_rb = used_ins[7:4];
    assign read_rt = used_ins[3:0];
    assign write_rt = used_ins[3:0];

    wire[1:0] raw_hazard;
    reg[1:0] prev_raw_hazard = 0;
    assign raw_hazard = prev_raw_hazard ? prev_raw_hazard - 2'h1 :
                    {1'b0,valid_d && isDefined && !next_stall_e && used_t_write_ops && ( a_read_ops && (read_ra == used_write_rt)
                    ||  b_read_ops && (read_rb == used_write_rt)
                    ||  t_read_ops && (read_rt == used_write_rt))};

    
    wire raw_hazard_a = valid_d && isDefined && !next_stall_e && used_t_write_ops && ( a_read_ops && (read_ra == used_write_rt));
    wire raw_hazard_b = valid_d && isDefined && !next_stall_e && used_t_write_ops && ( b_read_ops && (read_rb == used_write_rt));
    wire raw_hazard_t = valid_d && isDefined && !next_stall_e && used_t_write_ops && ( t_read_ops && (read_rt == used_write_rt));

    reg raw_hazard_a_d;
    reg raw_hazard_b_d;
    reg raw_hazard_t_d;


    wire[3:0]addx;
    wire[3:0]addy;
    assign addx = (isSub | isAdd | isMul) ? used_ins[11:8] : used_ins[3:0];
    assign addy = (isSub | isAdd | isMul) ? used_ins[7:4] : used_ins[11:8];       

    reg[3:0] prev_addx;
    reg[3:0] prev_addy;

    reg t_write_ops_d;
    reg[3:0] write_rt_d;

    assign isDefined = ((isSub | isMovl | isMovh | isJz | isJnz | isJs | isJns | isLd | isSt | isAdd | isMul | isMov) === 1);
    assign updatesRegs = ((isSub | isMovl | isMovh | isLd | isAdd | isMul | isMov) == 1);

    always @(posedge clk) begin
        stall_d <= flush ? 0 : next_stall_d;
        valid_d <= valid_f2 && !flush;
        saved_ins <= (next_stall_d && !stall_d) ? ins : saved_ins;
        prev_raw_hazard <= flush ? 0 : raw_hazard;
        prev_addx <= addx;
        prev_addy <= addy;

        raw_hazard_a_d <= raw_hazard_a;
        raw_hazard_b_d <= raw_hazard_b;
        raw_hazard_t_d <= raw_hazard_t;

        if(valid_f2) begin
            if(!next_stall_d) begin
                pc_d <= faddr_f2;

                pred_pc_d <= pred_pc_f2;
                pred_taken_d <= pred_taken_f2;
                pred_valid_d <= pred_valid_f2;

                isSub_d <= (opcode == 0);
                isMovl_d <= (opcode == 8);
                isMovh_d <= (opcode == 9);
                isJz_d <= (opcode == 4'he) & (xop == 0);
                isJnz_d <= (opcode == 4'he) & (xop == 1);
                isJs_d <= (opcode == 4'he) & (xop == 2);
                isJns_d <= (opcode == 4'he) & (xop == 3);
                isLd_d <= (opcode == 4'hf) & (xop == 0);
                isSt_d <= (opcode == 4'hf) & (xop == 1);
                isMov_d <= (opcode == 4'hb);
                isAdd_d <= opcode == 1;
                isMul_d <= opcode == 2;


                i <= used_ins[11:4];
                rt <= used_ins[3:0];
                ra <= used_ins[11:8];
                rb <= used_ins[7:4];

                t_write_ops_d <= t_write_ops;
                write_rt_d <= write_rt;

                isDefined_d <= isDefined;
                updatesRegs_d <= updatesRegs;
            end
        end
    end







    //---EXECUTE---
    wire misaligned;
    reg[15:0] pc_e;
    reg[2:0] stall_e = 3'h0;
    reg valid_e=0;
    //wire[1:0] next_stall_e = mem_hazard ? mem_hazard_stall : 
    //                                      (stall_e ? stall_e - 2'h1 : 
    //                                                 misaligned ? 2 : 
    //                                                              {1'h0,(isLd_d & isDefined_d & valid_d)});

    wire[2:0] next_stall_e = stall_e ? stall_e - 3'h1 :
                                 stall_d ? 3'h0 :
                                 isSt_d && misaligned ? next_mis_st_cnt :
                                 mem_hazard && isLd_d ? mem_hazard_stall :
                                 isLd_d && misaligned ? 3'h2 :
                                    {2'h0,(isLd_d & isDefined_d & valid_d)};
    // registers
    wire[15:0]regx;
    wire[15:0]regy;

    reg[15:0] saved_regx;
    reg[15:0]saved_regy;

    reg dont_write_back = 0;

    wire[15:0] used_regx;
    wire[15:0] used_regy;

    reg[15:0] prev_ldata;

    reg[15:0] pred_pc_e;
    reg pred_valid_e;
    reg pred_taken_e;

    //assign addx = isSub ? used_ins[11:8] : used_ins[3:0];
    //assign addy = isSub ? used_ins[7:4] : used_ins[11:8]; 
    wire[15:0] forward_regx = (isSub_d | isAdd_d | isMul_d) ? (raw_hazard_a_d ? datat : regx) :
                                    (raw_hazard_t_d ? datat : regy);

    wire[15:0] forward_regy = (isSub_d | isAdd_d | isMul_d) ? (raw_hazard_b_d ? datat : regy) :
                                    (raw_hazard_a_d ? datat : regy);


    wire[2:0] next_mis_st_cnt = mis_st_cnt ? mis_st_cnt - 1 :
                                            stall_d ? 0 :
                                            (misaligned && mem_hazard && isSt_d) ? 3 :
                                                                (misaligned && isSt_d) ? 3 : 0;
    
    wire load_ex = isSt_d && (mis_st_cnt == 3 || mis_st_cnt == 2);
    wire[15:0] laddr_ex = mis_st_cnt == 3 ? used_regy +2 :
                            used_regy;

    wire store_ex = isSt_d && (mis_st_cnt == 1);
    wire[15:0] saddr_ex = (mis_st_cnt == 1) ? used_regy + 2 : used_regy;
    // 100: A B
    // 102: C D pre
    // 
    wire[15:0] sdata_ex = (mis_st_cnt == 1) ? {used_regx[7:0],ldata[7:0]} : {ldata[15:8],used_regx[15:8]};
    //     wire[15:0] sdata_ex = (mis_st_cnt == 1) ? {ldata[15:8],used_regx[15:8]} : {used_regx[7:0],prev_ldata[7:0]};

    
    reg[2:0] mis_st_cnt = 0;

    wire[15:0] temp_regx;
    wire[15:0] temp_regy;
    
    //forwb
    wire[3:0]addt;
    wire[15:0]datat;
    wire updatesRegs_w;
    regs regs(clk,addx,temp_regx,addy,temp_regy,updatesRegs_w,addt,datat);

    assign regx = prev_addx == 0 ? 16'h0 : temp_regx;
    assign regy = prev_addy == 0 ? 16'h0 : temp_regy;

    

    reg[15:0]vt;
    reg[15:0]out;
    reg[3:0]rt_e;
    reg[15:0] prev_laddr;

    assign used_regx = stall_e ? saved_regx : prev_raw_hazard ? forward_regx : regx;
    assign used_regy = stall_e ? saved_regy : prev_raw_hazard ? forward_regy : regy;

    wire mem_hazard;
    wire[15:0] mem_read_addr;
    wire[15:0] mem_write_addr;

    assign mem_read_addr = used_regy;

    assign mem_hazard = !stall_d && !stall_e && valid_e && writeen && (isLd_d | isSt_d) && isDefined_d && 
                        ((saddr_e[15:1] == mem_read_addr[15:1]) 
                        || (misaligned  && (saddr_e[15:1] == mem_read_addr[15:1] + 1)));
    


    reg mem_hazard_e;
    reg prev_mem_hazard;
    reg prev_prev_memhazard;
    reg prev_prev_laddr;

    wire[1:0] mem_hazard_stall = misaligned ? 3 : 2;

    reg saved_t_write_ops;
    reg[3:0] saved_write_rt;
    wire used_t_write_ops;
    wire[3:0] used_write_rt;
    assign used_t_write_ops = stall_e ? saved_t_write_ops : t_write_ops_d;
    assign used_write_rt = stall_e ? saved_write_rt : write_rt_d;


    assign misaligned = !stall_d && used_regy[0] & (isLd_d | isSt_d) & !stall_e & valid_d & isDefined_d;

    reg isSub_e;
    reg isMovl_e;
    reg isMovh_e;
    reg isJz_e;
    reg isJnz_e;
    reg isJs_e;
    reg isJns_e;
    reg isLd_e;
    reg isSt_e;
    reg isAdd_e;
    reg isMul_e;
    reg isMov_e;
    reg isDefined_e;
    reg updatesRegs_e;
    reg misaligned_e;
    reg prev_misaligned;
    reg prev_prev_misaligned;

    //assign laddr = prev_misaligned ? prev_laddr + 2 : used_regy;

    assign laddr = (prev_misaligned && ! prev_mem_hazard) ? prev_laddr + 2 :
                        (prev_misaligned && prev_mem_hazard) ? used_regy :
                        (prev_prev_misaligned && prev_prev_memhazard) ? prev_laddr + 2 :
                        used_regy;

    reg[15:0] saddr_e;
    reg isJumping;

    reg[15:0] used_regx_e;


    always @(posedge clk) begin
        stall_e <= flush ? 0 : next_stall_e;
        valid_e <= valid_d && !flush;
        prev_laddr <= laddr;
        prev_misaligned <=  misaligned;
        prev_prev_misaligned <= prev_misaligned;
        prev_prev_memhazard <= prev_mem_hazard;
        prev_prev_laddr <= prev_laddr;
        prev_mem_hazard <= mem_hazard;
        saved_regx <= next_stall_e && ! stall_e ? used_regx : saved_regx;
        saved_regy <= next_stall_e && ! stall_e ? used_regy : saved_regy;
        saved_t_write_ops <= next_stall_e && ! stall_e ? used_t_write_ops : saved_t_write_ops;
        saved_write_rt <= next_stall_e && ! stall_e ? used_write_rt : saved_write_rt;
        dont_write_back <= prev_raw_hazard != 0;
        mis_st_cnt <= next_mis_st_cnt;
        used_regx_e <= used_regx;
        if(valid_d)
            misaligned_e <= used_regy[0] & isLd_d & isDefined_d;
            if(!next_stall_e) begin
                if(isSub_d) begin
                    out <= used_regx - used_regy;
                end
                if(isAdd_d) begin
                    out <= used_regx + used_regy;
                end
                if(isMul_d) begin
                    out <= used_regx * used_regy;
                end
                if((isMovl_d | isMovh_d | isJz_d | isJnz_d | isJs_d | isJns_d | isSt_d | isMov_d) === 1) begin
                    vt <= used_regx;
                    saddr_e <= used_regy;
                    out <=  isMovl_d ? {{8{i[7]}},i}:
                            isMovh_d ? (used_regx & 16'hff) | (i << 8) :
                            isMov_d ? used_regy : 
                            isSt_d ? ((mis_st_cnt == 1) ? {ldata[15:8], used_regx[15:8]} : used_regx) :
                            0;
                end
                
                pc_e <= pc_d;
                isSub_e <= isSub_d;
                isMovl_e <= isMovl_d;
                isMovh_e <= isMovh_d;
                isJz_e <= isJz_d;
                isJnz_e <= isJnz_d;
                isJs_e <= isJs_d;
                isJns_e <= isJns_d;
                isLd_e <= isLd_d;
                isSt_e <= isSt_d;
                isAdd_e <= isAdd_d;
                isMul_e <= isMul_d;
                isMov_e <= isMov_d;
                isDefined_e <= isDefined_d;
                updatesRegs_e <= updatesRegs_d;
                rt_e <= rt;

                pred_pc_e <= pred_pc_d;
                pred_valid_e <= pred_valid_d;
                pred_taken_e <= pred_taken_d;

                isJumping <= (isJz_d & (used_regy === 0)) |
                             (isJnz_d & (used_regy != 0)) |
                             (isJs_d & (used_regy[15:15] == 1)) |
                             (isJns_d & (used_regy[15:15] == 0));
                
            end
    end


    // 100: A B ldata
    // 102: C D prev

    //load @ 101

    // D A


    //---WRITEBACK---
    reg[15:0]pc_w;
    wire mispredict = valid_e && (((pred_pc_e != vt) && pred_taken_e) || !pred_taken_e) && pred_valid_e && !dont_write_back && isJumping;
    wire mispredict_nj = valid_e && pred_taken_e && pred_valid_e && !dont_write_back && !isJumping && (isJz_e || isJnz_e || isJs_e || isJns_e);
    assign updatesRegs_w = updatesRegs_e && !stall_e && isDefined_e && valid_e && !dont_write_back;
    assign addt = rt_e;
    reg[7:0] reg_copy[0:15];

    wire[15:0] used_out = isMovh_e ? {out[15:8],reg_copy[addt]} : out;
    assign datat = isLd_e ? (misaligned_e ? {prev_ldata[7:0],ldata[15:8]} : ldata) : used_out;
    //    assign datat = isLd_e ? (misaligned_e ? {ldata[7:0],prev_ldata[15:8]} : ldata) : out;

    // Wrong order
    assign writeen = isSt_e && valid_e && !dont_write_back && !stall_e;
    assign saddr = saddr_e;
    assign sdata = saddr_e[0] ? {ldata[15:8],used_out[7:0]} : used_out;
    assign flush = ((isJumping && (mispredict || !pred_valid_e)) || mispredict_nj || smc) && valid_e && !flush_wb;
    reg flush_wb = 0;
    reg isDefined_w;
    wire smc;
    assign smc = writeen && ((((saddr[15:1] == faddr[15:1]) && valid_f1_)
                         || ((saddr[15:1] == faddr_f1[15:1]) && valid_f1)
                         || ((saddr[15:1] == faddr_f2[15:1]) && valid_f2)
                         || ((saddr[15:1] == pc_d[15:1]) && valid_d)
                         || ((saddr[15:1] == pc_e[15:1]) && valid_e))
                         || saddr[0] && (
                            (((saddr[15:1] + 1 == faddr[15:1]) && valid_f1_)
                            || ((saddr[15:1] + 1 == faddr_f1[15:1]) && valid_f1)
                            || ((saddr[15:1] + 1 == faddr_f2[15:1]) && valid_f2)
                            || ((saddr[15:1] + 1 == pc_d[15:1]) && valid_d)
                            || ((saddr[15:1] + 1  == pc_e[15:1]) && valid_e))
                         ));
                         
    assign bp_wen = (pc_e != pc_w) && valid_e && !dont_write_back && (isJz_e || isJnz_e || isJs_e || isJns_e);
    assign bp_write_addr = pc_e;
    assign bp_write_branch = vt;
    assign bp_write_taken = isJumping;

    wire retired = valid_e && ((pc_e != pc_w) || pc_e == 0);
    wire[15:0] mem_addr = saddr;
    wire[15:0] mem_data = used_regx_e;
    wire[15:0] jump_addr = isJumping ? vt : pc_e + 2;

    
    always @(posedge clk) begin
    //branch branch(clk, faddr,pred_target,pred_taken,pred_valid,bp_wen,bp_write_addr,bp_write_branch,bp_write_taken);

        pc_w <= pc_e;
        prev_ldata <= ldata;
        flush_wb <= flush;
        if(updatesRegs_w) begin
            reg_copy[addt] <= datat[7:0];
            if(rt_e == 0)
                $write("%c",datat[7:0]);
        end
        isDefined_w <= isDefined_e;
        if(flush & isJumping & (mispredict || !pred_valid_e)) begin //Do I need stall/valid checks here
            pc <= vt;
        end
        else begin 
            if(flush && (smc || mispredict_nj)) begin
                pc <= pc_e + 2;
            end
            else begin
                if(!(next_stall_f1 && !flush) && (pred_taken && pred_valid && !flush_wb)) begin
                    pc <= pred_target + 2;
                end
                else begin
                    if(!next_stall_f1 && !flush)
                        pc <= pc + 2;
                end
            end
        end

    end

            
    //---ADMIN---
    always @(posedge clk) begin
        if(!stall_e && valid_e) halt <= ! isDefined_e;
        
        

        /*$write("pc = %d\n",pc);
        $write("    ins = %x\n",ins);
        $write("    issub = %x\n",isSub);
        $write("    ismovl = %x\n",isMovl);
        $write("    ismovh = %x\n",isMovh);
        $write("    isjz = %x\n",isJz);
        $write("    isjnz = %x\n",isJnz);
        $write("    isjs = %x\n",isJs);
        $write("    isjns = %x\n",isJns);
        $write("    isld = %x\n",isLd);
        $write("    isst = %x\n", isSt);
        $write("    isdef = %x\n",isDefined);
        $write("    rt = %x\n",rt);
        $write("    out = %x\n",out);*/


        //$write("%c",out[7:0]);
    end

    //always @(posedge clk) begin
    //    if(misaligned && isSt_d) begin
            //$write("misaligned store\n");
            //$finish;
    //    end
    //end

endmodule
