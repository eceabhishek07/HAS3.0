//This document contains the Test Bench to verify Single Core L1 MESI Cache in a Multicore environment

`timescale 1ps/1ps

//Define Address Size
`define ADDRESSSIZE 32

//Define the stimulus to the L1 Cache. This class contains all inputs to the DUT at Top level
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
		this.PrRd = 0;
		this.PrWr = 0;
		this.cg = new();
    
	endfunction
  
	//To Indicate that the stimulus has been applied
	event stimulusDriven_e;

	constraint C1 {PrRd inside {1,0};}
	constraint C2 {PrWr inside {1,0};}
   
	covergroup cg @stimulusDriven_e;
		cover_point_PrRd  : coverpoint PrRd;
		cover_point_PrRWr : coverpoint PrWr;
		cross_PrRd_PrWr   : cross cover_point_PrRd, cover_point_PrRWr;
	endgroup
 
endclass : singleCacheStimulus

module tb();

	singleCacheStimulus sti = new();

	initial begin
		sti.randomize();
		sti.cg.sample();
		sti.randomize();
		sti.cg.sample();
   
	end
endmodule



