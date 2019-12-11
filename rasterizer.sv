// Rasterizes a horizontal line in the X Z plane
// init must go high when new data is presented. Inputs will
// not be reused unless the module is re-inited.
//
// cont must go high to signal the module to generate a new pixel
// output valid will go high when a new pixel is ready
// done will go high when the entire line is done
// 
// the x and z coordinates of the end points of the line must be past in
// the y coordinate being rendered at must be passed in
// the 3 verticies of the surrounding triangle are used to UV interpolation
//
// Outputs an RGB, as well as an XYZ every output valid
module rast_line(
    input logic CLK, RESET,
    input logic init,
    input logic cont,
    input int y_in,
    input int left_x_in,
    input int left_z_in,
    input int right_x_in,
    input int right_z_in,
    input int top_in[4], // x y z shorts(u v)
    input int mid_in[4],
    input int bot_in[4],
    input int area,
    output byte rgb[3],
    output int xyz[3],
    output logic output_valid,
    output logic done
);

// Main counters
int x_cnt, x_cnt_next;
int z_cnt, z_cnt_next;
int dzBdx, dzBdx_next; // dz by dx

// Input latches
int y, y_next;
int left_x, left_x_next;
int left_z, left_z_next;
int right_x, right_x_next;
int right_z, right_z_next;
int top[4], top_next[4];
int mid[4], mid_next[4];
int bot[4], bot_next[4];


// Unpacked vertex data
int top_vert[3];
int mid_vert[3];
int bot_vert[3];

int top_uv[2];
int mid_uv[2];
int bot_uv[2];

// Normal Calc (Moved to rast triangle)
// int bot_minus_mid[3];
// int top_minus_mid[3];
// int normal[3];
// int area, area_next;
// 
// vec_sub norm_sub1(bot_vert, mid_vert, bot_minus_mid);
// vec_sub norm_sub2(top_vert, mid_vert, top_minus_mid);
// vec_cross norm_cross(top_minus_mid, bot_minus_mid, normal);
// vec_norm norm_area(normal, area_next);

//barycentric interpolation calculation
int bot_minus_pos[3];
int mid_minus_pos[3];
int top_minus_pos[3];
int bot_minus_pos_next[3];
int mid_minus_pos_next[3];
int top_minus_pos_next[3];

int bot_area, bot_area_next, bot_area_norm, bot_area_norm_next, bot_area_raw[3];
int mid_area, mid_area_next, mid_area_norm, mid_area_norm_next, mid_area_raw[3];
int top_area, top_area_next, top_area_norm, top_area_norm_next, top_area_raw[3];

vec_sub b_sub1(bot_vert, xyz, bot_minus_pos_next); // Sync lvl
vec_sub b_sub2(mid_vert, xyz, mid_minus_pos_next);
vec_sub b_sub3(top_vert, xyz, top_minus_pos_next);

vec_cross b_cross1(mid_minus_pos, top_minus_pos, bot_area_raw);
vec_cross b_cross2(top_minus_pos, bot_minus_pos, mid_area_raw);
vec_cross b_cross3(bot_minus_pos, mid_minus_pos, top_area_raw);

vec_norm b_norm1(bot_area_raw, bot_area_norm_next); // Sync lvl
vec_norm b_norm2(mid_area_raw, mid_area_norm_next);
vec_norm b_norm3(top_area_raw, top_area_norm_next);

//UV interpolation
int bot_uv_inter[2];
int mid_uv_inter[2];
int top_uv_inter[2];
int bot_uv_inter_next[2];
int mid_uv_inter_next[2];
int top_uv_inter_next[2];
int uv_inter_temp[2];
int uv_inter[2];

vec2_mul mul_inter1(bot_uv, bot_area, bot_uv_inter_next); // Sync lvl
vec2_mul mul_inter2(mid_uv, mid_area, mid_uv_inter_next);
vec2_mul mul_inter3(top_uv, top_area, top_uv_inter_next);

vec2_add add_inter1(bot_uv_inter, mid_uv_inter, uv_inter_temp);
vec2_add add_inter2(uv_inter_temp, top_uv_inter, uv_inter);

