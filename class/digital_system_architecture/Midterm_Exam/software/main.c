/***************************** Include Files ********************************/
#include "xparameters.h"    // 하드웨어 파라미터 (Device ID 등)
#include "xgpio.h"          // AXI GPIO 드라이버 API
#include "xuartlite.h"      // AXI UART Lite 드라이버 API
#include "xil_printf.h"     // 콘솔 출력 함수
// #include "xil_types.h"   // <<-- 제거됨
// #include <stdlib.h>      // <<-- 제거됨

/************************** Constant Definitions ****************************/
// GPIO 관련 정의
#define GPIO_DEVICE_ID         XPAR_AXI_GPIO_0_DEVICE_ID // xparameters.h 에서 정의됨
#define LED_CHANNEL            2 // geurim.pdf 기반, GPIO2 포트
#define SWITCH_CHANNEL         1 // geurim.pdf 기반, GPIO 포트
#define LED0_MASK              0x0001 // 0번 비트 마스크
#define SWITCH_1_TO_15_MASK    0xFFFE // 1~15번 비트 마스크

// UART 관련 정의 추가
#define UARTLITE_DEVICE_ID     XPAR_AXI_UARTLITE_0_DEVICE_ID // xparameters.h 에서 정의됨
#define UART_BUFFER_SIZE       16 // UART 입력 버퍼 크기

// 모드 정의 (가독성)
#define MODE_SWITCH            0
#define MODE_UART              1

// --- UART Lite 저수준 레지스터 접근용 상수 (주의: 비표준 우회용) ---
#define XUL_STATUS_REG_OFFSET     0x08  // 상태 레지스터 오프셋
#define XUL_SR_RX_FIFO_VALID_DATA 0x01  // 상태 레지스터 내 수신 데이터 유효 비트 (Bit 0)
#define XUL_RX_FIFO_OFFSET        0x00  // 수신 FIFO 레지스터 오프셋
#define XUL_TX_FIFO_OFFSET        0x04  // 송신 FIFO 레지스터 오프셋

/************************** Function Prototypes *****************************/
// 표준 C 타입 또는 기본 타입 사용
int InitializeGpio();
// unsigned int 사용 (u32 대신)
void HandleSwitchControlMode(XGpio *GpioInstPtr, unsigned int *previous_switch_state_ptr, unsigned int *current_led_state_ptr);
int InitializeUartLite();
void HandleUartControlMode(XUartLite *UartInstPtr, XGpio *GpioInstPtr, unsigned int *current_led_state_ptr);
// int 사용, char* 사용
int UartReceiveInteger(XUartLite *UartInstPtr, char *buffer, int buffer_size);
// atoi 대신 사용할 사용자 정의 함수
int custom_atoi(const char *str);

/************************** Variable Definitions ****************************/
// 드라이버 인스턴스 (전역) - 딱 한 번만 정의되어야 함
XGpio GpioInstance;
XUartLite UartLiteInstance;

// 상태 변수 (전역, unsigned int 사용) - 딱 한 번만 정의되어야 함
unsigned int previous_sw_state = 0;
unsigned int current_led_state = 0;
int current_mode = -1; // -1: 초기 상태

/************************** Function Definitions ****************************/

/**
 * @brief 메인 함수: 시스템 초기화 및 주 제어 루프 실행 - 딱 한 번만 정의되어야 함
 */
