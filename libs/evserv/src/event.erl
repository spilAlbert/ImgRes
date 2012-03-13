-module(event).
-compile(export_all).
-record(state, {server,
		client,
		name="",
		path="",
		options}).


%% Internal call


convert_tuple(Tuple,1) -> convert_tuple(setelement(1,Tuple,list_to_atom(element(1,Tuple))),2);
convert_tuple(Tuple,N) ->
                Size = tuple_size(Tuple),
                 if Size == N ->
                        setelement(N,Tuple,list_to_integer(element(N,Tuple)));
                 true ->
                        convert_tuple(setelement(N,Tuple,list_to_integer(element(N,Tuple))),N+1)
                 end.


%% End



start(Client,EventName, PathName,Options) ->
	spawn(?MODULE,init,[self(),Client,EventName,PathName,Options]).

start_link(Client,EventName, PathName,Options) ->
	spawn_link(?MODULE,init,[self(),Client,EventName,PathName,Options]).

init(Server,Client,EventName,PathName,Options) ->
	loop(#state{server=Server,
			client=Client,
			name=EventName,
			path=PathName,
			options=Options}).

cancel(Pid) ->
	Ref = erlang:monitor(process,Pid),
	Pid ! {self(),Ref,cancel},
	receive
		{Ref,ok} ->
			erlang:demonitor(Ref,[flush]),
			ok;
		{'DOWN',Ref,process,Pid,_Reason} ->
			ok
	end.



loop(S = #state{server=Server}) ->
	receive
		{Server, Ref, cancel} ->
			Server ! {Ref, ok}
	after 1000 ->
		% Rename the path to save the file as /path/Resized_filename
		[Filename|_] = lists:reverse(string:tokens(S#state.path,"/")),
		Newfilename = string:concat(Filename,".jpg"),
		% Hardcoded url,ARGH!
		NewPath2 = string:concat("/home/admins/albertadm/imgRes/priv/www/",Newfilename),
		
		Fun = fun(Tuple) -> event:convert_tuple(Tuple,1) end,
		Actions = lists:map(Fun,S#state.options),

		%[{Action,SizeX,SizeY},{Quality,Num}] = S#state.options,
		%gm:convert(S#state.path, NewPath2 ,[{list_to_atom(Action), list_to_integer(SizeX), list_to_integer(SizeY)}, {list_to_atom(Quality),list_to_integer(Num)}]),
	
		gm:convert(S#state.path, NewPath2 ,Actions),
		Server ! {done, S#state.name, Newfilename}
	end.


