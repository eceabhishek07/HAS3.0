//This document contains the Test Bench to verify Single Core L1 MESI Cache in a Multicore environment. Any References to section numbers in the comments have to be looked up in the verification plan submitted.
//NOTE: All the signals to the DUT/Arbiter are accessed via an sv interface. When the DUT and Arbiter Designs are made available, 
//they shall be connected to the interface.
//In order to test the depth of functionality, a top level test is
//instantiated inside another test and then low level verification is done in
//this test within the top level test

`timescale 1ps/1ps
//Include defines.sv file containing all Macros
//`include "defines.sv"
`include "interfaces.sv"

//enum type for MESI States
typedef enum bit[1:0] {INVALID, SHARED, EXCLUSIVE, MODIFIED} mesiStateType;

//Define a base class that contains repeatedly used waiting tasks and fields.
class baseTestClass;
  rand reg[`ADDRESSSIZE - 1 : 0] Address;
   
   constraint c_Address { Address inside {[32'h00000000:32'hffffffff]};}

   //Delay until Cache Wrapper responds to any stimulus either from Proc or Arbiter or Memory. Measured in cycles of clk
   rand int Max_Resp_Delay;

   constraint c_max_delay {Max_Resp_Delay inside {[2:6]};}
   int delay;
   
   
   //Task to wait and check for Com_Bus_Req_proc_0 and CPU_Stall to be asserted
   virtual task check_ComBusReqproc_CPUStall_assert(virtual interface globalInterface sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Com_Bus_Req_proc_0 && sintf.CPU_stall);
        end
      join_any
      disable fork;
    //Check if Com_Bus_Req_proc_0 is asserted  
    assert(sintf.Com_Bus_Req_proc_0) $display("SUCCESS: %m Checker: Com_Bus_Req_Proc is asserted within timeout after PrRd is asserted");
    else $warning(1,"%m TEST:  Checker: Com_Bus_Req_Proc is not asserted after PrRd", $time);
    return;
   endtask : check_ComBusReqproc_CPUStall_assert
   
   //Task to wait and check for Com_Bus_Req_snoop_0 to be asserted
   virtual task check_ComBusReqSnoop_assert(virtual interface globalInterface sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(sintf.Com_Bus_Req_snoop_0);
        end
      join_any
      disable fork;
    //Check if Com_Bus_Req_ is asserted  
    assert(sintf.Com_Bus_Req_snoop_0) $display("SUCCESS: sChecker: Com_Bus_Req_snoop_0 is asserted within timeout after BusRd is asserted");
    else $warning(1,"TEST:  Checker: Com_Bus_Req_snoop_0 is not asserted after BusRd", $time);
   endtask : check_ComBusReqSnoop_assert
   
   
   //Task to wait and check for Com_Bus_Req_snoop_0 to be deasserted
   virtual task check_ComBusReqSnoop_deassert(virtual interface globalInterface sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(!sintf.Com_Bus_Req_snoop_0);
        end
      join_any
      disable fork;
    //Check if Com_Bus_Req_ is asserted  
    assert(!sintf.Com_Bus_Req_snoop_0) $display("SUCCESS: sChecker: Com_Bus_Req_snoop_0 is deasserted within timeout after BusRd is asserted");
    else $warning(1,"TEST:  Checker: Com_Bus_Req_snoop_0 is not deasserted after BusRd", $time);
   endtask : check_ComBusReqSnoop_deassert
 
   //Task to wait for Com_Bus_Req_proc_0 and CPU_Stall to be deasserted
   virtual task check_ComBusReqproc_CPUStall_deaassert(virtual interface globalInterface sintf);
      delay = 0;
      fork
        begin 
         while(delay <= Max_Resp_Delay) begin
           @(posedge sintf.clk);
           delay += 1; 
         end 
        end
        begin 
           wait(!sintf.Com_Bus_Req_proc_0 && !sintf.CPU_stall);
        end
      join_any
      disable fork;
      assert(!sintf.CPU_stall && !sintf.Com_Bus_Req_proc_0) $display("SUCCESS: CPU_stall and Com_Bus_Req_proc_0 are deasserted");
      else $warning(1,"TEST: Checker:Either or both of CPU_stall and Com_Bus_Req_proc_0 are not deasserted", $time);
   endtask : check_ComBusReqproc_CPUStall_deaassert
 
    //Task to wait for Com Bus Gnt Proc to be asserted
    virtual task check_ComBusGntproc_assert(virtual interface globalInterface sintf);
    delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
      end
      begin 
         wait(sintf.Com_Bus_Gnt_proc_0);
      end
    join_any
    disable fork;
   endtask : check_ComBusGntproc_assert
   //Task to wait for BusRd is raised.
   virtual task check_BusRd_assert(virtual interface globalInterface sintf);
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
  virtual task check_Address_Com_load(virtual interface globalInterface sintf);
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
    
    assert(sintf.Address[31:2] == sintf.Address_Com[31:2] &&
           sintf.Address[1:0] == sintf.Address_Com[1:0]) 
    else $warning(1," Checker: Address is either not placed on Address_Com bus or wrong address is placed",$time);
  endtask : check_Address_Com_load

  //Task to wait till CPU_stall is de-asserted
virtual  task check_CPU_stall_deassert(virtual interface globalInterface sintf);
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
    else $warning(1," Checker: CPU stall not de-asserted ",$time);
  endtask : check_CPU_stall_deassert
  
  //Task to wait till BusRdX is asserted
 virtual task check_BusRdX_assert(virtual interface globalInterface sintf);
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
    assert(sintf.BusRdX)
    else $warning(1," Checker: BusRdX  not asserted",$time);
  endtask : check_BusRdX_assert
  
  
  //Task to wait till BusRdX is asserted
 virtual  task check_MemOprnAbrt_assert(virtual interface globalInterface sintf);
     delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(sintf.Mem_oprn_abort);
      end
    join_any
    disable fork;
    assert(sintf.Mem_oprn_abort)
    else $warning(1," Checker:  Mem_oprn_abort not asserted",$time);
  endtask : check_MemOprnAbrt_assert
 
// Check for Shared to be asserted
virtual task check_Shared_assert(virtual interface globalInterface sintf);
   delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(sintf.Shared);
      end
    join_any
    disable fork;
    assert(sintf.Shared)
    else $warning(1," Checker: Shared not asserted",$time);
endtask : check_Shared_assert

// Check for Invalidate to be asserted
virtual task check_Invalidate_assert(virtual interface globalInterface sintf);
   delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(sintf.Invalidate);
      end
    join_any
    disable fork;
    assert(sintf.Invalidate)
    else $warning(1," Checker:  Invalidate not asserted",$time);
endtask : check_Invalidate_assert

// Check for Mem_wr to be asserted
virtual task check_MemWr_assert(virtual interface globalInterface sintf);
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
    assert(sintf.Mem_wr)
    else $warning(1," Checker:  Invalidate not asserted",$time);
endtask : check_MemWr_assert

// Check for Data in Bus to be asserted
virtual task check_DataInBus_assert(virtual interface globalInterface sintf);
   delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(sintf.Data_in_Bus);
      end
    join_any
    disable fork;
    assert(sintf.Invalidate)
    else $warning(1," Checker:  Data in Bus not asserted",$time);
endtask : check_DataInBus_assert

//Task to wait till Single Bit is asserted! Alas Not working...Must find a new strategy to make this work. For now it shall  be here!
 virtual task check_singleBit_assert(input sbit, virtual interface
globalInterface sintf  );
     delay = 0;
    fork
      begin
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         $display("delay = %d, Max_Resp_Delay = %d, BIT = %d", delay, Max_Resp_Delay, sbit);
         delay += 1; 
       end 
       end
      begin 
         wait(sbit);
      end
    join_any
    disable fork;
    assert(sbit)
    else $warning(1," %m : Checker:  Required Bit Field not asserted",$time);
  endtask : check_singleBit_assert
  
  //Task to wait till Bus is valid..same fate as above
  virtual task check_bus_valid(input logic [31:0] BUS, virtual interface globalInterface sintf );
    delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge sintf.clk);
         delay += 1; 
       end 
       end
      begin 
         wait(BUS != 32'hz);
      end
    join_any
    disable fork;
    assert(BUS != 32'hz)
    else $warning(1," %m: Checker:  The BUS contains invalid value",$time);
  endtask : check_bus_valid

 //Task to wait till DataBusCom is valid.
  virtual task check_DataBusCom_valid(virtual interface globalInterface sintf );
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
    assert(sintf.Data_Bus_Com != 32'hz)
    else $warning(1," %m: Checker:  The BUS contains invalid value",$time);
  endtask : check_DataBusCom_valid



  //Task to check actual and expected next MESI states
  virtual task check_MESI_fsm(input mesiStateType actualMesiState, input
mesiStateType expectedMesiState, input logic clk);
    delay = 0;
    fork
      begin 
       while(delay <= Max_Resp_Delay) begin
         @(posedge clk);
         delay += 1; 
       end 
       end
      begin 
         wait(actualMesiState == expectedMesiState);
      end
    join_any
    disable fork;
    assert(actualMesiState == expectedMesiState)
    else $warning(1," Next MESI State does not match with expected next MESI state",$time);
  endtask : check_MESI_fsm

  //Task to check if Data Bus is set with valid data
  virtual task check_DataBus_valid(virtual interface globalInterface sintf );
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
    assert(sintf.Data_Bus != 32'hz)
    else $warning(1," %m: Checker:  The BUS contains invalid value",$time);
  endtask : check_DataBus_valid
 
  //Task to reset signals after each operation
  virtual task reset_DUT_inputs(virtual interface globalInterface dif);

        dif.Address_Com_reg 			<= 32'hZ;
	dif.Data_Bus_Com_reg 			<= 32'hZ;
	dif.Data_in_Bus_reg	 		<= 32'hZ;	
	dif.Data_Bus_reg                	    = 32'hZ;
        dif.PrRd                            = 0;
        dif.PrWr                            = 0;
        dif.Address                         = 32'hz;
        dif.BusRd_reg                       = 1'bz;
        dif.BusRdX_reg                      = 1'bz;
 
  endtask : reset_DUT_inputs

 //task to determine LRU var state expected.
  virtual function determine_LRU_var_exp(input logic [1:0] line_no, ref logic [2:0] next_state);
    begin
       case(line_no)
          2'b00: next_state[2:1] = 2'b11;
          2'b01: next_state[2:1] = 2'b10;
          2'b10: begin next_state[2:2] =  1'b0; next_state[0:0] = 1'b1; end
          2'b11: begin next_state[2:2] =  1'b0; next_state[0:0] = 1'b0; end
       endcase
    end
  endfunction

 //task to determine LRU line to replace
  virtual function logic [1:0] determine_LineToBeReplaced_LRU(input logic[2:0] state);
    begin
      if(!state[2:2]) begin
          if(!state[1:1])
            return 2'b00;
          else return 2'b01; 
      end 
      else begin
          if(!state[0:0]) return 2'b10;
          else return 2'b11;
      end
    end
  endfunction : determine_LineToBeReplaced_LRU
endclass


//Test cases to verify top level functionality specified in section 4.8.1.
// A Simple Directed Testcase for Scenario 2,3,5,7 of Section 4.8.1: Read Miss with no copy available in other Caches. Verified at the top level
class topReadMiss extends baseTestClass;
   
//   Creates the simple Read stimulus and drives it to the DUT and checks for the behavior. Take the single Top Level Cache interface as input.
   task testSimpleReadMiss(virtual interface globalInterface sintf);
    begin
     
     sintf.PrRd = 1;
     sintf.PrWr = 0;
     sintf.Address = Address; 
      
    // Check for behavior
    //Com_Bus_Req_proc_0 and CPU_stall must be made high
     check_ComBusReqproc_CPUStall_assert(sintf); 
    $display("Waiting for Com Bus Gnt Proc to be asserted...."); 
    //Wait until arbiter grants access
     check_ComBusGntproc_assert(sintf);
     //check_ComBusGntproc_assert(sintf);
    
    //Check if the Cache raises BusRd
    check_BusRd_assert(sintf);
    
    assert(sintf.BusRd)
    else $warning(1,"TEST: testSimpleReadMiss Checker: BusRd is not asserted after Com_Bus_Gnt_proc asserted ", $time);

    //Wait until cache places Address in Address_Com bus
    check_Address_Com_load(sintf);

    //Main Memory requests for Bus Access. Wait for Bus Access Grant by the arbiter
    sintf.Mem_snoop_req = 1;
    wait(sintf.Mem_snoop_gnt == 1);
 
    //Main Memory puts data on the Data_Bus_Com and raises Data_in_Bus
    sintf.Data_Bus_Com_reg = 32'hBABABABA;
    sintf.Data_in_Bus_reg = 1;
    
    //Check if Data_Bus is valid with the data
    check_DataBus_valid(sintf); 
    //Check if CPU_stall is de-asserted on asserting Data_in_Bus
    check_CPU_stall_deassert(sintf); 
    end
   endtask : testSimpleReadMiss
endclass : topReadMiss


// A Simple Directed Testcase for Scenario 1 of Section 4.8.1 :Read Hit. Verified at the top level
class topReadHit extends baseTestClass;

   task testSimpleReadHit(virtual interface globalInterface sintf);
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
      else $warning(1,"TEST:  testSimpleReadHit Checker: Data_Bus is not loaded with Cache data within timeout after PrRd is asserted", $time);
      
      //Check if CPU_stall and Com_Bus_Req_proc_0 is deasserted
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
     task testReadMissReplaceModified(virtual interface globalInterface sintf);
          
      sintf.Address = Address;
      sintf.PrRd    = 1;
      sintf.PrWr    = 0;
      
      // Check for behavior
      //Com_Bus_Req_proc_0 and CPU_stall must be made high
      check_ComBusReqproc_CPUStall_assert(sintf);

      //Since free block is not available, replacement of the modified block has to be carried out. Wait for bus access grant from arbiter
      wait(sintf.Com_Bus_Gnt_proc_0);
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
           wait(Address[31:2] == sintf.Address_Com[31:2]);
        end
      join_any
      disable fork;
      
      assert(Address[31:2] == sintf.Address_Com[31:2]) $display("SUCCESS: Address_Com is loaded with correct address");
      else $warning(1,"TEST:  testReadMissReplaceModified Checker: Address_Com is loaded with wrong address or is not loaded within timeout", $time);
      
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
      else $warning(1,"TEST:  testReadMissReplaceModified Checker: Data_Bus_Com is not loaded with valid data within timeout", $time);

      
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
      else $warning(1,"TEST:  testReadMissReplaceModified Checker:Mem_wr is not made high within timeout", $time);
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
   task testWriteMiss(virtual interface globalInterface sintf);
        begin
          sintf.PrWr      = 1; 
          sintf.PrRd      = 0;
          sintf.Address   = Address; 
          sintf.Data_Bus_reg  = wrData;

          //wait for CPU_stall and Com_Bus_Gnt_proc to be made high
          check_ComBusReqproc_CPUStall_assert(sintf);

          check_ComBusGntproc_assert(sintf);

          check_BusRdX_assert(sintf);

          check_Address_Com_load(sintf);

          //Lower Memory or Other Cache Loads Data on the Bus
          sintf.Data_in_Bus_reg = 1;

          sintf.Data_Bus_Com_reg = 32'hCAFECAFE;
          
          check_ComBusReqproc_CPUStall_deaassert(sintf);
        end 
   endtask : testWriteMiss

endclass: topWriteMiss

//A simple directed test for scenarios 12,14,16 in section 4.8.1. This will verify write Miss Operation with no free block available. Tests until block is written back into the Cache.
class topWriteMissModifiedReplacement extends baseTestClass;
   //data to be written
   rand int wrData;
   constraint c_wrData  {wrData inside {32'h00000000,32'hffffffff};}
   task testWriteMissReplaceModified(virtual interface globalInterface sintf);
        begin
          sintf.PrWr      = 1; 
          sintf.PrRd      = 0;
          sintf.Address   = Address; 
          sintf.Data_Bus_reg  = wrData;

          // Check for behavior
      //Com_Bus_Req_proc_0 and CPU_stall must be made high
      check_ComBusReqproc_CPUStall_assert(sintf);

      //Since free block is not available, replacement of the modified block has to be carried out. Wait for bus access grant from arbiter
      wait(sintf.Com_Bus_Gnt_proc_0);
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
      else $warning(1,"TEST:  testWriteMissReplaceModified Checker: Address_Com is loaded with wrong address or is not loaded within timeout", $time);
      
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
      else $warning(1,"TEST:  testWriteMissReplaceModified Checker: Data_Bus_Com is not loaded with valid data within timeout", $time);

      
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
      else $warning(1,"TEST:  testWriteMissReplaceModified Checker:Mem_wr is not made high within timeout", $time);
    end 
   endtask : testWriteMissReplaceModified
endclass : topWriteMissModifiedReplacement


// A Simple Directed Testcase for Scenario 9 of Section 4.8.1 :Write Hit. Verified at the top level
class topWriteHit extends baseTestClass;
    //the second argument is the MESI state of the block that is hit. Use the following : 0 for shared state, 1 for exclusive state, 2 for modified state
	task testSimpleWriteHit(virtual interface globalInterface sintf, input logic [1:0] MESI_state);
		begin
      
			//Do a Write
			sintf.Address = Address;
			sintf.PrRd    = 0;
			sintf.PrWr    = 1;
			sintf.Data_Bus_reg = 32'hFEEBFEEB;
            if(MESI_state == 0 || MESI_state == 1) begin
               check_Invalidate_assert(sintf);
            end
            			
      
		//Check if CPU_stall and Com_Bus_Req_proc_0 is deasserted
		check_ComBusReqproc_CPUStall_deaassert(sintf);
      
       
	end
endtask : testSimpleWriteHit
   

endclass : topWriteHit

//Simple Directed test to verify scenario 20,21,22 in section 4.8.1 in which DUT Cache snoops a BusRd  while it contains
//the addressed block in shared/Modified/Exclusive state
class topBusRdSnoop extends baseTestClass;
    //use MESI_state as follows: 0 for Shared, 1 for Exclusive, 2 for Modified.
	task testBusRdSnoop(virtual interface globalInterface sintf,input logic [1:0] MESI_state );
	 begin
	 //Other Cache raises Bus Rd signal
	 sintf.BusRd_reg = 1;
	 
	 //Check if DUT Cache Requests for Snoop Access
	 check_ComBusReqSnoop_assert(sintf);
	 //if data is already in bus, then check if Bus Snoop request is deasserted
	 if(sintf.Data_in_Bus) begin
	   check_ComBusReqSnoop_deassert(sintf);
	 end else begin
	       
	     //wait for grant
	     wait(sintf.Com_Bus_Gnt_snoop_0);
	 	//The Cache should raise mem operation abort
	 	check_MemOprnAbrt_assert(sintf);
	 	//block is in shared state
	 	if(MESI_state == 0) begin
	 	  //Check if shared signal is made high
	 	  check_Shared_assert(sintf);
	 	  //Check if Data bus com is loaded with data
	 	  check_DataBusCom_valid(sintf);
	 	  //Check if Data in Bus is made high
	 	  check_DataInBus_assert(sintf);
	 	  //Check if com bus req snoop is deasserted
	 	  check_ComBusReqSnoop_deassert(sintf);
	 	end
	 	else if(MESI_state == 1) begin //in Exclusive state
                  //Check if shared signal is made high
	 	  check_Shared_assert(sintf);
	 	  //Check if Data bus com is loaded with data
	 	  check_DataBusCom_valid(sintf);
	 	  //Check if Data in Bus is made high
	 	  check_DataInBus_assert(sintf);
	 	  //Check if com bus req snoop is deasserted
	 	  check_ComBusReqSnoop_deassert(sintf);
	 	end 
	 	else if(MESI_state == 2) begin //in Modified state
	 	  //Check if Data bus com is loaded with data
	 	  check_DataBusCom_valid(sintf);
	 	  //Check if mem wr signal is asserted
	 	  check_MemWr_assert(sintf);
	 	  //Raise Mem Wr Done
	 	  sintf.Mem_write_done = 1;
	 	  //Check if shared signal is made high
	 	  check_Shared_assert(sintf);
	 	  //Check if Data in Bus made high
	 	  check_DataInBus_assert(sintf);
	 	  //Check if com bus req snoop is deasserted
	 	  check_ComBusReqSnoop_deassert(sintf);
	 	end					
	  end					
	 end
	endtask
endclass : topBusRdSnoop

//Simple Directed test to verify scenario 23,24,25 in section 4.8.1 in which DUT Cache snoops a BusRdX  while it contains
//the addressed block in shared/Modified/Exclusive state
class topBusRdXSnoop extends baseTestClass;
	//use MESI_state as follows: 0 for Shared, 1 for Exclusive, 2 for Modified.
	task testBusRdXSnoop(virtual interface globalInterface sintf,input logic [1:0] MESI_state );
	 begin
	  //Other Cache raises Bus Rd signal
	  sintf.BusRd_reg = 1;
	  
	  //Check if DUT Cache Requests for Snoop Access
	  check_ComBusReqSnoop_assert(sintf);
	  //if data is already in bus, then check if Bus Snoop request is deasserted
	  if(sintf.Data_in_Bus) begin
	  	check_ComBusReqSnoop_deassert(sintf);
	  end else begin
	        
	   //wait for grant
	   wait(sintf.Com_Bus_Gnt_snoop_0);
	   //The Cache should raise mem operation abort
	   check_MemOprnAbrt_assert(sintf);
	   //block is in shared state
	   if(MESI_state == 0) begin
	   	//Check if shared signal is made high
	   	check_Shared_assert(sintf);
	   	
	   end
	   else if(MESI_state == 1) begin //in Exclusive state
	   	//Nothing done at top level. Only internal states are changed.
	   	
	   end 
	   else if(MESI_state == 2) begin //in Modified state
	   	//Check if Common Bus Access is requested
	   	check_ComBusReqSnoop_assert(sintf);
	   	//wait for access grant
	   	wait(sintf.Com_Bus_Gnt_snoop_0);
	   	//check if data bus com has valid data
	   	check_DataBusCom_valid(sintf);
	   	//check if mem wr is asserted
	   	check_MemWr_assert(sintf);
	   	//raise the memory write done
	   	sintf.Mem_write_done = 1;
	   	//check if com bus req snoop is deasserted
	   	check_ComBusReqSnoop_deassert(sintf);
	   	
	   end
	  		
	  end										
	 end
	endtask
endclass : topBusRdXSnoop

//Unit level Tests: Defined in 4.8.2.
//Unit Interface considered is cache_controller;


//Class to test MESI FSM functionality depending on the top level Processor Write/Read Request and current MESI State.
//Constrained Randomization is used to consider M/S/E MESI states as initial
//states. 
class unitMESIProc extends baseTestClass;
   
   rand mesiStateType current_mesi_state;
   rand mesiStateType next_mesi_state;
  
   constraint c_current_mesi_state {current_mesi_state inside
{MODIFIED,EXCLUSIVE,SHARED};} 
   
   rand bit PrRd;
   rand bit PrWr;
   //constrain this parameter: 2'b10 for Read, 2'b01 for Write
   constraint c_PrRd {PrRd inside {1,0};
                      PrWr == ~PrRd;}
    
   task testUnitMESIProc(virtual interface globalInterface cci );
     begin
        cci.PrRd = PrRd;
        cci.PrWr = PrWr;
        cci.Address = 32'hbabacafe;
        
        //set the Current_MESI_state_proc input
        cci.Current_MESI_state_proc = current_mesi_state;
        case(cci.PrWr)
           1'b1: begin
                   cci.Data_Bus_reg = 32'habababab;
                   case(cci.Current_MESI_state_proc)
                       MODIFIED:  begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_proc),MODIFIED,cci.clk); 
                       end
                       EXCLUSIVE: begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_proc),MODIFIED,cci.clk); 
                       end
                       SHARED:    begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_proc),MODIFIED,cci.clk);
                         //check if invalidate signal is asserted
                         check_Invalidate_assert(cci); 
                       end
                   endcase
                 end
           1'b0: begin
                       check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_proc),mesiStateType'(cci.Current_MESI_state_proc),cci.clk); 
                 end
        endcase
        //store the next mesi state
        next_mesi_state = mesiStateType'(cci.Updated_MESI_state_proc);
        //sample for coverage
        cg_PrRdWr_MESI_fsm_proc.sample();
        
     end
    
   endtask : testUnitMESIProc
   //Define covergroup to see what initial states are covered when Processor
   //Request is Read/Write
   covergroup cg_PrRdWr_MESI_fsm_proc;
      cover_item_cur_mesi_state : coverpoint current_mesi_state;
      cover_item_next_mesi_state : coverpoint next_mesi_state;
      cover_item_PrRd      : coverpoint PrRd;
      cover_item_PrWr      : coverpoint PrWr;
      cross_cover_item_MESI_PrRdWr : cross cover_item_PrRd, cover_item_PrWr, cover_item_cur_mesi_state;
      cross_cover_item_MESI_curXnext_state : cross cover_item_cur_mesi_state, cover_item_next_mesi_state;
   endgroup : cg_PrRdWr_MESI_fsm_proc

   function new();
      cg_PrRdWr_MESI_fsm_proc = new;
   endfunction: new 
