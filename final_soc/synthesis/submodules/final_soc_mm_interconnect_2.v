// final_soc_mm_interconnect_2.v

// This file was auto-generated from altera_mm_interconnect_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 18.1 625

`timescale 1 ps / 1 ps
module final_soc_mm_interconnect_2 (
		input  wire        clk_0_clk_clk,                              //                            clk_0_clk.clk
		input  wire        copy_dma_reset_reset_bridge_in_reset_reset, // copy_dma_reset_reset_bridge_in_reset.reset
		input  wire [27:0] copy_dma_write_master_address,              //                copy_dma_write_master.address
		output wire        copy_dma_write_master_waitrequest,          //                                     .waitrequest
		input  wire [3:0]  copy_dma_write_master_byteenable,           //                                     .byteenable
		input  wire        copy_dma_write_master_chipselect,           //                                     .chipselect
		input  wire        copy_dma_write_master_write,                //                                     .write
		input  wire [31:0] copy_dma_write_master_writedata,            //                                     .writedata
		output wire [16:0] frame_buffer_s1_address,                    //                      frame_buffer_s1.address
		output wire        frame_buffer_s1_write,                      //                                     .write
		input  wire [31:0] frame_buffer_s1_readdata,                   //                                     .readdata
		output wire [31:0] frame_buffer_s1_writedata,                  //                                     .writedata
		output wire [3:0]  frame_buffer_s1_byteenable,                 //                                     .byteenable
		output wire        frame_buffer_s1_chipselect,                 //                                     .chipselect
		output wire        frame_buffer_s1_clken                       //                                     .clken
	);

	wire         copy_dma_write_master_translator_avalon_universal_master_0_waitrequest;   // frame_buffer_s1_translator:uav_waitrequest -> copy_dma_write_master_translator:uav_waitrequest
	wire  [31:0] copy_dma_write_master_translator_avalon_universal_master_0_readdata;      // frame_buffer_s1_translator:uav_readdata -> copy_dma_write_master_translator:uav_readdata
	wire         copy_dma_write_master_translator_avalon_universal_master_0_debugaccess;   // copy_dma_write_master_translator:uav_debugaccess -> frame_buffer_s1_translator:uav_debugaccess
	wire  [27:0] copy_dma_write_master_translator_avalon_universal_master_0_address;       // copy_dma_write_master_translator:uav_address -> frame_buffer_s1_translator:uav_address
	wire         copy_dma_write_master_translator_avalon_universal_master_0_read;          // copy_dma_write_master_translator:uav_read -> frame_buffer_s1_translator:uav_read
	wire   [3:0] copy_dma_write_master_translator_avalon_universal_master_0_byteenable;    // copy_dma_write_master_translator:uav_byteenable -> frame_buffer_s1_translator:uav_byteenable
	wire         copy_dma_write_master_translator_avalon_universal_master_0_readdatavalid; // frame_buffer_s1_translator:uav_readdatavalid -> copy_dma_write_master_translator:uav_readdatavalid
	wire         copy_dma_write_master_translator_avalon_universal_master_0_lock;          // copy_dma_write_master_translator:uav_lock -> frame_buffer_s1_translator:uav_lock
	wire         copy_dma_write_master_translator_avalon_universal_master_0_write;         // copy_dma_write_master_translator:uav_write -> frame_buffer_s1_translator:uav_write
	wire  [31:0] copy_dma_write_master_translator_avalon_universal_master_0_writedata;     // copy_dma_write_master_translator:uav_writedata -> frame_buffer_s1_translator:uav_writedata
	wire   [2:0] copy_dma_write_master_translator_avalon_universal_master_0_burstcount;    // copy_dma_write_master_translator:uav_burstcount -> frame_buffer_s1_translator:uav_burstcount

	altera_merlin_master_translator #(
		.AV_ADDRESS_W                (28),
		.AV_DATA_W                   (32),
		.AV_BURSTCOUNT_W             (1),
		.AV_BYTEENABLE_W             (4),
		.UAV_ADDRESS_W               (28),
		.UAV_BURSTCOUNT_W            (3),
		.USE_READ                    (0),
		.USE_WRITE                   (1),
		.USE_BEGINBURSTTRANSFER      (0),
		.USE_BEGINTRANSFER           (0),
		.USE_CHIPSELECT              (1),
		.USE_BURSTCOUNT              (0),
		.USE_READDATAVALID           (0),
		.USE_WAITREQUEST             (1),
		.USE_READRESPONSE            (0),
		.USE_WRITERESPONSE           (0),
		.AV_SYMBOLS_PER_WORD         (4),
		.AV_ADDRESS_SYMBOLS          (1),
		.AV_BURSTCOUNT_SYMBOLS       (0),
		.AV_CONSTANT_BURST_BEHAVIOR  (0),
		.UAV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_LINEWRAPBURSTS           (0),
		.AV_REGISTERINCOMINGSIGNALS  (0)
	) copy_dma_write_master_translator (
		.clk                    (clk_0_clk_clk),                                                            //                       clk.clk
		.reset                  (copy_dma_reset_reset_bridge_in_reset_reset),                               //                     reset.reset
		.uav_address            (copy_dma_write_master_translator_avalon_universal_master_0_address),       // avalon_universal_master_0.address
		.uav_burstcount         (copy_dma_write_master_translator_avalon_universal_master_0_burstcount),    //                          .burstcount
		.uav_read               (copy_dma_write_master_translator_avalon_universal_master_0_read),          //                          .read
		.uav_write              (copy_dma_write_master_translator_avalon_universal_master_0_write),         //                          .write
		.uav_waitrequest        (copy_dma_write_master_translator_avalon_universal_master_0_waitrequest),   //                          .waitrequest
		.uav_readdatavalid      (copy_dma_write_master_translator_avalon_universal_master_0_readdatavalid), //                          .readdatavalid
		.uav_byteenable         (copy_dma_write_master_translator_avalon_universal_master_0_byteenable),    //                          .byteenable
		.uav_readdata           (copy_dma_write_master_translator_avalon_universal_master_0_readdata),      //                          .readdata
		.uav_writedata          (copy_dma_write_master_translator_avalon_universal_master_0_writedata),     //                          .writedata
		.uav_lock               (copy_dma_write_master_translator_avalon_universal_master_0_lock),          //                          .lock
		.uav_debugaccess        (copy_dma_write_master_translator_avalon_universal_master_0_debugaccess),   //                          .debugaccess
		.av_address             (copy_dma_write_master_address),                                            //      avalon_anti_master_0.address
		.av_waitrequest         (copy_dma_write_master_waitrequest),                                        //                          .waitrequest
		.av_byteenable          (copy_dma_write_master_byteenable),                                         //                          .byteenable
		.av_chipselect          (copy_dma_write_master_chipselect),                                         //                          .chipselect
		.av_write               (copy_dma_write_master_write),                                              //                          .write
		.av_writedata           (copy_dma_write_master_writedata),                                          //                          .writedata
		.av_burstcount          (1'b1),                                                                     //               (terminated)
		.av_beginbursttransfer  (1'b0),                                                                     //               (terminated)
		.av_begintransfer       (1'b0),                                                                     //               (terminated)
		.av_read                (1'b0),                                                                     //               (terminated)
		.av_readdata            (),                                                                         //               (terminated)
		.av_readdatavalid       (),                                                                         //               (terminated)
		.av_lock                (1'b0),                                                                     //               (terminated)
		.av_debugaccess         (1'b0),                                                                     //               (terminated)
		.uav_clken              (),                                                                         //               (terminated)
		.av_clken               (1'b1),                                                                     //               (terminated)
		.uav_response           (2'b00),                                                                    //               (terminated)
		.av_response            (),                                                                         //               (terminated)
		.uav_writeresponsevalid (1'b0),                                                                     //               (terminated)
		.av_writeresponsevalid  ()                                                                          //               (terminated)
	);

	altera_merlin_slave_translator #(
		.AV_ADDRESS_W                   (17),
		.AV_DATA_W                      (32),
		.UAV_DATA_W                     (32),
		.AV_BURSTCOUNT_W                (1),
		.AV_BYTEENABLE_W                (4),
		.UAV_BYTEENABLE_W               (4),
		.UAV_ADDRESS_W                  (28),
		.UAV_BURSTCOUNT_W               (3),
		.AV_READLATENCY                 (1),
		.USE_READDATAVALID              (0),
		.USE_WAITREQUEST                (0),
		.USE_UAV_CLKEN                  (0),
		.USE_READRESPONSE               (0),
		.USE_WRITERESPONSE              (0),
		.AV_SYMBOLS_PER_WORD            (4),
		.AV_ADDRESS_SYMBOLS             (0),
		.AV_BURSTCOUNT_SYMBOLS          (0),
		.AV_CONSTANT_BURST_BEHAVIOR     (0),
		.UAV_CONSTANT_BURST_BEHAVIOR    (0),
		.AV_REQUIRE_UNALIGNED_ADDRESSES (0),
		.CHIPSELECT_THROUGH_READLATENCY (0),
		.AV_READ_WAIT_CYCLES            (0),
		.AV_WRITE_WAIT_CYCLES           (0),
		.AV_SETUP_WAIT_CYCLES           (0),
		.AV_DATA_HOLD_CYCLES            (0)
	) frame_buffer_s1_translator (
		.clk                    (clk_0_clk_clk),                                                            //                      clk.clk
		.reset                  (copy_dma_reset_reset_bridge_in_reset_reset),                               //                    reset.reset
		.uav_address            (copy_dma_write_master_translator_avalon_universal_master_0_address),       // avalon_universal_slave_0.address
		.uav_burstcount         (copy_dma_write_master_translator_avalon_universal_master_0_burstcount),    //                         .burstcount
		.uav_read               (copy_dma_write_master_translator_avalon_universal_master_0_read),          //                         .read
		.uav_write              (copy_dma_write_master_translator_avalon_universal_master_0_write),         //                         .write
		.uav_waitrequest        (copy_dma_write_master_translator_avalon_universal_master_0_waitrequest),   //                         .waitrequest
		.uav_readdatavalid      (copy_dma_write_master_translator_avalon_universal_master_0_readdatavalid), //                         .readdatavalid
		.uav_byteenable         (copy_dma_write_master_translator_avalon_universal_master_0_byteenable),    //                         .byteenable
		.uav_readdata           (copy_dma_write_master_translator_avalon_universal_master_0_readdata),      //                         .readdata
		.uav_writedata          (copy_dma_write_master_translator_avalon_universal_master_0_writedata),     //                         .writedata
		.uav_lock               (copy_dma_write_master_translator_avalon_universal_master_0_lock),          //                         .lock
		.uav_debugaccess        (copy_dma_write_master_translator_avalon_universal_master_0_debugaccess),   //                         .debugaccess
		.av_address             (frame_buffer_s1_address),                                                  //      avalon_anti_slave_0.address
		.av_write               (frame_buffer_s1_write),                                                    //                         .write
		.av_readdata            (frame_buffer_s1_readdata),                                                 //                         .readdata
		.av_writedata           (frame_buffer_s1_writedata),                                                //                         .writedata
		.av_byteenable          (frame_buffer_s1_byteenable),                                               //                         .byteenable
		.av_chipselect          (frame_buffer_s1_chipselect),                                               //                         .chipselect
		.av_clken               (frame_buffer_s1_clken),                                                    //                         .clken
		.av_read                (),                                                                         //              (terminated)
		.av_begintransfer       (),                                                                         //              (terminated)
		.av_beginbursttransfer  (),                                                                         //              (terminated)
		.av_burstcount          (),                                                                         //              (terminated)
		.av_readdatavalid       (1'b0),                                                                     //              (terminated)
		.av_waitrequest         (1'b0),                                                                     //              (terminated)
		.av_writebyteenable     (),                                                                         //              (terminated)
		.av_lock                (),                                                                         //              (terminated)
		.uav_clken              (1'b0),                                                                     //              (terminated)
		.av_debugaccess         (),                                                                         //              (terminated)
		.av_outputenable        (),                                                                         //              (terminated)
		.uav_response           (),                                                                         //              (terminated)
		.av_response            (2'b00),                                                                    //              (terminated)
		.uav_writeresponsevalid (),                                                                         //              (terminated)
		.av_writeresponsevalid  (1'b0)                                                                      //              (terminated)
	);

endmodule
