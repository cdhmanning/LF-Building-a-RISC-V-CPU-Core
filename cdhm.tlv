\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   // PC
   
   $next_pc[31:0] = $reset ? 0 :
                    $pc + 4;
   $pc[31:0] = >>1$next_pc;
  
  //IMEM
  
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Decode
   $opcode[6:0] = $instr[6:0];
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = $instr[31:25];  
   $decode_bits[16:0] = {$funct7, $funct3, $opcode};
   
   $is_beq  = $decode_bits ==? 17'bxxxxxxx_000_1100011;
   $is_bne  = $decode_bits ==? 17'bxxxxxxx_001_1100011;
   $is_blt  = $decode_bits ==? 17'bxxxxxxx_100_1100011;
   $is_bge  = $decode_bits ==? 17'bxxxxxxx_101_1100011;
   $is_bltu = $decode_bits ==? 17'bxxxxxxx_110_1100011;
   $is_bgeu = $decode_bits ==? 17'bxxxxxxx_111_1100011;
   
   $is_add  = $decode_bits ==? 17'bx0xxxxx_000_1100011;
   $is_addi = $decode_bits ==? 17'bxxxxxxx_000_0010011;
   
   $op_bits[6:0] = $instr[6:0];
   
   $is_u_instr = ($op_bits ==? 7'b00101xx) ||
                 ($op_bits ==? 7'b01101xx);

   $is_i_instr = ($op_bits ==? 7'b00000xx) ||
                 ($op_bits ==? 7'b00001xx) ||
                 ($op_bits ==? 7'b00100xx) ||
                 ($op_bits ==? 7'b00110xx) ||
                 ($op_bits ==? 7'b11001xx);

   $is_b_instr = ($op_bits ==? 7'b11000xx);

   $is_j_instr = ($op_bits ==? 7'b11011xx);

   $is_s_instr = ($op_bits ==? 7'b01000xx) ||
                 ($op_bits ==? 7'b01001xx);

   $is_r_instr = ($op_bits ==? 7'b01011xx) ||
                 ($op_bits ==? 7'b01100xx) ||
                 ($op_bits ==? 7'b01110xx) ||
                 ($op_bits ==? 7'b10100xx);

   $rs2_valid = $is_r_instr ||
                $is_s_instr ||
                $is_b_instr;
   $rs1_valid = $is_r_instr ||
                $is_s_instr ||
                $is_b_instr ||
                $is_i_instr;
   $rd_valid = $is_r_instr ||
               $is_i_instr ||
               $is_u_instr ||
               $is_j_instr;
   $imm_valid = $is_r_instr ||
                $is_i_instr ||
                $is_u_instr ||
                $is_j_instr;
 
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[4:0] = $instr[11:7];
 
   $i_imm[31:0] = { {21{$instr[31]}}, $instr[30:20] };
   $s_imm[31:0] = { {21{$instr[31]}}, $instr[30:25], $instr[11:7] };
   $b_imm[31:0] = { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0};
   $u_imm[31:0] = { $instr[31:12], 12'b0 };
   $j_imm[31:0] = { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0};
   
   $imm[31:0] = $is_i_instr ? $i_imm :
                $is_s_instr ? $s_imm :
                $is_b_instr ? $b_imm :
                $is_u_instr ? $u_imm :
                $is_j_instr ? $j_imm :
                32'b0;

   m4+rf(32, 32, $reset, $rd_valid, $rd, $wr_data[31:0], $rs1_valid, $rs1, $rs1_data, $rs2_valid, $rs2, $rs2_data)

   $src1_value[31:0] = $rs1_data;
   $src2_value[31:0] = $rs2_data;
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;

   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct7 $imm_valid $imm)
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule



