#ifndef TYPES_H_
#define TYPES_H_

#include "alt_types.h"

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240
#define BYTES_PER_PIXEL 4

#define GPU_MODE_IDLE 0
#define GPU_MODE_RENDER 1
#define GPU_MODE_CLEAR_FRAME 2
#define GPU_MODE_CLEAR_DEPTH 3

#define FP_SCALE (1<<8)

#define KEY_RIGHT 0x4f
#define KEY_DOWN  0x51
#define KEY_LEFT  0x50
#define KEY_UP    0x52

#define KEY_W 0x1A
#define KEY_S 0x16
#define KEY_A 0x04
#define KEY_D 0x07
#define KEY_SPACE 0x2C
#define KEY_C 0x06

#define KEY_E 0x08
#define KEY_Q 0x14

#define KEY_R 0x15

#define KEY_1 0x1E
#define KEY_2 0x1F
#define KEY_3 0x20
#define KEY_4 0x21
#define KEY_5 0x22
#define KEY_6 0x23
#define KEY_7 0x24
#define KEY_8 0x25
#define KEY_9 0x26
#define KEY_0 0x27

#define KEY_I 0x0c
#define KEY_O 0x12
#define KEY_P 0x13

#define BLOCK_GRASS 0
#define BLOCK_DIRT 1
#define BLOCK_LOG 2
#define BLOCK_LOG_DARK 3
#define BLOCK_PLANK 4
#define BLOCK_LEAF_TRANS 5
#define BLOCK_LEAF_SOLID 6
#define BLOCK_STONE 7
#define BLOCK_COBBLE 8
#define BLOCK_PUMPKIN 9
#define BLOCK_FURNACE 10
#define BLOCK_GLASS 11
#define BLOCK_BEEHIVE 12

typedef struct pixel_t {
	char b;
	char g;
	char r;
	char a;
} pixel_t;


//typedef struct vga_controller_t {
//	volatile pixel_t line1[SCREEN_WIDTH];
//	volatile alt_u32 rendering_frame;
//    volatile alt_u32 needs_write;
//    volatile alt_8 padding[1536-8];  //1536 total size in between
//	volatile pixel_t line2[SCREEN_WIDTH];
//} vga_controller_t ;

typedef union z_buffer_t   {
	alt_u32 D2[SCREEN_HEIGHT][SCREEN_WIDTH];
	alt_u32 D1[SCREEN_HEIGHT*SCREEN_WIDTH];
} z_buffer_t ;

typedef union frame_buffer_t   {
	pixel_t D2[SCREEN_HEIGHT][SCREEN_WIDTH];
	pixel_t D1[SCREEN_HEIGHT*SCREEN_WIDTH];
} frame_buffer_t ;

typedef struct vga_controller_t {
	volatile frame_buffer_t* frame_pointer;
	volatile alt_32 should_draw;
} vga_controller_t ;

typedef struct dma_controller_t {
	volatile frame_buffer_t* front_buffer;
	volatile frame_buffer_t* back_buffer;
	volatile int resolution;
	volatile int status;
} dma_controller_t;

typedef struct copy_dma_controller_t {
	volatile int status;
	volatile frame_buffer_t* write_pointer;
	volatile frame_buffer_t* read_pointer;
	volatile int length;
	volatile int res_1;
	volatile int res_2;
	volatile int control;
	volatile int res_3;
};

typedef struct vec3_t {
	volatile int x;
	volatile int y;
	volatile int z;
} vec3_t;

typedef struct gpu_core_t {
	volatile frame_buffer_t* frame_pointer;
	volatile int start;
	volatile int done;
	volatile z_buffer_t* z_buffer;
	volatile int scale;
	volatile int x;
	volatile int y;
	volatile int z;
	volatile int mode;
	volatile int block_id;
	volatile vec3_t cam_x_axis;
	volatile vec3_t cam_y_axis;
	volatile vec3_t cam_z_axis;
	volatile vec3_t cam_pos;
	volatile vec3_t cam_trans;
	volatile int z_clip;
} gpu_core_t;

typedef struct block_t {
	int x;
	int y;
	int z;
	int block_id;
} block_t;

#endif


