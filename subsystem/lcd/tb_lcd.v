module test();

    reg clk;
    reg tft_clk;
    reg tft_sdo;
    reg rst_n;
    reg clk_sdram;
    reg wr_fifo;
    reg [15:0] sdram_data;
    reg [3:0] RESULT;    



    wire tft_sck;
    wire tft_sdi;
    wire tft_dc;  
    wire tft_reset;
    wire tft_cs;
    wire [11:0] output_rdusedw;
    wire [4:0] r;
    wire [5:0] g;
    wire [4:0] b;

  hellosoc_top TOP(
	.tft_sdo                (tft_sdo     ),         //主设备数据输出，从设备数据输入
	.tft_sck                (tft_sck     ),         //SPI总线时钟信号
	.tft_sdi                (tft_sdi     ),         //主设备数据输入，从设备数据输出 
	.tft_dc                 (tft_dc      ),         //LCD寄存器/数据选择信号
	.tft_reset              (tft_reset   ),         //LCD复位信号
	.tft_cs                 (tft_cs      ),         //LCD片选信号
	.rst_n                  (rst_n       ),         //系统复位信号
	.clk_sdram              (clk_sdram   ),         //sdram时钟信号，用于写fifo
	.wr_fifo                (wr_fifo     ),         //写fifo信号
	.sdram_data             (sdram_data  ),         //sdram数据输入
	.tft_clk                (tft_clk     ),         //LCD时钟信号
	.output_rdusedw         (output_rduse),         //sdram中可以读的word数   
    .fbClk                  (       ),
	.r                      (r           ),
	.g                      (g           ),
	.b                      (b           ),
	.start_28               (),
	.RESULT                 (RESULT)

  );
initial begin
  clk=0;
  //tft_reset=1;
  tft_clk=0;
  rst_n=0;
  clk_sdram=0;
  wr_fifo=0;
  sdram_data=0;
  RESULT=0; 
  tft_sdo=0; 

  #10;
  rst_n=1;
  rst_n=0;
  #1000  ;
  rst_n=1;
 // tft_reset=0;
  wr_fifo=1;
end
always #10 
begin 
    clk<=~clk;
end
always #50 
begin 
    tft_clk<=~tft_clk; 
end
always #30 
begin 
    clk_sdram<=~clk_sdram;
end
always #20
begin
    tft_sdo=tft_sdo+1;
    sdram_data=sdram_data+2;
    RESULT=RESULT+4;
end
initial begin
    #10000  $finish;
end

endmodule