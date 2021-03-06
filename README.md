# Hand-Writing-Digital-Recognization-Based-on-FPGA
A recognition system of handwritten numerals is designed and implemented in FPGA. The system consists of Cortex M3 microcontroller, image processing hardware accelerator, and control circuits of camera and LCD. Image processing hardware accelerator is realized through parallel computing, data reuse, and data compression. The system is described using Verilog HDL, synthesized through Quartus II, simulated through ModelSim. It is tested on DE-2 development board featuring Cyclone IV FPGA. The success rate of handwritten numerals recognition  is over 90%. The processing speed exceeds 150 frame per second for 28×28 pixel color image.
本设计在 FPGA芯片上设计实现了一个以Cortex M3为内核的轻量级手写体数字识别图像处理片上系统，系统搭载了图像处理硬件加速器以及摄像头、液晶屏等外设模块。硬件图像处理加速器通过并行计算、数据复用、数据压缩等方式实现。系统采用Verilog硬件描述语言进行设计描述，用QUARTUS II综合，用ModelSim进行仿真测试。在载有Cyclone IV芯片的DE-2开发板上对系统进行了硬件测试。系统的手写数字识别成功率为90%以上，对28×28像素的彩色图像处理速度超过150帧/s。

我的毕业设计，当时没有上传，最近整理一下放上来了，很多细节都忘了，找个时间我再理一下。
整体的结构图如下

![image](https://user-images.githubusercontent.com/53364849/142157810-e41f68a0-03c9-41b2-aed2-dd0ff3fb79c5.png)

![11](https://user-images.githubusercontent.com/53364849/142157837-512ca62f-e580-4f38-bbd8-abeb2bdce7e7.png)
