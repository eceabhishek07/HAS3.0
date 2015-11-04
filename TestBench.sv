//This document contains the Test Bench to verify Single Core L1 MESI Cache in a Multicore environment. Any References to section numbers in the comments have to be looked up in the verification plan submitted.


`timescale 1ps/1ps

//Define Address Size
`define ADDRESSSIZE 32

//Define the stimulus to the L1 Cache at Top level. This class contains all inputs to the DUT at Top level
class singleCacheStimulus;
  
  //PrRd signal
  rand bit PrRd;
 
  //PrWr signal
  rand bit PrWr;

  //Address 
  rand reg [`ADDRESSSIZE-1:0] Address;

  //Data Bus
  rand reg [`ADDRESSSIZE-1:0] Data_Bus;  

  //Shared
  rand bit Shared;
  
  //Com_Bus_Gnt_proc
  rand bit Com_Bus_Gnt_proc;

  //Com_Bus_Gnt_snoop
  rand bit Com_Bus_Gnt_snoop;

  //All_Invalidation_done
  rand bit All_Invalidation_done;

  //Address_Com
  rand reg [`ADDRESSSIZE-1:0] Address_Com;
  
  //Data_Bus_Com
  rand reg [`ADDRESSSIZE-1:0] Data_Bus_Com;

  //BusRd
  rand bit BusRd;

  //BusRdX
  rand bit BusRdX;

  //Invalidate
  rand bit Invalidate;
  
  //Data_in_Bus
  rand bit Data_in_Bus;
  
  //Mem_write_done
  rand bit Mem_write_done;

  function new();
    //Initialize the fields in this constructor
    this.PrRd             = 0;
    this.PrWr             = 0;
    this.Com_Bus_Gnt_proc = 0;
    this.Data_Bus         = 32'hz;
    this.Address_Com      = 32'hz;
    this.Data_Bus_Com     = 32'hz;
    this.Data_in_Bus      = 32'hz;
     
  endfunction

endclass : singleCacheStimulus

//Interface containing interfacing signals between (Proc and Cache), (Cache and Memory), (Memory and Arbiter), (Cache and Bus). To be used for Both DL and IL. 'Wr' related signals shall be ignored.
interface procMemCacheBusArbIntf;
  
  logic 			clk;
  //Interface between Proc and Cache
  logic 			PrRd; 
  logic 			PrWr;
  logic [`ADDRESSSIZE-1 : 0]	Address;
  logic			        CPU_stall; 
  //Interface between Proc and Arbiter                     
  logic 			Com_Bus_Gnt_proc;
  logic 			Com_Bus_Gnt_snoop;
  //Interface between Cache and Bus
  logic 			All_Invalidation_done;
  logic 			Shared;
  logic 			BusRd;
  logic 			BusRdX;
  logic 			Invalidate;
  logic 		        Invalidation_done;
  logic 			Shared_local;
  //Interface between Cache/Bus and Lower Level Memory
  logic 		        Mem_wr;
  logic 		        Mem_oprn_abort;
  logic 		        Mem_write_done;
  logic			        Data_in_Bus;
  logic [`ADDRESSSIZE-1 : 0]	Address_Com;
  logic [`ADDRESSSIZE-1 : 0]	Data_Bus_Com; 
  logic [`ADDRESSSIZE-1 : 0]	Data_Bus;
  logic 			Com_Bus_Req_proc;
  logic 			Com_Bus_Req_snoop;
  //Interface between Lower Level Memory and Arbiter
  logic                         Mem_req_snoop;
  logic                         Mem_gnt_snoop;
endinterface

