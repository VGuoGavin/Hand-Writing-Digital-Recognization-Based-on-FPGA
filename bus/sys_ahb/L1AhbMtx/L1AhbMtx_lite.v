//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2001-2013-2020 ARM Limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//      SVN Information
//
//      Checked In          : $Date: 2012-10-15 18:01:36 +0100 (Mon, 15 Oct 2012) $
//
//      Revision            : $Revision: 225465 $
//
//      Release Information : Cortex-M System Design Kit-r1p0-01rel0
//
//-----------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
//  Abstract            : BusMatrixLite is a wrapper module that wraps around
//                        the BusMatrix module to give AHB Lite compliant
//                        slave and master interfaces.
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module L1AhbMtx_lite (

    // Common AHB signals
    HCLK,
    HRESETn,

    // System Address Remap control
    REMAP,

    // Input port SI0 (inputs from master 0)
    HADDRS0,
    HTRANSS0,
    HWRITES0,
    HSIZES0,
    HBURSTS0,
    HPROTS0,
    HWDATAS0,
    HMASTLOCKS0,

    // Input port SI1 (inputs from master 1)
    HADDRS1,
    HTRANSS1,
    HWRITES1,
    HSIZES1,
    HBURSTS1,
    HPROTS1,
    HWDATAS1,
    HMASTLOCKS1,

    // Input port SI2 (inputs from master 2)
    HADDRS2,
    HTRANSS2,
    HWRITES2,
    HSIZES2,
    HBURSTS2,
    HPROTS2,
    HWDATAS2,
    HMASTLOCKS2,

    // Input port SI3 (inputs from master 3)
    HADDRS3,
    HTRANSS3,
    HWRITES3,
    HSIZES3,
    HBURSTS3,
    HPROTS3,
    HWDATAS3,
    HMASTLOCKS3,

    // Input port SI4 (inputs from master 4)
    HADDRS4,
    HTRANSS4,
    HWRITES4,
    HSIZES4,
    HBURSTS4,
    HPROTS4,
    HWDATAS4,
    HMASTLOCKS4,

    // Output port MI0 (inputs from slave 0)
    HRDATAM0,
    HREADYOUTM0,
    HRESPM0,

    // Output port MI1 (inputs from slave 1)
    HRDATAM1,
    HREADYOUTM1,
    HRESPM1,

    // Output port MI2 (inputs from slave 2)
    HRDATAM2,
    HREADYOUTM2,
    HRESPM2,

    // Output port MI3 (inputs from slave 3)
    HRDATAM3,
    HREADYOUTM3,
    HRESPM3,

    // Output port MI4 (inputs from slave 4)
    HRDATAM4,
    HREADYOUTM4,
    HRESPM4,

    // Scan test dummy signals; not connected until scan insertion
    SCANENABLE,   // Scan Test Mode Enable
    SCANINHCLK,   // Scan Chain Input


    // Output port MI0 (outputs to slave 0)
    HSELM0,
    HADDRM0,
    HTRANSM0,
    HWRITEM0,
    HSIZEM0,
    HBURSTM0,
    HPROTM0,
    HWDATAM0,
    HMASTLOCKM0,
    HREADYMUXM0,

    // Output port MI1 (outputs to slave 1)
    HSELM1,
    HADDRM1,
    HTRANSM1,
    HWRITEM1,
    HSIZEM1,
    HBURSTM1,
    HPROTM1,
    HWDATAM1,
    HMASTLOCKM1,
    HREADYMUXM1,

    // Output port MI2 (outputs to slave 2)
    HSELM2,
    HADDRM2,
    HTRANSM2,
    HWRITEM2,
    HSIZEM2,
    HBURSTM2,
    HPROTM2,
    HWDATAM2,
    HMASTLOCKM2,
    HREADYMUXM2,

    // Output port MI3 (outputs to slave 3)
    HSELM3,
    HADDRM3,
    HTRANSM3,
    HWRITEM3,
    HSIZEM3,
    HBURSTM3,
    HPROTM3,
    HWDATAM3,
    HMASTLOCKM3,
    HREADYMUXM3,

    // Output port MI4 (outputs to slave 4)
    HSELM4,
    HADDRM4,
    HTRANSM4,
    HWRITEM4,
    HSIZEM4,
    HBURSTM4,
    HPROTM4,
    HWDATAM4,
    HMASTLOCKM4,
    HREADYMUXM4,

    // Input port SI0 (outputs to master 0)
    HRDATAS0,
    HREADYS0,
    HRESPS0,

    // Input port SI1 (outputs to master 1)
    HRDATAS1,
    HREADYS1,
    HRESPS1,

    // Input port SI2 (outputs to master 2)
    HRDATAS2,
    HREADYS2,
    HRESPS2,

    // Input port SI3 (outputs to master 3)
    HRDATAS3,
    HREADYS3,
    HRESPS3,

    // Input port SI4 (outputs to master 4)
    HRDATAS4,
    HREADYS4,
    HRESPS4,

    // Scan test dummy signals; not connected until scan insertion
    SCANOUTHCLK   // Scan Chain Output

    );

