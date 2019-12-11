
// Actual implementation of the interface to save compile time
// Implements the connections to the avalob bus. THe avalon
// master signals are used to write to memory locations
// such as the SDRAM and onchip memory. The avalon slave
// is used for the nios to send data to the gpu to render.
// Control signals such as wait request are used for syncronization
module gpu_core(
    input  logic CLK_clk,
    input  logic RESET_reset,
    // Ava lon slave signals
    input  logic GPU_SLAVE_read,
    output logic [31:0] GPU_SLAVE_readdata,
    input  logic GPU_SLAVE_write,
    input  logic [31:0] GPU_SLAVE_writedata,
    input  logic [31:0] GPU_SLAVE_address,
    input  logic GPU_SLAVE_chipselect,
    // avalon master signals
    output logic [31:0] GPU_MASTER_address,
    //output logic [18:0] GPU_MASTER_burstcount,
    output logic GPU_MASTER_read,
    input  logic [31:0] GPU_MASTER_readdata,
    output logic GPU_MASTER_chipselect,
    input  logic GPU_MASTER_readdatavalid,
    input  logic GPU_MASTER_writeresponsevalid,
    output logic GPU_MASTER_write,
    output logic [31:0] GPU_MASTER_writedata,
    input  logic [1:0] GPU_MASTER_response,
    input  logic GPU_MASTER_waitrequest
);

// Memory mapped registers
int frame_pointer, frame_pointer_next;
int z_buffer_pointer, z_buffer_pointer_next;
logic start, start_next;
logic done, done_next;
int scale, scale_next;
int x, x_next;
int y, y_next;
int z, z_next;
int mode, mode_next;
int block_id, block_id_next;

// rasterization variables
logic rast_start;
logic rast_cont;
byte rast_rgb[3];
int rast_xyz[3];
logic rast_done;
logic rast_ready;

int prj[4][4];
int prj_raw[4][4];
int cam[4][4];

int tv1[3] = '{100 * (1<<8), 100 * (1<<8), 0};
int tv2[3] = '{50 * (1<<8), 300 * (1<<8), 0};
int tv3[3] = '{250 * (1<<8), 200 * (1<<8), 0};

int x_axis[3];
int y_axis[3];
int z_axis[3];
int x_axis_next[3];
int y_axis_next[3];
int z_axis_next[3];
int cam_pos[3];
int cam_pos_next[3];
int trans[3];
int trans_next[3];

int z_clip, z_clip_next;

// Matrix calculations
gen_prj_mat m1(320 * (1<<8), 240 * (1<<8), 5 * (1<<8), 200 * (1<<8), prj_raw);
gen_camera_mat m2(x_axis, y_axis, z_axis, cam_pos, trans, cam);

mat_mat_mul m3(cam, prj_raw, prj);