//Define a base class that contains repeatedly used waiting tasks and fields.
class baseTestClass;
  rand reg[`ADDRESSSIZE - 1 : 0] Address;
   
   constraint c_Address { Address inside {32'h00000000,32'hffffffff};}

   //Delay until Cache Wrapper responds to any stimulus either from Proc or Arbiter or Memory. Measured in cycles of clk
   rand int Max_Resp_Delay;

   constraint c_max_delay {Max_Resp_Delay inside {2,6};}
   int delay;
   
   
   //Task to wait and check for Com_Bus_Req_proc and CPU_Stall to be asserted
   virtual task check_ComBusReqproc_CPUStall_assert(virtual interface procMemCacheBusArbIntf sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Com_Bus_Req_proc && sintf.CPU_stall);
        end
      join_any
      disable fork;
    //Check if Com_Bus_Req_proc is asserted  
    assert(sintf.Com_Bus_Req_proc) $display("SUCCESS: sChecker: Com_Bus_Req_Proc is asserted within timeout after PrRd is asserted");
    else $fatal(1,"TEST:  Checker: Com_Bus_Req_Proc is not asserted after PrRd", $time);
   endtask : check_ComBusReqproc_CPUStall_assert
 
  //Task to wait for Com_Bus_Req_proc and CPU_Stall to be deasserted
   virtual task check_ComBusReqproc_CPUStall_deaassert(virtual interface procMemCacheBusArbIntf sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(!sintf.Com_Bus_Req_proc && !sintf.CPU_stall);
        end
      join_any
      disable fork;
      assert(!sintf.CPU_stall && !sintf.Com_Bus_Req_proc) $display("SUCCESS: CPU_stall and Com_Bus_Req_proc are deasserted");
      else $fatal(1,"TEST: Checker:Either or both of CPU_stall and Com_Bus_Req_proc are not deasserted", $time);
   endtask : check_ComBusReqproc_CPUStall_deaassert


   //Task to wait for BusRd is raised.
   virtual task check_BusRd_assert(virtual interface procMemCacheBusArbIntf sintf);
    delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
      end
      begin 
         wait(sintf.BusRd);
      end
    join_any
    disable fork;
   endtask : check_BusRd_assert
   
  //Task to wait till address placed by cache on Address_Com bus
  virtual task check_Address_Com_load(virtual interface procMemCacheBusArbIntf sintf);
    delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
      end
      begin 
         wait(sintf.Address == sintf.Address_Com);
      end
    join_any
    disable fork;
    
    assert(sintf.Address == sintf.Address_Com) 
    else $fatal(" Checker: Address is either not placed on Address_Com bus or wrong address is placed");
  endtask : check_Address_Com_load

  //Task to wait till CPU_stall is de-asserted
  task check_CPU_stall_deassert(virtual interface procMemCacheBusArbIntf sintf);
     delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(!sintf.CPU_stall);
      end
    join_any
    disable fork;
    assert(!sintf.CPU_stall) 
    else $fatal(" Checker: CPU stall not de-asserted ");
  endtask : check_CPU_stall_deassert
  
  //Task to wait till BusRdX is asserted
  task check_BusRdX_assert(virtual interface procMemCacheBusArbIntf sintf);
     delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(sintf.BusRdX);
      end
    join_any
    disable fork;
    assert(sintf.BusRdX); 
    else $fatal(" Checker: BusRdX  not asserted");

  
  endtask : check_BusRdX_assert
endclass

// A Simple Directed Testcase for Scenario 2,3,5,7 of Section 4.8.1: Read Miss with no copy available in other Caches. Verified at the top level
class topReadMiss extends baseTestClass;
   
//   Creates the simple Read stimulus and drives it to the DUT and checks for the behavior. Take the single Top Level Cache interface as input.
   task testSimpleReadMiss(virtual interface procMemCacheBusArbIntf sintf);
    begin
     
     sintf.PrRd = 1;
     sintf.PrWr = 0;
     sintf.Address = Address; 
      
    // Check for behavior
    //Com_Bus_Req_proc and CPU_stall must be made high
     check_ComBusReqproc_CPUStall_assert(sintf); 
    

  
    //Wait until arbiter grants access
    wait(sintf.Com_Bus_Gnt_proc == 1);
    
    //Check if the Cache raises BusRd
    check_BusRd_assert(sintf);
    
    assert(sintf.BusRd)
    else $fatal(1,"TEST: testSimpleReadMiss Checker: BusRd is not asserted after Com_Bus_Gnt_proc asserted ", $time);

    //Wait until cache places Address in Address_Com bus
    check_Address_Com_load(sintf);

    //Main Memory requests for Bus Access. Wait for Bus Access Grant by the arbiter
    sintf.Mem_req_snoop = 1;
    wait(sintf.Mem_gnt_snoop == 1);
 
    //Main Memory puts data on the Data_Bus_Com and raises Data_in_Bus
    sintf.Data_Bus_Com = 32'hBABABABA;
    sintf.Data_in_Bus  = 1;
    
    //Check if CPU_stall is de-asserted on asserting Data_in_Bus
    check_CPU_stall_deassert(sintf); 
    
    end
   endtask : testSimpleReadMiss
endclass : topReadMiss


// A Simple Directed Testcase for Scenario 1 of Section 4.8.1 :Read Hit. Verified at the top level
class topReadHit extends baseTestClass;

   task testSimpleReadHit(virtual interface procMemCacheBusArbIntf sintf);
    begin
      
      //Do a Read Hit
      sintf.Address = Address;
      sintf.PrRd    = 1;
      sintf.PrWr    = 0;

      //Check if Data is placed on Data_Bus
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Data_Bus != 32'hz);
        end
      join_any
      disable fork;
      
      assert(sintf.Data_Bus != 32'hz) $display("SUCCESS: testSimpleReadHit Checker: Data_Bus is loaded with Cache data within timeout after PrRd is asserted");
      else $fatal(1,"TEST:  testSimpleReadHit Checker: Data_Bus is loaded with Cache data within timeout after PrRd is asserted", $time);
      
      //Check if CPU_stall and Com_Bus_Req_proc is deasserted
      check_ComBusReqproc_CPUStall_deaassert(sintf);
      
       
    end
   endtask : testSimpleReadHit
   

endclass : topReadHit


// A Simple Directed Testcase for Scenario 4,6,8 of Section 4.8.1. Read Miss with replacement required for a Modified block. Tests until the dirty block is written back to memory.

class topReadMissReplaceModified extends baseTestClass;
   
     rand reg [`ADDRESSSIZE - 1 : 0] Address;
     
     constraint c_Address { Address inside {32'h00000000,32'hffffffff};}
   
     //Delay until Cache Wrapper responds to any stimulus either from Proc or Arbiter or Memory. Measured in cycles of clk
     rand int Max_Resp_Delay;
     constraint c_max_delay {Max_Resp_Delay inside {2,6};}
     int delay;
     task testReadMissReplaceModified(virtual interface procMemCacheBusArbIntf sintf);
          
      sintf.Address = Address;
      sintf.PrRd    = 1;
      sintf.PrWr    = 0;
      
      // Check for behavior
      //Com_Bus_Req_proc and CPU_stall must be made high
      check_ComBusReqproc_CPUStall_assert(sintf);

      //Since free block is not available, replacement of the modified block has to be carried out. Wait for bus access grant from arbiter
      wait(sintf.Com_Bus_Gnt_proc);
      //Wait till Address com bus is loaded with Address of the Block to be replaced
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Address[31:2] == sintf.Address_Com[31:2]);
        end
      join_any
      disable fork;
      
      assert(sintf.Address[31:2] == sintf.Address_Com[31:2]) $display("SUCCESS: Address_Com is loaded with correct address");
      else $fatal(1,"TEST:  testReadMissReplaceModified Checker: Address_Com is loaded with wrong address or is not loaded within timeout", $time);
      
      //Wait till Data com bus is loaded with Valid Data
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Data_Bus_Com != 32'hz);
        end
      join_any
      disable fork;
      
      assert(sintf.Data_Bus_Com != 32'hz) $display("SUCCESS: Data_Bus_Com is loaded with Valid Data");
      else $fatal(1,"TEST:  testReadMissReplaceModified Checker: Data_Bus_Com is not loaded with valid data within timeout", $time);

      
      //Wait till Mem_wr signal is made high
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Mem_wr);
        end
      join_any
      disable fork;
      
      assert(sintf.Mem_wr) $display("SUCCESS: Mem_wr is made high");
      else $fatal(1,"TEST:  testReadMissReplaceModified Checker:Mem_wr is not made high within timeout", $time);
      //Memory asserts Memory Wr Done
      sintf.Mem_write_done = 1;
     //free block is now available. Cache will do free block operations for read miss.             
     endtask : testReadMissReplaceModified