endclass: unitMESIProc

//Class to test MESI FSM functionality on the snoop side.
class unitMESISnoop extends baseTestClass;
      
   rand mesiStateType current_mesi_state;
  
   constraint c_current_mesi_state {current_mesi_state inside
{MODIFIED,EXCLUSIVE,SHARED};} 
   
   rand bit BusRd;
   rand bit BusRdX;
   //constrain this parameter: 2'b10 for Read, 2'b01 for Write
   constraint c_PrRd {BusRd inside {1,0};
                      BusRdX == ~BusRd;}
    
   task testUnitMESISnoop(virtual interface globalInterface cci );
     begin
        cci.BusRd_reg   = BusRd;
        cci.BusRdX_reg  = BusRdX;
        cci.Address = 32'hbabacafe;
        
        //set the Current_MESI_state_proc input
        cci.Current_MESI_state_snoop = current_mesi_state;
        case(cci.BusRdX_reg)
           1'b1: begin
                   case(cci.Current_MESI_state_snoop)
                       MODIFIED:  begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_snoop),INVALID,cci.clk); 
                       end
                       EXCLUSIVE: begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_snoop),MODIFIED,cci.clk); 
                       end
                       SHARED:    begin
                         check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_snoop),MODIFIED,cci.clk);
                         //check if invalidate signal is asserted
                         check_Invalidate_assert(cci); 
                       end
                   endcase
                 end
           1'b0: begin
                       check_MESI_fsm(mesiStateType'(cci.Updated_MESI_state_snoop),mesiStateType'(cci.Current_MESI_state_snoop),cci.clk); 
                 end
        endcase
        //sample for coverage
       cg_BusRdRdX_MESI_fsm_snoop.sample();
        
     end
    
   endtask : testUnitMESISnoop
   //Define covergroup to see what initial states are covered when other
   //caches Request is Bus Read/ReadX
   covergroup cg_BusRdRdX_MESI_fsm_snoop;
      cover_item_init_mesi_state      : coverpoint current_mesi_state;
      cover_item_BusRd                : coverpoint BusRd;
      cover_item_BusRdX               : coverpoint BusRdX;
      cross_cover_item_MESI_BusRdRdX  : cross cover_item_BusRd, cover_item_BusRdX, cover_item_init_mesi_state;
   endgroup : cg_BusRdRdX_MESI_fsm_snoop

   function new();
      cg_BusRdRdX_MESI_fsm_snoop = new;
   endfunction: new  
 