// -----------------------------------------------------------------------------
// Input and Output declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    input         HCLK;            // AHB System Clock
    input         HRESETn;         // AHB System Reset

    // System Address Remap control
    input   [3:0] REMAP;           // System Address REMAP control

    // Input port SI0 (inputs from master 0)
    input  [31:0] HADDRS0;         // Address bus
    input   [1:0] HTRANSS0;        // Transfer type
    input         HWRITES0;        // Transfer direction
    input   [2:0] HSIZES0;         // Transfer size
    input   [2:0] HBURSTS0;        // Burst type
    input   [3:0] HPROTS0;         // Protection control
    input  [31:0] HWDATAS0;        // Write data
    input         HMASTLOCKS0;     // Locked Sequence

    // Input port SI1 (inputs from master 1)
    input  [31:0] HADDRS1;         // Address bus
    input   [1:0] HTRANSS1;        // Transfer type
    input         HWRITES1;        // Transfer direction
    input   [2:0] HSIZES1;         // Transfer size
    input   [2:0] HBURSTS1;        // Burst type
    input   [3:0] HPROTS1;         // Protection control
    input  [31:0] HWDATAS1;        // Write data
    input         HMASTLOCKS1;     // Locked Sequence

    // Input port SI2 (inputs from master 2)
    input  [31:0] HADDRS2;         // Address bus
    input   [1:0] HTRANSS2;        // Transfer type
    input         HWRITES2;        // Transfer direction
    input   [2:0] HSIZES2;         // Transfer size
    input   [2:0] HBURSTS2;        // Burst type
    input   [3:0] HPROTS2;         // Protection control
    input  [31:0] HWDATAS2;        // Write data
    input         HMASTLOCKS2;     // Locked Sequence

    // Input port SI3 (inputs from master 3)
    input  [31:0] HADDRS3;         // Address bus
    input   [1:0] HTRANSS3;        // Transfer type
    input         HWRITES3;        // Transfer direction
    input   [2:0] HSIZES3;         // Transfer size
    input   [2:0] HBURSTS3;        // Burst type
    input   [3:0] HPROTS3;         // Protection control
    input  [31:0] HWDATAS3;        // Write data
    input         HMASTLOCKS3;     // Locked Sequence

    // Input port SI4 (inputs from master 4)
    input  [31:0] HADDRS4;         // Address bus
    input   [1:0] HTRANSS4;        // Transfer type
    input         HWRITES4;        // Transfer direction
    input   [2:0] HSIZES4;         // Transfer size
    input   [2:0] HBURSTS4;        // Burst type
    input   [3:0] HPROTS4;         // Protection control
    input  [31:0] HWDATAS4;        // Write data
    input         HMASTLOCKS4;     // Locked Sequence

    // Output port MI0 (inputs from slave 0)
    input  [31:0] HRDATAM0;        // Read data bus
    input         HREADYOUTM0;     // HREADY feedback
    input         HRESPM0;         // Transfer response

    // Output port MI1 (inputs from slave 1)
    input  [31:0] HRDATAM1;        // Read data bus
    input         HREADYOUTM1;     // HREADY feedback
    input         HRESPM1;         // Transfer response

    // Output port MI2 (inputs from slave 2)
    input  [31:0] HRDATAM2;        // Read data bus
    input         HREADYOUTM2;     // HREADY feedback
    input         HRESPM2;         // Transfer response

    // Output port MI3 (inputs from slave 3)
    input  [31:0] HRDATAM3;        // Read data bus
    input         HREADYOUTM3;     // HREADY feedback
    input         HRESPM3;         // Transfer response

    // Output port MI4 (inputs from slave 4)
    input  [31:0] HRDATAM4;        // Read data bus
    input         HREADYOUTM4;     // HREADY feedback
    input         HRESPM4;         // Transfer response

    // Scan test dummy signals; not connected until scan insertion
    input         SCANENABLE;      // Scan enable signal
    input         SCANINHCLK;      // HCLK scan input


    // Output port MI0 (outputs to slave 0)
    output        HSELM0;          // Slave Select
    output [31:0] HADDRM0;         // Address bus
    output  [1:0] HTRANSM0;        // Transfer type
    output        HWRITEM0;        // Transfer direction
    output  [2:0] HSIZEM0;         // Transfer size
    output  [2:0] HBURSTM0;        // Burst type
    output  [3:0] HPROTM0;         // Protection control
    output [31:0] HWDATAM0;        // Write data
    output        HMASTLOCKM0;     // Locked Sequence
    output        HREADYMUXM0;     // Transfer done

    // Output port MI1 (outputs to slave 1)
    output        HSELM1;          // Slave Select
    output [31:0] HADDRM1;         // Address bus
    output  [1:0] HTRANSM1;        // Transfer type
    output        HWRITEM1;        // Transfer direction
    output  [2:0] HSIZEM1;         // Transfer size
    output  [2:0] HBURSTM1;        // Burst type
    output  [3:0] HPROTM1;         // Protection control
    output [31:0] HWDATAM1;        // Write data
    output        HMASTLOCKM1;     // Locked Sequence
    output        HREADYMUXM1;     // Transfer done

    // Output port MI2 (outputs to slave 2)
    output        HSELM2;          // Slave Select
    output [31:0] HADDRM2;         // Address bus
    output  [1:0] HTRANSM2;        // Transfer type
    output        HWRITEM2;        // Transfer direction
    output  [2:0] HSIZEM2;         // Transfer size
    output  [2:0] HBURSTM2;        // Burst type
    output  [3:0] HPROTM2;         // Protection control
    output [31:0] HWDATAM2;        // Write data
    output        HMASTLOCKM2;     // Locked Sequence
    output        HREADYMUXM2;     // Transfer done

    // Output port MI3 (outputs to slave 3)
    output        HSELM3;          // Slave Select
    output [31:0] HADDRM3;         // Address bus
    output  [1:0] HTRANSM3;        // Transfer type
    output        HWRITEM3;        // Transfer direction
    output  [2:0] HSIZEM3;         // Transfer size
    output  [2:0] HBURSTM3;        // Burst type
    output  [3:0] HPROTM3;         // Protection control
    output [31:0] HWDATAM3;        // Write data
    output        HMASTLOCKM3;     // Locked Sequence
    output        HREADYMUXM3;     // Transfer done

    // Output port MI4 (outputs to slave 4)
    output        HSELM4;          // Slave Select
    output [31:0] HADDRM4;         // Address bus
    output  [1:0] HTRANSM4;        // Transfer type
    output        HWRITEM4;        // Transfer direction
    output  [2:0] HSIZEM4;         // Transfer size
    output  [2:0] HBURSTM4;        // Burst type
    output  [3:0] HPROTM4;         // Protection control
    output [31:0] HWDATAM4;        // Write data
    output        HMASTLOCKM4;     // Locked Sequence
    output        HREADYMUXM4;     // Transfer done

    // Input port SI0 (outputs to master 0)
    output [31:0] HRDATAS0;        // Read data bus
    output        HREADYS0;     // HREADY feedback
    output        HRESPS0;         // Transfer response

    // Input port SI1 (outputs to master 1)
    output [31:0] HRDATAS1;        // Read data bus
    output        HREADYS1;     // HREADY feedback
    output        HRESPS1;         // Transfer response

    // Input port SI2 (outputs to master 2)
    output [31:0] HRDATAS2;        // Read data bus
    output        HREADYS2;     // HREADY feedback
    output        HRESPS2;         // Transfer response

    // Input port SI3 (outputs to master 3)
    output [31:0] HRDATAS3;        // Read data bus
    output        HREADYS3;     // HREADY feedback
    output        HRESPS3;         // Transfer response

    // Input port SI4 (outputs to master 4)
    output [31:0] HRDATAS4;        // Read data bus
    output        HREADYS4;     // HREADY feedback
    output        HRESPS4;         // Transfer response

    // Scan test dummy signals; not connected until scan insertion
    output        SCANOUTHCLK;     // Scan Chain Output

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------

    // Common AHB signals
    wire         HCLK;            // AHB System Clock
    wire         HRESETn;         // AHB System Reset

    // System Address Remap control
    wire   [3:0] REMAP;           // System REMAP signal

    // Input Port SI0
    wire  [31:0] HADDRS0;         // Address bus
    wire   [1:0] HTRANSS0;        // Transfer type
    wire         HWRITES0;        // Transfer direction
    wire   [2:0] HSIZES0;         // Transfer size
    wire   [2:0] HBURSTS0;        // Burst type
    wire   [3:0] HPROTS0;         // Protection control
    wire  [31:0] HWDATAS0;        // Write data
    wire         HMASTLOCKS0;     // Locked Sequence

    wire  [31:0] HRDATAS0;        // Read data bus
    wire         HREADYS0;     // HREADY feedback
    wire         HRESPS0;         // Transfer response

    // Input Port SI1
    wire  [31:0] HADDRS1;         // Address bus
    wire   [1:0] HTRANSS1;        // Transfer type
    wire         HWRITES1;        // Transfer direction
    wire   [2:0] HSIZES1;         // Transfer size
    wire   [2:0] HBURSTS1;        // Burst type
    wire   [3:0] HPROTS1;         // Protection control
    wire  [31:0] HWDATAS1;        // Write data
    wire         HMASTLOCKS1;     // Locked Sequence

    wire  [31:0] HRDATAS1;        // Read data bus
    wire         HREADYS1;     // HREADY feedback
    wire         HRESPS1;         // Transfer response

    // Input Port SI2
    wire  [31:0] HADDRS2;         // Address bus
    wire   [1:0] HTRANSS2;        // Transfer type
    wire         HWRITES2;        // Transfer direction
    wire   [2:0] HSIZES2;         // Transfer size
    wire   [2:0] HBURSTS2;        // Burst type
    wire   [3:0] HPROTS2;         // Protection control
    wire  [31:0] HWDATAS2;        // Write data
    wire         HMASTLOCKS2;     // Locked Sequence

    wire  [31:0] HRDATAS2;        // Read data bus
    wire         HREADYS2;     // HREADY feedback
    wire         HRESPS2;         // Transfer response

    // Input Port SI3
    wire  [31:0] HADDRS3;         // Address bus
    wire   [1:0] HTRANSS3;        // Transfer type
    wire         HWRITES3;        // Transfer direction
    wire   [2:0] HSIZES3;         // Transfer size
    wire   [2:0] HBURSTS3;        // Burst type
    wire   [3:0] HPROTS3;         // Protection control
    wire  [31:0] HWDATAS3;        // Write data
    wire         HMASTLOCKS3;     // Locked Sequence

    wire  [31:0] HRDATAS3;        // Read data bus
    wire         HREADYS3;     // HREADY feedback
    wire         HRESPS3;         // Transfer response

    // Input Port SI4
    wire  [31:0] HADDRS4;         // Address bus
    wire   [1:0] HTRANSS4;        // Transfer type
    wire         HWRITES4;        // Transfer direction
    wire   [2:0] HSIZES4;         // Transfer size
    wire   [2:0] HBURSTS4;        // Burst type
    wire   [3:0] HPROTS4;         // Protection control
    wire  [31:0] HWDATAS4;        // Write data
    wire         HMASTLOCKS4;     // Locked Sequence

    wire  [31:0] HRDATAS4;        // Read data bus
    wire         HREADYS4;     // HREADY feedback
    wire         HRESPS4;         // Transfer response

    // Output Port MI0
    wire         HSELM0;          // Slave Select
    wire  [31:0] HADDRM0;         // Address bus
    wire   [1:0] HTRANSM0;        // Transfer type
    wire         HWRITEM0;        // Transfer direction
    wire   [2:0] HSIZEM0;         // Transfer size
    wire   [2:0] HBURSTM0;        // Burst type
    wire   [3:0] HPROTM0;         // Protection control
    wire  [31:0] HWDATAM0;        // Write data
    wire         HMASTLOCKM0;     // Locked Sequence
    wire         HREADYMUXM0;     // Transfer done

    wire  [31:0] HRDATAM0;        // Read data bus
    wire         HREADYOUTM0;     // HREADY feedback
    wire         HRESPM0;         // Transfer response

    // Output Port MI1
    wire         HSELM1;          // Slave Select
    wire  [31:0] HADDRM1;         // Address bus
    wire   [1:0] HTRANSM1;        // Transfer type
    wire         HWRITEM1;        // Transfer direction
    wire   [2:0] HSIZEM1;         // Transfer size
    wire   [2:0] HBURSTM1;        // Burst type
    wire   [3:0] HPROTM1;         // Protection control
    wire  [31:0] HWDATAM1;        // Write data
    wire         HMASTLOCKM1;     // Locked Sequence
    wire         HREADYMUXM1;     // Transfer done

    wire  [31:0] HRDATAM1;        // Read data bus
    wire         HREADYOUTM1;     // HREADY feedback
    wire         HRESPM1;         // Transfer response

    // Output Port MI2
    wire         HSELM2;          // Slave Select
    wire  [31:0] HADDRM2;         // Address bus
    wire   [1:0] HTRANSM2;        // Transfer type
    wire         HWRITEM2;        // Transfer direction
    wire   [2:0] HSIZEM2;         // Transfer size
    wire   [2:0] HBURSTM2;        // Burst type
    wire   [3:0] HPROTM2;         // Protection control
    wire  [31:0] HWDATAM2;        // Write data
    wire         HMASTLOCKM2;     // Locked Sequence
    wire         HREADYMUXM2;     // Transfer done

    wire  [31:0] HRDATAM2;        // Read data bus
    wire         HREADYOUTM2;     // HREADY feedback
    wire         HRESPM2;         // Transfer response

    // Output Port MI3
    wire         HSELM3;          // Slave Select
    wire  [31:0] HADDRM3;         // Address bus
    wire   [1:0] HTRANSM3;        // Transfer type
    wire         HWRITEM3;        // Transfer direction
    wire   [2:0] HSIZEM3;         // Transfer size
    wire   [2:0] HBURSTM3;        // Burst type
    wire   [3:0] HPROTM3;         // Protection control
    wire  [31:0] HWDATAM3;        // Write data
    wire         HMASTLOCKM3;     // Locked Sequence
    wire         HREADYMUXM3;     // Transfer done

    wire  [31:0] HRDATAM3;        // Read data bus
    wire         HREADYOUTM3;     // HREADY feedback
    wire         HRESPM3;         // Transfer response

    // Output Port MI4
    wire         HSELM4;          // Slave Select
    wire  [31:0] HADDRM4;         // Address bus
    wire   [1:0] HTRANSM4;        // Transfer type
    wire         HWRITEM4;        // Transfer direction
    wire   [2:0] HSIZEM4;         // Transfer size
    wire   [2:0] HBURSTM4;        // Burst type
    wire   [3:0] HPROTM4;         // Protection control
    wire  [31:0] HWDATAM4;        // Write data
    wire         HMASTLOCKM4;     // Locked Sequence
    wire         HREADYMUXM4;     // Transfer done

    wire  [31:0] HRDATAM4;        // Read data bus
    wire         HREADYOUTM4;     // HREADY feedback
    wire         HRESPM4;         // Transfer response


// -----------------------------------------------------------------------------
// Signal declarations
// -----------------------------------------------------------------------------
    wire   [3:0] tie_hi_4;
    wire         tie_hi;
    wire         tie_low;
    wire   [1:0] i_hrespS0;
    wire   [1:0] i_hrespS1;
    wire   [1:0] i_hrespS2;
    wire   [1:0] i_hrespS3;
    wire   [1:0] i_hrespS4;

    wire   [3:0]        i_hmasterM0;
    wire   [1:0] i_hrespM0;
    wire   [3:0]        i_hmasterM1;
    wire   [1:0] i_hrespM1;
    wire   [3:0]        i_hmasterM2;
    wire   [1:0] i_hrespM2;
    wire   [3:0]        i_hmasterM3;
    wire   [1:0] i_hrespM3;
    wire   [3:0]        i_hmasterM4;
    wire   [1:0] i_hrespM4;

// -----------------------------------------------------------------------------
// Beginning of main code
// -----------------------------------------------------------------------------

    assign tie_hi   = 1'b1;
    assign tie_hi_4 = 4'b1111;
    assign tie_low  = 1'b0;


    assign HRESPS0  = i_hrespS0[0];

    assign HRESPS1  = i_hrespS1[0];

    assign HRESPS2  = i_hrespS2[0];

    assign HRESPS3  = i_hrespS3[0];

    assign HRESPS4  = i_hrespS4[0];

    assign i_hrespM0 = {tie_low, HRESPM0};
    assign i_hrespM1 = {tie_low, HRESPM1};
    assign i_hrespM2 = {tie_low, HRESPM2};
    assign i_hrespM3 = {tie_low, HRESPM3};
    assign i_hrespM4 = {tie_low, HRESPM4};