int main()
{
    int Status; // 함수 상태 반환값 저장용

    // --- 초기화 ---
    xil_printf("\r\n--- System Initialization ---\r\n");

    // GPIO 초기화
    Status = InitializeGpio();
    if (Status != 0) { // 0: 성공, 0이 아니면 실패
        xil_printf("GPIO Initialization Failed\r\n");
        return 1; // 실패 시 1 반환
    }

    // UART Lite 초기화
    Status = InitializeUartLite();
    if (Status != 0) {
        xil_printf("UART Initialization Failed\r\n");
        return 1;
    }

    xil_printf("--- Initialization Complete ---\r\n");

    // --- 초기 모드 설정 및 상태 설정 ---
    previous_sw_state = XGpio_DiscreteRead(&GpioInstance, SWITCH_CHANNEL);
    current_led_state = (previous_sw_state & SWITCH_1_TO_15_MASK) | LED0_MASK;
    XGpio_DiscreteWrite(&GpioInstance, LED_CHANNEL, current_led_state);
    current_mode = (previous_sw_state & LED0_MASK) ? MODE_UART : MODE_SWITCH;

    if (current_mode == MODE_SWITCH) {
        xil_printf("***** Switch Control Mode *****\r\n");
    } else {
        xil_printf("***** UART Control Mode *****\r\n");
    }
    xil_printf("Initial Switches: 0x%04X, Initial LEDs: 0x%04X\r\n", previous_sw_state, current_led_state);


    // --- 메인 루프 ---
    while (1) // 무한 반복
    {
        // 1. 현재 스위치 상태 읽기
        unsigned int current_switch_state = XGpio_DiscreteRead(&GpioInstance, SWITCH_CHANNEL);
        // 2. SW0 값으로 새로운 모드 확인
        int new_mode = (current_switch_state & LED0_MASK) ? MODE_UART : MODE_SWITCH;

        // 3. 모드 전환 감지 및 처리
        if (new_mode != current_mode) {
            current_mode = new_mode;
            if (current_mode == MODE_SWITCH) {
                xil_printf("\r\n***** Switch Control Mode *****\r\n");
                current_led_state = (current_switch_state & SWITCH_1_TO_15_MASK) | LED0_MASK;
                XGpio_DiscreteWrite(&GpioInstance, LED_CHANNEL, current_led_state);
                previous_sw_state = current_switch_state;
            } else {
                xil_printf("\r\n***** UART Control Mode *****\r\n");
            }
        }

        // 4. 현재 모드에 따른 작업 수행
        if (current_mode == MODE_SWITCH) {
            HandleSwitchControlMode(&GpioInstance, &previous_sw_state, &current_led_state);
        } else { // current_mode == MODE_UART
            HandleUartControlMode(&UartLiteInstance, &GpioInstance, &current_led_state);
        }
    }
    // return 0; // 도달하지 않음
}

/**
 * @brief GPIO 디바이스 초기화 및 채널 방향 설정 - 딱 한 번만 정의되어야 함
 * @return 성공 시 0, 실패 시 1
 */
int InitializeGpio()
{
    int Status;
    XGpio_Config *cfg_ptr;

    cfg_ptr = XGpio_LookupConfig(GPIO_DEVICE_ID);
    if (cfg_ptr == NULL) {
         xil_printf("GPIO LookupConfig failed\r\n");
         return 1;
    }

    Status = XGpio_CfgInitialize(&GpioInstance, cfg_ptr, cfg_ptr->BaseAddress);
    if (Status != 0) {
        xil_printf("GPIO CfgInitialize failed\r\n");
        return 1;
    }

    XGpio_SetDataDirection(&GpioInstance, LED_CHANNEL, 0x00000000);
    XGpio_SetDataDirection(&GpioInstance, SWITCH_CHANNEL, 0xFFFFFFFF);

    xil_printf("GPIO Initialized Successfully.\r\n");
    return 0;
}

/**
 * @brief UART Lite 디바이스 초기화 - 딱 한 번만 정의되어야 함
 * @return 성공 시 0, 실패 시 1
 */
int InitializeUartLite()
{
    int Status;
    Status = XUartLite_Initialize(&UartLiteInstance, UARTLITE_DEVICE_ID);
    if (Status != 0) {
        xil_printf("UARTLite Initialize Failed\r\n");
        return 1;
    }
    XUartLite_ResetFifos(&UartLiteInstance);
    xil_printf("UART Initialized Successfully.\r\n");
    return 0;
}


/**
 * @brief 스위치 제어 모드 처리 (요구사항 1, 2, 3) - 딱 한 번만 정의되어야 함
 * @param GpioInstPtr GPIO 인스턴스 포인터
 * @param previous_switch_state_ptr 이전 스위치 상태 변수의 주소
 * @param current_led_state_ptr 현재 LED 상태 변수의 주소
 */
void HandleSwitchControlMode(XGpio *GpioInstPtr, unsigned int *previous_switch_state_ptr, unsigned int *current_led_state_ptr)
{
    unsigned int current_switch_state;
    unsigned int new_led_state;

    current_switch_state = XGpio_DiscreteRead(GpioInstPtr, SWITCH_CHANNEL);

    if (current_switch_state != *previous_switch_state_ptr)
    {
        xil_printf("[LED Update] Switch Changed (Prev: 0x%04X, Curr: 0x%04X)\r\n", *previous_switch_state_ptr, current_switch_state);
        new_led_state = (current_switch_state & SWITCH_1_TO_15_MASK) | LED0_MASK;
        XGpio_DiscreteWrite(GpioInstPtr, LED_CHANNEL, new_led_state);
        *current_led_state_ptr = new_led_state;
        *previous_switch_state_ptr = current_switch_state;
    }
}

