/*********************************************************************
 * INCLUDES
 */

#include "bcomdef.h"
#include "OSAL.h"
#include "OSAL_PwrMgr.h"
#include "OSAL_Clock.h"

#include "OnBoard.h"
#include "hal_adc.h"
#include "hal_led.h"
#include "hal_key.h"

#include "hal_i2c.h"

#include "battservice.h"

#include "debug.h"

#include "gatt.h"

#include "hci.h"

#include "gapgattserver.h"
#include "gattservapp.h"
#include "devinfoservice.h"
#include "health_profile.h"

#include "peripheral.h"

#include "gapbondmgr.h"

#include "mma865x.h"

#include "simpleBLEPeripheral.h"

#if defined FEATURE_OAD
#include "oad.h"
#include "oad_target.h"
#endif

/*********************************************************************
 * MACROS
 */

/*********************************************************************
 * CONSTANTS
 */

#define HI_UINT32(x)                          (((x) >> 16) & 0xffff)
#define LO_UINT32(x)                          ((x) & 0xffff)

// define LEDs
#define LED0_PIO                              P0_2
#define LED1_PIO                              P0_3
#define LED2_PIO                              P0_1
#define LED3_PIO                              P0_4
#define LED4_PIO                              P0_5
#define LED5_PIO                              P0_6
#define LED6_PIO                              P1_0
#define LED7_PIO                              P1_6
#define LED8_PIO                              P1_7
#define LED9_PIO                              P2_1
#define LED10_PIO                             P2_2
#define LED11_PIO                             P2_0

#define MOTOR_PIO                             P0_0

#define OPEN_PIO                              0
#define CLOSE_PIO                             1

// How often to perform periodic event
#define SBP_PERIODIC_EVT_PERIOD               0

// What is the advertising interval when device is discoverable (units of 625us, 160=100ms)
#define DEFAULT_ADVERTISING_INTERVAL          160

// Limited discoverable mode advertises for 30.72s, and then stops
// General discoverable mode advertises indefinitely

#define DEFAULT_DISCOVERABLE_MODE             GAP_ADTYPE_FLAGS_GENERAL

// Minimum connection interval (units of 1.25ms, 80=100ms) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_MIN_CONN_INTERVAL     80

// Maximum connection interval (units of 1.25ms, 800=1000ms) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_MAX_CONN_INTERVAL     160

// Slave latency to use if automatic parameter update request is enabled
#define DEFAULT_DESIRED_SLAVE_LATENCY         4

// Supervision timeout value (units of 10ms, 1000=10s) if automatic parameter update request is enabled
#define DEFAULT_DESIRED_CONN_TIMEOUT          5000

// Whether to enable automatic parameter update request when a connection is formed
#define DEFAULT_ENABLE_UPDATE_REQUEST         TRUE

// Connection Pause Peripheral time value (in seconds)
#define DEFAULT_CONN_PAUSE_PERIPHERAL         6

// Company Identifier: Texas Instruments Inc. (13)
#define TI_COMPANY_ID                         0x000D

#define INVALID_CONNHANDLE                    0xFFFF

// Length of bd addr as a string
#define B_ADDR_STR_LEN                        15

// Battery level is critical when it is less than this %
#define DEFAULT_BATT_CRITICAL_LEVEL           6

// Battery measurement period in ms
#define DEFAULT_BATT_PERIOD                   15000

// Battery measurement period in ms
#define DEFAULT_ACC_PERIOD                    100




// define i2c address
#define ACC_ADDRESS                           0x1D

//define registers for MMA8652FC
#define F_STATUS                    0x00
#define OUT_X_MSB                   0x01
#define OUT_X_LSB                   0x02
#define OUT_Y_MSB                   0x03
#define OUT_Y_LSB                   0x04
#define OUT_Z_MSB                   0x05
#define OUT_Z_LSB                   0x06

#define F_SETUP                     0x09
#define TRIG_CFG                    0x0A
#define SYSMOD                      0x0B
#define INT_SOURCE                  0x0C
#define WHO_AM_I                    0x0D
#define XYZ_DATA_CFG                0x0E
#define HP_FILTER_CUTOFF            0x0F

#define PL_STATUS                   0x10
#define PL_CFG                      0x11
#define PL_COUNT                    0x12
#define PL_BF_ZCOMP                 0x13
#define P_L_THS_REG                 0x14
#define FF_MT_CFG                   0x15
#define FF_MT_SRC                   0x16
#define FF_MT_THS                   0x17
#define FF_MT_COUNT                 0x18

#define TRANSIENT_CFG               0x1D
#define TRANSIENT_SRC               0x1E
#define TRANSIENT_THS               0x1F
#define TRANSIENT_COUNT             0x20

#define PULSE_CFG                   0x21
#define PULSE_SRC                   0x22
#define PULSE_THSX                  0x23
#define PULSE_THSY                  0x24
#define PULSE_THSZ                  0x25
#define PULSE_TMLT                  0x26
#define PULSE_LTCY                  0x27
#define PULSE_WIND                  0x28
#define ASLP_COUNT                  0x29
#define CTRL_REG1                   0x2A
#define CTRL_REG2                   0x2B
#define CTRL_REG3                   0x2C
#define CTRL_REG4                   0x2D
#define CTRL_REG5                   0x2E
#define OFF_X                       0x2F
#define OFF_Y                       0x30
#define OFF_Z                       0x31

uint8 X0, X1, Y0, Y1, Z1, Z0;
int16 X_out, Y_out, Z_out;
uint8 INT_STATUS;

int16 PACE_DUR_MIN = 6; //0.3s
int16 PACE_DUR_MAX = 12; //1.2s
int16 ALT_MIN = 300;
int16 DIR = 1; //12
int16 first_pace = 1; //
int16 pace_count = 0; //
int16 PACE_PEAK = 0;
int16 PACE_BOTTOM = 0;
int16 time_count = 0;
int16 cross_count = 0; //0
int16 ACC_CUR = 0;


#define EEPROM_ADDRESS                      0x50

//define i2c clock rate
#define I2C_CLOCK_RATE                      i2cClock_33KHZ

// define for eeprom
#define EEPROM_ADDRESS_BLOCK_SIZE           8
#define EEPROM_ADDRESS_BLOCK_COUNT          4000

#define EEPROM_ADDRESS_RESERVE_MAX          32768
#define EEPROM_ADDRESS_DATA_MAX             (EEPROM_ADDRESS_BLOCK_SIZE * EEPROM_ADDRESS_BLOCK_COUNT)

#define EEPROM_POSITION_STEP_DATA           (EEPROM_ADDRESS_DATA_MAX)

#define TAP_DATA_TYPE                       1
#define STEP_DATA_TYPE                      2
#define TAP_HOUR_START_TYPE                 3

#define DATA_TYPE_COUNT                     3

#define SYNC_CODE                           22

