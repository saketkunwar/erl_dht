%% Author: saket kunwar
%% Created: Sep 15, 2009
%% Description: TODO: Add description to vlc
-module(vlc).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([play/1,vlclistener/0,vlcsender/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

play(File)->
	A=list_to_atom(File),
	
	case whereis(A) of
	undefined->
		
   		register(A,spawn(fun()->os:cmd("vlc " ++ File) end));
	_->
		ok
	end.

 
%%@doc sends whole vlc file in vlc mode
vlcsender(File)->
	Dir="c:/stream/",
	Command="vlc " ++ string:concat(Dir,File)++ " :sout=#duplicate{dst=std{access=http,mux=mp4,dst=localhost:5000}}",
	io:format("~p~n",[Command]),
	os:cmd(Command).

%%@doc vlc listens to a port
vlclistener()->
	os:cmd("vlc http://localhost:5000 :sout=#duplicate{dst=display,dst=std{access=file,dst=c:/stream/t1.mp4}}").