endclass : topReadMissReplaceModified


//A simple directed test for scenarios 10,11,13,15 in section 4.8.1. This will verify the basic write Miss operation with free block available
class topWriteMiss extends baseTestClass;
   
    //data to be written
   rand int wrData;
   constraint c_wrData  {wrData inside {32'h00000000,32'hffffffff};}
   task testWriteMiss(virtual interface procMemCacheBusArbIntf sintf);
        begin
          sintf.PrWr      = 1; 
          sintf.PrRd      = 0;
          sintf.Address   = Address; 
          sintf.Data_Bus  = wrData;

          //wait for CPU_stall and Com_Bus_Gnt_proc to be made high
          check_ComBusReqproc_CPUStall_assert(sintf);

          wait(Com_Bus_Gnt_proc);

          check_BusRdX_assert(sintf);

          check_Address_Com_load(sintf);

          //Lower Memory or Other Cache Loads Data on the Bus
          sintf.Data_in_Bus  = 1;

          sintf.Data_Bus_Com = 32'hDEADBEEF;
          
          check_ComBusReqproc_CPUStall_deaassert(sintf);
        end 
   endtask : testWriteMiss

endclass

//A simple directed test for scenarios 12,14,16 in section 4.8.1. This will verify write Miss Operation with no free block available. Tests until block is written back into the Cache.
class topWriteMissModifiedReplacement extends baseTestClass;
   //data to be written
   rand int wrData;
   constraint c_wrData  {wrData inside {32'h00000000,32'hffffffff};}
   task testWriteMissReplaceModified(virtual interface procMemCacheBusArbIntf sintf);
        begin
          sintf.PrWr      = 1; 
          sintf.PrRd      = 0;
          sintf.Address   = Address; 
          sintf.Data_Bus  = wrData;

          // Check for behavior
      //Com_Bus_Req_proc and CPU_stall must be made high
      check_ComBusReqproc_CPUStall_assert(sintf);

      //Since free block is not available, replacement of the modified block has to be carried out. Wait for bus access grant from arbiter
      wait(sintf.Com_Bus_Gnt_proc);
      //Wait till Address com bus is loaded with Address of the Block to be replaced
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Address[31:2] == sintf.Address_Com[31:2]);
        end
      join_any
      disable fork;
      
      assert(sintf.Address[31:2] == sintf.Address_Com[31:2]) $display("SUCCESS: Address_Com is loaded with correct address");
      else $fatal(1,"TEST:  testWriteMissReplaceModified Checker: Address_Com is loaded with wrong address or is not loaded within timeout", $time);
      
      //Wait till Data com bus is loaded with Valid Data
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Data_Bus_Com != 32'hz);
        end
      join_any
      disable fork;
      
      assert(sintf.Data_Bus_Com != 32'hz) $display("SUCCESS: Data_Bus_Com is loaded with Valid Data");
      else $fatal(1,"TEST:  testWriteMissReplaceModified Checker: Data_Bus_Com is not loaded with valid data within timeout", $time);

      
      //Wait till Mem_wr signal is made high
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Mem_wr);
        end
      join_any
      disable fork;
      
      assert(sintf.Mem_wr) $display("SUCCESS: Mem_wr is made high");
      else $fatal(1,"TEST:  testWriteMissReplaceModified Checker:Mem_wr is not made high within timeout", $time);
    end 
   endtask : testWriteMissReplaceModified
endclass
module tb();
 reg Com_Bus_Req_proc;
 reg CPU_stall;

 initial 
  scintf.clk = 0;
 always
   #100  scintf.clk = ~scintf.clk;

 procMemCacheBusArbIntf scintf();
 assign scintf.Com_Bus_Req_proc = Com_Bus_Req_proc;
 assign scintf.CPU_stall = CPU_stall;
 virtual interface procMemCacheBusArbIntf local_sci;
 topReadMiss srm;
 initial begin
  srm = new();
  void'(srm.randomize());
  local_sci = scintf;
  srm.testSimpleReadMiss(local_sci);
 end
//Model DUT Behavior Just for testing the test cases
 initial begin
   Com_Bus_Req_proc = 0;
   CPU_stall = 0;
   //#100 Com_Bus_Req_proc = 1;
   //CPU_stall = 1;
 end
endmodule