// Texture lookup
texture text(CLK, uv_inter, rgb);

enum logic [5:0] {
    IDLE,
    INIT,
    RENDERING_CALC,
    RENDERING_CALC_2,
    RENDERING_CALC_3,
    RENDERING_CALC_4,
    RENDERING_CALC_5,
    RENDERING_SLEEP,
    RENDERING_TEXT,
    DONE_SLEEP,
    DONE
} state = IDLE, next_state;

always_comb begin
    //default
    x_cnt_next = x_cnt;
    z_cnt_next = z_cnt;
    dzBdx_next = dzBdx;
    next_state = state;
    xyz = '{0, 0, 0};
    done = 0;
    output_valid = 0;

    y_next = y;
    left_x_next = left_x;
    left_z_next = left_z;
    right_x_next = right_x;
    right_z_next = right_z;
    top_next = top;
    mid_next = mid;
    bot_next = bot;


    // barycentric finish
    bot_area_next = (bot_area_norm * (1<<8))/ area;
    mid_area_next = (mid_area_norm * (1<<8))/ area;
    top_area_next = (top_area_norm * (1<<8))/ area;



    // Unpack vertex data
    top_vert[0] = top[0];
    top_vert[1] = top[1];
    top_vert[2] = top[2];
    mid_vert[0] = mid[0];
    mid_vert[1] = mid[1];
    mid_vert[2] = mid[2];
    bot_vert[0] = bot[0];
    bot_vert[1] = bot[1];
    bot_vert[2] = bot[2];

    top_uv = '{top[3][31:16]*(1<<8), top[3][15:0]*(1<<8)};
    mid_uv = '{mid[3][31:16]*(1<<8), mid[3][15:0]*(1<<8)};
    bot_uv = '{bot[3][31:16]*(1<<8), bot[3][15:0]*(1<<8)};

    // Setup counts and dz/dy slope
    if(state == INIT) begin
        x_cnt_next = left_x;
        z_cnt_next = left_z;
        dzBdx_next = ((right_z - left_z) * (1<<8))  / (right_x - left_x);
        y_next = y_in;
        left_x_next = left_x_in;
        left_z_next = left_z_in;
        right_x_next = right_x_in;
        right_z_next = right_z_in;
        top_next = top_in;
        mid_next = mid_in;
        bot_next = bot_in;
    end else if(state == DONE) begin
        done = 1;
    end
    xyz = '{x_cnt, y, z_cnt};

    // State machine
    unique case(state)
        IDLE: begin
            if(init)
                next_state = INIT;
            else
                next_state = IDLE;
        end
        INIT: begin
            if(~init)
                next_state = RENDERING_CALC;
            else
                next_state = INIT;
        end
        RENDERING_CALC: begin
            next_state = RENDERING_CALC_2;
        end
        RENDERING_CALC_2: begin
            next_state = RENDERING_CALC_3;
        end
        RENDERING_CALC_3: begin
            next_state = RENDERING_CALC_4;
        end
        RENDERING_CALC_4: begin
            next_state = RENDERING_CALC_5;
        end
        RENDERING_CALC_5: begin
            next_state = RENDERING_SLEEP;
        end
        RENDERING_SLEEP: begin
            next_state = RENDERING_TEXT;
            output_valid = 1;
        end
        RENDERING_TEXT: begin
            output_valid = 1;
            if(((x_cnt >= (right_x + (0<<8))) || (x_cnt >= (320*(1<<8)))) & cont)
                next_state = DONE_SLEEP;
            else if(cont) begin
                next_state = RENDERING_CALC;
                x_cnt_next = x_cnt + (1<<8);
                z_cnt_next = z_cnt + dzBdx;
            end else begin

            end
        end
        DONE_SLEEP: begin
            next_state = DONE;
        end
        DONE: begin
            if(init)
                next_state = DONE;
            else
                next_state = IDLE;
        end


    endcase

end