endclass: unitMESISnoop


//Testcase to verify Pseudo LRU Block
class unitPlruBlkReplace extends baseTestClass;
  
  //define index field
  rand reg[`INDEX_SIZE - 1:0] set_index;
  constraint c_set_index {set_index inside {0,14'b11111111111111};}
  //define Tag of first block to be accessed
  rand reg[`TAG_SIZE - 1 : 0] first_access_tag;
  constraint c_first_access_tag {first_access_tag inside {0,16'hffff};}
   
  reg [2:0] expected_lru_var;
  reg [1:0] expected_line_to_replace;

  task testPlruReplace(virtual interface globalInterface gi);
       //set initial LRU Var expected. Make sure this is same as used in DUT
       //when the design is released.
       expected_lru_var = 3'b000;
       
       //fill out all 4 lines of a set
       for(int j = 0 ; j < 4 ; j++) begin
         gi.PrRd = 1;
         gi.PrWr = 0;
         //Read from a different address to fill out all lines in the set with
         //set_index index value
         gi.Address = {first_access_tag + j,set_index,2'b00};
         //check if CPU_stall is asserted
         wait(gi.CPU_stall);
         //wait until CPU_stall is de-asserted
         wait(!gi.CPU_stall);
         //determine the expected value of lru_var
         determine_LRU_var_exp(j,expected_lru_var);
         //reset the DUT
         reset_DUT_inputs(gi);
       end
       
       //Access a block address that has same set_index as above but different
       //Tag
       gi.PrRd = 1;
       gi.PrWr = 0;
       gi.Address = {first_access_tag + 10,set_index,2'b00};
       //determine expected line to be replaced
       expected_line_to_replace = determine_LineToBeReplaced_LRU(expected_lru_var);
       //wait for Blk_accessed to go High
       wait(gi.Blk_accessed);
       //wait for LRU_replacement_proc is valid. Assuming it is set to z.
       wait(gi.LRU_replacement_proc != 2'bz);
       //check if the same line is being replaced by the dut
       assert(expected_line_to_replace == gi.LRU_replacement_proc)
       else $warning(1,"Wrong line is replaced by LRU block",$time);
      //sample coverage if test succeeds
       cg_PlruReplace.sample();
  endtask : testPlruReplace
  
  //define covergroup to collect data about what sets and lines are covered.
  covergroup cg_PlruReplace;
     cover_point_set_index        : coverpoint set_index;
     cover_point_first_access_tag : coverpoint first_access_tag;
     cover_point_index_x_tag      : cross cover_point_set_index, cover_point_first_access_tag;
  endgroup
  
  function new(); 
    cg_PlruReplace = new;
  endfunction
  
endclass : unitPlruBlkReplace

//Macro level Tests
//Define test classes for lowest blocks for low level verification discussed in section 4.8.2
//For blocks inside Cache Controller

//Class to contain stimulus and task to check correctness of Address Segregator Block
class testAddrSeg;
	rand reg [`ADDRESSSIZE - 1 : 0] Address;
	constraint c_Address { Address inside {[32'h00000000 : 32'hffffffff]};}
	
	reg[`BLK_OFFSET_SIZE - 1 : 0] Expected_Blk_offset_proc;
	reg[`TAG_SIZE - 1 : 0]        Expected_Tag_proc;
	reg[`INDEX_SIZE - 1 : 0]      Expected_Index_proc;
	
	//define Cover group to collect the addresses covered
	covergroup cg_Address_testAddrSeg;
	  coverpoint_Address : coverpoint Address {
	  option.auto_bin_max = 8;    //divide the range of possible addresses into 8 bins
	  }
	endgroup
	
	function new();
		cg_Address_testAddrSeg = new;
	endfunction : new
	
	task testAddr(virtual interface globalInterface asi);
          asi.PrRd    = 1; 
          asi.PrWr    = 0; 
	  asi.Address = this.Address;
	  Expected_Blk_offset_proc = this.Address[`BLK_OFFSET_SIZE - 1 : 0];
	  Expected_Tag_proc        = this.Address[`TAG_MSB : `TAG_LSB];
	  Expected_Index_proc      = this.Address[`INDEX_MSB : `INDEX_LSB];
	  @(posedge asi.clk); 
	  @(posedge asi.clk); 
	  //Check for mismatch
	  assert((asi.Blk_offset_proc == Expected_Blk_offset_proc) &&
	         (asi.Tag_proc        == Expected_Tag_proc)        &&
	         (asi.Index_proc      == Expected_Index_proc)) $display("TEST PASSED: Address Segregator Works Fine. testAddrSeg");
	  else $warning(1,"Address Segregator failure",$time);
	  
	  //sample the coverage
	  cg_Address_testAddrSeg.sample();
	  return;   
	endtask : testAddr		
endclass : testAddrSeg
//Create class to test blk accessed blk