#define LONG_PRESS_INTERVAL                 1000
#define DOUBLE_PRESS_INTERVAL               500
#define ACC_LOAD_INTERVAL                   2500    // 80MS * 30
#define LED_CYCLE_INTERVAL                  100
#define BLINK_LED_INTERVAL                  500
#define TIME_DISPLAY_INTERVAL               5000


/*********************************************************************
 * TYPEDEFS
 */

/*********************************************************************
 * GLOBAL VARIABLES
 */

/*********************************************************************
 * EXTERNAL VARIABLES
 */

/*********************************************************************
 * EXTERNAL FUNCTIONS
 */

/*********************************************************************
 * LOCAL VARIABLES
 */
static uint8 simpleBLEPeripheral_TaskID;   // Task ID for internal task/event processing

static gaprole_States_t gapProfileState = GAPROLE_INIT;

// GAP - SCAN RSP data (max size = 31 bytes)
uint8 scanRspData[] =
{
    // complete name
    0x11,   // length of this data, p.s. contain header and body
    GAP_ADTYPE_LOCAL_NAME_COMPLETE,
    'A',
    'd',
    'd',
    'i',
    'n',
    'g',
    ' ',
    'A',
    '1',
    '-',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',

    // connection interval range
    0x05,   // length of this data
    GAP_ADTYPE_SLAVE_CONN_INTERVAL_RANGE,
    LO_UINT16( DEFAULT_DESIRED_MIN_CONN_INTERVAL ),
    HI_UINT16( DEFAULT_DESIRED_MIN_CONN_INTERVAL ),
    LO_UINT16( DEFAULT_DESIRED_MAX_CONN_INTERVAL ),
    HI_UINT16( DEFAULT_DESIRED_MAX_CONN_INTERVAL ),

    // Tx power level
    0x02,   // length of this data
    GAP_ADTYPE_POWER_LEVEL,
    0       // 0dBm
};

// GAP - Advertisement data (max size = 31 bytes, though this is
// best kept short to conserve power while advertisting)
static uint8 advertData[] =
{
    // Flags; this sets the device to use limited discoverable
    // mode (advertises for 30 seconds at a time) instead of general
    // discoverable mode (advertises indefinitely)
    0x02,   // length of this data
    GAP_ADTYPE_FLAGS,
    DEFAULT_DISCOVERABLE_MODE | GAP_ADTYPE_FLAGS_BREDR_NOT_SUPPORTED,

    // service UUID, to notify central devices what services are included
    // in this peripheral
    0x05,   // length of this data
    GAP_ADTYPE_16BIT_MORE,      // some of the UUID's, but not all
    LO_UINT16( HEALTH_SERV_UUID ),
    HI_UINT16( HEALTH_SERV_UUID ),
    LO_UINT16(BATT_SERVICE_UUID),
    HI_UINT16(BATT_SERVICE_UUID)

};

// GAP GATT Attributes
uint8 attDeviceName[GAP_DEVICE_NAME_LEN] = "Adding A1-000000";

// define for eeprom
uint16 stepDataStart = 0, stepDataStop = 0;

typedef struct
{
    UTCTimeStruct       tm;
    UTCTime             hourSeconds;
    uint16              count;
    uint8               type;
}one_data_t;

one_data_t oneData[DATA_TYPE_COUNT];

// RAM DB
// uint8 db[EEPROM_ADDRESS_DATA_MAX];

// define for keys
uint8 slipWaitFor = 0, lockSlip = 0, blinkPIO = 0, blinkMinutes = 13, onTheKey = 0, ledCycleCount = 0;

/*********************************************************************
 * LOCAL FUNCTIONS
 */
static void simpleBLEPeripheral_ProcessOSALMsg( osal_event_hdr_t *pMsg );
static void peripheralStateNotificationCB( gaprole_States_t newState );
static void performPeriodicTask( void );
static void simpleProfileChangeCB( uint8 paramID );

static void battPeriodicTask( void );
static void battCB(uint8 event);

static void accInit(void);
static void accLoop(void);

// static void accGetIntData(void);
// static void accGetAccData(void);
static void accGetAccData(uint8 count);

static void eepromWrite(uint8 type);
static void eepromRead(void);

static void closeAllPIO(void);

static void shock(void);
static void time(void);

static void babyMove(void);

static void toggleLEDWithTime(uint8 num, uint8 io);
static void blinkLED(void);

static void toggleAdvert(uint8 status);

static void saveStepData();
static void loadStepData();


/*********************************************************************
 * PROFILE CALLBACKS
 */

// GAP Role Callbacks
static gapRolesCBs_t simpleBLEPeripheral_PeripheralCBs =
{
    peripheralStateNotificationCB,  // Profile State Change Callbacks
    NULL                            // When a valid RSSI is read from controller (not used by application)
};

// GAP Bond Manager Callbacks
static gapBondCBs_t simpleBLEPeripheral_BondMgrCBs =
{
    NULL,                     // Passcode callback (not used by application)
    NULL                      // Pairing / Bonding state Callback (not used by application)
};

// Simple GATT Profile Callbacks
static simpleProfileCBs_t simpleBLEPeripheral_SimpleProfileCBs =
{
    simpleProfileChangeCB    // Charactersitic value change callback
};

/*********************************************************************
 * PUBLIC FUNCTIONS
 */

/*********************************************************************
 * @fn      SimpleBLEPeripheral_Init
 *
 * @brief   Initialization function for the Simple BLE Peripheral App Task.
 *          This is called during initialization and should contain
 *          any application specific initialization (ie. hardware
 *          initialization/setup, table initialization, power up
 *          notificaiton ... ).
 *
 * @param   task_id - the ID assigned by OSAL.  This ID should be
 *                    used to send messages and set timers.
 *
 * @return  none
 */