// BusMatrix instance
  L1AhbMtx uL1AhbMtx (
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),
    .REMAP      (REMAP),

    // Input port SI0 signals
    .HSELS0       (tie_hi),
    .HADDRS0      (HADDRS0),
    .HTRANSS0     (HTRANSS0),
    .HWRITES0     (HWRITES0),
    .HSIZES0      (HSIZES0),
    .HBURSTS0     (HBURSTS0),
    .HPROTS0      (HPROTS0),
    .HWDATAS0     (HWDATAS0),
    .HMASTLOCKS0  (HMASTLOCKS0),
    .HMASTERS0    (tie_hi_4),
    .HREADYS0     (HREADYS0),
    .HRDATAS0     (HRDATAS0),
    .HREADYOUTS0  (HREADYS0),
    .HRESPS0      (i_hrespS0),

    // Input port SI1 signals
    .HSELS1       (tie_hi),
    .HADDRS1      (HADDRS1),
    .HTRANSS1     (HTRANSS1),
    .HWRITES1     (HWRITES1),
    .HSIZES1      (HSIZES1),
    .HBURSTS1     (HBURSTS1),
    .HPROTS1      (HPROTS1),
    .HWDATAS1     (HWDATAS1),
    .HMASTLOCKS1  (HMASTLOCKS1),
    .HMASTERS1    (tie_hi_4),
    .HREADYS1     (HREADYS1),
    .HRDATAS1     (HRDATAS1),
    .HREADYOUTS1  (HREADYS1),
    .HRESPS1      (i_hrespS1),

    // Input port SI2 signals
    .HSELS2       (tie_hi),
    .HADDRS2      (HADDRS2),
    .HTRANSS2     (HTRANSS2),
    .HWRITES2     (HWRITES2),
    .HSIZES2      (HSIZES2),
    .HBURSTS2     (HBURSTS2),
    .HPROTS2      (HPROTS2),
    .HWDATAS2     (HWDATAS2),
    .HMASTLOCKS2  (HMASTLOCKS2),
    .HMASTERS2    (tie_hi_4),
    .HREADYS2     (HREADYS2),
    .HRDATAS2     (HRDATAS2),
    .HREADYOUTS2  (HREADYS2),
    .HRESPS2      (i_hrespS2),

    // Input port SI3 signals
    .HSELS3       (tie_hi),
    .HADDRS3      (HADDRS3),
    .HTRANSS3     (HTRANSS3),
    .HWRITES3     (HWRITES3),
    .HSIZES3      (HSIZES3),
    .HBURSTS3     (HBURSTS3),
    .HPROTS3      (HPROTS3),
    .HWDATAS3     (HWDATAS3),
    .HMASTLOCKS3  (HMASTLOCKS3),
    .HMASTERS3    (tie_hi_4),
    .HREADYS3     (HREADYS3),
    .HRDATAS3     (HRDATAS3),
    .HREADYOUTS3  (HREADYS3),
    .HRESPS3      (i_hrespS3),

    // Input port SI4 signals
    .HSELS4       (tie_hi),
    .HADDRS4      (HADDRS4),
    .HTRANSS4     (HTRANSS4),
    .HWRITES4     (HWRITES4),
    .HSIZES4      (HSIZES4),
    .HBURSTS4     (HBURSTS4),
    .HPROTS4      (HPROTS4),
    .HWDATAS4     (HWDATAS4),
    .HMASTLOCKS4  (HMASTLOCKS4),
    .HMASTERS4    (tie_hi_4),
    .HREADYS4     (HREADYS4),
    .HRDATAS4     (HRDATAS4),
    .HREADYOUTS4  (HREADYS4),
    .HRESPS4      (i_hrespS4),


    // Output port MI0 signals
    .HSELM0       (HSELM0),
    .HADDRM0      (HADDRM0),
    .HTRANSM0     (HTRANSM0),
    .HWRITEM0     (HWRITEM0),
    .HSIZEM0      (HSIZEM0),
    .HBURSTM0     (HBURSTM0),
    .HPROTM0      (HPROTM0),
    .HWDATAM0     (HWDATAM0),
    .HMASTERM0    (i_hmasterM0),
    .HMASTLOCKM0  (HMASTLOCKM0),
    .HREADYMUXM0  (HREADYMUXM0),
    .HRDATAM0     (HRDATAM0),
    .HREADYOUTM0  (HREADYOUTM0),
    .HRESPM0      (i_hrespM0),

    // Output port MI1 signals
    .HSELM1       (HSELM1),
    .HADDRM1      (HADDRM1),
    .HTRANSM1     (HTRANSM1),
    .HWRITEM1     (HWRITEM1),
    .HSIZEM1      (HSIZEM1),
    .HBURSTM1     (HBURSTM1),
    .HPROTM1      (HPROTM1),
    .HWDATAM1     (HWDATAM1),
    .HMASTERM1    (i_hmasterM1),
    .HMASTLOCKM1  (HMASTLOCKM1),
    .HREADYMUXM1  (HREADYMUXM1),
    .HRDATAM1     (HRDATAM1),
    .HREADYOUTM1  (HREADYOUTM1),
    .HRESPM1      (i_hrespM1),

    // Output port MI2 signals
    .HSELM2       (HSELM2),
    .HADDRM2      (HADDRM2),
    .HTRANSM2     (HTRANSM2),
    .HWRITEM2     (HWRITEM2),
    .HSIZEM2      (HSIZEM2),
    .HBURSTM2     (HBURSTM2),
    .HPROTM2      (HPROTM2),
    .HWDATAM2     (HWDATAM2),
    .HMASTERM2    (i_hmasterM2),
    .HMASTLOCKM2  (HMASTLOCKM2),
    .HREADYMUXM2  (HREADYMUXM2),
    .HRDATAM2     (HRDATAM2),
    .HREADYOUTM2  (HREADYOUTM2),
    .HRESPM2      (i_hrespM2),

    // Output port MI3 signals
    .HSELM3       (HSELM3),
    .HADDRM3      (HADDRM3),
    .HTRANSM3     (HTRANSM3),
    .HWRITEM3     (HWRITEM3),
    .HSIZEM3      (HSIZEM3),
    .HBURSTM3     (HBURSTM3),
    .HPROTM3      (HPROTM3),
    .HWDATAM3     (HWDATAM3),
    .HMASTERM3    (i_hmasterM3),
    .HMASTLOCKM3  (HMASTLOCKM3),
    .HREADYMUXM3  (HREADYMUXM3),
    .HRDATAM3     (HRDATAM3),
    .HREADYOUTM3  (HREADYOUTM3),
    .HRESPM3      (i_hrespM3),

    // Output port MI4 signals
    .HSELM4       (HSELM4),
    .HADDRM4      (HADDRM4),
    .HTRANSM4     (HTRANSM4),
    .HWRITEM4     (HWRITEM4),
    .HSIZEM4      (HSIZEM4),
    .HBURSTM4     (HBURSTM4),
    .HPROTM4      (HPROTM4),
    .HWDATAM4     (HWDATAM4),
    .HMASTERM4    (i_hmasterM4),
    .HMASTLOCKM4  (HMASTLOCKM4),
    .HREADYMUXM4  (HREADYMUXM4),
    .HRDATAM4     (HRDATAM4),
    .HREADYOUTM4  (HREADYOUTM4),
    .HRESPM4      (i_hrespM4),


    // Scan test dummy signals; not connected until scan insertion
    .SCANENABLE            (SCANENABLE),
    .SCANINHCLK            (SCANINHCLK),
    .SCANOUTHCLK           (SCANOUTHCLK)
  );


endmodule
