/*
 * =====================================================================================
 *
 *       Filename:  final_submission_debugged.c
 *
 *    Description:  Final submission code with USART communication debugged.
 *                  - Added terminal echo feature for user input visibility.
 *                  - All other hardware settings and project logic remain the same.
 *
 *        Version:  FINAL-DEBUGGED
 *        Created:  2025-06-13
 *       Compiler:  avr-gcc (Microchip Studio)
 *
 *         Author:  Senior Engineer (Perplexity AI)
 *
 * =====================================================================================
 */

#define F_CPU 14745600UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// --- 상수 정의 ---
#define MODE_STOPWATCH  0
#define MODE_TIMER      1
#define FND_DATA_PORT   PORTB
#define FND_DATA_DDR    DDRB
#define FND_CONTROL_PORT PORTE
#define FND_CONTROL_DDR  DDRE
#define BUTTON_PIN      PIND
#define BUTTON_DDR      DDRD
#define START_STOP_BTN  PD0
#define RESET_BTN       PD1
#define RX_BUFFER_SIZE  16

// --- 전역 변수 ---
volatile uint16_t g_time_counter = 0;
volatile uint8_t g_current_mode = MODE_STOPWATCH;
volatile uint8_t g_is_running = 0;
volatile char g_rx_buffer[RX_BUFFER_SIZE];
volatile uint8_t g_rx_index = 0;
const unsigned char g_fnd_font_cathode[10] = {0b01000000, 0b01111001, 0b00100100, 0b00110000, 0b00011001, 0b00010010, 0b00000010, 0b01011000, 0b00000000, 0b00010000};

// --- 함수 원형 선언 ---
void init_ports(void);
void init_timer1_10ms(void);
void init_usart1(void);
void usart1_tx_char(char data);
void usart1_tx_string(const char *str);
void display_fnd(uint16_t time_val);
void reset_system_state(void);
void process_command(void);
void handle_buttons(void);

// --- 메인 함수 ---
int main(void) {
    init_ports();
    init_usart1();
    init_timer1_10ms();
    usart1_tx_string("\r\n=== System Ready [FINAL-DEBUGGED] ===\r\n");
    reset_system_state();
    sei();
    while (1) {
        handle_buttons();
        display_fnd(g_time_counter);
    }
}

// --- 초기화 함수 ---
void init_ports(void) {
    FND_DATA_DDR = 0xFF;
    FND_CONTROL_DDR |= 0xF0;
    BUTTON_DDR &= ~((1 << START_STOP_BTN) | (1 << RESET_BTN));
    PORTD |= ((1 << START_STOP_BTN) | (1 << RESET_BTN));
}

void init_timer1_10ms(void) {
    TCCR1B |= (1 << WGM12);
    TCCR1B |= (1 << CS11) | (1 << CS10);
    OCR1A = 2304;
    TIMSK |= (1 << OCIE1A);
}

void init_usart1(void) {
    UCSR1B = (1 << RXEN1) | (1 << TXEN1) | (1 << RXCIE1);
    UBRR1H = 0;
    UBRR1L = 95;
    UCSR1C = (1 << UCSZ11) | (1 << UCSZ10);
}

// --- 인터럽트 서비스 루틴 ---
ISR(TIMER1_COMPA_vect) {
    if (!g_is_running) return;
    if (g_current_mode == MODE_STOPWATCH) {
        if (g_time_counter < 9999) g_time_counter++;
        else g_is_running = 0;
    } else if (g_current_mode == MODE_TIMER) {
        if (g_time_counter > 0) g_time_counter--;
        if (g_time_counter == 0) {
            g_is_running = 0;
            usart1_tx_string("\r\n>> Timer Complete! <<\r\n");
        }
    }
}

