/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
    13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_vga_interface (
    // Avalon Clock Input
    input logic CLK,
    input logic        VGA_CLK_clk,      //VGA Clock
    output  logic      CLK_OUT_clk,      // Exported VGA Clock
    
    // Avalon Reset Input
    input logic RESET,
    
    // Avalon-MM Slave Signals
    input  logic VGA_READ,                    // Avalon-MM Read
    input  logic VGA_WRITE,                    // Avalon-MM Write
    input  logic VGA_CS,                        // Avalon-MM Chip Select
    input  logic [3:0] VGA_BYTE_EN,        // Avalon-MM Byte Enable
    input  logic [1:0] VGA_ADDR,            // Avalon-MM Address
    input  logic [31:0] VGA_WRITEDATA,    // Avalon-MM Write Data
    output logic [31:0] VGA_READDATA,    // Avalon-MM Read Data

    // Avalon-MM Master Signals
    output logic [31:0] VGA_MASTER_ADDR,
    output logic VGA_MASTER_READ,
    input  logic [31:0] VGA_MASTER_READDATA,
    output logic VGA_MASTER_CS,
    input  logic VGA_MASTER_WAIT_REQUEST,
    input  logic VGA_MASTER_READDATAVALID, 
    
    // Exported Conduits
    output logic [7:0]  VGA_R,        //VGA Red
                        VGA_G,        //VGA Green
                        VGA_B,        //VGA Blue
    output logic [7:0]  DEBUG,
    output logic        VGA_SYNC_N,   //VGA Sync signal
                        VGA_BLANK_N,  //VGA Blank signal
                        VGA_VS,       //VGA virtical sync signal
                        VGA_HS       //VGA horizontal sync signal

);

logic [9:0] DrawX, DrawY;

VGA_controller vga_cont(.Clk(CLK), .Reset(RESET), .VGA_HS, .VGA_VS,
    .VGA_CLK(VGA_CLK_clk), .VGA_BLANK_N, .VGA_SYNC_N, .DrawX, .DrawY);

VGA_mapper map(.CLK, .VGA_CLK(VGA_CLK_clk), .RESET, .VGA_ADDR, .VGA_WRITEDATA, 
    .VGA_WRITE, .VGA_CS,
    .VGA_BYTE_EN, .VGA_BLANK_N, .VGA_R, .VGA_G, .VGA_B, 
    .VGA_READ, .VGA_READDATA, .VGA_MASTER_ADDR, .VGA_MASTER_READ,
    .VGA_MASTER_READDATA, .VGA_MASTER_CS, .VGA_MASTER_WAIT_REQUEST, 
    .DrawX, .DrawY, .DEBUG, .VGA_MASTER_READDATAVALID);

assign CLK_OUT_clk = VGA_CLK_clk;

// always_ff @ (posedge CLK) begin
//     if(VGA_CS & VGA_WRITE & VGA_BYTE_EN)
//         DEBUG <= VGA_ADDR[10:4];
// end

endmodule
