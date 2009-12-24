%% Author: saket kunwar
%% Created: Oct 1, 2009
%% Description: TODO: Add description to cache
-module(cache).
-include_lib("eunit/include/eunit.hrl").
%%
%% Include files
%%
-define(cache_size,1000).  %%cache size in mb
%%
%% Exported Functions
%%
-export([create/1,store_file/2,write_to_cache/2,write/4,process_request/3,test/1]).

%%
%% API Functions
%%

-define(path,"./data/").
-define(p(Id),string:concat("./data/cache",erlang:integer_to_list(Id))++"/").
-include("stream.hrl").
%%
%% Local Functions
%%
%%@doc creates the cache directory 
create(Id)->
	%%if a instance of node has been crreated from this directory then use
	%%the previous cache i.e just rename it
	P=?p(Id),
	io:format("~p~n",[P]),
	filelib:ensure_dir(P),
	case file:make_dir(P) of
		ok->
			io:format("cache directory created ~n");
		{error,eexist}->
			io:format("cache exists")
	end.




process_request(NodeId,File,Num)->
		io:format("XXXXXXXXXXXXXXxx ~p and file ~p~n",[NodeId,File]),
		case file:open(?p(NodeId)++File,[read,binary,raw]) of
			{ok,S}->
				file:close(S),
				{stream,?p(NodeId)++File,Num};
			{error,enoent}->
				%%WRONG HERE WRONG HERE FOR CACHE FILE TEST i.e look at remote_replication example
				Tempfile=?p(NodeId)++"temp"++File,
				io:format("temPfile ~p~n",[Tempfile]),
				case file:open(Tempfile,[read,binary,raw]) of
					{ok,T}->
						file:close(T),
						{cache_stream,Tempfile,Num};
					{error,enoent}->
						io:format("requested file ~p doesn not exist at this node ~p~n ",[Tempfile,NodeId]),
						nofile
				end		
		end.

write(NodeId,File,D,Packet)->
	%%needs adjustment for open once only ...dn maybe store all in buffmap before write operatin 
	{ok,S}=file:open(?p(NodeId)++File,[raw,append,binary]),
	 %%as we write to new cache file from beginnning and not the 
	%%offsets of the streamed file,,problemo with original implementation
	CacheChunkoffset=(Packet-1)*?chunksize, 
	file:pwrite(S,CacheChunkoffset,D),
	file:close(S).



write_to_cache(Id,File)->
	case file:read_file_info("./data/cache/") of
		{ok,Fileinfo}->
				lru(File);  %%send dir size here
						
		{error,_}->
				io:format("error with dir ~n")
	end,
	ok.
%%@doc stores file from the runninig directory to cache directory
store_file(File,Id)->
	file:copy(File,?p(Id)++File),
	Val=lists:keyfind(Id,1,boot:nodelist()),
	boot:storekey(Val,{File,[{all,Val}]}).  %%for simul will have to be more generic
	

lru({Key,Bin})->
	Dirsize=34234,   %%get the current cache dir size
	PathFile=string:concat("./data/cache",Key),
	Rem=?cache_size-Dirsize,
	Binsize=size(Bin),
	if 
		(Rem<Binsize)->
			evict_lru(),
			lru({Key,Bin});
		true->
			filestreams:chunkwrite(PathFile,Bin,0)
		
	end.
	
init_lru()->
	%%need to implement efficint algol for recently used
	{ok,Filenames}=file:list_dir("./data/cache"),
	%%keep a list of used files
	%% determine most recently used
	k.
evict_lru()->
	k.



test([H|T])->
	create(H),
	write(H,"temp1.txt",<<"hello testing cache write ">>,0),
	test(T);
test([])->
	ok.