// Lots of D flip flops
always_ff @ (posedge CLK) begin
    if(RESET) begin
        x_cnt <= 0;
        z_cnt <= 0;
        dzBdx <= 0;
        state <= IDLE;
        y <= 0;
        left_x <= 0; 
        left_z <= 0; 
        right_x <= 0; 
        right_z <= 0; 
        top <= '{0, 0, 0, 0}; 
        mid <= '{0, 0, 0, 0}; 
        bot <= '{0, 0, 0, 0}; 
        bot_minus_pos <= '{0, 0, 0};
        mid_minus_pos <= '{0, 0, 0};
        top_minus_pos <= '{0, 0, 0};
        //area <= 0;
        bot_area_norm <= 0;
        mid_area_norm <= 0;
        top_area_norm <= 0;
        bot_uv_inter <= '{0, 0};
        mid_uv_inter <= '{0, 0};
        top_uv_inter <= '{0, 0};
        bot_area <= 0;
        mid_area <= 0;
        top_area <= 0;
    end else begin
        x_cnt <= x_cnt_next;
        z_cnt <= z_cnt_next;
        dzBdx <= dzBdx_next;
        state <= next_state;
        y <= y_next;
        left_x <= left_x_next; 
        left_z <= left_z_next; 
        right_x <= right_x_next; 
        right_z <= right_z_next; 
        top <= top_next; 
        mid <= mid_next; 
        bot <= bot_next; 
        bot_minus_pos <= bot_minus_pos_next;
        mid_minus_pos <= mid_minus_pos_next;
        top_minus_pos <= top_minus_pos_next;
        //area <= area_next;
        bot_area_norm <= bot_area_norm_next; 
        mid_area_norm <= mid_area_norm_next; 
        top_area_norm <= top_area_norm_next; 
        bot_uv_inter <= bot_uv_inter_next;
        mid_uv_inter <= mid_uv_inter_next;
        top_uv_inter <= top_uv_inter_next;
        bot_area <= bot_area_next;
        mid_area <= mid_area_next;
        top_area <= top_area_next;
    end

end

endmodule

// Rasterizes a triangle by splitting it into many horizontal
// lines and drawing those via rast_line
//
// cont must be set high whenever the module should produce a new
// pixel. draw ready goes high when the new pixel is ready
//
// 3 verticies of ther triangle must be passed in, along with their UV coords
//
// done is set high when the triangle is done
//
// outputs an RGB and XYZ every draw ready
module rast_triangle(
    input logic CLK, RESET,
    input logic start,
    input logic cont,
    input int v1_p[4], // x y z int(r g b a)
    input int v2_p[4],
    input int v3_p[4],
    output logic draw_ready,
    output byte rgb[3],
    output int  xyz[3],
    output logic done
);

// Unpacked input verticies
int v1[3];
int v2[3];
int v3[3];

// Normal Calc
int v2_minus_v1[3];
int v3_minus_v1[3];
int normal[3];
int area, area_next;
int signed back_face_cull;

vec_sub norm_sub1(v2, v1, v2_minus_v1);
vec_sub norm_sub2(v3, v1, v3_minus_v1);
vec_cross norm_cross(v2_minus_v1, v3_minus_v1, normal);
vec_dot back_cull_dot(v1, normal, back_face_cull);
vec_norm norm_area(normal, area_next);

// Vertex soring vars
int top_p[4];
int mid_p[4];
int bot_p[4];
int temp_p[4];

// Unpacked sorted verticies
int top[3], top_next[3];
int mid[3], mid_next[3];
int bot[3], bot_next[3];

// Edge inputs/outputs
logic init;
logic e1_step, e2_step, e3_step;

int e1_pos[3], e2_pos[3], e3_pos[3]; 
int e1_min[3], e2_min[3], e3_min[3]; 
int e1_max[3], e2_max[3], e3_max[3]; 


// Edge 1 is from bot to mid, E2 is from mid to top, E3 from ot to top
vert_edge E1(CLK, RESET, init, e1_step, bot, mid, e1_pos, e1_min, e1_max);
vert_edge E2(CLK, RESET, init, e2_step, mid, top, e2_pos, e2_min, e2_max);
vert_edge E3(CLK, RESET, init, e3_step, bot, top, e3_pos, e3_min, e3_max);

