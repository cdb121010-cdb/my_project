`timescale 1ns / 1ps

module apb_rgb_led(
    // System Ports
    input  wire        PCLK,     // APB Clock
    input  wire        PRESETn,  // APB Active-low Reset

    // APB Slave Interface Ports
    input  wire [31:0] PADDR,    // Address Bus
    input  wire        PSEL,     // Slave Select
    input  wire        PENABLE,  // Enable (Strobe)
    input  wire        PWRITE,   // Write Control (1'b1: Write, 1'b0: Read)
    input  wire [31:0] PWDATA,   // Write Data
    output wire [31:0] PRDATA,   // Read Data
    output wire        PREADY,   // Ready signal (Tied to 1 for simple 1-cycle access)
    output wire        PSLVERR,  // Slave Error (Not used in this design)

    // PWM Output Ports
    output wire [5:0]  o_pwm_ch  // 6 PWM channels [0-2: LED0 R,G,B], [3-5: LED1 R,G,B]
);

    //================================================================
    // 1. Register Map Definition (32-bit aligned)
    //================================================================
    parameter ADDR_WIDTH = 5; // Address bits to decode: PADDR[4:2] for 4-byte alignment
    
    // Address Offset for each register
    parameter ADDR_LED0_R_DUTY = 5'h00; // 0x00
    parameter ADDR_LED0_G_DUTY = 5'h01; // 0x04
    parameter ADDR_LED0_B_DUTY = 5'h02; // 0x08
    parameter ADDR_LED1_R_DUTY = 5'h03; // 0x0C
    parameter ADDR_LED1_G_DUTY = 5'h04; // 0x10
    parameter ADDR_LED1_B_DUTY = 5'h05; // 0x14

    //================================================================
    // 2. APB Write Logic - Register Storage
    //================================================================
    reg [7:0] r_duty_reg [0:5]; // Array of 6 registers for each PWM channel's duty cycle

    // APB Write Transaction Signal
    wire w_apb_write_en = PSEL & PENABLE & PWRITE;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset all duty registers to 0
            r_duty_reg[0] <= 8'h00;
            r_duty_reg[1] <= 8'h00;
            r_duty_reg[2] <= 8'h00;
            r_duty_reg[3] <= 8'h00;
            r_duty_reg[4] <= 8'h00;
            r_duty_reg[5] <= 8'h00;
        end else begin
            if (w_apb_write_en) begin
                // Decode address and write data to the corresponding register
                // We only look at PADDR[4:2] because addresses are 4-byte aligned.
                case (PADDR[ADDR_WIDTH-1:2])
                    ADDR_LED0_R_DUTY: r_duty_reg[0] <= PWDATA[7:0];
                    ADDR_LED0_G_DUTY: r_duty_reg[1] <= PWDATA[7:0];
                    ADDR_LED0_B_DUTY: r_duty_reg[2] <= PWDATA[7:0];
                    ADDR_LED1_R_DUTY: r_duty_reg[3] <= PWDATA[7:0];
                    ADDR_LED1_G_DUTY: r_duty_reg[4] <= PWDATA[7:0];
                    ADDR_LED1_B_DUTY: r_duty_reg[5] <= PWDATA[7:0];
                    default:          ; // Do nothing for undefined addresses
                endcase
            end
        end
    end

    //================================================================
    // 3. APB Read Logic - Combinational
    //================================================================
    reg [31:0] r_prdata_mux;

    always @(*) begin
        // Decode address and select the corresponding register value for PRDATA
        case (PADDR[ADDR_WIDTH-1:2])
            ADDR_LED0_R_DUTY: r_prdata_mux = {24'h0, r_duty_reg[0]};
            ADDR_LED0_G_DUTY: r_prdata_mux = {24'h0, r_duty_reg[1]};
            ADDR_LED0_B_DUTY: r_prdata_mux = {24'h0, r_duty_reg[2]};
            ADDR_LED1_R_DUTY: r_prdata_mux = {24'h0, r_duty_reg[3]};
            ADDR_LED1_G_DUTY: r_prdata_mux = {24'h0, r_duty_reg[4]};
            ADDR_LED1_B_DUTY: r_prdata_mux = {24'h0, r_duty_reg[5]};
            default:          r_prdata_mux = 32'h0; // Read from undefined address returns 0
        endcase
    end
    
    assign PRDATA = r_prdata_mux;

    // For this simple slave, we are always ready for a transaction.
    assign PREADY = 1'b1;
    // No error conditions are implemented.
    assign PSLVERR = 1'b0;

    //================================================================
    // 4. PWM Generation Logic
    //================================================================
    // PWM Period Counter: ~1ms cycle for 100MHz clock (100,000 cycles)
    localparam PWM_PERIOD = 100000;
    reg [16:0] pwm_period_counter; // Needs to hold up to 99,999 (17 bits)

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            pwm_period_counter <= 0;
        end else begin
            if (pwm_period_counter < PWM_PERIOD - 1) begin
                pwm_period_counter <= pwm_period_counter + 1;
            end else begin
                pwm_period_counter <= 0;
            end
        end
    end

    // Generate 6 PWM channels
    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : pwm_channel_gen
            // Scale the 8-bit duty value (0-255) to the PWM period (0-99999)
            // Scaling factor: 100000 / 256 ~= 390.625. We use 391 for simplicity.
            wire [16:0] w_scaled_duty;
            assign w_scaled_duty = r_duty_reg[i] * 17'd391;

            // Generate PWM output signal based on comparison
            // Handle edge cases: duty=255 is always ON, duty=0 is always OFF.
            assign o_pwm_ch[i] = (r_duty_reg[i] == 8'hFF) ? 1'b1 :
                                 (r_duty_reg[i] == 8'h00) ? 1'b0 :
                                 (pwm_period_counter < w_scaled_duty);
        end
    endgenerate

endmodule