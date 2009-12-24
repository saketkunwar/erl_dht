%% Author:saket kunwar
%% Created: Feb 11, 2009

-module(filestreams).
%%
%% Include files
%%
%% Exported Functions
%%
-export([info/3,streamer/2,streamfile/4,streammapinfo/3,sendstreammapinfo/3,chunk_select/2,stream_select/3,chunkwrite/3]).

%%
%% API Functions
%%
%%
streammapinfo(File,Streams,Chunksize)->
		Size=filelib:file_size(File),
		Streamsize=Size div Streams,
		Numofpacket=(Streamsize div Chunksize),   %%1 as last packet is Stremsize rem Chunksiz,,
		Keys=keylist(lists:seq(0,Streams-1),File,Streamsize,[]),
		io:format("File info, Num of packet in a Stream:~p Keys:~p~n",[Numofpacket,Keys]),
		{bufffilemapinfo,{Keys,Numofpacket}}.
info(File,Streams,Chunksize)->
		Size=filelib:file_size(File),
		Streamsize=Size div Streams.
		
	
keylist([H|T],File,Streamsize,L)->
		keylist([X||X<-T],File,Streamsize,lists:append(L,[{File,Streamsize*H}]));

keylist([],_,_,L)->
		L.

sendstreammapinfo(File,Streams,Chunksize)->
	 %%localhost and port=5000 is default 
		Host=localhost,
		Port=5000,  
		{bufffilemapinfo,{Keys,Nump}}=streammapinfo(File,Streams,Chunksize),
		send(Host,Port,{bufffilemapinfo,{Keys,Nump}}),
		io:format("sent  filemapinfo ~n").
streamer(Conn_data,File_data)->
	ok.
	
streamfile(File,Streams,Chunksize,Num)->   %%num is the stream num to send all or particular
		sendstreammapinfo(File,Streams,Chunksize),
      	{ok,S}=file:open(File,[read,binary,raw]),
   		io:format("opened file ~n"),
    		Filesize=filelib:file_size(File),
    		filediv({File,S},Streams,Chunksize,Filesize,Num).
%%need adjustment for last offsets
filediv({File,S},Stream,Chunksize,Size,Num)->
      	B=Size rem Stream,
		Offset=[(Size div Stream)*X||X<-lists:seq(0,(Stream-1))],  %% only works for more than  1 stream
      	Length=lists:nth(2,Offset),
      	io:format("offset ~p and length ~p with additional end bytes ~p~n",[Offset,Length,B]),
		case Num of
		all->
      		filereadloop({File,S},lists:sublist(Offset,(Stream-1)),Length,Chunksize),
      		filereadloop({File,S},[lists:last(Offset)],Length+B,Chunksize);
		_->
			Off=lists:nth(Num,Offset),
			filereadloop({File,S},[Off],Length,Chunksize)
		end.

filereadloop({File,S},[H|T],Len,Chunksize)->
      	{ok,Data}=file:pread(S,H,Len),
      	io:format("read ~p  ~p~n",[H,Len]),
   		createchunks({Data,Chunksize},Len,list_to_tuple([File]++[H])),  
		filereadloop({File,S},[X||X<-T],Len,Chunksize);


filereadloop({_,_},[],_,_)->
    ok.

createchunks({Data,Chunksize},Len,KeygenfromOffset)->
		Numpacket=Len div Chunksize,
		io:format("num packet ~p~n ",[Numpacket]),
		Keys=for(1,Numpacket,fun(I)->list_to_tuple([KeygenfromOffset]++[I]) end),
		chunkloop({Data,Chunksize},Keys).

%%note offset is calculated from keys
chunkloop({Data,Chunksize},[Hkeys|Tkeys])->    
		{Chunk,Remainingchunk}=split_binary(Data,Chunksize),
		{{_,S},N}=Hkeys,
		Chunkoffset=S+((N-1)*Chunksize),
		chunksend({Chunk,{Hkeys,Chunkoffset}}),
		chunkloop({Remainingchunk,Chunksize},[X||X<-Tkeys]);
chunkloop({_,_},[])->
		ok.		

chunkwrite(File,Chunk,Offset)->
	%%needs adjustment for open once only
		{ok,S}=file:open(File,[raw,append,binary]),
		file:pwrite(S,Offset,Chunk).

%% sends to localost and port 5000 as default
%% the data sent is of the format {filedata,Key,{Offset,Data}}
chunksend({Data,KeyOffset})->    
		send(localhost,5000,{filedata,{KeyOffset,Data}}),
		io:format("data at offset ~p~n sent",[KeyOffset]), 
		ok.

%%resend invidual packet provided packetnum,streamnum and chunksize is known
chunk_select([H|T],Chunksize)->
		
		{{File,Stream},Packet}=H,
		Offset=Stream+((Packet-1)*Chunksize),  %%case when stream is 0 better calculate these routines
		io:format("offset is ~p~n is",[Offset]),
		{ok,S}=file:open(File,[read,binary,raw]),
		{ok,Data}=file:pread(S,Offset,Chunksize),	
		io:format("data ~p~n",[Data]),			
		chunk_select([X||X<-T],Chunksize);

chunk_select([],_)->
		ok.

%%send whole streams
stream_select(File,Totalstream,{Streamnum,Chunksize})->
		{ok,S}=file:open(File,[read,binary,raw]),
		Size=filelib:file_size(File),
		Stream=Size div Totalstream,
		Offset=Stream*Streamnum,
		Len=Stream*Chunksize,
		{ok,Data}=file:pread(S,Offset,Len),
		io:format("stream ~p~n",[Data]).


send(Host,Port,Message)->
		{ok,Socket}=gen_tcp:connect(Host,Port,[binary,{packet,0}]),
		io:format("connected to ~p~n",[Host]),
		Binary_message=term_to_binary(Message),
		ok=gen_tcp:send(Socket,Binary_message).
	

for (Max,Max,F)-> [F(Max)];
for (I,Max,F)->[F(I)|for(I+1,Max,F)].

