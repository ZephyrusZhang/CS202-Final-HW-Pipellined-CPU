`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk, rst_n,
    
    input      display_en,
    input      [COORDINATE_WIDTH - 1:0] x,
    input      [COORDINATE_WIDTH - 1:0] y,
    input      clk_vga,

    input      vga_write_enable,                        // from data_mem (vga write enable)
    input      [`ISA_WIDTH - 1:0] vga_store_data,       // from data_mem (data to vga)

    output reg [`VGA_BIT_DEPTH - 1:0] vga            // VGA display signal
    );

    reg [`ISA_WIDTH - 1:0] value_to_display;

    always @(*) begin
        if (vga_write_enable) 
            value_to_display <= vga_store_data;
        else
            value_to_display <= value_to_display;
    end
    
    reg [:0] addr_out, addr_out_next;
    wire [`VGA_BIT_DEPTH - 1:0] zero_out, one_out;
    
    zero_ram ram_unit(.clk(clk), .addr(addr_out), .data_out(data_out));
    
    localparam X_GAP = (DISPLAY_WIDTH - PICTURE_WIDTH) / 2,
               Y_GAP = (DISPLAY_HEIGHT - PICTURE_HEIGHT) / 2;
    
    reg [3:0] state, next_state;
    reg [(INPUT_DATA_WIDTH / 2) - 1:0] data_temp;
    reg [POSITION_WIDTH - 1:0] black_index_reg;
    reg [(POSITION_SIZE * POSITION_WIDTH) - 1:0] position_reg;
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state <= FIRST;
            addr_in <= 0;
            data_in <= 0;
            ram_en <= 1'b0;
            black_index_reg <= 0;
            position_reg <= 0;
        end else begin 
            state <= next_state;
            addr_in <= addr_in_next;
            data_in <= data_in_next;
            ram_en <= ram_en_next;
            black_index_reg <= black_index;
            position_reg <= position;
        end
    end

    always @(uart_data, state) begin
        // defaults
        next_state = state;
        addr_in_next = addr_in;
        data_in_next = data_in;
        ram_en_next = ram_en;
        
        if (write_en) // double check the data state
            case (state)
                FIRST: begin
                    data_in_next[(INPUT_DATA_WIDTH - 1):0] = uart_data; // R and G
                    ram_en_next = 1'b0;
                    next_state = SECOND;
                end
                SECOND: begin
                    data_in_next[(`VGA_BIT_DEPTH - 1):(INPUT_DATA_WIDTH - 1)] = uart_data[(INPUT_DATA_WIDTH / 2 - 1):0]; // B
                    data_temp = uart_data[(INPUT_DATA_WIDTH - 1):(INPUT_DATA_WIDTH / 2 - 1)]; // R
                    ram_en_next = 1'b1;
                    next_state = THIRD;
                    
                    if (addr_in + 1 == PICTURE_WIDTH * PICTURE_HEIGHT) addr_in_next = 0;
                    else addr_in_next = addr_in_next + 1;
                end
                THIRD: begin
                    data_in_next = {uart_data, data_temp}; // G and B
                    ram_en_next = 1'b1;
                    next_state <= FIRST;
                    
                    if (addr_in + 1 == PICTURE_WIDTH * PICTURE_HEIGHT) addr_in_next = 0;
                    else addr_in_next = addr_in_next + 1;
                end
            endcase
    end
    
    wire [COORDINATE_WIDTH - 1:0] x_segment_pixel, x_local_index, x_local_index_next, x_global_index, x_global_index_next,
                                  y_segment_pixel, y_local_index, y_local_index_next, y_global_index, y_global_index_next;
    
    assign x_segment_pixel     = picture_width / h_seg_count;
    assign x_local_index       = (x - X_GAP) % x_segment_pixel;
    assign x_local_index_next  = (x - X_GAP + 1) % x_segment_pixel;
    assign x_global_index      = (x - X_GAP) / x_segment_pixel;
    assign x_global_index_next = (x - X_GAP + 1) / x_segment_pixel;
    
    assign y_segment_pixel     = picture_height / v_seg_count;
    assign y_local_index       = (y - Y_GAP) % y_segment_pixel;
    assign y_local_index_next  = (y - Y_GAP + 1) % y_segment_pixel;
    assign y_global_index      = (y - Y_GAP) / y_segment_pixel;
    assign y_global_index_next = (y - Y_GAP + 1) / y_segment_pixel;
    
    reg [POSITION_WIDTH - 1:0] display_index, display_index_next;
    
//    always @(posedge clk, negedge rst_n) begin
//        if (!rst_n) begin
//            addr_out <= 0;
//            display_index <= 0;
//        end else begin 
//            addr_out <= addr_out_next;
//            display_index <= display_index_next;
//        end
//    end
    
    localparam BACKGROUND_COLOR = 12'b0111_0111_0111, // light gray
               BORDER_COLOR     = 12'b0010_0010_0010; // dark gray
               
    wire [7:0] region_state;
    assign region_state = {(y < (Y_GAP - BORDER_SIZE)), ((Y_GAP + picture_height + BORDER_SIZE) < y),
                           (y < Y_GAP),                 ((Y_GAP + picture_height) < y),
                           (x < (X_GAP - BORDER_SIZE)), ((X_GAP + picture_width + BORDER_SIZE) < x),
                           (x < X_GAP),                 ((X_GAP + picture_width) < x)};
    
    wire [3:0] pixel_state;
    assign pixel_state = {(x + 1 == X_GAP + picture_width), (y + 1 == Y_GAP + picture_height), 
                          (x_local_index_next == 0),             (y_local_index_next == 0)};
    
    always @(posedge clk_vga) begin
        if (!rst_n) begin
            addr_out <= 0;
            display_index <= 0;
        end else if (display_en)
            casex (region_state)
                8'b0X1X_00XX, 8'bX0X1_00XX: vga <= BORDER_COLOR; // above at upper border or below at lower border
                8'bXX00_0X1X, 8'bXX00_X0X1: begin // sides of the frame
                    vga <= BORDER_COLOR;
                    // predict first contact
                    addr_out <= ((((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                              + y_local_index) * PICTURE_WIDTH)
                              + ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                end
                8'bXX00_XX00: begin // in picture frame
                    if (display_index == black_index_reg) vga <= 0;
                    else vga <= data_out;
                    casex (pixel_state)
                        4'b11XX: begin // one pixel before bottom right
                            display_index <= 0;
                            addr_out <= ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel * PICTURE_WIDTH)
                                      + ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b10X0: begin // at the end of one row but still in the same row segment
                            display_index <= display_index - h_seg_count + 1;
                            addr_out <= ((((position_reg[((display_index - h_seg_count + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      + y_local_index_next) * PICTURE_WIDTH)
                                      + ((position_reg[((display_index - h_seg_count + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b10X1: begin // end of row segment
                            display_index <= display_index + 1;
                            addr_out <= (((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      * PICTURE_WIDTH)
                                      + ((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b0X1X: begin // end of one block segment
                            display_index <= display_index + 1;
                            addr_out <= ((((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      + y_local_index) * PICTURE_WIDTH)
                                      + ((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        default: addr_out <= addr_out + 1; // in regional block
                    endcase
                end
                default: vga <= BACKGROUND_COLOR; // outside the frame
            endcase
        else vga <= 0;
    end

endmodule

endmodule