void SimpleBLEPeripheral_Init( uint8 task_id )
{
    simpleBLEPeripheral_TaskID = task_id;

    // Debug_init(simpleBLEPeripheral_TaskID);

    //xp code
    accInit();
    //xp code

    // use low 6 bytes mac address of ti2541 to be our sn
    char hex[] = "0123456789ABCDEF";
    uint8 ownAddress[B_ADDR_LEN];

    // read unique ieee address
    LL_ReadBDADDR(ownAddress);

    uint8 sn[] =
    {
        hex[HI_UINT8(ownAddress[2])],
        hex[LO_UINT8(ownAddress[2])],
        hex[HI_UINT8(ownAddress[1])],
        hex[LO_UINT8(ownAddress[1])],
        hex[HI_UINT8(ownAddress[0])],
        hex[LO_UINT8(ownAddress[0])]
    };

    // rewrite device name
    osal_memcpy(&scanRspData[12], sn, sizeof(sn));
    osal_memcpy(&attDeviceName[10], sn, sizeof(sn));

    // Setup the GAP
    VOID GAP_SetParamValue( TGAP_CONN_PAUSE_PERIPHERAL, DEFAULT_CONN_PAUSE_PERIPHERAL );

    // Setup the GAP Peripheral Role Profile
    {
        // For other hardware platforms, device starts advertising upon initialization
        uint8 initial_advertising_enable = TRUE;

        // By setting this to zero, the device will go into the waiting state after
        // being discoverable for 30.72 second, and will not being advertising again
        // until the enabler is set back to TRUE
        uint16 gapRole_AdvertOffTime = 0;

        uint8 enable_update_request = DEFAULT_ENABLE_UPDATE_REQUEST;
        uint16 desired_min_interval = DEFAULT_DESIRED_MIN_CONN_INTERVAL;
        uint16 desired_max_interval = DEFAULT_DESIRED_MAX_CONN_INTERVAL;
        uint16 desired_slave_latency = DEFAULT_DESIRED_SLAVE_LATENCY;
        uint16 desired_conn_timeout = DEFAULT_DESIRED_CONN_TIMEOUT;

        // Set the GAP Role Parameters
        GAPRole_SetParameter( GAPROLE_ADVERT_ENABLED, sizeof( uint8 ), &initial_advertising_enable );
        GAPRole_SetParameter( GAPROLE_ADVERT_OFF_TIME, sizeof( uint16 ), &gapRole_AdvertOffTime );

        GAPRole_SetParameter( GAPROLE_SCAN_RSP_DATA, sizeof ( scanRspData ), scanRspData );
        GAPRole_SetParameter( GAPROLE_ADVERT_DATA, sizeof( advertData ), advertData );

        GAPRole_SetParameter( GAPROLE_PARAM_UPDATE_ENABLE, sizeof( uint8 ), &enable_update_request );
        GAPRole_SetParameter( GAPROLE_MIN_CONN_INTERVAL, sizeof( uint16 ), &desired_min_interval );
        GAPRole_SetParameter( GAPROLE_MAX_CONN_INTERVAL, sizeof( uint16 ), &desired_max_interval );
        GAPRole_SetParameter( GAPROLE_SLAVE_LATENCY, sizeof( uint16 ), &desired_slave_latency );
        GAPRole_SetParameter( GAPROLE_TIMEOUT_MULTIPLIER, sizeof( uint16 ), &desired_conn_timeout );
    }

    // Set the GAP Characteristics
    GGS_SetParameter( GGS_DEVICE_NAME_ATT, GAP_DEVICE_NAME_LEN, attDeviceName );

    // Set advertising interval
    {
        uint16 advInt = DEFAULT_ADVERTISING_INTERVAL;

        GAP_SetParamValue( TGAP_LIM_DISC_ADV_INT_MIN, advInt );
        GAP_SetParamValue( TGAP_LIM_DISC_ADV_INT_MAX, advInt );
        GAP_SetParamValue( TGAP_GEN_DISC_ADV_INT_MIN, advInt );
        GAP_SetParamValue( TGAP_GEN_DISC_ADV_INT_MAX, advInt );
    }

    // Setup the GAP Bond Manager
    {
        uint32 passkey = 0; // passkey "000000"
        uint8 pairMode = GAPBOND_PAIRING_MODE_WAIT_FOR_REQ;
        // uint8 pairMode = GAPBOND_PAIRING_MODE_NO_PAIRING;
        uint8 mitm = TRUE;
        uint8 ioCap = GAPBOND_IO_CAP_DISPLAY_ONLY;
        uint8 bonding = TRUE;
        GAPBondMgr_SetParameter( GAPBOND_DEFAULT_PASSCODE, sizeof ( uint32 ), &passkey );
        GAPBondMgr_SetParameter( GAPBOND_PAIRING_MODE, sizeof ( uint8 ), &pairMode );
        GAPBondMgr_SetParameter( GAPBOND_MITM_PROTECTION, sizeof ( uint8 ), &mitm );
        GAPBondMgr_SetParameter( GAPBOND_IO_CAPABILITIES, sizeof ( uint8 ), &ioCap );
        GAPBondMgr_SetParameter( GAPBOND_BONDING_ENABLED, sizeof ( uint8 ), &bonding );
    }

    // Initialize GATT attributes
    GGS_AddService( GATT_ALL_SERVICES );            // GAP
    GATTServApp_AddService( GATT_ALL_SERVICES );    // GATT attributes
    // DevInfo_AddService();                           // Device Information Service
    SimpleProfile_AddService( GATT_ALL_SERVICES );  // Simple GATT Profile
    Batt_AddService();

#if defined FEATURE_OAD
    VOID OADTarget_AddService();                    // OAD Profile
#endif

    // Setup the SimpleProfile Characteristic Values
    {
        // uint8   healthSync = 1;
        // uint32  healthClock = 0;
        uint16  healthDataHeader = DATA_TYPE_COUNT;
        // uint8   healthDataBody = 0;
        // SimpleProfile_SetParameter( HEALTH_SYNC, sizeof ( uint8 ), &healthSync );
        // SimpleProfile_SetParameter( HEALTH_CLOCK, sizeof ( uint32 ), &healthClock );
        SimpleProfile_SetParameter( HEALTH_DATA_HEADER, sizeof ( uint16 ), &healthDataHeader );
        // SimpleProfile_SetParameter( HEALTH_DATA_BODY, sizeof ( uint8 ), &healthDataBody );
    }

    // Setup Battery Characteristic Values
    {
        uint8 critical = DEFAULT_BATT_CRITICAL_LEVEL;
        Batt_SetParameter( BATT_PARAM_CRITICAL_LEVEL, sizeof (uint8 ), &critical );
    }

    // see the name
    RegisterForKeys( simpleBLEPeripheral_TaskID );

    // initialize IO's settings    

    // OBSSEL0 = 0x00;
    // OBSSEL1 = 0x00;

    P0DIR = 0x7F;
    P0SEL = 0x00;

    P1DIR = 0xC3;
    P1SEL = 0x00;

    P2DIR = 0xFF;
    P2SEL = 0x00;

    // sunshine!
    // P0 = B(10000001);
    // P1 = 0x00;
    // P2 = 0x00;

    //close all
    closeAllPIO();

    // MOTOR_PIO = OPEN_PIO;

    // Register callback with SimpleGATTprofile
    VOID SimpleProfile_RegisterAppCBs( &simpleBLEPeripheral_SimpleProfileCBs );

    // Register for Battery service callback;
    Batt_Register ( battCB );

    // Enable clock divide on halt
    // This reduces active current while radio is active and CC254x MCU
    // is halted
    HCI_EXT_ClkDivOnHaltCmd( HCI_EXT_ENABLE_CLK_DIVIDE_ON_HALT );

#if defined ( DC_DC_P0_7 )

    // Enable stack to toggle bypass control on TPS62730 (DC/DC converter)
    HCI_EXT_MapPmIoPortCmd( HCI_EXT_PM_IO_PORT_P0, HCI_EXT_PM_IO_PORT_PIN7 );

#endif // defined ( DC_DC_P0_7 )

    osal_set_event( simpleBLEPeripheral_TaskID, ACC_PERIODIC_EVT );

    // load step data from eeprom
    loadStepData();

    uint16 length = ((stepDataStop - stepDataStart) / 8) + DATA_TYPE_COUNT;
    SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &length);

    // Setup a delayed profile startup
    osal_set_event( simpleBLEPeripheral_TaskID, SBP_START_DEVICE_EVT );
}

/*********************************************************************
 * @fn      SimpleBLEPeripheral_ProcessEvent
 *
 * @brief   Simple BLE Peripheral Application Task event processor.  This function
 *          is called to process all events for the task.  Events
 *          include timers, messages and any other user defined events.
 *
 * @param   task_id  - The OSAL assigned task ID.
 * @param   events - events to process.  This is a bit map and can
 *                   contain more than one event.
 *
 * @return  events not processed
 */
uint16 SimpleBLEPeripheral_ProcessEvent( uint8 task_id, uint16 events )
{

    VOID task_id; // OSAL required parameter that isn't used in this function

    if ( events & SYS_EVENT_MSG )
    {
        uint8 *pMsg;

        if ( (pMsg = osal_msg_receive( simpleBLEPeripheral_TaskID )) != NULL )
        {
            simpleBLEPeripheral_ProcessOSALMsg( (osal_event_hdr_t *)pMsg );

            // Release the OSAL message
            VOID osal_msg_deallocate( pMsg );
        }

        // return unprocessed events
        return (events ^ SYS_EVENT_MSG);
    }

    if ( events & SBP_START_DEVICE_EVT )
    {
        // Start the Device
        VOID GAPRole_StartDevice( &simpleBLEPeripheral_PeripheralCBs );

        // Start Bond Manager
        VOID GAPBondMgr_Register( &simpleBLEPeripheral_BondMgrCBs );

        toggleAdvert(TRUE);

        // Set timer for first periodic event
        osal_start_timerEx( simpleBLEPeripheral_TaskID, SBP_PERIODIC_EVT, SBP_PERIODIC_EVT_PERIOD );

        return ( events ^ SBP_START_DEVICE_EVT );
    }

    if ( events & ACC_PERIODIC_EVT )
    {

        // accLoop();

        HalI2CInit(ACC_ADDRESS, I2C_CLOCK_RATE);

        uint8 addr, val;

        addr = F_STATUS;
        HalMotionI2CWrite(1, &addr);
        HalMotionI2CRead(1, &val);

        val &= ~(BV(6)|BV(7));

        if (val)
        {
            accGetAccData(val);
        }

        // {
        //     uint8 d[8] = {val,0,0,0,0,0,0,0};

        //     // osal_memcpy(&d[0], &X_out, sizeof(int16));
        //     // osal_memcpy(&d[2], &Y_out, sizeof(int16));
        //     // osal_memcpy(&d[4], &Z_out, sizeof(int16));

        //     SimpleProfile_SetParameter( HEALTH_SYNC, 8, d );
        // }

        // restart timer
        // osal_start_timerEx( simpleBLEPeripheral_TaskID, ACC_PERIODIC_EVT, 100 );
        osal_start_timerEx( simpleBLEPeripheral_TaskID, ACC_PERIODIC_EVT, ACC_LOAD_INTERVAL );

        return (events ^ ACC_PERIODIC_EVT);
    }



    if ( events & BATT_PERIODIC_EVT )
    {
        // Perform periodic battery task
        battPeriodicTask();

        return (events ^ BATT_PERIODIC_EVT);
    }

    if ( events & SBP_PERIODIC_EVT )
    {
        // Restart timer
        if ( SBP_PERIODIC_EVT_PERIOD )
        {
            osal_start_timerEx( simpleBLEPeripheral_TaskID, SBP_PERIODIC_EVT, SBP_PERIODIC_EVT_PERIOD );
        }

        // Perform periodic application task
        performPeriodicTask();

        return (events ^ SBP_PERIODIC_EVT);
    }

    if ( events & SLIP_TIMEOUT_EVT )
    {

        // double tap!!!
        if (slipWaitFor == 3)
        {
            time();
        }

        slipWaitFor = 0;

        return (events ^ SLIP_TIMEOUT_EVT);
    }

    if ( events & MOTOR_STOP_EVT )
    {
        
        MOTOR_PIO = CLOSE_PIO;

        return (events ^ MOTOR_STOP_EVT);
    }

    if ( events & BLINK_LED_EVT )
    {
        
        blinkLED();

        return (events ^ BLINK_LED_EVT);
    }

    if ( events & TIME_STOP_EVT )
    {
        
        osal_stop_timerEx(simpleBLEPeripheral_TaskID, BLINK_LED_EVT);

        closeAllPIO();

        blinkPIO = 0;

        blinkMinutes = 13;

        lockSlip = 0;

        return (events ^ TIME_STOP_EVT);
    }

    if ( events & LED_CYCLE_EVT )
    {
        
        if (ledCycleCount < 7)
        {
            toggleLEDWithTime(ledCycleCount, OPEN_PIO);
            toggleLEDWithTime(12 - ledCycleCount, OPEN_PIO);
        }
        
        toggleLEDWithTime(ledCycleCount - 1, CLOSE_PIO);
        toggleLEDWithTime(13 - ledCycleCount, CLOSE_PIO);
        
        ledCycleCount++;
        
        if (ledCycleCount < 8)
        {
            osal_start_timerEx( simpleBLEPeripheral_TaskID, LED_CYCLE_EVT, LED_CYCLE_INTERVAL );

        }else{

            ledCycleCount = 0;
            lockSlip = 0;
        }

        return (events ^ LED_CYCLE_EVT);
    }

    if ( events & CLOSE_ALL_EVT )
    {

        closeAllPIO();

        return (events ^ CLOSE_ALL_EVT);
    }

    if ( events & LONG_PRESS_EVT )
    {

        if (onTheKey)
        {
            babyMove();
            eepromWrite(TAP_DATA_TYPE);
        }

        return (events ^ LONG_PRESS_EVT);
    }

    // Discard unknown events
    return 0;
}

/*********************************************************************
 * @fn      simpleBLEPeripheral_ProcessOSALMsg
 *
 * @brief   Process an incoming task message.
 *
 * @param   pMsg - message to process
 *
 * @return  none
 */
static void simpleBLEPeripheral_ProcessOSALMsg( osal_event_hdr_t *pMsg )
{
    switch ( pMsg->event )
    {

    case KEY_CHANGE:

    {
      
      // press > 0
      // release == 0
      uint8 keys = ((keyChange_t *)pMsg)->keys;

      onTheKey = keys ? 1 : 0;

      if (lockSlip)
      {
          break;
      }

      if (onTheKey)
      {
          osal_start_timerEx( simpleBLEPeripheral_TaskID, LONG_PRESS_EVT , LONG_PRESS_INTERVAL );
      }else{
        osal_stop_timerEx( simpleBLEPeripheral_TaskID, LONG_PRESS_EVT );
      }

      if (onTheKey)
      {
          if (slipWaitFor == 0)
          {
            slipWaitFor = 2;

          }else if (slipWaitFor == 2){

            slipWaitFor = 3;

            osal_stop_timerEx( simpleBLEPeripheral_TaskID, SLIP_TIMEOUT_EVT );

          }else if (slipWaitFor == 3){

            // trible tap!!
            eepromWrite(TAP_HOUR_START_TYPE);
            babyMove();

            osal_stop_timerEx( simpleBLEPeripheral_TaskID, SLIP_TIMEOUT_EVT );

            slipWaitFor = 0;
          }
      }

      if (slipWaitFor != 0)
      {
          osal_start_timerEx( simpleBLEPeripheral_TaskID, SLIP_TIMEOUT_EVT , DOUBLE_PRESS_INTERVAL );
      }

    }

      break;

    default:
        // do nothing
        break;
    }
}

/*********************************************************************
 * @fn      peripheralStateNotificationCB
 *
 * @brief   Notification from the profile of a state change.
 *
 * @param   newState - new state
 *
 * @return  none
 */
static void peripheralStateNotificationCB( gaprole_States_t newState )
{
    
    closeAllPIO();

    switch ( newState )
    {
    case GAPROLE_STARTED:
    {
        uint8 ownAddress[B_ADDR_LEN];
        uint8 systemId[DEVINFO_SYSTEM_ID_LEN];

        GAPRole_GetParameter(GAPROLE_BD_ADDR, ownAddress);

        // use 6 bytes of device address for 8 bytes of system ID value
        systemId[0] = ownAddress[0];
        systemId[1] = ownAddress[1];
        systemId[2] = ownAddress[2];

        // set middle bytes to zero
        systemId[4] = 0x00;
        systemId[3] = 0x00;

        // shift three bytes up
        systemId[7] = ownAddress[5];
        systemId[6] = ownAddress[4];
        systemId[5] = ownAddress[3];


        DevInfo_SetParameter(DEVINFO_SYSTEM_ID, DEVINFO_SYSTEM_ID_LEN, systemId);

        LED1_PIO = OPEN_PIO;
        
    }
    break;

    case GAPROLE_ADVERTISING:
    {
        LED2_PIO = OPEN_PIO;
    }
    break;

    case GAPROLE_CONNECTED:
    {
        LED3_PIO = OPEN_PIO;
    }
    break;

    case GAPROLE_WAITING:
    {
        LED4_PIO = OPEN_PIO;
    }
    break;

    case GAPROLE_WAITING_AFTER_TIMEOUT:
    {
        LED5_PIO = OPEN_PIO;
    }
    break;

    case GAPROLE_ERROR:
    {
        LED6_PIO = OPEN_PIO;
    }
    break;

    default:
    {

    }
    break;

    }

    gapProfileState = newState;

    VOID gapProfileState;     // added to prevent compiler warning with
    // "CC2540 Slave" configurations


}

/*********************************************************************
 * @fn      battCB
 *
 * @brief   Callback function for battery service.
 *
 * @param   event - service event
 *
 * @return  none
 */
static void battCB(uint8 event)
{
    if (event == BATT_LEVEL_NOTI_ENABLED)
    {
        // if connected start periodic measurement
        if (gapProfileState == GAPROLE_CONNECTED)
        {
            osal_start_timerEx( simpleBLEPeripheral_TaskID, BATT_PERIODIC_EVT, DEFAULT_BATT_PERIOD );
        }
    }
    else if (event == BATT_LEVEL_NOTI_DISABLED)
    {
        // stop periodic measurement
        osal_stop_timerEx( simpleBLEPeripheral_TaskID, BATT_PERIODIC_EVT );
    }
}

/*********************************************************************
 * @fn      battPeriodicTask
 *
 * @brief   Perform a periodic task for battery measurement.
 *
 * @param   none
 *
 * @return  none
 */
static void battPeriodicTask( void )
{
    if (gapProfileState == GAPROLE_CONNECTED)
    {
        // perform battery level check
        Batt_MeasLevel( );

        // Restart timer
        osal_start_timerEx( simpleBLEPeripheral_TaskID, BATT_PERIODIC_EVT, DEFAULT_BATT_PERIOD );
    }
}

/*********************************************************************
 * @fn      performPeriodicTask
 *
 * @brief   Perform a periodic application task. This function gets
 *          called every five seconds as a result of the SBP_PERIODIC_EVT
 *          OSAL event. In this example, the value of the third
 *          characteristic in the SimpleGATTProfile service is retrieved
 *          from the profile, and then copied into the value of the
 *          the fourth characteristic.
 *
 * @param   none
 *
 * @return  none
 */
static void performPeriodicTask( void )
{
    // loadStepData();
}

/*********************************************************************
 * @fn      simpleProfileChangeCB
 *
 * @brief   Callback from SimpleBLEProfile indicating a value change
 *
 * @param   paramID - parameter ID of the value that was changed.
 *
 * @return  none
 */
static void simpleProfileChangeCB( uint8 paramID )
{
    uint16 newValue;
    uint32 clock;

    switch ( paramID )
    {
    case HEALTH_SYNC:
        SimpleProfile_GetParameter( HEALTH_SYNC, &newValue );

        if (newValue == SYNC_CODE)
        {
            eepromRead();
        }

        break;

    case HEALTH_CLOCK:
        SimpleProfile_GetParameter( HEALTH_CLOCK, &clock );

        osal_setClock(clock);

        UTCTime now;

        now = osal_getClock();

        UTCTimeStruct date;

        osal_ConvertUTCTime(&date, now);

        // {
        //     uint8 d[8] = {1,2,3,4,5,6,7,8};

        //     // osal_memcpy(&d[0], &X_out, sizeof(int16));
        //     // osal_memcpy(&d[2], &Y_out, sizeof(int16));
        //     // osal_memcpy(&d[4], &Z_out, sizeof(int16));

        //     SimpleProfile_SetParameter( HEALTH_SYNC, 8, d );
        // }

        break;

    case HEALTH_DATA_BODY:

        // eepromRead();

        break;

    default:
        // should not reach here!
        break;
    }
}

/*********************************************************************
 * @fn      closeAllPIO
 *
 * @param   none
 *
 * @return  none
 */

static void closeAllPIO(void){

    P0 = 0xFF;

    // open
    P1 = 0xC1;

    // close
    // P1 = 0xC3;

    P2 = 0x07;
}

/*********************************************************************
 * @fn      shock
 *
 * @param   none
 *
 * @return  none
 */

static void shock(void){

    MOTOR_PIO = OPEN_PIO;

    osal_start_timerEx( simpleBLEPeripheral_TaskID, MOTOR_STOP_EVT, 200 );
}



/*********************************************************************
 * @fn      time
 *
 * @param   none
 *
 * @return  none
 */

static void toggleLEDWithTime(uint8 num, uint8 io){

    switch(num){
        case 1:
            LED1_PIO = io;
            break;
        case 2:
            LED2_PIO = io;
            break;
        case 3:
            LED3_PIO = io;
            break;
        case 4:
            LED4_PIO = io;
            break;
        case 5:
            LED5_PIO = io;
            break;
        case 6:
            LED6_PIO = io;
            break;
        case 7:
            LED7_PIO = io;
            break;
        case 8:
            LED8_PIO = io;
            break;
        case 9:
            LED9_PIO = io;
            break;
        case 10:
            LED10_PIO = io;
            break;
        case 11:
            LED11_PIO = io;
            break;
        case 0:
            LED0_PIO = io;
            break;
        default:
            break; 
    }
}

static void blinkLED(void){

    blinkPIO = !blinkPIO;

    toggleLEDWithTime(blinkMinutes, blinkPIO);

    osal_start_timerEx( simpleBLEPeripheral_TaskID, BLINK_LED_EVT, BLINK_LED_INTERVAL );
}

static void time(void){

    lockSlip = 1;

    shock();

    // get current time
    UTCTime current;
    UTCTimeStruct currentTm;

    current = osal_getClock();
    osal_ConvertUTCTime(&currentTm, current);

    // display hour
    uint8 hour = currentTm.hour;

    if (hour >= 12)
    {
        hour = hour - 12;
    }

    toggleLEDWithTime(hour, OPEN_PIO);

    // display minutes
    blinkMinutes = currentTm.minutes / 5;

    if (hour == blinkMinutes)
    {
        if (blinkMinutes == 0)
        {
            blinkMinutes = 1;
        }else{
            blinkMinutes--;
        }
    }

    blinkLED();

    // stop time
    osal_start_timerEx( simpleBLEPeripheral_TaskID, TIME_STOP_EVT, TIME_DISPLAY_INTERVAL );

}

static void babyMove(void){

    lockSlip = 1;

    osal_set_event( simpleBLEPeripheral_TaskID, LED_CYCLE_EVT );

    shock();
}

static void toggleAdvert(uint8 status){

    uint8 turnOnAdv = status;
    GAPRole_SetParameter(GAPROLE_ADVERT_ENABLED, sizeof( uint8 ), &turnOnAdv);
}

/*********************************************************************
 * @fn      accInit
 *
 * @param   none
 *
 * @return  none
 */
static void accInit( void )
{
    HalI2CInit(ACC_ADDRESS, I2C_CLOCK_RATE);

    uint8 pBuf[2], n;

    pBuf[0] = CTRL_REG2;
    pBuf[1] = RST_MASK;
    HalI2CWrite(2, pBuf);

    // make sure reset is ok
    do {
      pBuf[0] = CTRL_REG2;
      HalMotionI2CWrite(1, pBuf);
      HalMotionI2CRead(1, &pBuf[1]);
      n = pBuf[1];

    } while (n & RST_MASK);

    pBuf[0] = XYZ_DATA_CFG;
    pBuf[1] = FULL_SCALE_8G;
    HalI2CWrite(2, pBuf);    

    //tap config

    // pBuf[0] = PULSE_CFG;
    // pBuf[1] = (DPA_MASK|PELE_MASK|ZDPEFE_MASK);
    // HalI2CWrite(2, pBuf);

    // pBuf[0] = PULSE_THSX;
    // pBuf[1] = 0x06;//0x01;//0x00;   
    // HalI2CWrite(2, pBuf); 

    // pBuf[0] = PULSE_THSY;
    // pBuf[1] = 0x06;//0x01;//0x00;   
    // HalI2CWrite(2, pBuf); 

    // pBuf[0] = PULSE_THSZ;
    // pBuf[1] = 0x08;//0x01;//0x00;   
    // HalI2CWrite(2, pBuf);

    // pBuf[0] = PULSE_TMLT;
    // pBuf[1] = 0x06;     //about 1 sec in 12.5Hz low power 
    // HalI2CWrite(2, pBuf);

    // pBuf[0] = PULSE_LTCY;
    // pBuf[1] = 0x06;//0x00;  
    // HalI2CWrite(2, pBuf);

    // pBuf[0] = PULSE_WIND;
    // pBuf[1] = 0x0C;     
    // HalI2CWrite(2, pBuf);     

    // pBuf[0] = HP_FILTER_CUTOFF_REG;
    // pBuf[1] = 0x00;     
    // HalI2CWrite(2, pBuf);   

    //use fifo
    pBuf[0] = F_SETUP;
    pBuf[1] = 0x40;
    HalI2CWrite(2, pBuf);

    // 50hz + low power mode, 15ua
    // put acc to active
    pBuf[0] = CTRL_REG2;
    pBuf[1] = SMOD_LOW_POWER | MOD_LOW_POWER | SLPE_MASK;
    HalI2CWrite(2, pBuf);

    pBuf[0] = CTRL_REG1;
    pBuf[1] = (ASLP_RATE_12_5HZ + DATA_RATE_12_5HZ) | ACTIVE_MASK;
    HalI2CWrite(2, pBuf);

}

static void accLoop(void)
{

    

    // accGetAccData();

    //todo
    X_out = X_out >> 6;
    Y_out = Y_out >> 6;
    Z_out = Z_out >> 6;

    // uint8 d[8];

    // osal_memcpy(&d[0], &X_out, sizeof(int16));
    // osal_memcpy(&d[2], &Y_out, sizeof(int16));
    // osal_memcpy(&d[4], &Z_out, sizeof(int16));

    // SimpleProfile_SetParameter( HEALTH_SYNC, sizeof ( d ), d );


    ACC_CUR = X_out * X_out + Y_out * Y_out + Z_out * Z_out - 4096;

    //SimpleProfile_SetParameter( HEALTH_SYNC, sizeof ( ACC_CUR ), &ACC_CUR );

    if ((DIR == 1) && (ACC_CUR > 0))
    {

        if (first_pace == 0)
        {
            cross_count = cross_count + 1;
            if (cross_count == 1)
            {

                time_count = 0;
                PACE_PEAK = ACC_CUR;
                PACE_BOTTOM = 0;

            }
            else if (cross_count == 2)
            {

                if (((time_count) >= PACE_DUR_MIN) && ((time_count) <= PACE_DUR_MAX) && ((PACE_PEAK - PACE_BOTTOM) >= ALT_MIN))
                {
                    // add one step
                    pace_count = pace_count + 1;

                    // LED0_PIO = OPEN_PIO;
                    // LED3_PIO = OPEN_PIO;
                    // LED6_PIO = OPEN_PIO;
                    // LED9_PIO = OPEN_PIO;

                    // osal_start_timerEx( simpleBLEPeripheral_TaskID, CLOSE_ALL_EVT, 300 );

                    cross_count = 0;

                    // uint8 d[6];

                    // osal_memcpy(&d[0], &pace_count, sizeof(int16));

                    // SimpleProfile_SetParameter( HEALTH_SYNC, sizeof ( d ), d );

                    eepromWrite(STEP_DATA_TYPE);

                }
                else
                {

                    time_count = 0;
                    PACE_PEAK = ACC_CUR;
                    PACE_BOTTOM = 0;
                    cross_count = 1;
                }
            }
        }
        else
        {
            first_pace = 0;

            time_count = 0;
            PACE_PEAK = ACC_CUR;
            PACE_BOTTOM = 0;
        }
        DIR = 2;
    }
    else if ((DIR == 2) && (ACC_CUR >= 0))
    {
        if (ACC_CUR > PACE_PEAK) PACE_PEAK = ACC_CUR;
    }
    else if ((DIR == 2) && (ACC_CUR < 0))
    {
        PACE_BOTTOM = ACC_CUR;
        DIR = 1;
    }
    else if ((DIR == 1) && (ACC_CUR <= 0))
    {
        if (ACC_CUR < PACE_BOTTOM) PACE_BOTTOM = ACC_CUR;
    }

    // accGetIntData();//read INT registers

    // if (INT_STATUS & 0x80)
    // {

    //     // time();

    // }

    time_count++;
}


// static void accGetAccData(void)
static void accGetAccData(uint8 count)
{
    HalI2CInit(ACC_ADDRESS, I2C_CLOCK_RATE);

    // uint8 addr = OUT_X_MSB, accBuf[6];

    // HalMotionI2CWrite(1, &addr);
    // HalMotionI2CRead(6, accBuf);

    // X_out = (int16)((accBuf[0] << 8) | accBuf[1]);
    // Y_out = (int16)((accBuf[2] << 8) | accBuf[3]);
    // Z_out = (int16)((accBuf[4] << 8) | accBuf[5]);

    uint8 addr = OUT_X_MSB, accBuf[192];

    HalMotionI2CWrite(1, &addr);
    HalMotionI2CRead(count * 6, accBuf);

    for (int i = 0; i < count * 6; i += 6)
    {
        X_out = (int16)((accBuf[i] << 8) | accBuf[i+1]);
        Y_out = (int16)((accBuf[i+2] << 8) | accBuf[i+3]);
        Z_out = (int16)((accBuf[i+4] << 8) | accBuf[i+5]);

        accLoop();
    }
}

// static void accGetIntData(void)
// {
//     HalI2CInit(ACC_ADDRESS, I2C_CLOCK_RATE);

//     uint8 pBuf[2];

//     //read INT
//     pBuf[0] = PULSE_SRC;
//     HalMotionI2CWrite(1, pBuf);
//     HalMotionI2CRead(1, &pBuf[1]);
//     INT_STATUS = pBuf[1];

//     //DebugValue(INT_STATUS);
// }

// for memcpy

// static void eepromWrite(uint8 type){

//     toggleAdvert(TRUE);

//     uint8 point = type - 1;

//     UTCTime current;
//     UTCTimeStruct currentTm;

//     current = osal_getClock();
//     osal_ConvertUTCTime(&currentTm, current);

//     // if there is step data, count it by hour
//     if (type == STEP_DATA_TYPE)
//     {
//         currentTm.minutes = 0;
//     }

//     currentTm.seconds = 0;

//     if (oneData[point].hourSeconds == 0)       // data is empty
//     {
//         oneData[point].tm = currentTm;
//         oneData[point].hourSeconds = osal_ConvertUTCSecs(&oneData[point].tm);

//         oneData[point].count = 1;
//         oneData[point].type = type;

//     }else if(oneData[point].tm.year != currentTm.year ||
//              oneData[point].tm.month != currentTm.month ||
//              oneData[point].tm.day != currentTm.day ||
//              oneData[point].tm.minutes != currentTm.minutes ||         // for test, one minutes
//              oneData[point].tm.hour != currentTm.hour){                // pass a hour, need to write

//         // uint8 aBuf[2];
//         uint8 dBuf[8] = {
//             LO_UINT16(LO_UINT32(oneData[point].hourSeconds)),
//             HI_UINT16(LO_UINT32(oneData[point].hourSeconds)),
//             LO_UINT16(HI_UINT32(oneData[point].hourSeconds)),
//             HI_UINT16(HI_UINT32(oneData[point].hourSeconds)),
//             LO_UINT16(oneData[point].count),
//             HI_UINT16(oneData[point].count),
//             oneData[point].type,
//             0
//         };

//         osal_memcpy(&db[stepDataStop], &dBuf[0], 8);

//         stepDataStop += 8;

//         // arrive maxsize
//         if (stepDataStop >= EEPROM_ADDRESS_DATA_MAX)
//         {
//             stepDataStop = 0;
//         }

//         // space is full
//         if (stepDataStop == stepDataStart)
//         {
//             stepDataStart += 8;
//         }

//         uint16 length = ((stepDataStop - stepDataStart) / 8) + DATA_TYPE_COUNT;

//         // SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &stepDataStop);
//         SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &length);
//         SimpleProfile_SetParameter( HEALTH_SYNC, 8, dBuf);

//         // refresh oneData[point]
//         oneData[point].tm = currentTm;
//         oneData[point].hourSeconds = osal_ConvertUTCSecs(&oneData[point].tm);

//         oneData[point].count = 1;

//     }else{      // in same hour

//         oneData[point].count ++;
//     }

// }

// static void eepromRead(void){

//     while(stepDataStart != stepDataStop){
//         uint8 dBuf[8];

//         osal_memcpy(&dBuf[0], &db[stepDataStart], 8);

//         stepDataStart += 8;

//         // arrive maxsize
//         if (stepDataStart >= EEPROM_ADDRESS_DATA_MAX)
//         {
//             stepDataStart = 0;
//         }

//         SimpleProfile_SetParameter( HEALTH_DATA_BODY, 8,  dBuf);
//         SimpleProfile_SetParameter( HEALTH_SYNC, 8, dBuf);
//     }

//     if (stepDataStart == stepDataStop)
//     {
        
//         int i;

//         for (i = 0; i < DATA_TYPE_COUNT; i++)
//         {
//             uint8 dBuf[8] = {
//                 LO_UINT16(LO_UINT32(oneData[i].hourSeconds)),
//                 HI_UINT16(LO_UINT32(oneData[i].hourSeconds)),
//                 LO_UINT16(HI_UINT32(oneData[i].hourSeconds)),
//                 HI_UINT16(HI_UINT32(oneData[i].hourSeconds)),
//                 LO_UINT16(oneData[i].count),
//                 HI_UINT16(oneData[i].count),
//                 oneData[i].type,
//                 0
//             };

//             SimpleProfile_SetParameter( HEALTH_DATA_BODY, 8,  dBuf);

//             oneData[i].count = 0;
//         }
//     }

//     uint16 length = DATA_TYPE_COUNT;
//     SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &length);
// }






// for eeprom

static void eepromWrite(uint8 type){

    uint8 point = type - 1;

    UTCTime current;
    UTCTimeStruct currentTm;

    current = osal_getClock();
    osal_ConvertUTCTime(&currentTm, current);

    if (type == STEP_DATA_TYPE)
    {
        currentTm.minutes = 0;
    }

    currentTm.seconds = 0;

    if (oneData[point].hourSeconds == 0)       // data is empty
    {
        oneData[point].tm = currentTm;
        oneData[point].hourSeconds = osal_ConvertUTCSecs(&oneData[point].tm);

        oneData[point].count = 1;
        oneData[point].type = type;

    }else if(oneData[point].tm.year != currentTm.year ||
             oneData[point].tm.month != currentTm.month ||
             oneData[point].tm.day != currentTm.day ||
             oneData[point].tm.minutes != currentTm.minutes ||         
             oneData[point].tm.hour != currentTm.hour){                // pass a hour or a minute, need to write

        // write to eeprom
        HalI2CInit(EEPROM_ADDRESS, I2C_CLOCK_RATE);

        uint8 dBuf[10] = {
            LO_UINT16(stepDataStop),    // address
            HI_UINT16(stepDataStop),    // address
            LO_UINT16(LO_UINT32(oneData[point].hourSeconds)),
            HI_UINT16(LO_UINT32(oneData[point].hourSeconds)),
            LO_UINT16(HI_UINT32(oneData[point].hourSeconds)),
            HI_UINT16(HI_UINT32(oneData[point].hourSeconds)),
            LO_UINT16(oneData[point].count),
            HI_UINT16(oneData[point].count),
            oneData[point].type,
            0
        };

        HalI2CWrite(sizeof(dBuf), dBuf);
        HalI2CAckPolling();

        stepDataStop += 8;

        // arrive maxsize
        if (stepDataStop >= EEPROM_ADDRESS_DATA_MAX)
        {
            stepDataStop = 0;
        }

        // space is full
        if (stepDataStop == stepDataStart)
        {
            stepDataStart += 8;
        }

        uint16 length = ((stepDataStop - stepDataStart) / 8) + DATA_TYPE_COUNT;

        // SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &stepDataStop);
        SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &length);
        SimpleProfile_SetParameter( HEALTH_SYNC, 8, dBuf);


        // refresh oneData[point]
        oneData[point].tm = currentTm;
        oneData[point].hourSeconds = osal_ConvertUTCSecs(&oneData[point].tm);

        oneData[point].count = 1;

        saveStepData();

    }else{      // in same hour

        oneData[point].count ++;
    }

}

static void eepromRead(void){

    HalI2CInit(EEPROM_ADDRESS, I2C_CLOCK_RATE);

    while(stepDataStart != stepDataStop){

        uint8 dBuf[8], addr[2] = {
            LO_UINT16(stepDataStart),
            HI_UINT16(stepDataStart)
        };

        HalI2CWrite(sizeof(addr), addr);
        HalI2CRead(sizeof(dBuf), dBuf);

        stepDataStart += 8;

        // arrive maxsize
        if (stepDataStart >= EEPROM_ADDRESS_DATA_MAX)
        {
            stepDataStart = 0;
        }

        SimpleProfile_SetParameter( HEALTH_DATA_BODY, 8,  dBuf);
        SimpleProfile_SetParameter( HEALTH_SYNC, 8, dBuf);
    }

    // read no-saved data
    if (stepDataStart == stepDataStop)
    {
        
        int i;

        for (i = 0; i < DATA_TYPE_COUNT; i++)
        {
            uint8 dBuf[8] = {
                LO_UINT16(LO_UINT32(oneData[i].hourSeconds)),
                HI_UINT16(LO_UINT32(oneData[i].hourSeconds)),
                LO_UINT16(HI_UINT32(oneData[i].hourSeconds)),
                HI_UINT16(HI_UINT32(oneData[i].hourSeconds)),
                LO_UINT16(oneData[i].count),
                HI_UINT16(oneData[i].count),
                oneData[i].type,
                0
            };

            SimpleProfile_SetParameter( HEALTH_DATA_BODY, 8,  dBuf);

            oneData[i].count = 0;
        }
    }

    uint16 length = DATA_TYPE_COUNT;
    SimpleProfile_SetParameter( HEALTH_DATA_HEADER, 2,  &length);

    saveStepData();
}

static void saveStepData(void){

    HalI2CInit(EEPROM_ADDRESS, I2C_CLOCK_RATE);

    uint8 dBuf[4] = {
        LO_UINT16(EEPROM_POSITION_STEP_DATA),    // address
        HI_UINT16(EEPROM_POSITION_STEP_DATA),    // address
        LO_UINT16(stepDataStart),
        HI_UINT16(stepDataStart)
    }, cBuf[4] = {
        LO_UINT16(EEPROM_POSITION_STEP_DATA + 2),    // address
        HI_UINT16(EEPROM_POSITION_STEP_DATA + 2),    // address
        LO_UINT16(stepDataStop),
        HI_UINT16(stepDataStop)
    };

    HalI2CWrite(sizeof(dBuf), dBuf);
    HalI2CAckPolling();

    HalI2CWrite(sizeof(cBuf), cBuf);
    HalI2CAckPolling();

    // uint8 d[8];

    // osal_memcpy(d, &dBuf[2], 8);
    // SimpleProfile_SetParameter( HEALTH_SYNC, 8, d);

}

static void loadStepData(void){

    HalI2CInit(EEPROM_ADDRESS, I2C_CLOCK_RATE);

    uint8 addr1[2] = {
        LO_UINT16(EEPROM_POSITION_STEP_DATA),
        HI_UINT16(EEPROM_POSITION_STEP_DATA)
    }, addr2[2] = {
        LO_UINT16(EEPROM_POSITION_STEP_DATA + 2),
        HI_UINT16(EEPROM_POSITION_STEP_DATA + 2)
    }, dBuf[2], cBuf[2];

    HalI2CWrite(sizeof(addr1), addr1);
    HalI2CRead(sizeof(dBuf), dBuf);

    HalI2CWrite(sizeof(addr2), addr2);
    HalI2CRead(sizeof(cBuf), cBuf);

    if (!(dBuf[0] == 0xff && dBuf[1] == 0xff))
    {
        stepDataStart = (uint16)((dBuf[1] << 8) | dBuf[0]);
    }

    if (!(cBuf[0] == 0xff && cBuf[1] == 0xff))
    {
        stepDataStop = (uint16)((cBuf[1] << 8) | cBuf[0]);
    }

    uint8 d[8];

    osal_memcpy(d, &stepDataStart, 2);
    osal_memcpy(&d[2], &stepDataStop, 2);
    SimpleProfile_SetParameter( HEALTH_SYNC, 8, d);
}

/*********************************************************************
*********************************************************************/
