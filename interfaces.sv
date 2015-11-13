//This document contains interfaces to various blocks in the DUT specified in Cache.
// Names of the interfaces are similar to the names of the blocks used in HAS3.0. Wherever there is deviation, explanation is provided.

//Interface containing interfacing signals between (Proc and Cache), (Cache and Memory), (Memory and Arbiter), (Cache and Bus).
// To be used for Both DL and IL. For IL 'Wr' related signals shall be ignored.Contains interfaces of internal blocks too. 
interface globalInterface();
  //Most of the fields defined are common to cache_controller, cache_block, cache_wrapper
   logic 			clk;
  //Interface between Proc and Cache
   logic 			PrRd; 
   logic 			PrWr;
   logic [`ADDRESSSIZE-1 : 0]	Address;
   logic			CPU_stall; 
  //Interface between Proc and Arbiter                     
   wire 			Com_Bus_Gnt_proc_0;
   wire                         Com_Bus_Gnt_proc_1;
   wire                         Com_Bus_Gnt_proc_2;
   wire                         Com_Bus_Gnt_proc_3;
   wire                         Com_Bus_Gnt_proc_4;
   wire                         Com_Bus_Gnt_proc_5;
   wire                         Com_Bus_Gnt_proc_6;
   wire                         Com_Bus_Gnt_proc_7;
   wire 			Com_Bus_Gnt_snoop;
  //Interface between Cache and Bus
   logic 			All_Invalidation_done;
   logic 			Shared;
   wire         		BusRd;
   reg          		BusRd_reg;
   wire 		        BusRdX;
   reg  		        BusRdX_reg;
   wire 			Invalidate;
   wire 		        Invalidation_done;
   logic 			Shared_local;
  //Interface between Cache/Bus and Lower Level Memory
   logic 		        Mem_wr;
   logic 		        Mem_oprn_abort;
   logic 		        Mem_write_done;
   wire		                Data_in_Bus;
   logic	                Data_in_Bus_reg;
   assign Data_in_Bus = PrRd|| PrWr ? Data_in_Bus_reg : 1'bz;
   wire [`ADDRESSSIZE-1 : 0]	Address_Com;
   logic [`ADDRESSSIZE-1 : 0]	Address_Com_reg;
   wire [`ADDRESSSIZE-1 : 0]	Data_Bus_Com; 
   logic [`ADDRESSSIZE-1 : 0]	Data_Bus_Com_reg;
   assign Data_Bus_Com = PrRd || PrWr ? Data_Bus_Com_reg : 32'hZ;

   wire [`ADDRESSSIZE-1 : 0]	Data_Bus;
   reg  [`ADDRESSSIZE-1 : 0]	Data_Bus_reg;
   assign Data_Bus = PrWr ? Data_Bus_reg : 32'bZ;
   wire                         Com_Bus_Req_proc_0;
   wire                         Com_Bus_Req_proc_1;
   wire                         Com_Bus_Req_proc_2;
   wire                         Com_Bus_Req_proc_3;
   wire                         Com_Bus_Req_proc_4;
   wire                         Com_Bus_Req_proc_5;
   wire                         Com_Bus_Req_proc_6;
   wire                         Com_Bus_Req_proc_7;
   wire 			Com_Bus_Req_snoop_0;
   wire                         Com_Bus_Req_snoop_1;
   wire                         Com_Bus_Req_snoop_2;
   wire                         Com_Bus_Req_snoop_3;
   wire                         Com_Bus_Req_snoop_4;
   wire                         Com_Bus_Gnt_snoop_0;
   wire                         Com_Bus_Gnt_snoop_1;
   wire                         Com_Bus_Gnt_snoop_2;
   wire                         Com_Bus_Gnt_snoop_3;
  //Interface between Lower Level Memory and Arbiter
   logic                        Mem_snoop_req;
   wire                         Mem_snoop_gnt;
   logic [1:0]                  Current_MESI_state_proc;
   logic [1:0]                  Current_MESI_state_snoop;
   logic [1:0]                  Blk_accessed;
   logic [1:0]                  LRU_replacement_proc;
   logic [1:0]                  Updated_MESI_state_proc;
   logic [1:0]                  Updated_MESI_state_snoop;
  //Interface of Address Segregator Block
   logic [`BLK_OFFSET_SIZE - 1 : 0] Blk_offset_proc;
   logic [`TAG_SIZE - 1 : 0]        Tag_proc;
   logic [`INDEX_SIZE - 1 : 0]      Index_proc; 
  
 // modport cache_wrapper (input clk,  PrWr, PrRd, Address,logic Data_Bus, output CPU_stall, Com_Bus_Req_proc, input Com_Bus_Gnt_proc, output Com_Bus_Req_snoop , input Com_Bus_Gnt_snoop, logic Address_Com, logic  Data_Bus_Com, logic BusRd, BusRdX, Invalidate, Data_in_Bus, output Mem_wr, Mem_oprn_abort, input Mem_write_done, output Invalidation_done, input All_Invalidation_done, output Shared_local, input Shared); 
endinterface : globalInterface