rast_cube cube_renderer(CLK_clk, RESET_reset, rast_start, rast_cont, 
    scale, '{x, y, z}, block_id, prj, z_clip, rast_ready, rast_rgb, rast_xyz, rast_done);


int clear_counter, clear_counter_next;

int read_addr;

// Overwall state
enum logic [5:0] {
    IDLE,
    RUNNING,
    DONE
} state = IDLE, next_state;

// Reading/Writing state
enum logic [5:0] {
    Z_READ_SLEEP,
    Z_READ,
    RGB_WRITE_SLEEP,
    RGB_WRITE,
    Z_WRITE_SLEEP,
    Z_WRITE
} rast_state = Z_READ_SLEEP, rast_next_state;

always_comb begin

    //default slave
    GPU_SLAVE_readdata = 32'hzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    //default master
    GPU_MASTER_address = 32'hzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    GPU_MASTER_read = 0;
    GPU_MASTER_chipselect = 0;
    GPU_MASTER_write = 0;
    GPU_MASTER_writedata = 32'hzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    //GPU_MASTER_burstcount = 19'hzzzz;
    //'next' defaults
    frame_pointer_next = frame_pointer;
    rast_next_state = rast_state;
    next_state = state;
    start_next = start;
    done_next = done;
    z_buffer_pointer_next = z_buffer_pointer;
    scale_next = scale;
    x_next = x;
    y_next = y;
    z_next = z;
    clear_counter_next = clear_counter;
    mode_next = mode;
    block_id_next = block_id;
    x_axis_next = x_axis;
    y_axis_next = y_axis;
    z_axis_next = z_axis;
    cam_pos_next = cam_pos;
    z_clip_next = z_clip;

    // rast defaults
    rast_start = 0;
    rast_cont = 0;
    
    read_addr = 32'hxxxxxxxxxxxxxxxx;

    // Software-Hardware interface 
    //
    // Slave
    if(GPU_SLAVE_chipselect) begin
        // Slave Reads
        if(GPU_SLAVE_read) begin
            case(GPU_SLAVE_address)
                0: GPU_SLAVE_readdata = frame_pointer;
                1: GPU_SLAVE_readdata = start;
                2: GPU_SLAVE_readdata = done;
                3: GPU_SLAVE_readdata = z_buffer_pointer;
                4: GPU_SLAVE_readdata = scale;
                5: GPU_SLAVE_readdata = x;
                6: GPU_SLAVE_readdata = y;
                7: GPU_SLAVE_readdata = z;
                8: GPU_SLAVE_readdata = mode;
                9: GPU_SLAVE_readdata = block_id;
                10: GPU_SLAVE_readdata = x_axis[0];
                11: GPU_SLAVE_readdata = x_axis[1];
                12: GPU_SLAVE_readdata = x_axis[2];
                13: GPU_SLAVE_readdata = y_axis[0];
                14: GPU_SLAVE_readdata = y_axis[1];
                15: GPU_SLAVE_readdata = y_axis[2];
                16: GPU_SLAVE_readdata = z_axis[0];
                17: GPU_SLAVE_readdata = z_axis[1];
                18: GPU_SLAVE_readdata = z_axis[2];
                19: GPU_SLAVE_readdata = cam_pos[0];
                20: GPU_SLAVE_readdata = cam_pos[1];
                21: GPU_SLAVE_readdata = cam_pos[2];
                22: GPU_SLAVE_readdata = trans[0];
                23: GPU_SLAVE_readdata = trans[1];
                24: GPU_SLAVE_readdata = trans[2];
                25: GPU_SLAVE_readdata = z_clip;
            endcase
        end

        // Slave Writes
        if(GPU_SLAVE_write) begin
            case(GPU_SLAVE_address)
                0: frame_pointer_next    = GPU_SLAVE_writedata;
                1: start_next            = GPU_SLAVE_writedata;
                2: done_next             = GPU_SLAVE_writedata;
                3: z_buffer_pointer_next = GPU_SLAVE_writedata;
                4: scale_next            = GPU_SLAVE_writedata;
                5: x_next                = GPU_SLAVE_writedata;
                6: y_next                = GPU_SLAVE_writedata;
                7: z_next                = GPU_SLAVE_writedata;
                8: mode_next             = GPU_SLAVE_writedata;
                9: block_id_next         = GPU_SLAVE_writedata;
                10: x_axis_next[0]       = GPU_SLAVE_writedata;
                11: x_axis_next[1]       = GPU_SLAVE_writedata;
                12: x_axis_next[2]       = GPU_SLAVE_writedata;
                13: y_axis_next[0]       = GPU_SLAVE_writedata;
                14: y_axis_next[1]       = GPU_SLAVE_writedata;
                15: y_axis_next[2]       = GPU_SLAVE_writedata;
                16: z_axis_next[0]       = GPU_SLAVE_writedata;
                17: z_axis_next[1]       = GPU_SLAVE_writedata;
                18: z_axis_next[2]       = GPU_SLAVE_writedata;
                19: cam_pos_next[0]      = GPU_SLAVE_writedata;
                20: cam_pos_next[1]      = GPU_SLAVE_writedata;
                21: cam_pos_next[2]      = GPU_SLAVE_writedata;
                22: trans_next[0]        = GPU_SLAVE_writedata;
                23: trans_next[1]        = GPU_SLAVE_writedata;
                24: trans_next[2]        = GPU_SLAVE_writedata;
                25: z_clip_next          = GPU_SLAVE_writedata;
            endcase
        end

    end
    
    // Memory read/write statemachine next states
    if(state == RUNNING) begin
        if(mode == 1) begin // Cube rendering
            if(rast_ready) begin
                read_addr = (((rast_xyz[1]/(1<<8))*320) + (rast_xyz[0]/(1<<8)))*4;

                GPU_MASTER_chipselect = 1;
                if((rast_state == Z_READ) || (rast_state == Z_READ_SLEEP)) begin // Check depth buffer and frame bounds
                    GPU_MASTER_read = 1;
                    GPU_MASTER_address = z_buffer_pointer + read_addr;

                    if(GPU_MASTER_readdatavalid & ~GPU_MASTER_waitrequest) begin

                        if(rast_state == Z_READ_SLEEP) begin
                            rast_next_state = Z_READ;
                        end else begin
                            // Skip off screen pixels and pure yellow pixels
                            if((GPU_MASTER_readdata > rast_xyz[2]) & (rast_xyz[0] > 0) & (rast_xyz[0] < (320*(1<<8))) & (rast_xyz[1] > 0) & (rast_xyz[1] < (240*(1<<8))) & ((rast_rgb[0] != 8'd255) || (rast_rgb[1] != 8'd255) || (rast_rgb[2] != 8'd0) )) begin
                                rast_next_state = RGB_WRITE_SLEEP;
                            end else begin
                                rast_cont = 1; // Skip pixel
                                rast_next_state = Z_READ_SLEEP;
                            end
                        end
                    end

                end else if((rast_state == RGB_WRITE) || (rast_state == RGB_WRITE_SLEEP) ) begin // Write rgb to frame buffer
                    GPU_MASTER_write = 1;
                    GPU_MASTER_writedata = {8'h00, rast_rgb[0], rast_rgb[1], rast_rgb[2]};
                    GPU_MASTER_address = frame_pointer + read_addr;
                    if(GPU_MASTER_writeresponsevalid & ~GPU_MASTER_waitrequest) begin
                        if(rast_state == RGB_WRITE_SLEEP)
                            rast_next_state = RGB_WRITE;
                        else
                            rast_next_state = Z_WRITE_SLEEP;
                    end

                end else if((rast_state == Z_WRITE) || (rast_state == Z_WRITE_SLEEP)) begin // Write z to depth buffer
                    GPU_MASTER_write = 1;
                    GPU_MASTER_writedata = rast_xyz[2];
                    GPU_MASTER_address = z_buffer_pointer + read_addr;
                    if(GPU_MASTER_writeresponsevalid & ~GPU_MASTER_waitrequest) begin
                        if(rast_state == Z_WRITE_SLEEP) begin
                            rast_next_state = Z_WRITE;
                        end else begin
                            rast_next_state = Z_READ_SLEEP;
                            rast_cont = 1;
                        end
                    end
                end
            end
        end else if((mode == 2) | (mode == 3)) begin // Clearing
            GPU_MASTER_chipselect = 1;
            GPU_MASTER_write = 1;
            if(mode == 2) begin // Clear frame buffer to 87CEEB
                GPU_MASTER_writedata = {8'h00, 8'h87, 8'hCE, 8'hEB};
                GPU_MASTER_address = frame_pointer + clear_counter*4;
            end else begin // Clear depth buffer
                GPU_MASTER_writedata = {8'h7F, 8'hFF, 8'hFF, 8'hFF};
                GPU_MASTER_address = z_buffer_pointer + clear_counter*4;
            end
            if(~GPU_MASTER_waitrequest)
                clear_counter_next = clear_counter + 1;
        end
    end

    // Next state
    unique case(state)
        IDLE: begin
            if(start) begin
                next_state = RUNNING;
                if(mode == 1)
                    rast_start = 1; //rast
                else if((mode == 2) | (mode == 3))
                    clear_counter_next = 0; // clear
                else
                    next_state = DONE;
            end
            else
                next_state = IDLE;
        end
        RUNNING: begin
            if(mode == 1) begin //rast
                rast_start = 1;
                if(rast_done) begin 
                    done_next = 1; 
                    next_state = DONE;
                end
            end else if((mode == 2) | (mode == 3)) begin //clear
                if(clear_counter > (320 * 240)) begin
                    next_state = DONE;
                    done_next = 1;
                end
                else
                    next_state = RUNNING;
            end
            else
                next_state = RUNNING;
        end
        DONE: begin
            if(~start)
                next_state = IDLE;
            else
                next_state = DONE;
        end
        default:
            next_state = state;
    endcase
end

// D flip flops
always_ff @ (posedge CLK_clk) begin
    if(RESET_reset) begin
        frame_pointer <= 0;
        start <= 0;
        done <= 0;
        state <= IDLE;
        rast_state <= Z_READ;
        z_buffer_pointer <= 0;
        scale <= 0;
        x <= 0;
        y <= 0;
        z <= 0;
        clear_counter <= 0;
        mode <= 0;
        block_id <= 0;
        x_axis <= '{(1<<8), 0, 0};
        y_axis <= '{0, (1<<8), 0};
        z_axis <= '{0, 0, (1<<8)};
        cam_pos <= '{0, 0, 0};
        trans <= '{0, 0, 0};
        z_clip <= 0;
    end else begin
        frame_pointer <= frame_pointer_next;
        start <= start_next;
        done <= done_next;
        state <= next_state;
        rast_state <= rast_next_state;
        z_buffer_pointer <= z_buffer_pointer_next;
        scale <= scale_next;
        x <= x_next;
        y <= y_next;
        z <= z_next;
        clear_counter <= clear_counter_next;
        mode <= mode_next;
        block_id <= block_id_next;
        x_axis <= x_axis_next;
        y_axis <= y_axis_next;
        z_axis <= z_axis_next;
        cam_pos <= cam_pos_next;
        trans <= trans_next;
        z_clip <= z_clip_next;
    end
end

endmodule

// Rasterizes a cube in 3D
//
// Start initializes and stats all calculations
// cont signals the module to produce a new pixel
// scale, pos, and blockID define the block to be rendered
// prj and zclip define the projection matrix and the near z clipping axis to
// render
// Rast ready signals a new pixel is ready
//
// RGB and XYZ are produced every rast_ready
// done is high when the cube is done readering
//
// Splits the cube into 12 triangles are draws them all
module rast_cube(
    input logic CLK,
    input logic RESET,
    input logic start,
    input logic cont,
    input int scale,
    input int pos[3],
    input int block_id,
    input int prj[4][4],
    input int z_clip,
    output logic rast_ready,
    output byte rgb[3],
    output int xyz[3],
    output logic done
);

// State for rendering a cube and its 12 faces
enum logic [5:0] {
    IDLE,
    PROJECTING_1,
    PROJECTING_2,
    PROJECTING_3,
    PROJECTING_4,
    TOP_1, TOP_2,
    BOT_1, BOT_2,
    FRONT_1, FRONT_2,
    LEFT_1, LEFT_2,
    RIGHT_1, RIGHT_2,
    BACK_1, BACK_2,
    DONE
} state = IDLE, next_state;



//0 -> back_top_left
//1 -> back_top_right
//2 -> back_bot_left
//3 -> back_bot_right
//4 -> front_top_left
//5 -> front_top_right
//6 -> front_bot_left
//7 -> front_bot_right
int verticies[8][3];
int face_uv[6][4][4];
int face_uv_next[6][4][4];

int test_scale = 16 * (1<<8);
int test_vec[3] = '{15 * (1<<8), 0 * (1<<8) ,  -70* (1<<8)};

project_cube projector(CLK, RESET, scale, pos, prj, verticies);

// Rasterization variables
logic rast_done;
logic rast_start = 0;
int v1[3];
int v2[3];
int v3[3];
int tv1[4] = '{0, 0, 0, 0};
int tv2[4] = '{0, 0, 0, 0};
int tv3[4] = '{0, 0, 0, 0};

rast_triangle triangle_renderer(CLK, RESET, rast_start, cont,
    tv3, tv2, tv1, rast_ready, rgb, xyz, rast_done);

int offset;

always_comb begin
    next_state = state;
    rast_start = 0;
    tv1 = '{0, 0, 0, 0};
    tv2 = '{0, 0, 0, 0};
    tv3 = '{0, 0, 0, 0};
    done = 0;

    offset = block_id * 32;

    // Append vertex colors
    // vertex 0 => back_top_left
    // vertex 1 => back_top_right
    // vertex 2 => back_bot_left
    // vertex 3 => back_bot_right
    // vertex 4 => front_top_left
    // vertex 5 => front_top_right
    // vertex 6 => front_bot_left
    // vertex 7 => front_bot_right
    //
    // face 0 => top
    // face 1 => bottom
    // face 2 => back
    // face 3 => left
    // face 4 => right
    // face 5 => front
    if(state == PROJECTING_4) begin
    // Group into faces and append UV
    //
    // top
    face_uv_next[0][0] = '{verticies[0][0], verticies[0][1], verticies[0][2], {16'd00 + offset, 16'd00}}; // back_top_left
    face_uv_next[0][1] = '{verticies[1][0], verticies[1][1], verticies[1][2], {16'd15 + offset, 16'd00}}; // back_top_right
    face_uv_next[0][2] = '{verticies[4][0], verticies[4][1], verticies[4][2], {16'd00 + offset, 16'd15}}; // front_top_left
    face_uv_next[0][3] = '{verticies[5][0], verticies[5][1], verticies[5][2], {16'd15 + offset, 16'd15}}; // front_top_right
    // bot
    face_uv_next[1][0] = '{verticies[2][0], verticies[2][1], verticies[2][2], {16'd16 + offset, 16'd00}}; // back_bot_left
    face_uv_next[1][1] = '{verticies[3][0], verticies[3][1], verticies[3][2], {16'd31 + offset, 16'd00}}; // back_bot_right
    face_uv_next[1][2] = '{verticies[6][0], verticies[6][1], verticies[6][2], {16'd16 + offset, 16'd15}}; // front_bot_left
    face_uv_next[1][3] = '{verticies[7][0], verticies[7][1], verticies[7][2], {16'd31 + offset, 16'd15}}; // front_bot_right
    // back
    face_uv_next[2][0] = '{verticies[0][0], verticies[0][1], verticies[0][2], {16'd16 + offset, 16'd16}}; // back_top_left
    face_uv_next[2][1] = '{verticies[1][0], verticies[1][1], verticies[1][2], {16'd31 + offset, 16'd16}}; // back_top_right
    face_uv_next[2][2] = '{verticies[2][0], verticies[2][1], verticies[2][2], {16'd16 + offset, 16'd31}}; // back_bot_left
    face_uv_next[2][3] = '{verticies[3][0], verticies[3][1], verticies[3][2], {16'd31 + offset, 16'd31}}; // back_bot_right
    // left
    face_uv_next[3][0] = '{verticies[0][0], verticies[0][1], verticies[0][2], {16'd16 + offset, 16'd16}}; // back_top_left
    face_uv_next[3][1] = '{verticies[2][0], verticies[2][1], verticies[2][2], {16'd16 + offset, 16'd31}}; // back_bot_left
    face_uv_next[3][2] = '{verticies[4][0], verticies[4][1], verticies[4][2], {16'd31 + offset, 16'd16}}; // front_top_left
    face_uv_next[3][3] = '{verticies[6][0], verticies[6][1], verticies[6][2], {16'd31 + offset, 16'd31}}; // front_bot_left
    // right
    face_uv_next[4][0] = '{verticies[1][0], verticies[1][1], verticies[1][2], {16'd16 + offset, 16'd16}}; // back_top_right
    face_uv_next[4][1] = '{verticies[3][0], verticies[3][1], verticies[3][2], {16'd16 + offset, 16'd31}}; // back_bot_right
    face_uv_next[4][2] = '{verticies[5][0], verticies[5][1], verticies[5][2], {16'd31 + offset, 16'd16}}; // front_top_right
    face_uv_next[4][3] = '{verticies[7][0], verticies[7][1], verticies[7][2], {16'd31 + offset, 16'd31}}; // front_bot_right
    // front
    face_uv_next[5][0] = '{verticies[4][0], verticies[4][1], verticies[4][2], {16'd00 + offset, 16'd16}}; // front_top_left
    face_uv_next[5][1] = '{verticies[5][0], verticies[5][1], verticies[5][2], {16'd15 + offset, 16'd16}}; // front_top_right
    face_uv_next[5][2] = '{verticies[6][0], verticies[6][1], verticies[6][2], {16'd00 + offset, 16'd31}}; // front_bot_left
    face_uv_next[5][3] = '{verticies[7][0], verticies[7][1], verticies[7][2], {16'd15 + offset, 16'd31}}; // front_bot_right

    end else begin
        face_uv_next = face_uv;
    end


    // state logic
    unique case(state)
        IDLE: begin
            if(start) begin
                next_state = PROJECTING_1;
            end
        end
        PROJECTING_1: begin
            next_state = PROJECTING_2;
        end
        PROJECTING_2: begin
            next_state = PROJECTING_3;
        end
        PROJECTING_3: begin
            next_state = PROJECTING_4;
        end
        PROJECTING_4: begin
            // back_top_left.x and front_bot_right.x are < 0
            if((verticies[0][0] < 30) || (verticies[7][0] < 30)) // TODO 
                next_state = DONE;
            // back_top_left.x and front_bot_right.x are > screen_width
            else if((verticies[0][0] > (320 || (1<<8))) & (verticies[7][0] > (320 * (1<<8))))
                next_state = DONE;
            else if((verticies[0][1] < 30) || (verticies[7][1] < 30)) // TODO 
                next_state = DONE;
            // back_top_left.x and front_bot_right.x are > screen_width
            else if((verticies[0][1] > (240 * (1<<8))) || (verticies[7][1] > (240 * (1<<8))))
                next_state = DONE;
            else if(verticies[0][2] < (z_clip))
                next_state = DONE;
            else
                next_state = TOP_1;
        end
        TOP_1: begin
            rast_start = 1;
            tv3 = face_uv[0][0];
            tv2 = face_uv[0][1];
            tv1 = face_uv[0][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = TOP_2;
            end
        end
        TOP_2: begin
            rast_start = 1;
            tv1 = face_uv[0][0];
            tv2 = face_uv[0][2];
            tv3 = face_uv[0][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = BOT_1;
            end
        end
        BOT_1: begin 
            rast_start = 1;
            tv1 = face_uv[1][0];
            tv2 = face_uv[1][1];
            tv3 = face_uv[1][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = BOT_2;
            end
        end
        BOT_2: begin
            rast_start = 1;
            tv3 = face_uv[1][0];
            tv2 = face_uv[1][2];
            tv1 = face_uv[1][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = BACK_1; 
            end
        end
        BACK_1: begin 
            rast_start = 1;
            tv1 = face_uv[2][0];
            tv2 = face_uv[2][1];
            tv3 = face_uv[2][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = BACK_2;
            end
        end
        BACK_2: begin
            rast_start = 1;
            tv3 = face_uv[2][0];
            tv2 = face_uv[2][2];
            tv1 = face_uv[2][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = LEFT_1;  
            end
        end
        LEFT_1: begin
            rast_start = 1;
            tv1 = face_uv[3][0];
            tv2 = face_uv[3][1];
            tv3 = face_uv[3][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = LEFT_2;
            end
        end
        LEFT_2: begin
            rast_start = 1;
            tv3 = face_uv[3][0];
            tv2 = face_uv[3][2];
            tv1 = face_uv[3][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = RIGHT_1;
            end
        end
        RIGHT_1: begin 
            rast_start = 1;
            tv3 = face_uv[4][0];
            tv2 = face_uv[4][1];
            tv1 = face_uv[4][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = RIGHT_2;
            end
        end
        RIGHT_2: begin
            rast_start = 1;
            tv1 = face_uv[4][0];
            tv2 = face_uv[4][2];
            tv3 = face_uv[4][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = FRONT_1;
            end
        end
        FRONT_1: begin
            rast_start = 1;
            tv3 = face_uv[5][0];
            tv2 = face_uv[5][1];
            tv1 = face_uv[5][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = FRONT_2;
            end
        end
        FRONT_2: begin
            rast_start = 1;
            tv1 = face_uv[5][0];
            tv2 = face_uv[5][2];
            tv3 = face_uv[5][3];
            if(rast_done) begin
                rast_start = 0;
                next_state = DONE;
            end
        end
        DONE: begin
            done = 1;
            next_state = IDLE;
        end
    endcase
end

// D flip flop
always_ff @ (posedge CLK) begin
    if(RESET) begin
        state <= IDLE;
    end else begin
        state <= next_state;
        face_uv <= face_uv_next;
    end
end

endmodule

// Projects a cube into 3d by generating the 8 verticies and multiplying them
// by the project matrix
module project_cube(
    input logic CLK,
    input logic RESET,
    input int scale,
    input int pos[3],
    input int prj[4][4],
    output int out[8][3]
);


// 8 vertex locations
int back_top_left[4];
int back_top_right[4];
int back_bot_left[4];
int back_bot_right[4];
int front_top_left[4];
int front_top_right[4];
int front_bot_left[4];
int front_bot_right[4];

int all_verticies[8][4];
int prj_vert[8][4];
int prj_vert_next[8][4];
int screen_verts[8][3];
int screen_verts_next[8][3];

assign all_verticies = '{back_top_left, back_top_right, back_bot_left, back_bot_right, front_top_left, front_top_right, front_bot_left, front_bot_right};

// Matrix multiplcation and view port transform
mat_vec_mul projectors[8](.m1(prj), .vec(all_verticies), .out(prj_vert_next));
viewport_trans view_transformers[8](.CLK, .RESET, .vec(prj_vert), .out(screen_verts_next));

assign out = screen_verts;

// D flip flops
always_ff @ (posedge CLK) begin
    prj_vert <= prj_vert_next;
    screen_verts <= screen_verts_next;
end

always_comb begin
    // Start at position
    back_top_left[0] = pos[0];
    back_top_right[0] = pos[0];
    back_bot_left[0] = pos[0];
    back_bot_right[0] = pos[0];
    front_top_left[0] = pos[0];
    front_top_right[0] = pos[0];
    front_bot_left[0] = pos[0];
    front_bot_right[0] = pos[0];

    back_top_left[1] = pos[1];
    back_top_right[1] = pos[1];
    back_bot_left[1] = pos[1];
    back_bot_right[1] = pos[1];
    front_top_left[1] = pos[1];
    front_top_right[1] = pos[1];
    front_bot_left[1] = pos[1];
    front_bot_right[1] = pos[1];

    back_top_left[2] = pos[2];
    back_top_right[2] = pos[2];
    back_bot_left[2] = pos[2];
    back_bot_right[2] = pos[2];
    front_top_left[2] = pos[2];
    front_top_right[2] = pos[2];
    front_bot_left[2] = pos[2];
    front_bot_right[2] = pos[2];

    // W component is 1
    
    back_top_left[3] = 1 * (1<<8);
    back_top_right[3] = 1 * (1<<8);
    back_bot_left[3] = 1 * (1<<8);
    back_bot_right[3] = 1 * (1<<8);
    front_top_left[3] = 1 * (1<<8);
    front_top_right[3] = 1 * (1<<8);
    front_bot_left[3] = 1 * (1<<8);
    front_bot_right[3] = 1 * (1<<8);

    // All left verticies need to be shifted to the right by scale
    back_top_left[0] += scale;
    back_bot_left[0] += scale;
    front_top_left[0] += scale;
    front_bot_left[0] += scale;

    // All bot verticies need to be shifted down by scale
    back_bot_left[1] -= scale;
    back_bot_right[1] -= scale;
    front_bot_left[1] -= scale;
    front_bot_right[1] -= scale;

    // All front verticies need to be shifted fowards by scale
    front_top_left[2] += scale;
    front_top_right[2] += scale;
    front_bot_left[2] += scale;
    front_bot_right[2] += scale;
end

endmodule

// Converts a 4D vector into 2D screen space by dividing by the W component
// and scaling it to the screen
module viewport_trans(
    input logic CLK,
    input logic RESET,
    input int vec[4],
    output int out[3]
);

int pers_div[3];
int pers_div_next[3];

always_comb begin
    // Persepective divide
    pers_div_next[0] = (vec[0]*(1<<8)) / vec[3];
    pers_div_next[1] = (vec[1]*(1<<8)) / vec[3];
    pers_div_next[2] = (vec[2]*(1<<8)) / vec[3];
    // Viewport transform
    out[0] = pers_div[0] + ((((1*(1<<8)) + pers_div[0])*(160*(1<<8)))/(1<<8));
    out[1] = pers_div[1] + ((((1*(1<<8)) - pers_div[1])*(120*(1<<8)))/(1<<8));
    out[2] = pers_div[2];
end

// D flip flops
always_ff @ (posedge CLK) begin
    if(RESET)
        pers_div <= '{0, 0, 0};
    else
        pers_div <= pers_div_next;
end

endmodule
