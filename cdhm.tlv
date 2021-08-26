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
   //m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   //m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   //m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   //// Loop:
   //m4_asm(ADD, x14, x13, x14)           // Incremental summation
   //m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   //m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   //// Test result value in x14, and set x31 to reflect pass/fail.
   //m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45
   //m4_asm(BGE, x0, x0, 0)               // Done. Jump to itself (infinite loop).
   //
   //m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------
   m4_test_prog()


\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   // PC
   
   $next_pc[31:0] = $reset ? 0 :
                    $taken_br ? $br_tgt_pc :
                    $pc + 4;
   $pc[31:0] = >>1$next_pc;
  
  //IMEM
  
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Decode
   $opcode[6:0] = $instr[6:0];
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = $instr[31:25];  
   $decode_bits[16:0] = {$funct7, $funct3, $opcode};
   
   
   $is_lui   = $decode_bits ==? 17'bxxxxxxx_xxx_0110111;
   $is_auipc = $decode_bits ==? 17'bxxxxxxx_xxx_0010111;
   $is_jal   = $decode_bits ==? 17'bxxxxxxx_xxx_1101111;
   $is_jalr  = $decode_bits ==? 17'bxxxxxxx_000_1100111;

   $is_beq   = $decode_bits ==? 17'bxxxxxxx_000_1100011;
   $is_bne   = $decode_bits ==? 17'bxxxxxxx_001_1100011;
   $is_blt   = $decode_bits ==? 17'bxxxxxxx_100_1100011;
   $is_bge   = $decode_bits ==? 17'bxxxxxxx_101_1100011;
   $is_bltu  = $decode_bits ==? 17'bxxxxxxx_110_1100011;
   $is_bgeu  = $decode_bits ==? 17'bxxxxxxx_111_1100011;
   
   $is_addi  = $decode_bits ==? 17'bxxxxxxx_000_0010011;
   $is_slti  = $decode_bits ==? 17'bxxxxxxx_010_0010011;
   $is_sltiu = $decode_bits ==? 17'bxxxxxxx_011_0010011;
   $is_xori  = $decode_bits ==? 17'bxxxxxxx_100_0010011;
   $is_ori   = $decode_bits ==? 17'bxxxxxxx_110_0010011;
   $is_andi  = $decode_bits ==? 17'bxxxxxxx_111_0010011;
   $is_slli  = $decode_bits ==? 17'bx0xxxxx_001_0010011;
   $is_srli  = $decode_bits ==? 17'bx0xxxxx_101_0010011;
   $is_srai  = $decode_bits ==? 17'bx1xxxxx_101_0010011;

   $is_add   = $decode_bits ==? 17'bx0xxxxx_000_0110011;
   $is_sub   = $decode_bits ==? 17'bx1xxxxx_000_0110011;
   $is_sll   = $decode_bits ==? 17'bx0xxxxx_001_0110011;
   $is_slt   = $decode_bits ==? 17'bx0xxxxx_010_0110011;
   $is_sltu  = $decode_bits ==? 17'bx0xxxxx_011_0110011;
   $is_xor   = $decode_bits ==? 17'bx0xxxxx_100_0110011;
   $is_srl   = $decode_bits ==? 17'bx0xxxxx_101_0110011;
   $is_sra   = $decode_bits ==? 17'bx1xxxxx_101_0110011;
   $is_or    = $decode_bits ==? 17'bx0xxxxx_110_0110011;
   $is_and   = $decode_bits ==? 17'bx0xxxxx_111_0110011;

   $is_load  = $decode_bits ==? 17'bxxxxxxx_xxx_0000011;
   $is_store = $decode_bits ==? 17'bxxxxxxx_xxx_0100011;
   
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

   // Register file
   // Note that reads frox x0 always return 0
   m4+rf(32, 32, $reset, $rd_valid, $rd, $wr_data[31:0], $rs1_valid, $rs1, $rs1_data, $rs2_valid, $rs2, $rs2_data)

   $wr_data[31:0]    = $rd == 0 ? 0 : $result;
   $src1_value[31:0] = $rs1 == 0 ? 0 : $rs1_data;
   $src2_value[31:0] = $rs2 == 0 ? 0 : $rs2_data;
   
   // ALU
   $zext_src1_value[62:0] = { 31'b0, $src1_value};
   $sext_src1_value[62:0] = { {31{$src1_value[31]}}, $src1_value};
   $sra_result[62:0] = $sext_src1_value >> $src2_value[4:0];
   $srai_result[62:0] = $sext_src1_value >> $imm[4:0];
   
   $sltu_result[31:0] = { 31'b0, $src1_value < $src2_value};
   $sltiu_result[31:0] = { 31'b0, $src1_value < $imm};

   $result[31:0] = 
                   $is_andi ? $src1_value & $imm :
                   $is_ori  ? $src1_value | $imm :
                   $is_xori ? $src1_value ^ $imm :
                   $is_addi ? $src1_value + $imm :
                   $is_slli ? $src1_value << $imm[4:0] :
                   $is_srli ? $src1_value >> $imm[4:0] :
                   
                   $is_and  ? $src1_value & $src2_value :
                   $is_or   ? $src1_value | $src2_value :
                   $is_xor  ? $src1_value ^ $src2_value :
                   $is_add  ? $src1_value + $src2_value :
                   $is_sub  ? $src1_value - $src2_value :
                   $is_sll  ? $src1_value << $src2_value :
                   $is_srl  ? $src1_value >> $src2_value :
                   
                   $is_sltu  ? $sltu_result :
                   $is_sltiu ? $sltiu_result :
                   $is_lui   ? {$imm[31:12], 12'b0 } :
                   $is_auipc ? $pc + $imm :
                   $is_jal   ? $pc + 32'd4 :
                   $is_jalr  ? $pc + 32'd4 :
                   
                   $is_slt   ? ( $src1_value[31] == $src_value[31] ?
                                      $sltu_result :
                                      { 31'b0, $src1_value[31]} ) :
                   $is_slti  ? ( $src1_value[31] == $imm[31] ?
                                      $sltiu_result :
                                      { 31'b0, $src1_value[31]} ) :
                   $is_sra   ? $sra_result[31:0] :
                   $is_srai  ? $srai_result[31:0] :
                   
                              0;
   
   // Branching
   $sign_diff = $src1_value[31] != $src2_value[31];
   $taken_br = 
              ($is_beq   && ($src1_value == $src2_value)) ||
              ($is_bne   && ($src1_value != $src2_value)) ||
              ($is_blt   && (($src1_value < $src2_value)  ^ $sign_diff)) ||
              ($is_bge   && (($src1_value >= $src2_value) ^ $sign_diff)) ||
              ($is_bltu  && ($src1_value < $src2_value)) ||
              ($is_bgeu  && ($src1_value >= $src2_value));
   $br_tgt_pc[31:0] = $pc + $imm;
  
   // Assert these to end simulation (before Makerchip cycle limit).
   //*passed = 1'b0;
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;

   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct7 $imm_valid $imm)
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule






