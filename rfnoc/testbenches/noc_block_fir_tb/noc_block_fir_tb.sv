/* 
 * Copyright 2017 <+YOU OR YOUR COMPANY+>.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_fir_tb();
  `TEST_BENCH_INIT("noc_block_fir",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_fir, 0);

  localparam SPP = 128; // Samples per packet
  localparam NUM_ITERATIONS = 4;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;
    logic [15:0] real_val;
    logic [15:0] cplx_val;
    logic last;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_fir, RB_NOC_ID, readback);
    $display("Read fir NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_fir.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_fir,SC16,SPP);
    `RFNOC_CONNECT(noc_block_fir,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_fir, noc_block_fir.SR_TEST_REG_0, random_word);
    tb_streamer.read_user_reg(sid_noc_block_fir, 0, readback);
    $sformat(s, "User register 0 incorrect readback! Expected: %0d, Actual %0d", readback[31:0], random_word);
    `ASSERT_ERROR(readback[31:0] == random_word, s);
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_fir, noc_block_fir.SR_TEST_REG_1, random_word);
    tb_streamer.read_user_reg(sid_noc_block_fir, 1, readback);
    $sformat(s, "User register 1 incorrect readback! Expected: %0d, Actual %0d", readback[31:0], random_word);
    `ASSERT_ERROR(readback[31:0] == random_word, s);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    // fir's user code is a loopback, so we should receive
    // back exactly what we send
    `TEST_CASE_START("Test sequence");
//    fork
//      begin
//        cvita_payload_t send_payload;
//        for (int i = 0; i < SPP/2; i++) begin
//          send_payload.push_back(64'(i));
//        end
//        tb_streamer.send(send_payload);
//      end
      //begin
        //cvita_payload_t recv_payload;
        //cvita_metadata_t md;
        //logic [63:0] expected_value;
        //tb_streamer.recv(recv_payload,md);
       // for (int i = 0; i < SPP/2; i++) begin
       //   expected_value = i;
       //   $sformat(s, "Incorrect value received! Expected: %0d, Received: %0d", expected_value, recv_payload[i]);
       //   `ASSERT_ERROR(recv_payload[i] == expected_value, s);
       // end
      //end
    //join

   fork
    begin
      for (int n = 0; n < NUM_ITERATIONS; n++) begin
        for (int i = 0; i < (SPP/8); i++) begin
          tb_streamer.push_word({ 16'd32767,     16'd0},0);
          tb_streamer.push_word({ 16'd23170, 16'd23170},0);
          tb_streamer.push_word({     16'd0, 16'd32767},0);
          tb_streamer.push_word({-16'd23170, 16'd23170},0);
          tb_streamer.push_word({-16'd32767,     16'd0},0);
          tb_streamer.push_word({-16'd23170,-16'd23170},0);
          tb_streamer.push_word({     16'd0,-16'd32767},0);
          tb_streamer.push_word({ 16'd23170,-16'd23170},(i == (SPP/8)-1)); // Assert tlast on final word
        end
      end
    end
    begin
      for (int n = 0; n < NUM_ITERATIONS; n++) begin
        $display("Iteration");
        for (int k = 0; k < SPP; k++) begin
          
          tb_streamer.pull_word({real_val,cplx_val},last);
//          if (k == FFT_BIN) begin
            // Assert that for the special case of a 1/8th sample rate sine wave input, 
            // the real part of the corresponding 1/8th sample rate FFT bin should always be greater than 0 and
            // the complex part equal to 0.
//            `ASSERT_ERROR(real_val > 32'd0, "FFT bin real part is not greater than 0!");
//            `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
//          end else begin
            // Assert all other FFT bins should be 0 for both complex and real parts
//            `ASSERT_ERROR(real_val == 32'd0, "FFT bin real part is not 0!");
//            `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
//          end
          // Check packet size via tlast assertion
          if (k == SPP-1) begin
            $display("rec tlast");
            `ASSERT_ERROR(last == 1'b1, "Detected late tlast!");
          end else begin
            `ASSERT_ERROR(last == 1'b0, "Detected early tlast!");
          end
        end
      end
    end
    join

    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule