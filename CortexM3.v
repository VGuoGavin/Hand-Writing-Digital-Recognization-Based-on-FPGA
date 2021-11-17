module CortexM3 #(
    parameter                   SimPresent = 1
)   (
    input       wire            CLK50m,
    input       wire            RSTn,

    // SWD
    inout       wire            SWDIO,
    input       wire            SWCLK,

    // UART
    output      wire            TXD,
    input       wire            RXD,
    output      wire            TXDLED,

    //GPIO
    input       wire    [15:0]  PORTIN,
    output      wire    [15:0]  PORTOUT,
    output      wire    [15:0]  PORTEN,
    output      wire    [15:0]  PORTFUNC,

    // LCD
    output      wire            LCD_CS,
    output      wire            LCD_RS,
    output      wire            LCD_WR,
    output      wire            LCD_RD,
    output      wire            LCD_RST,
    output      wire    [15:0]  LCD_DATA,
    output      wire            LCD_BL_CTR,

    //手写体识别

	//clocks & reset
//	input wire clk50,             
//	input wire rst,
	input wire start_gray_kn,
	//OV7670
	input wire [7:0] data_cam, 
	input wire VSYNC_cam,               //场同步信号
	input wire HREF_cam,				//行同步信号
	input wire PCLK_cam,        		//像素时钟
	output wire XCLK_cam,				//系统时钟输入
	output wire res_cam,					//复位信号
	output wire on_off_cam,				//上电（0：工作，1：掉电）
	output wire sioc,					//SCCB时钟口
	output wire siod,					//SCCB数据口
	//VGA
	output wire [4:0] r,  
	output wire [5:0] g,
	output wire [4:0] b, 	
	//SDRAM
	output wire cs_n,					//片选
	output wire ras_n,					//行地址选通信号，低电平表示行地址
	output wire cas_n,					//列地址选通信号，低电平选通
	output wire we_n,					//写使能，低电平有效
	output wire [1:0] dqm,				//数据掩码，表示DQ的有效部分
	output wire [11:0] sd_addr,
	output wire [1:0] ba,				//L-Bank地址线
	output wire Cke,					//时钟使能，禁止时钟时SDRAM会进入自刷新模式
	inout wire [15:0] sd_data, 
	output wire sdram_clk, 
	//TFT
	input tft_sdo,						//主设备数据输出
	output wire tft_sck, 				//时钟信号
	output wire tft_sdi, 				//主设备数据输入
	output wire tft_dc, 
	output wire tft_reset, 
	output wire tft_cs,
	//LED
	output reg [7:0] LED,
	//3.3V
	output gpio3_3,
	output result_led

);

//
           


wire fbClk;

wire clk25;
wire clk100;
wire clk24;
wire clk143; 
wire [15:0] input_fifo_to_sdram;

assign gpio3_3= 1'b1 ;
assign sdram_clk = clk143;


wire locked;
wire [11:0] output_rdusedw_TFT;
wire start_image;
wire [3:0] RESULT;
reg GO_NEIROSET;
wire end_neiroset;
reg [3:0] RESULT_2;

wire ctrl_busy;
wire [23:0] wr_addr;
wire wr_enable;
wire [15:0] rd_data;
reg [23:0] rd_addr;
wire rd_ready;
reg ready;

assign result_led=RESULT_2;
//





assign  TXDLED = ~TXD;

//------------------------------------------------------------------------------
// GLOBAL BUF
//------------------------------------------------------------------------------

wire            clk;
wire            swck;

generate 
        if(SimPresent) begin : SimClock

                assign swck = SWCLK;
                assign clk  = CLK50m;
        
        end else begin : SynClock

                GLOBAL sw_clk(
                        .in                     (SWCLK),
                        .out                    (swck)
                );
                PLL PLL(
                        .refclk                 (CLK50m),
                        .rst                    (~RSTn),
                        .outclk_0               (clk)
                );
        end    
endgenerate         


//------------------------------------------------------------------------------
// DEBUG IOBUF 
//------------------------------------------------------------------------------

wire            SWDO;
wire            SWDOEN;
wire            SWDI;

generate
    if(SimPresent) begin : SimIOBuf

        assign SWDI = SWDIO;
        assign SWDIO = (SWDOEN) ?  SWDO : 1'bz;

    end else begin : SynIOBuf

        IOBUF SWIOBUF(
            .datain                 (SWDO),
            .oe                     (SWDOEN),
            .dataout                (SWDI),
            .dataio                 (SWDIO)
        );

    end
endgenerate

//------------------------------------------------------------------------------
// RESET
//------------------------------------------------------------------------------

wire            SYSRESETREQ;
reg             cpuresetn;

always @(posedge clk or negedge RSTn)begin
    if (~RSTn) 
        cpuresetn <= 1'b0;
    else if (SYSRESETREQ) 
        cpuresetn <= 1'b0;
    else 
        cpuresetn <= 1'b1;
end

wire        SLEEPing;

//------------------------------------------------------------------------------
// DEBUG CONFIG
//------------------------------------------------------------------------------


wire            CDBGPWRUPREQ;
reg             CDBGPWRUPACK;

always @(posedge clk or negedge RSTn)begin
    if (~RSTn) 
        CDBGPWRUPACK <= 1'b0;
    else 
        CDBGPWRUPACK <= CDBGPWRUPREQ;
end

//------------------------------------------------------------------------------
// INTERRUPT 
//------------------------------------------------------------------------------

wire    [239:0] IRQ;


//------------------------------------------------------------------------------
// CORE BUS
//------------------------------------------------------------------------------

// CPU I-Code 
wire    [31:0]  HADDRI;
wire    [1:0]   HTRANSI;
wire    [2:0]   HSIZEI;
wire    [2:0]   HBURSTI;
wire    [3:0]   HPROTI;
wire    [31:0]  HRDATAI;
wire            HREADYI;
wire    [1:0]   HRESPI;

// CPU D-Code 
wire    [31:0]  HADDRD;
wire    [1:0]   HTRANSD;
wire    [2:0]   HSIZED;
wire    [2:0]   HBURSTD;
wire    [3:0]   HPROTD;
wire    [31:0]  HWDATAD;
wire            HWRITED;
wire    [31:0]  HRDATAD;
wire            HREADYD;
wire    [1:0]   HRESPD;
wire    [1:0]   HMASTERD;

// CPU System bus 
wire    [31:0]  HADDRS;
wire    [1:0]   HTRANSS;
wire            HWRITES;
wire    [2:0]   HSIZES;
wire    [31:0]  HWDATAS;
wire    [2:0]   HBURSTS;
wire    [3:0]   HPROTS;
wire            HREADYS;
wire    [31:0]  HRDATAS;
wire    [1:0]   HRESPS;
wire    [1:0]   HMASTERS;
wire            HMASTERLOCKS;


//------------------------------------------------------------------------------
// Instantiate Cortex-M3 processor 
//------------------------------------------------------------------------------

cortexm3ds_logic ulogic(
    // PMU
    .ISOLATEn                           (1'b1),
    .RETAINn                            (1'b1),

    // RESETS
    .PORESETn                           (RSTn),
    .SYSRESETn                          (cpuresetn),
    .SYSRESETREQ                        (SYSRESETREQ),
    .RSTBYPASS                          (1'b0),
    .CGBYPASS                           (1'b0),
    .SE                                 (1'b0),

    // CLOCKS
    .FCLK                               (clk),
    .HCLK                               (clk),
    .TRACECLKIN                         (1'b0),

    // SYSTICK
    .STCLK                              (1'b0),
    .STCALIB                            (26'b0),
    .AUXFAULT                           (32'b0),

    // CONFIG - SYSTEM
    .BIGEND                             (1'b0),
    .DNOTITRANS                         (1'b1),
    
    // SWJDAP
    .nTRST                              (1'b1),
    .SWDITMS                            (SWDI),
    .SWCLKTCK                           (swck),
    .TDI                                (1'b0),
    .CDBGPWRUPACK                       (CDBGPWRUPACK),
    .CDBGPWRUPREQ                       (CDBGPWRUPREQ),
    .SWDO                               (SWDO),
    .SWDOEN                             (SWDOEN),

    // IRQS
    .INTISR                             (IRQ),
    .INTNMI                             (1'b0),
    
    // I-CODE BUS
    .HREADYI                            (HREADYI),
    .HRDATAI                            (HRDATAI),
    .HRESPI                             (HRESPI),
    .IFLUSH                             (1'b0),
    .HADDRI                             (HADDRI),
    .HTRANSI                            (HTRANSI),
    .HSIZEI                             (HSIZEI),
    .HBURSTI                            (HBURSTI),
    .HPROTI                             (HPROTI),

    // D-CODE BUS
    .HREADYD                            (HREADYD),
    .HRDATAD                            (HRDATAD),
    .HRESPD                             (HRESPD),
    .EXRESPD                            (1'b0),
    .HADDRD                             (HADDRD),
    .HTRANSD                            (HTRANSD),
    .HSIZED                             (HSIZED),
    .HBURSTD                            (HBURSTD),
    .HPROTD                             (HPROTD),
    .HWDATAD                            (HWDATAD),
    .HWRITED                            (HWRITED),
    .HMASTERD                           (HMASTERD),

    // SYSTEM BUS
    .HREADYS                            (HREADYS),
    .HRDATAS                            (HRDATAS),
    .HRESPS                             (HRESPS),
    .EXRESPS                            (1'b0),
    .HADDRS                             (HADDRS),
    .HTRANSS                            (HTRANSS),
    .HSIZES                             (HSIZES),
    .HBURSTS                            (HBURSTS),
    .HPROTS                             (HPROTS),
    .HWDATAS                            (HWDATAS),
    .HWRITES                            (HWRITES),
    .HMASTERS                           (HMASTERS),
    .HMASTLOCKS                         (HMASTERLOCKS),

    // SLEEP
    .RXEV                               (1'b0),
    .SLEEPHOLDREQn                      (1'b1),
    .SLEEPING                           (SLEEPing),
    
    // EXTERNAL DEBUG REQUEST
    .EDBGRQ                             (1'b0),
    .DBGRESTART                         (1'b0),
    
    // DAP HMASTER OVERRIDE
    .FIXMASTERTYPE                      (1'b0),

    // WIC
    .WICENREQ                           (1'b0),

    // TIMESTAMP INTERFACE
    .TSVALUEB                           (48'b0),

    // CONFIG - DEBUG
    .DBGEN                              (1'b1),
    .NIDEN                              (1'b1),
    .MPUDISABLE                         (1'b0)
);

//------------------------------------------------------------------------------
// AHB L1 BUS MATRIX
//------------------------------------------------------------------------------


// DMA MASTER
wire    [31:0]  HADDRDM;
wire    [1:0]   HTRANSDM;
wire            HWRITEDM;
wire    [2:0]   HSIZEDM;
wire    [31:0]  HWDATADM;
wire    [2:0]   HBURSTDM;
wire    [3:0]   HPROTDM;
wire            HREADYDM;
wire    [31:0]  HRDATADM;
wire    [1:0]   HRESPDM;
wire    [1:0]   HMASTERDM;
wire            HMASTERLOCKDM;

assign  HADDRDM         =   32'b0;
assign  HTRANSDM        =   2'b0;
assign  HWRITEDM        =   1'b0;
assign  HSIZEDM         =   3'b0;
assign  HWDATADM        =   32'b0;
assign  HBURSTDM        =   3'b0;
assign  HPROTDM         =   4'b0;
assign  HMASTERDM       =   2'b0;
assign  HMASTERLOCKDM   =   1'b0;

// RESERVED MASTER 
wire    [31:0]  HADDRR;
wire    [1:0]   HTRANSR;
wire            WRITER;
wire    [2:0]   HSIZER;
wire    [31:0]  HWDATAR;
wire    [2:0]   HBURSTR;
wire    [3:0]   HPROTR;
wire            HREADYR;
wire    [31:0]  HRDATAR;
wire    [1:0]   HRESPR;
wire    [1:0]   HMASTERR;
wire            HMASTERLOCKR;

assign  HADDRR          =   32'b0;
assign  HTRANSR         =   2'b0;
assign  HWRITER         =   1'b0;
assign  HSIZER          =   3'b0;
assign  HWDATAR         =   32'b0;
assign  HBURSTR         =   3'b0;
assign  HPROTR          =   4'b0;
assign  HMASTERR        =   2'b0;
assign  HMASTERLOCKR    =   1'b0;

wire    [31:0]  HADDR_AHBL1P0;
wire    [1:0]   HTRANS_AHBL1P0;
wire            HWRITE_AHBL1P0;
wire    [2:0]   HSIZE_AHBL1P0;
wire    [31:0]  HWDATA_AHBL1P0;
wire    [2:0]   HBURST_AHBL1P0;
wire    [3:0]   HPROT_AHBL1P0;
wire            HREADY_AHBL1P0;
wire    [31:0]  HRDATA_AHBL1P0;
wire    [1:0]   HRESP_AHBL1P0;
wire            HREADYOUT_AHBL1P0;
wire            HSEL_AHBL1P0;
wire    [1:0]   HMASTER_AHBL1P0;
wire            HMASTERLOCK_AHBL1P0;

wire    [31:0]  HADDR_AHBL1P1;
wire    [1:0]   HTRANS_AHBL1P1;
wire            HWRITE_AHBL1P1;
wire    [2:0]   HSIZE_AHBL1P1;
wire    [31:0]  HWDATA_AHBL1P1;
wire    [2:0]   HBURST_AHBL1P1;
wire    [3:0]   HPROT_AHBL1P1;
wire            HREADY_AHBL1P1;
wire    [31:0]  HRDATA_AHBL1P1;
wire    [1:0]   HRESP_AHBL1P1;
wire            HREADYOUT_AHBL1P1;
wire            HSEL_AHBL1P1;
wire    [1:0]   HMASTER_AHBL1P1;
wire            HMASTERLOCK_AHBL1P1;

wire    [31:0]  HADDR_AHBL1P4;
wire    [1:0]   HTRANS_AHBL1P4;
wire            HWRITE_AHBL1P4;
wire    [2:0]   HSIZE_AHBL1P4;
wire    [31:0]  HWDATA_AHBL1P4;
wire    [2:0]   HBURST_AHBL1P4;
wire    [3:0]   HPROT_AHBL1P4;
wire            HREADY_AHBL1P4;
wire    [31:0]  HRDATA_AHBL1P4;
wire    [1:0]   HRESP_AHBL1P4;
wire            HREADYOUT_AHBL1P4;
wire            HSEL_AHBL1P4;
wire    [1:0]   HMASTER_AHBL1P4;
wire            HMASTERLOCK_AHBL1P4;

wire    [31:0]  HADDR_AHBL1P2;
wire    [1:0]   HTRANS_AHBL1P2;
wire            HWRITE_AHBL1P2;
wire    [2:0]   HSIZE_AHBL1P2;
wire    [31:0]  HWDATA_AHBL1P2;
wire    [2:0]   HBURST_AHBL1P2;
wire    [3:0]   HPROT_AHBL1P2;
wire            HREADY_AHBL1P2;
wire    [31:0]  HRDATA_AHBL1P2;
wire    [1:0]   HRESP_AHBL1P2;
wire            HREADYOUT_AHBL1P2;
wire            HSEL_AHBL1P2;
wire    [1:0]   HMASTER_AHBL1P2;
wire            HMASTERLOCK_AHBL1P2;

wire    [31:0]  HADDR_AHBL1P3;
wire    [1:0]   HTRANS_AHBL1P3;
wire            HWRITE_AHBL1P3;
wire    [2:0]   HSIZE_AHBL1P3;
wire    [31:0]  HWDATA_AHBL1P3;
wire    [2:0]   HBURST_AHBL1P3;
wire    [3:0]   HPROT_AHBL1P3;
wire            HREADY_AHBL1P3;
wire    [31:0]  HRDATA_AHBL1P3;
wire    [1:0]   HRESP_AHBL1P3;
wire            HREADYOUT_AHBL1P3;
wire            HSEL_AHBL1P3;
wire    [1:0]   HMASTER_AHBL1P3;
wire            HMASTERLOCK_AHBL1P3;

L1AhbMtx    L1AhbMtx(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),

    .REMAP                              (4'b0),

    .HSELS1                             (1'b1),
    .HADDRS1                            (HADDRI),
    .HTRANSS1                           (HTRANSI),
    .HWRITES1                           (1'b0),
    .HSIZES1                            (HSIZEI),
    .HBURSTS1                           (HBURSTI),
    .HPROTS1                            (HPROTI),
    .HMASTERS1                          (4'b0),
    .HWDATAS1                           (32'b0),
    .HMASTLOCKS1                        (1'b0),
    .HREADYS1                           (HREADYI),
    .HRDATAS1                           (HRDATAI),
    .HREADYOUTS1                        (HREADYI),
    .HRESPS1                            (HRESPI),

    .HSELS0                             (1'b1),
    .HADDRS0                            (HADDRD),
    .HTRANSS0                           (HTRANSD),
    .HWRITES0                           (HWRITED),
    .HSIZES0                            (HSIZED),
    .HBURSTS0                           (HBURSTD),
    .HPROTS0                            (HPROTD),
    .HMASTERS0                          ({2'b0,HMASTERD}),
    .HWDATAS0                           (HWDATAD),
    .HMASTLOCKS0                        (1'b0),
    .HREADYS0                           (HREADYD),
    .HREADYOUTS0                        (HREADYD),
    .HRESPS0                            (HRESPD),
    .HRDATAS0                           (HRDATAD),

    .HSELS2                             (1'b1),
    .HADDRS2                            (HADDRS),
    .HTRANSS2                           (HTRANSS),
    .HWRITES2                           (HWRITES),
    .HSIZES2                            (HSIZES),
    .HBURSTS2                           (HBURSTS),
    .HPROTS2                            (HPROTS),
    .HMASTERS2                          ({2'b0,HMASTERS}),
    .HWDATAS2                           (HWDATAS),
    .HMASTLOCKS2                        (HMASTERLOCKS),
    .HREADYS2                           (HREADYS),
    .HREADYOUTS2                        (HREADYS),
    .HRESPS2                            (HRESPS),
    .HRDATAS2                           (HRDATAS),    

    .HSELS3                             (1'b1),
    .HADDRS3                            (HADDRDM),
    .HTRANSS3                           (HTRANSDM),
    .HWRITES3                           (HWRITEDM),
    .HSIZES3                            (HSIZEDM),
    .HBURSTS3                           (HBURSTDM),
    .HPROTS3                            (HPROTDM),
    .HMASTERS3                          ({2'b0,HMASTERDM}),
    .HWDATAS3                           (HWDATADM),
    .HMASTLOCKS3                        (HMASTERLOCKDM),
    .HREADYS3                           (1'b1),
    .HREADYOUTS3                        (HREADYDM),
    .HRESPS3                            (HRESPDM),
    .HRDATAS3                           (HRDATADM),

    .HSELS4                             (1'b1),
    .HADDRS4                            (HADDRR),
    .HTRANSS4                           (HTRANSR),
    .HWRITES4                           (HWRITER),
    .HSIZES4                            (HSIZER),
    .HBURSTS4                           (HBURSTR),
    .HPROTS4                            (HPROTR),
    .HMASTERS4                          ({2'b0,HMASTERR}),
    .HWDATAS4                           (HWDATAR),
    .HMASTLOCKS4                        (HMASTERLOCKR),
    .HREADYS4                           (1'b1),
    .HREADYOUTS4                        (HREADYR),
    .HRESPS4                            (HRESPR),
    .HRDATAS4                           (HRDATAR),

    .HSELM0                             (HSEL_AHBL1P0),
    .HADDRM0                            (HADDR_AHBL1P0),
    .HTRANSM0                           (HTRANS_AHBL1P0),
    .HWRITEM0                           (HWRITE_AHBL1P0),
    .HSIZEM0                            (HSIZE_AHBL1P0),
    .HBURSTM0                           (HBURST_AHBL1P0),
    .HPROTM0                            (HPROT_AHBL1P0),
    .HMASTERM0                          (HMASTER_AHBL1P0),
    .HWDATAM0                           (HWDATA_AHBL1P0),
    .HMASTLOCKM0                        (HMASTERLOCK_AHBL1P0),
    .HREADYMUXM0                        (HREADY_AHBL1P0),
    .HRDATAM0                           (HRDATA_AHBL1P0),
    .HREADYOUTM0                        (HREADYOUT_AHBL1P0),
    .HRESPM0                            (HRESP_AHBL1P0),

    .HSELM1                             (HSEL_AHBL1P1),
    .HADDRM1                            (HADDR_AHBL1P1),
    .HTRANSM1                           (HTRANS_AHBL1P1),
    .HWRITEM1                           (HWRITE_AHBL1P1),
    .HSIZEM1                            (HSIZE_AHBL1P1),
    .HBURSTM1                           (HBURST_AHBL1P1),
    .HPROTM1                            (HPROT_AHBL1P1),
    .HMASTERM1                          (HMASTER_AHBL1P1),
    .HWDATAM1                           (HWDATA_AHBL1P1),
    .HMASTLOCKM1                        (HMASTERLOCK_AHBL1P1),
    .HREADYMUXM1                        (HREADY_AHBL1P1),
    .HRDATAM1                           (HRDATA_AHBL1P1),
    .HREADYOUTM1                        (HREADYOUT_AHBL1P1),
    .HRESPM1                            (HRESP_AHBL1P1),

    .HSELM2                             (HSEL_AHBL1P2),
    .HADDRM2                            (HADDR_AHBL1P2),
    .HTRANSM2                           (HTRANS_AHBL1P2),
    .HWRITEM2                           (HWRITE_AHBL1P2),
    .HSIZEM2                            (HSIZE_AHBL1P2),
    .HBURSTM2                           (HBURST_AHBL1P2),
    .HPROTM2                            (HPROT_AHBL1P2),
    .HMASTERM2                          (HMASTER_AHBL1P2),
    .HWDATAM2                           (HWDATA_AHBL1P2),
    .HMASTLOCKM2                        (HMASTERLOCK_AHBL1P2),
    .HREADYMUXM2                        (HREADY_AHBL1P2),
    .HRDATAM2                           (HRDATA_AHBL1P2),
    .HREADYOUTM2                        (HREADYOUT_AHBL1P2),
    .HRESPM2                            (HRESP_AHBL1P2),

    .HSELM3                             (HSEL_AHBL1P3),
    .HADDRM3                            (HADDR_AHBL1P3),
    .HTRANSM3                           (HTRANS_AHBL1P3),
    .HWRITEM3                           (HWRITE_AHBL1P3),
    .HSIZEM3                            (HSIZE_AHBL1P3),
    .HBURSTM3                           (HBURST_AHBL1P3),
    .HPROTM3                            (HPROT_AHBL1P3),
    .HMASTERM3                          (HMASTER_AHBL1P3),
    .HWDATAM3                           (HWDATA_AHBL1P3),
    .HMASTLOCKM3                        (HMASTERLOCK_AHBL1P3),
    .HREADYMUXM3                        (HREADY_AHBL1P3),
    .HRDATAM3                           (HRDATA_AHBL1P3),
    .HREADYOUTM3                        (HREADYOUT_AHBL1P3),
    .HRESPM3                            (HRESP_AHBL1P3),

    .HSELM4                             (HSEL_AHBL1P4),
    .HADDRM4                            (HADDR_AHBL1P4),
    .HTRANSM4                           (HTRANS_AHBL1P4),
    .HWRITEM4                           (HWRITE_AHBL1P4),
    .HSIZEM4                            (HSIZE_AHBL1P4),
    .HBURSTM4                           (HBURST_AHBL1P4),
    .HPROTM4                            (HPROT_AHBL1P4),
    .HMASTERM4                          (HMASTER_AHBL1P4),
    .HWDATAM4                           (HWDATA_AHBL1P4),
    .HMASTLOCKM4                        (HMASTERLOCK_AHBL1P4),
    .HREADYMUXM4                        (HREADY_AHBL1P4),
    .HRDATAM4                           (HRDATA_AHBL1P4),
    .HREADYOUTM4                        (HREADYOUT_AHBL1P4),
    .HRESPM4                            (HRESP_AHBL1P4),

    .SCANENABLE                         (1'b0),
    .SCANINHCLK                         (1'b0),
    .SCANOUTHCLK                        ()
);

wire    [31:0]  HADDR_AHBL2M;
wire    [1:0]   HTRANS_AHBL2M;
wire    [2:0]   HSIZE_AHBL2M;
wire            HWRITE_AHBL2M;
wire    [3:0]   HPROT_AHBL2M;
wire    [1:0]   HMASTER_AHBL2M;
wire            HMASTERLOCK_AHBL2M;
wire    [31:0]  HWDATA_AHBL2M;
wire    [2:0]   HBURST_AHBL2M;
wire            HREADY_AHBL2M;
wire    [1:0]   HRESP_AHBL2M;
wire    [31:0]  HRDATA_AHBL2M;

cmsdk_ahb_to_ahb_sync #(
    .AW                                 (32),
    .DW                                 (32),
    .MW                                 (2),
    .BURST                              (1)
)   AhbBridge   (
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSELS                              (HSEL_AHBL1P4),
    .HADDRS                             (HADDR_AHBL1P4),
    .HTRANSS                            (HTRANS_AHBL1P4),
    .HSIZES                             (HSIZE_AHBL1P4),
    .HWRITES                            (HWRITE_AHBL1P4),
    .HREADYS                            (HREADY_AHBL1P4),
    .HPROTS                             (HPROT_AHBL1P4),
    .HMASTERS                           (HMASTER_AHBL1P4),
    .HMASTLOCKS                         (HMASTERLOCK_AHBL1P4),
    .HWDATAS                            (HWDATA_AHBL1P4),
    .HBURSTS                            (HBURST_AHBL1P4),
    .HREADYOUTS                         (HREADYOUT_AHBL1P4),
    .HRESPS                             (HRESP_AHBL1P4[0]),
    .HRDATAS                            (HRDATA_AHBL1P4),
    .HADDRM                             (HADDR_AHBL2M),
    .HTRANSM                            (HTRANS_AHBL2M),
    .HSIZEM                             (HSIZE_AHBL2M),
    .HWRITEM                            (HWRITE_AHBL2M),
    .HPROTM                             (HPROT_AHBL2M),
    .HMASTERM                           (HMASTER_AHBL2M),
    .HMASTLOCKM                         (HMASTERLOCK_AHBL2M),
    .HWDATAM                            (HWDATA_AHBL2M),
    .HBURSTM                            (HBURST_AHBL2M),
    .HREADYM                            (HREADYOUT_AHBL2M),
    .HRESPM                             (HRESP_AHBL2M[0]),
    .HRDATAM                            (HRDATA_AHBL2M)
);
assign  HRESP_AHBL1P4[1]    =   1'b0;

wire    [31:0]  HADDR_AHBL2P0;
wire    [1:0]   HTRANS_AHBL2P0;
wire            HWRITE_AHBL2P0;
wire    [2:0]   HSIZE_AHBL2P0;
wire    [31:0]  HWDATA_AHBL2P0;
wire    [2:0]   HBURST_AHBL2P0;
wire    [3:0]   HPROT_AHBL2P0;
wire            HREADY_AHBL2P0;
wire    [31:0]  HRDATA_AHBL2P0;
wire    [1:0]   HRESP_AHBL2P0;
wire            HREADYOUT_AHBL2P0;
wire            HSEL_AHBL2P0;
wire    [1:0]   HMASTER_AHBL2P0;
wire            HMASTERLOCK_AHBL2P0;

wire    [31:0]  HADDR_AHBL2P1;
wire    [1:0]   HTRANS_AHBL2P1;
wire            HWRITE_AHBL2P1;
wire    [2:0]   HSIZE_AHBL2P1;
wire    [31:0]  HWDATA_AHBL2P1;
wire    [2:0]   HBURST_AHBL2P1;
wire    [3:0]   HPROT_AHBL2P1;
wire            HREADY_AHBL2P1;
wire    [31:0]  HRDATA_AHBL2P1;
wire    [1:0]   HRESP_AHBL2P1;
wire            HREADYOUT_AHBL2P1;
wire            HSEL_AHBL2P1;
wire    [1:0]   HMASTER_AHBL2P1;
wire            HMASTERLOCK_AHBL2P1;


L2AhbMtx    L2AhbMtx(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),

    .REMAP                              (4'b0),

    .HSELS0                             (1'b1),
    .HADDRS0                            (HADDR_AHBL2M),
    .HTRANSS0                           (HTRANS_AHBL2M),
    .HWRITES0                           (HWRITE_AHBL2M),
    .HSIZES0                            (HSIZE_AHBL2M),
    .HBURSTS0                           (HBURST_AHBL2M),
    .HPROTS0                            (HPROT_AHBL2M),
    .HMASTERS0                          (HMASTER_AHBL2M),
    .HWDATAS0                           (HWDATA_AHBL2M),
    .HMASTLOCKS0                        (HMASTERLOCK_AHBL2M),
    .HREADYS0                           (HREADYOUT_AHBL2M),
    .HRDATAS0                           (HRDATA_AHBL2M),
    .HREADYOUTS0                        (HREADYOUT_AHBL2M),
    .HRESPS0                            (HRESP_AHBL2M),

    .HSELM0                             (HSEL_AHBL2P0),
    .HADDRM0                            (HADDR_AHBL2P0),
    .HTRANSM0                           (HTRANS_AHBL2P0),
    .HWRITEM0                           (HWRITE_AHBL2P0),
    .HSIZEM0                            (HSIZE_AHBL2P0),
    .HBURSTM0                           (HBURST_AHBL2P0),
    .HPROTM0                            (HPROT_AHBL2P0),
    .HMASTERM0                          (HMASTER_AHBL2P0),
    .HWDATAM0                           (HWDATA_AHBL2P0),
    .HMASTLOCKM0                        (HMASTERLOCK_AHBL2P0),
    .HREADYMUXM0                        (HREADY_AHBL2P0),
    .HRDATAM0                           (HRDATA_AHBL2P0),
    .HREADYOUTM0                        (HREADYOUT_AHBL2P0),
    .HRESPM0                            (HRESP_AHBL2P0),

    .HSELM1                             (HSEL_AHBL2P1),
    .HADDRM1                            (HADDR_AHBL2P1),
    .HTRANSM1                           (HTRANS_AHBL2P1),
    .HWRITEM1                           (HWRITE_AHBL2P1),
    .HSIZEM1                            (HSIZE_AHBL2P1),
    .HBURSTM1                           (HBURST_AHBL2P1),
    .HPROTM1                            (HPROT_AHBL2P1),
    .HMASTERM1                          (HMASTER_AHBL2P1),
    .HWDATAM1                           (HWDATA_AHBL2P1),
    .HMASTLOCKM1                        (HMASTERLOCK_AHBL2P1),
    .HREADYMUXM1                        (HREADY_AHBL2P1),
    .HRDATAM1                           (HRDATA_AHBL2P1),
    .HREADYOUTM1                        (HREADYOUT_AHBL2P1),
    .HRESPM1                            (HRESP_AHBL2P1),

    .SCANENABLE                         (1'b0),
    .SCANINHCLK                         (1'b0),
    .SCANOUTHCLK                        ()
);

wire    [15:0]  PADDR;    
wire            PENABLE;  
wire            PWRITE;   
wire    [3:0]   PSTRB;    
wire    [2:0]   PPROT;    
wire    [31:0]  PWDATA;   
wire            PSEL;     
wire            APBACTIVE;                  
wire    [31:0]  PRDATA;   
wire            PREADY;  
wire            PSLVERR; 

cmsdk_ahb_to_apb #(
    .ADDRWIDTH                          (16),
    .REGISTER_RDATA                     (1),
    .REGISTER_WDATA                     (1)
)    ApbBridge  (
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .PCLKEN                             (1'b1),
    .HSEL                               (HSEL_AHBL1P2),
    .HADDR                              (HADDR_AHBL1P2),
    .HTRANS                             (HTRANS_AHBL1P2),
    .HSIZE                              (HSIZE_AHBL1P2),
    .HPROT                              (HPROT_AHBL1P2),
    .HWRITE                             (HWRITE_AHBL1P2),
    .HREADY                             (HREADY_AHBL1P2),
    .HWDATA                             (HWDATA_AHBL1P2),
    .HREADYOUT                          (HREADYOUT_AHBL1P2),
    .HRDATA                             (HRDATA_AHBL1P2),
    .HRESP                              (HRESP_AHBL1P2[0]),        
    .PADDR                              (PADDR),
    .PENABLE                            (PENABLE),
    .PWRITE                             (PWRITE),
    .PSTRB                              (PSTRB),
    .PPROT                              (PPROT),
    .PWDATA                             (PWDATA),
    .PSEL                               (PSEL),
    .APBACTIVE                          (APBACTIVE),
    .PRDATA                             (PRDATA),
    .PREADY                             (PREADY),
    .PSLVERR                            (PSLVERR)                      
);
assign  HRESP_AHBL1P2[1]    =   1'b0;

wire            PSEL_APBP0;
wire            PREADY_APBP0;
wire    [31:0]  PRDATA_APBP0;
wire            PSLVERR_APBP0;

cmsdk_apb_slave_mux #(
    .PORT0_ENABLE                       (1),
    .PORT1_ENABLE                       (0),
    .PORT2_ENABLE                       (0),
    .PORT3_ENABLE                       (0),
    .PORT4_ENABLE                       (0),
    .PORT5_ENABLE                       (0),
    .PORT6_ENABLE                       (0),
    .PORT7_ENABLE                       (0),
    .PORT8_ENABLE                       (0),
    .PORT9_ENABLE                       (0),
    .PORT10_ENABLE                      (0),
    .PORT11_ENABLE                      (0),
    .PORT12_ENABLE                      (0),
    .PORT13_ENABLE                      (0),
    .PORT14_ENABLE                      (0),
    .PORT15_ENABLE                      (0)
)   ApbSystem   (
    .DECODE4BIT                         (PADDR[15:12]),
    .PSEL                               (PSEL),

    .PSEL0                              (PSEL_APBP0),
    .PREADY0                            (PREADY_APBP0),
    .PRDATA0                            (PRDATA_APBP0),
    .PSLVERR0                           (PSLVERR_APBP0),
    
    .PSEL1                              (),
    .PREADY1                            (1'b1),
    .PRDATA1                            (32'b0),
    .PSLVERR1                           (1'b0),

    .PSEL2                              (),
    .PREADY2                            (1'b1),
    .PRDATA2                            (32'b0),
    .PSLVERR2                           (1'b0),

    .PSEL3                              (),
    .PREADY3                            (1'b1),
    .PRDATA3                            (32'b0),
    .PSLVERR3                           (1'b0),

    .PSEL4                              (),
    .PREADY4                            (1'b1),
    .PRDATA4                            (32'b0),
    .PSLVERR4                           (1'b0),

    .PSEL5                              (),
    .PREADY5                            (1'b1),
    .PRDATA5                            (32'b0),
    .PSLVERR5                           (1'b0),

    .PSEL6                              (),
    .PREADY6                            (1'b1),
    .PRDATA6                            (32'b0),
    .PSLVERR6                           (1'b0),

    .PSEL7                              (),
    .PREADY7                            (1'b1),
    .PRDATA7                            (32'b0),
    .PSLVERR7                           (1'b0),

    .PSEL8                              (),
    .PREADY8                            (1'b1),
    .PRDATA8                            (32'b0),
    .PSLVERR8                           (1'b0),

    .PSEL9                              (),
    .PREADY9                            (1'b1),
    .PRDATA9                            (32'b0),
    .PSLVERR9                           (1'b0),

    .PSEL10                             (),
    .PREADY10                           (1'b1),
    .PRDATA10                           (32'b0),
    .PSLVERR10                          (1'b0),

    .PSEL11                             (),
    .PREADY11                           (1'b1),
    .PRDATA11                           (32'b0),
    .PSLVERR11                          (1'b0),

    .PSEL12                             (),
    .PREADY12                           (1'b1),
    .PRDATA12                           (32'b0),
    .PSLVERR12                          (1'b0),
    
    .PSEL13                             (),
    .PREADY13                           (1'b1),
    .PRDATA13                           (32'b0),
    .PSLVERR13                          (1'b0),

    .PSEL14                             (),
    .PREADY14                           (1'b1),
    .PRDATA14                           (32'b0),
    .PSLVERR14                          (1'b0),

    .PSEL15                             (),
    .PREADY15                           (1'b1),
    .PRDATA15                           (32'b0),
    .PSLVERR15                          (1'b0),

    .PREADY                             (PREADY),
    .PRDATA                             (PRDATA),
    .PSLVERR                            (PSLVERR)

);

//------------------------------------------------------------------------------
// AHB ITCM
//------------------------------------------------------------------------------

wire    [13:0]  ITCMADDR;
wire    [31:0]  ITCMRDATA,ITCMWDATA;
wire    [3:0]   ITCMWRITE;
wire            ITCMCS;

cmsdk_ahb_to_sram #(
    .AW                                 (16)
)   AhbItcm (
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSEL                               (HSEL_AHBL1P0),
    .HREADY                             (HREADY_AHBL1P0),
    .HTRANS                             (HTRANS_AHBL1P0),
    .HSIZE                              (HSIZE_AHBL1P0),
    .HWRITE                             (HWRITE_AHBL1P0),
    .HADDR                              (HADDR_AHBL1P0),
    .HWDATA                             (HWDATA_AHBL1P0),
    .HREADYOUT                          (HREADYOUT_AHBL1P0),
    .HRESP                              (HRESP_AHBL1P0[0]),
    .HRDATA                             (HRDATA_AHBL1P0),
    .SRAMRDATA                          (ITCMRDATA),
    .SRAMADDR                           (ITCMADDR),
    .SRAMWEN                            (ITCMWRITE),
    .SRAMWDATA                          (ITCMWDATA),
    .SRAMCS                             (ITCMCS)
);
assign  HRESP_AHBL1P0[1]    =   1'b0;

cmsdk_fpga_sram #(
    .AW                                 (14)
)   ITCM    (
    .CLK                                (clk),
    .ADDR                               (ITCMADDR),
    .WDATA                              (ITCMWDATA),
    .WREN                               (ITCMWRITE),
    .CS                                  (ITCMCS),
    .RDATA                              (ITCMRDATA)
);

//------------------------------------------------------------------------------
// AHB DTCM
//------------------------------------------------------------------------------

wire    [13:0]  DTCMADDR;
wire    [31:0]  DTCMRDATA,DTCMWDATA;
wire    [3:0]   DTCMWRITE;
wire            DTCMCS;

cmsdk_ahb_to_sram #(
    .AW                                 (16)
)   AhbDtcm (
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSEL                               (HSEL_AHBL1P1),
    .HREADY                             (HREADY_AHBL1P1),
    .HTRANS                             (HTRANS_AHBL1P1),
    .HSIZE                              (HSIZE_AHBL1P1),
    .HWRITE                             (HWRITE_AHBL1P1),
    .HADDR                              (HADDR_AHBL1P1),
    .HWDATA                             (HWDATA_AHBL1P1),
    .HREADYOUT                          (HREADYOUT_AHBL1P1),
    .HRESP                              (HRESP_AHBL1P1[0]),
    .HRDATA                             (HRDATA_AHBL1P1),
    .SRAMRDATA                          (DTCMRDATA),
    .SRAMADDR                           (DTCMADDR),
    .SRAMWEN                            (DTCMWRITE),
    .SRAMWDATA                          (DTCMWDATA),
    .SRAMCS                             (DTCMCS)
);
assign  HRESP_AHBL1P1[1]    =   1'b0;

cmsdk_fpga_sram #(
    .AW                                 (14)
)   DTCM    (
    .CLK                                (clk),
    .ADDR                               (DTCMADDR),
    .WDATA                              (DTCMWDATA),
    .WREN                               (DTCMWRITE),
    .CS                                 (DTCMCS),
    .RDATA                              (DTCMRDATA)
);

//------------------------------------------------------------------------------
// APB UART
//------------------------------------------------------------------------------

wire            TXINT;
wire            RXINT;
wire            TXOVRINT;
wire            RXOVRINT;
wire            UARTINT;      

cmsdk_apb_uart UART(
    .PCLK                               (clk),
    .PCLKG                              (clk),
    .PRESETn                            (cpuresetn),
    .PSEL                               (PSEL_APBP0),
    .PADDR                              (PADDR[11:2]),
    .PENABLE                            (PENABLE), 
    .PWRITE                             (PWRITE),
    .PWDATA                             (PWDATA),
    .ECOREVNUM                          (4'b0),
    .PRDATA                             (PRDATA_APBP0),
    .PREADY                             (PREADY_APBP0),
    .PSLVERR                            (PSLVERR_APBP0),
    .RXD                                (RXD),
    .TXD                                (TXD),
    .TXEN                               (TXEN),
    .BAUDTICK                           (BAUDTICK),
    .TXINT                              (TXINT),
    .RXINT                              (RXINT),
    .TXOVRINT                           (TXOVRINT),
    .RXOVRINT                           (RXOVRINT),
    .UARTINT                            (UARTINT)
);

//------------------------------------------------------------------------------
// APB DEFAULT SLAVE RESERVED FOR DDR
//------------------------------------------------------------------------------

cmsdk_ahb_default_slave Default4DDR(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSEL                               (HSEL_AHBL1P3),
    .HTRANS                             (HTRANS_AHBL1P3),
    .HREADY                             (HREADY_AHBL1P3),
    .HREADYOUT                          (HREADYOUT_AHBL1P3),
    .HRESP                              (HRESP_AHBL1P3[0])
);
assign  HRESP_AHBL1P3[1]    =   1'b0;
assign  HRDATA_AHBL1P3      =   32'b0;

//------------------------------------------------------------------------------
// APB DEFAULT SLAVE RESERVED FOR CAMERA
//------------------------------------------------------------------------------
/*
cmsdk_ahb_default_slave Default4Camera(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSEL                               (HSEL_AHBL2P0),
    .HTRANS                             (HTRANS_AHBL2P0),
    .HREADY                             (HREADY_AHBL2P0),
    .HREADYOUT                          (HREADYOUT_AHBL2P0),
    .HRESP                              (HRESP_AHBL2P0[0])
);
assign  HRESP_AHBL2P0[1]    =   1'b0;
assign  HRDATA_AHBL2P0      =   32'b0;
*/
//------------------------------------------------------------------------------
// APB DEFAULT SLAVE RESERVED FOR LCD
//------------------------------------------------------------------------------
/*
cmsdk_ahb_default_slave Default4LCD(
    .HCLK                               (clk),
    .HRESETn                            (cpuresetn),
    .HSEL                               (HSEL_AHBL2P1),
    .HTRANS                             (HTRANS_AHBL2P1),
    .HREADY                             (HREADY_AHBL2P1),
    .HREADYOUT                          (HREADYOUT_AHBL2P1),
    .HRESP                              (HRESP_AHBL2P1[0])
);
assign  HRESP_AHBL2P1[1]    =   1'b0;
assign  HRDATA_AHBL2P1      =   32'b0;
*/

//------------------------------------------------------------------------------
// AHB GPIO
//------------------------------------------------------------------------------
    
wire [15:0]  GPIOINT;
wire  COMBINT;
cmsdk_ahb_gpio #(
    .ALTERNATE_FUNC_MASK                (16'hFFFF),
    .ALTERNATE_FUNC_DEFAULT             (16'h0000),
    .BE                                 (0)
)
 GPIO_test(
    .HCLK                              (clk),
    .HRESETn                           (cpuresetn),
    .FCLK                              (clk),
    .HSEL                              (HSEL_AHBL2P0),
    .HREADY                            (HREADY_AHBL2P0),
    .HTRANS                            (HTRANS_AHBL2P0),
    .HSIZE                             (HSIZE_AHBL2P0),
    .HWRITE                            (HWRITE_AHBL2P0),
    .HADDR                             (HADDR_AHBL2P0),
    .HWDATA                            (HWDATA_AHBL2P0),

    .ECOREVNUM                         (4'b0),



    .HREADYOUT                         (HREADYOUT_AHBL2P0),
    .HRESP                             (HRESP_AHBL2P0),
    .HRDATA                            (HRDATA_AHBL2P0),

    .PORTIN                            (PORTIN),  //data input
    
    .PORTOUT                           (PORTOUT),
    .PORTEN                            (PORTEN),
    .PORTFUNC                          (PORTFUNC),

    .GPIOINT                           (GPIOINT),
    .COMBINT                           (COMBINT)

);


//------------------------------------------------------------------------------
// APB DEFAULT SLAVE RESERVED FOR LCD
//------------------------------------------------------------------------------

custom_ahb_lcd LCD(
        .HCLK                   (clk),
        .HRESETn                (cpuresetn),
        .HSEL                   (HSEL_AHBL2P1),
        .HADDR                  (HADDR_AHBL2P1),
        .HPROT                  (HPROT_AHBL2P1),
        .HSIZE                  (HSIZE_AHBL2P1),
        .HTRANS                 (HTRANS_AHBL2P1),
        .HWDATA                 (HWDATA_AHBL2P1),
        .HWRITE                 (HWRITE_AHBL2P1),
        .HRDATA                 (HRDATA_AHBL2P1),
        .HREADY                 (HREADY_AHBL2P1),
        .HREADYOUT              (HREADYOUT_AHBL2P1),
        .HRESP                  (HRESP_AHBL2P1[0]),
        .LCD_CS                 (LCD_CS),
        .LCD_RS                 (LCD_RS),
        .LCD_WR                 (LCD_WR),
        .LCD_RD                 (LCD_RD),
        .LCD_RST                (LCD_RST),
        .LCD_DATA               (LCD_DATA),
        .LCD_BL_CTR             (LCD_BL_CTR)
);
assign  HRESP_AHBL2P1[1]    =   1'b0;

 
//------------------------------------------------------------------------------
// INTERRUPT 
//------------------------------------------------------------------------------

assign  IRQ     =   {235'b0,COMBINT,GPIOINT[7],TXOVRINT|RXOVRINT,RXINT,TXINT};

//reg [7:0] LED;

//subsystem
always @(posedge CLK50m or negedge RSTn)
if (!RSTn)
  LED[7:0]=7'd11111111;
else  
begin
case(RESULT_2)
				4'b0000: LED[7:0] = 7'b11000000;    //0
            4'b0001: LED[7:0] = 7'b11111001;    //1
            4'b0010: LED[7:0] = 7'b10100100;    //2
            4'b0011: LED[7:0] = 7'b10110000;    //3
            4'b0100: LED[7:0] = 7'b10011001;    //4
            4'b0101: LED[7:0] = 7'b10010010;    //5
            4'b0110: LED[7:0] = 7'b10000010;    //6
            4'b0111: LED[7:0] = 7'b11111000;    //7
            4'b1000: LED[7:0] = 7'b10000000;    //8
            4'b1001: LED[7:0] = 7'b10010000;    //9
				default LED[7:0]=7'b11111111;
endcase
end

//reg counter=0;
//always @(posedge clk50 or negedge rst)
//if (!rst)
//	begin
//		LED[7]=~LED[7];
//		counter=0;
//	end
//else 
//	begin
//	if (counter==100000000)
//		begin
//			LED[7]=~LED[7];
//			counter=0;
//		end
//	else
//		begin 
//			counter=counter+1;
//		end
//	end


// Clocks

pll pll_for_sdram_0
(
	.areset   ( !RSTn ),
	.inclk0   ( CLK50m ),
	.c0       ( clk100 ),
	.c2       ( clk25 ),
	.c3       ( clk24 ),
	.locked   ( locked )
);

pll_for_disp pll2
(
	.areset   ( !RSTn ),
	.inclk0   ( CLK50m ),
	.c0       ( clk143 )

);

// Process data from camera

cam_wrp cam_wrp_0
(
	.rst_n                ( RSTn ),
	.data_cam             ( data_cam ),
	.HREF_cam             ( HREF_cam ),
	.PCLK_cam             ( PCLK_cam ),
	.ctrl_busy            ( ctrl_busy ),
	.input_fifo_to_sdram  ( input_fifo_to_sdram ),
	.addr_sdram           ( wr_addr ),
	.wr_enable            ( wr_enable )
);

assign XCLK_cam = clk24;

//TFT display

hellosoc_top TFT(
	.tft_sdo            ( tft_sdo ), 
	.tft_sck            ( tft_sck ), 
	.tft_sdi            ( tft_sdi ), 
	.tft_dc             ( tft_dc ), 
	.tft_reset          ( tft_reset ), 
	.tft_cs             ( tft_cs ),
	.rst_n              ( RSTn ),
	.clk_sdram          ( !rd_ready ),
	.wr_fifo            ( (!wr_enable) && ready ),
	.sdram_data         ( rd_data ),
	.tft_clk            ( clk100 ),
	.output_rdusedw     ( output_rdusedw_TFT ),
	.fbClk              ( fbClk ),
	.r                  ( r ),
	.g                  ( g ),
	.b                  ( b ),
	.start_28           ( start_image ),
	.RESULT             ( RESULT_2 )
);

reg [9:0] x_sdram;

always @(posedge rd_ready or negedge RSTn)
begin
	if (!RSTn)
	begin
		rd_addr = 320*201+3;
		ready=1'b1;
		x_sdram=0;
	end
	else
	begin
		if ((!wr_enable)&&(ready))
				begin
					if (rd_addr < 24'd76799) rd_addr = rd_addr + 1'b1;
					else rd_addr=24'd0;
					if (x_sdram<320) x_sdram=x_sdram+1'b1;
					else x_sdram=1;
				end
		if (x_sdram==320)
			begin
				if ((!wr_enable)&&(output_rdusedw_TFT<=3000)) begin ready=1'b1;  end
				else begin  ready=1'b0;  end
			end
	end
end

	
sdram_controller SDRAM(
	.wr_addr       (wr_addr),
	.wr_data       (input_fifo_to_sdram),
	.wr_enable     (wr_enable),
	.rd_addr       (rd_addr),
	.rd_data       (rd_data),
	.rd_ready      (rd_ready),
	.rd_enable     (!wr_enable),
	.busy          (ctrl_busy), 
	.rst_n         (RSTn), 
	.clk           (clk143),
	/* SDRAM SIDE */
	.addr          (sd_addr), 
	.bank_addr     (ba), 
	.data          (sd_data), 
	.clock_enable  (Cke),	 
	.cs_n          (cs_n), 
	.ras_n         (ras_n), 
	.cas_n         (cas_n), 
	.we_n          (we_n),	
	.data_mask_low (dqm[0]), 
	.data_mask_high(dqm[1]) 
);


reg start_gray;
wire end_gray;
reg [9:0] x_gray, y_gray;
wire [4:0] i_gray, j_gray;
wire [12:0] out_data_gray;
wire wrreq_gray;

pre_v2 grayscale(
	.clk           (fbClk), 
	.rst_n         (RSTn),
	.start         (start_gray), 
	.data          ({r,g,b}), 
	.end_pre       (end_gray), 
	.output_data   (out_data_gray), 
	.x             (x_gray), 
	.y             (y_gray), 
	.i             (i_gray), 
	.j             (j_gray) ,
	.data_req      (wrreq_gray)
);


TOP neiroset (
	.clk                (CLK50m),
	.GO                 (GO_NEIROSET),
	.RESULT             (RESULT),
	.we_database        (wrreq_gray),
	.dp_database        (out_data_gray),
	.address_p_database (j_gray*28+i_gray),
	.STOP               (end_neiroset)
);


always @(posedge fbClk or negedge RSTn) 
begin
	if ( !RSTn )
	begin
		x_gray = 10'd0;
		y_gray = 10'd0;
		start_gray = 1'b0;
	end
	else
	begin
		if (start_image)
			begin
				if (x_gray == 10'd319) 
				begin
					x_gray <= 10'd0;
					if (y_gray == 10'd239) 
					begin
						y_gray <= 10'd0;
					end
					else y_gray <= y_gray+1'b1;
				end
				else x_gray <= x_gray+1'b1;
			end
			
		if ((GO_NEIROSET == 1'b1) && (x_gray == 10'd47) && (y_gray == 10'd239)) start_gray = 1'b1;
		if (end_gray) start_gray = 1'b0;
	end
end	


always @(posedge CLK50m or negedge RSTn) 
begin
	if ( !RSTn )
	begin
		RESULT_2 = 4'b1111;
		GO_NEIROSET = 1'b1;
	end
	else
	begin
		if (end_gray) begin GO_NEIROSET = 1'b0; end
		if (end_neiroset) begin GO_NEIROSET = 1'b1; RESULT_2 = RESULT; end
	end
end



// start camera inititalization
reg [2:0] strt;

always @(posedge clk25 or negedge RSTn)
	if (!RSTn)
		strt <= 3'h0;
	else
	begin
		if (locked)
			begin
				if ( &strt )
					strt	<= strt;
				else
					strt	<= strt + 1'h1;
			end
	end

// camera inititalization
camera_configure 
#(	
	.CLK_FREQ 	( 25000000 )
)
camera_configure_0
(
	.clk   ( clk25            ),	
	.start ( ( strt == 3'h6 ) ),
	.sioc  ( sioc             ),
	.siod  ( siod             ),
	.done  ( 			        )
);

// reset camera with overall reset from button
assign res_cam    = RSTn;
assign on_off_cam = !RSTn;






endmodule