%% Author: saket kunwar			
%% Created: Sep 13, 2009
%% Description: TODO: Add description to buffmap
-module(buffmap).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([loop/4,init_file_process/2,testreceive/1]).

%%
%% API Functions
%%
loop(L,Offset,FileDisc,Id)->
	receive
			{add,Chunk}->
				
				{{Hkeys,Chunkoffset},D}=Chunk,
				{{File,Off},Packet}=Hkeys,
				%%make consideration for out of sequence
				
				Temp=string:concat("temp"++integer_to_list(Off),filename:basename(File)),   %%??file naming assumed Off is stream
			    %%io:format("HKEYS and chunkoffset ~p ,~p~n",[Hkeys,Chunkoffset]),
				%%filestreams:chunkwrite(Temp,D,Chunkoffset),
				%%vlc:play(Temp),
				%%io:format("adding chunk to~p in process ~p~n",[Temp,self()]),
				cache:write(Id,Temp,D,Packet), %%write where?  %%writing to single file from beggining
				loop(L,Offset,FileDisc,Id);
			{disp,From}->
				io:format("Offset ais ~p~n",[Offset]),
				From ! {offset,Offset},
				loop(L,Offset,FileDisc,Id)
	end.

%%
%% Local Functions
%%
init_file_process([H|T],NodeId)->
					
					{File,Offset}=H,
					
					Stream=list_to_atom(string:concat(File,integer_to_list(NodeId+Offset))),
					io:format("at init_process OFFSET HERE IS ~p~n",[Offset]),
					case whereis(Stream) of
					undefined->
							register(Stream,spawn (fun()->buffmap:loop([],Offset,H,NodeId) end)),
							io:format("created init_file prcess stream ~p~n",[Stream]);
					_->
							io:format("process for the file exists ~n")
					end,
					init_file_process(T,NodeId);
init_file_process([],_)->
						ok.


testreceive(N)->
	receive
		{command,filedata,Message}->
			%%io:format("received fildata times ~p~n",[N]),
			{{Hkeys,Chunkoffset},D}=Message,
			{{File,Off},Packet}=Hkeys,
			filestreams2:chunkwrite("testreceive.mp4",D,Chunkoffset),
			testreceive(N+1)
	end.
		
	
		
					