// Ceiling functions

// E1 y min ceiling, ...
int e1_ymin_c, e1_ymax_c; 
int e2_ymin_c, e2_ymax_c;
// E1 x ceiling, ...
int e1_x_c, e2_x_c, e3_x_c;

ceil c1(e1_min[1], e1_ymin_c);
ceil c2(e1_max[1], e1_ymax_c);
ceil c3(e2_min[1], e2_ymin_c);
ceil c4(e2_max[1], e2_ymax_c);

ceil c5(e1_pos[0], e1_x_c);
ceil c6(e2_pos[0], e2_x_c);
ceil c7(e3_pos[0], e3_x_c);


// vertical rasterization variables
int y_cnt, y_cnt_next;
int rast_x_min, rast_x_max;
int rast_left_z, rast_right_z;

// horizontal rasterization variables
logic h_rast_init;
logic line_done;
logic h_rast_valid;
rast_line h_rast(CLK, RESET, h_rast_init, cont, y_cnt, rast_x_min, rast_left_z, rast_x_max, rast_right_z,
                            top_p, mid_p, bot_p, area, rgb, xyz, h_rast_valid, line_done);

assign draw_ready = h_rast_valid;

enum logic [5:0] {
    IDLE,
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    INIT5,
    INIT6,
    INIT7,
    INIT8,
    RENDER_BOT_INIT_1,
    RENDER_BOT_INIT_2,
    RENDER_BOT,
    RENDER_TOP_INIT_1,
    RENDER_TOP_INIT_2,
    RENDER_TOP,
    WAIT
} state = IDLE, next_state;



