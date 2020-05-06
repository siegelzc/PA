`timescale 1ps/1ps

//Input: retired, which ins, reg addr, reg data, mem addr, mem data

//PC: opcode r[0] = hex
//PC: opcode m[0000] = hex
//Pc: opcode pc = hex


module log();
    wire clk;
    wire isSub;
    wire isMovl;
    wire isMovh;
    wire isJz;
    wire isJnz;
    wire isJs;
    wire isJns;
    wire isLd;
    wire isSt;
    wire jump_taken;
    wire retired;
    wire[15:0] pc;
    wire[15:0] jump_addr;

    wire[15:0] reg_addr;
    wire[15:0] mem_addr;
    wire[15:0] reg_data;
    wire[15:0] mem_data;


    assign clk = main.clk;
    assign isSub = main.isSub;
    assign isMovl = main.isMovl;
    assign isMovh = main.isMovh;
    assign isJz = main.isJz;
    assign isJnz = main.isJnz;
    assign isJs = main.isJs;
    assign isJns = main.isJns;
    assign isLd = main.isLd;
    assign isSt = main.isSt;
    assign jump_taken = main.isJumping;
    assign retired = main.retired;
    assign pc = main.pc_e;
    assign jump_addr = main.jump_addr;

    assign reg_addr = main.regs.waddr;
    assign reg_data = main.regs.wdata;
    assign mem_addr = main.mem_addr;
    assign mem_data = main.mem_data;

    integer logfile;
    initial
        logfile = $fopenw("cpu.log");

    always @(posedge clk) begin
        if (main.halt) begin
            $fclose(logfile);
        end
        if(retired) begin
            if(isSub)
                $fdisplay(logfile, "PC: %04h sub r[%h] = %04h",pc,reg_addr,reg_data);
            if(isMovl)
                $fdisplay(logfile, "PC: %04h movl r[%h] = %04h",pc,reg_addr,reg_data);
            if(isMovh)
                $fdisplay(logfile, "PC: %04h movh r[%h] = %04h",pc,reg_addr,reg_data);
            if(isLd)
                $fdisplay(logfile, "PC: %04h ld r[%h] = %04h",pc,reg_addr,reg_data);
            if(isSt)
                $fdisplay(logfile, "PC: %04h st m[%04h] = %04h",pc,mem_addr,mem_data);
            if(isJz)
                $fdisplay(logfile, "PC: %04h jz pc = %04h",pc,jump_addr);
            if(isJnz)
                $fdisplay(logfile, "PC: %04h jnz pc = %04h",pc,jump_addr);
            if(isJs)
                $fdisplay(logfile, "PC: %04h js pc = %04h",pc,jump_addr);
            if(isJns)
                $fdisplay(logfile, "PC: %04h jns pc = %04h",pc,jump_addr);
        end
    end


endmodule