ISR(USART1_RX_vect) {
    char received_char = UDR1;
    
    // [수정된 부분] 수신된 문자를 터미널에 즉시 되돌려 보냄 (에코 기능)
    usart1_tx_char(received_char);

    if (g_rx_index < RX_BUFFER_SIZE - 1) {
        if (received_char == '\r' || received_char == '\n') {
            g_rx_buffer[g_rx_index] = '\0';
            if (g_rx_index > 0) process_command();
            g_rx_index = 0;
        } else {
            g_rx_buffer[g_rx_index++] = received_char;
        }
    } else {
        g_rx_index = 0;
    }
}

// --- 주요 기능 함수 ---
void display_fnd(uint16_t time_val) {
    unsigned char digits[4];
    digits[0] = (time_val / 1000) % 10;
    digits[1] = (time_val / 100) % 10;
    digits[2] = (time_val / 10) % 10;
    digits[3] = time_val % 10;

    for (int i = 0; i < 4; i++) {
        FND_CONTROL_PORT = (1 << (i + 4));
        unsigned char data = g_fnd_font_cathode[digits[i]];
        if (i != 1) {
            data |= 0b10000000;
        }
        FND_DATA_PORT = data;
        _delay_ms(2);
    }
}

void handle_buttons(void) {
    if (!(BUTTON_PIN & (1 << START_STOP_BTN))) {
        _delay_ms(50);
        if (g_current_mode == MODE_STOPWATCH) g_is_running = !g_is_running;
        while(!(BUTTON_PIN & (1 << START_STOP_BTN)));
    }
    if (!(BUTTON_PIN & (1 << RESET_BTN))) {
        _delay_ms(50);
        if (g_current_mode == MODE_STOPWATCH && !g_is_running) g_time_counter = 0;
        while(!(BUTTON_PIN & (1 << RESET_BTN)));
    }
}

void process_command(void) {
    char cmd[RX_BUFFER_SIZE];
    strcpy(cmd, (const char*)g_rx_buffer);

    // '\r' 문자가 버퍼에 남아있을 수 있으므로 제거
    cmd[strcspn(cmd, "\r")] = 0;

    if (strcmp(cmd, "M0") == 0) {
        g_current_mode = MODE_STOPWATCH;
        reset_system_state();
    } else if (strcmp(cmd, "M1") == 0) {
        g_current_mode = MODE_TIMER;
        reset_system_state();
    } else if (g_current_mode == MODE_TIMER) {
        if (cmd[0] == 'T' && cmd[1] >= '0' && cmd[1] <= '9') {
            int seconds = atoi(&cmd[1]);
            if (seconds > 0 && seconds <= 99) {
                g_time_counter = (uint16_t)seconds * 100;
                g_is_running = 1;
                char msg[40];
                sprintf(msg, "\r\n[Timer Start] Set to %d seconds.\r\n", seconds);
                usart1_tx_string(msg);
            } else {
                usart1_tx_string("\r\n[Error] Invalid time. Use 1-99 seconds.\r\n");
            }
        } else if (strcmp(cmd, "TP") == 0) {
            g_is_running = 0;
            usart1_tx_string("\r\n[Timer Paused]\r\n");
        } else if (strcmp(cmd, "TR") == 0) {
            if (g_time_counter > 0) {
                g_is_running = 1;
                usart1_tx_string("\r\n[Timer Resumed]\r\n");
            }
        }
    }
}

void reset_system_state(void) {
    g_is_running = 0;
    g_time_counter = 0;
    if (g_current_mode == MODE_STOPWATCH) {
        usart1_tx_string("\r\n[Mode Change] -> Stopwatch Mode Activated.\r\n");
    } else {
        usart1_tx_string("\r\n[Mode Change] -> Timer Mode Activated.\r\n");
    }
}

// --- USART 통신 유틸리티 ---
void usart1_tx_char(char data) {
    while (!((UCSR1A >> UDRE1) & 0x1));
    UDR1 = data;
}

void usart1_tx_string(const char *str) {
    while (*str) usart1_tx_char(*str++);
}