always_comb begin

    // defaults
    temp_p[0] = 0;
    temp_p[1] = 0;
    temp_p[2] = 0;
    init = 0;
    y_cnt_next = y_cnt;
    next_state = state;
    rast_x_min = 0;
    rast_x_max = 0;
    rast_left_z = 0;
    rast_right_z = 0;
    e1_step = 0;
    e2_step = 0;
    e3_step = 0;
    h_rast_init = 0;
    done = 0;
    top_next = top;
    mid_next = mid;
    bot_next = bot;

    // Unpack input verticies
    v1[0] = v1_p[0];
    v1[1] = v1_p[1];
    v1[2] = v1_p[2];
    v2[0] = v2_p[0];
    v2[1] = v2_p[1];
    v2[2] = v2_p[2];
    v3[0] = v3_p[0];
    v3[1] = v3_p[1];
    v3[2] = v3_p[2];


    // Sorting logic
    // 0 is top of screen, so bot is really at the top
    
    top_p = v1_p;
    mid_p = v2_p;
    bot_p = v3_p;

    if(bot_p[1] > mid_p[1]) begin // If bot 'below' mid, swap
        temp_p = bot_p;
        bot_p = mid_p;
        mid_p = temp_p;
    end

    if (mid_p[1] > top_p[1]) begin // If mid is below top, swap
        temp_p = mid_p;
        mid_p = top_p;
        top_p = temp_p;
    end

    if (bot_p[1] > mid_p[1]) begin
        temp_p = bot_p;
        bot_p = mid_p;
        mid_p = temp_p;
    end

    // Unpack verticies
    bot_next[0] = bot_p[0];
    bot_next[1] = bot_p[1];
    bot_next[2] = bot_p[2];
    mid_next[0] = mid_p[0];
    mid_next[1] = mid_p[1];
    mid_next[2] = mid_p[2];
    top_next[0] = top_p[0];
    top_next[1] = top_p[1];
    top_next[2] = top_p[2];

    // State output logic
    //
    //
    // Main Inits
    if((state == INIT1) | (state == INIT2) | (state == INIT3) | (state == INIT4) | (state == INIT5) | (state == INIT7) | (state == INIT8) )
        init = 1;

    // Find left and right edge for bot
    if((state == RENDER_BOT) | (state == RENDER_BOT_INIT_1) | (state == RENDER_BOT_INIT_2)) begin //TODO y clipping
        if(e1_pos[0] < e3_pos[0]) begin 
            rast_x_min = e1_x_c;
            rast_x_max = e3_x_c;
            rast_left_z = e1_pos[2];
            rast_right_z = e3_pos[2];
        end else begin
            rast_x_min = e3_x_c;
            rast_x_max = e1_x_c;
            rast_left_z = e3_pos[2];
            rast_right_z = e1_pos[2];
        end
    end
    // Continue for Bot
    if(state == RENDER_BOT) begin
        if(line_done) begin
            e1_step = 1;
            e3_step = 1;
        end 
    end
    // Find left and right edge for top
    if((state == RENDER_TOP) | (state == RENDER_TOP_INIT_1) | (state == RENDER_TOP_INIT_2)) begin
        if(e2_pos[0] < e3_pos[0]) begin
            rast_x_min = e2_x_c;
            rast_x_max = e3_x_c;
            rast_left_z = e2_pos[2];
            rast_right_z = e3_pos[2];
        end else begin
            rast_x_min = e3_x_c;
            rast_x_max = e2_x_c;
            rast_left_z = e3_pos[2];
            rast_right_z = e2_pos[2];
        end
    end 
    // Continue for top
    if(state == RENDER_TOP) begin
        if(line_done) begin
            e2_step = 1;
            e3_step = 1;
        end 
    end

    // Line reinits
    if((state == RENDER_TOP_INIT_1) | (state == RENDER_TOP_INIT_2) | (state == RENDER_BOT_INIT_1) | (state == RENDER_BOT_INIT_2)) begin
        h_rast_init = 1;
    end

    if(state == WAIT) begin
        done = 1;
    end
    

    // Next state logic
    unique case(state)
        IDLE: begin
            if(start)
                next_state = INIT1;
            else 
                next_state = IDLE;
        end
        INIT1: begin
            next_state = INIT2;
        end
        INIT2: begin
            next_state = INIT3;
        end
        INIT3: begin
	        if(back_face_cull >= 0)
                next_state = WAIT;
            else
                next_state = INIT4;
        end
        INIT4: begin
            next_state = INIT5;
        end
        INIT5: begin
            next_state = INIT6;
        end
        INIT6: begin
            next_state = INIT7;
        end
        INIT7: begin
            next_state = INIT8;
        end
        INIT8: begin
            next_state = RENDER_BOT_INIT_1;
            y_cnt_next = e1_ymin_c;
        end
        RENDER_BOT_INIT_1: begin
            next_state = RENDER_BOT_INIT_2;
        end
        RENDER_BOT_INIT_2: begin
            next_state = RENDER_BOT;
        end
        RENDER_BOT: begin
            if(y_cnt >= e1_ymax_c) begin
                next_state = RENDER_TOP_INIT_1;
                y_cnt_next = e2_ymin_c;
            end else if(line_done) begin
                next_state = RENDER_BOT_INIT_1;
                y_cnt_next = y_cnt + (1<<8);
            end else begin
                next_state = RENDER_BOT;
            end
        end
        RENDER_TOP_INIT_1: begin
            next_state = RENDER_TOP_INIT_2;
        end
        RENDER_TOP_INIT_2: begin
            next_state = RENDER_TOP;
        end
        RENDER_TOP: begin
            if(y_cnt >= e2_ymax_c)
                next_state = WAIT;
            else if(line_done) begin
                next_state = RENDER_TOP_INIT_1;
                y_cnt_next = y_cnt + (1<<8);
            end else begin
                next_state = RENDER_TOP;
            end
        end
        WAIT: begin
            if(~start) 
                next_state = IDLE;
            else
                next_state = WAIT;
        end
        default:
            next_state = state;
    endcase


end