/**
 * @brief 사용자 정의 atoi 함수: 간단한 ASCII 문자열을 양의 정수로 변환 - 딱 한 번만 정의되어야 함
 * @param str 변환할 숫자 문자열
 * @return 변환된 정수 값. 오류(숫자 아닌 문자 포함 등) 시 -1 반환.
 */
int custom_atoi(const char *str)
{
    int result = 0;
    int i = 0;
    int has_digit = 0;

    if (str == NULL) { return -1; }

    while (str[i] != '\0') {
        if (str[i] >= '0' && str[i] <= '9') {
             if (result > (2147483647 / 10) || (result == (2147483647 / 10) && (str[i] - '0') > (2147483647 % 10))) {
                 return -1;
             }
            result = result * 10 + (str[i] - '0');
            has_digit = 1;
        } else {
            return -1;
        }
        i++;
    }
    if (!has_digit) { return -1; }
    return result;
}


/**
 * @brief UART로부터 숫자 입력을 받아 정수로 변환하는 헬퍼 함수 (저수준 우회 적용) - 딱 한 번만 정의되어야 함
 * @param UartInstPtr UART 인스턴스 포인터
 * @param buffer 수신 문자 임시 저장 버퍼
 * @param buffer_size 버퍼 크기
 * @return 변환된 정수. 오류 시 -1.
 */
int UartReceiveInteger(XUartLite *UartInstPtr, char *buffer, int buffer_size)
{
    unsigned char RecvChar;
    int i = 0;
    int valid_input = 0;

    buffer[0] = '\0';

    while (i < buffer_size - 1) {
        // --- XUartLite_IsReceiveEmpty 우회: 저수준 상태 레지스터 직접 확인 ---
        while ((XUartLite_ReadReg(UartInstPtr->RegBaseAddress, XUL_STATUS_REG_OFFSET) & XUL_SR_RX_FIFO_VALID_DATA) == 0);
        // ---------------------------------------------------------------------

        RecvChar = XUartLite_RecvByte(UartInstPtr->RegBaseAddress);

        if (RecvChar == '\r' || RecvChar == '\n') {
            if (valid_input) break; else continue;
        }
        else if ((RecvChar == '\b' || RecvChar == 127) && i > 0) {
            i--; buffer[i] = '\0'; xil_printf("\b \b");
            if (i == 0) valid_input = 0;
        }
        else if (RecvChar >= '0' && RecvChar <= '9') {
            buffer[i++] = (char)RecvChar; buffer[i] = '\0';
            XUartLite_Send(UartInstPtr, &RecvChar, 1);
            valid_input = 1;
        }
    }

    if (!valid_input) { return -1; }
    return custom_atoi(buffer);
}


/**
 * @brief UART 원격 제어 모드 처리 (요구사항 1~5) - 딱 한 번만 정의되어야 함
 * @param UartInstPtr UART 인스턴스 포인터
 * @param GpioInstPtr GPIO 인스턴스 포인터
 * @param current_led_state_ptr 현재 LED 상태 변수의 주소
 */
void HandleUartControlMode(XUartLite *UartInstPtr, XGpio *GpioInstPtr, unsigned int *current_led_state_ptr)
{
    char recv_buffer[UART_BUFFER_SIZE];
    int led_num = -1;
    int led_state = -1;

    xil_printf("==> Enter LED Number (0 ~ 15): ");
    led_num = UartReceiveInteger(UartInstPtr, recv_buffer, UART_BUFFER_SIZE);
    xil_printf("\r\n");

    if (led_num < 0 || led_num > 15) {
        xil_printf("[Error] Invalid LED Number (%d). Must be 0-15.\r\n", led_num);
        return;
    }

    xil_printf("==> Enter LED State (On = 1, Off = 0): ");
    led_state = UartReceiveInteger(UartInstPtr, recv_buffer, UART_BUFFER_SIZE);
    xil_printf("\r\n");

    if (led_state != 0 && led_state != 1) {
        xil_printf("[Error] Invalid LED State (%d). Must be 0 or 1.\r\n", led_state);
        return;
    }

    if (led_state == 1) {
        *current_led_state_ptr |= (1 << led_num);
    } else {
        *current_led_state_ptr &= ~(1 << led_num);
    }
    XGpio_DiscreteWrite(GpioInstPtr, LED_CHANNEL, *current_led_state_ptr);

    xil_printf("[LED Update] UART Command Received (LED %d -> %s)\r\n",
               led_num, (led_state == 1) ? "ON" : "OFF");
}