always_ff @ (posedge CLK) begin
    if(RESET) begin
        state <= IDLE;
        y_cnt <= 0;
        top <= '{0, 0, 0};
        bot <= '{0, 0, 0};
        mid <= '{0, 0, 0};
	area <= 0;
    end else begin
        state <= next_state;
        y_cnt <= y_cnt_next;
        top <= top_next;
        bot <= bot_next;
        mid <= mid_next;
	area <= area_next;
    end
        
end

endmodule

// Represents a 3d edge 
//
// The init process takes 6 cycles
// the module will step across the line, starting at the top
// current pos will move one unit in the y direction, and move
// the correct amounts in the x and z directions to stay on the line.
//
// This is done every cycle step is high
//
// The bounding box of the edge is also outputted
module vert_edge(
    input logic CLK, RESET,
    input logic init,
    input logic step,
    input int bot[3],
    input int top[3],
    output int current_pos[3],
    output int mins[3],
    output int maxs[3]
);

int current_pos_next[3];
int dxBdy, dxBdyNext; // dx by dy
int dzBdy, dzBdyNext; // dz by dy
int yPreStep;
int steps[3]; //dx, dy, dz

int min_pos[3];
int max_pos[3];

enum logic [5:0] {
    NOT_INIT,
    INIT_1,
    INIT_2,
    INIT_3,
    INIT_4,
    INIT_5,
    INIT_6
} init_state = NOT_INIT, init_state_next;

ceil_min_max minmaxers[3](bot, top, min_pos, max_pos);

always_comb begin
    current_pos_next = current_pos;
    dxBdyNext = dxBdy;
    dzBdyNext = dzBdy;

    // helper vars during init, not needed other times
    yPreStep = 32'hxxxxxxxx; 
    steps[0] = 32'hxxxxxxxx;
    steps[1] = 32'hxxxxxxxx;
    steps[2] = 32'hxxxxxxxx;

    if((init & (init_state == NOT_INIT)) | (init_state == INIT_1) |
         (init_state == INIT_2) | (init_state == INIT_3) |
         (init_state == INIT_4) | (init_state == INIT_5) |
         (init_state == INIT_6)
         ) begin
        // Init slopes/counters and do Y pre step
        steps[0] = top[0] - bot[0];
        steps[1] = top[1] - bot[1];
        steps[2] = top[2] - bot[2];

        dxBdyNext = (steps[0] * (1<<8))/steps[1];
        dzBdyNext = (steps[2] * (1<<8))/steps[1];

        yPreStep = min_pos[1] - bot[1];  // minY - bot.Y
        current_pos_next[0] = (bot[0] + ((yPreStep * dxBdyNext)/(1<<8)));
        current_pos_next[2] = (bot[2] + ((yPreStep * dzBdyNext)/(1<<8)));
        current_pos_next[1] = (bot[1] + yPreStep);
    end else if(step & (init_state == NOT_INIT)) begin
        // Step 1 unit is Y
        current_pos_next[0] += dxBdy;
        current_pos_next[2] += dzBdy;
        current_pos_next[1] += (1<<8);
    end

    unique case (init_state)
        NOT_INIT: begin
           if(init)
               init_state_next = INIT_1; 
           else
               init_state_next = NOT_INIT;
        end
        INIT_1: begin
            init_state_next = INIT_2;
        end
        INIT_2: begin
            init_state_next = INIT_3;
        end
        INIT_3: begin
            init_state_next = INIT_4;
        end
        INIT_4: begin
            init_state_next = INIT_5;
        end
        INIT_5: begin
            init_state_next = INIT_6;
        end
        INIT_6: begin
            if(~init)
                init_state_next = NOT_INIT;
            else
                init_state_next = INIT_6;
        end
    endcase

end

assign mins = min_pos;
assign maxs = max_pos;

always_ff @ (posedge CLK) begin
    if(RESET) begin
        current_pos <= '{0, 0, 0};
        dxBdy <= 0;
        dzBdy <= 0;
        init_state <= NOT_INIT;
    end
    else begin
        current_pos <= current_pos_next;
        dxBdy <= dxBdyNext; 
        dzBdy <= dzBdyNext; 
        init_state <= init_state_next;
    end
end

endmodule

