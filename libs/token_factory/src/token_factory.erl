-module(token_factory).
-compile(export_all).
-export([loop/4]).

start() -> register(?MODULE, Pid=spawn(?MODULE,init,[])),
           Pid.

stop() ->
	   ?MODULE ! shutdown.



get_token() ->
	Pid = erlang:whereis(?MODULE),
	Pid ! {self(),gimme_da_token},
	receive 
		{SUrl,AuthToken} ->
			{SUrl,AuthToken}
	after 2000 ->
		{error,timeout}
	end.

loop(User,Pass,Token,Url) ->
	receive 
		{Client,gimme_da_token} ->
			TokenSize = tuple_size(Token),
			if TokenSize == 0 ->
				Headers = [{"X-Storage-User",User},{"X-Storage-Pass",Pass}],
                        	{ok,{{_,200,_}, ReturnHeaders, _Body}} = httpc:request(get, { "http://files-stg.spilcloud.com/auth/v1.0",Headers},[],[]),
	                        {value,_AuthToken} = lists:keysearch("x-auth-token",1,ReturnHeaders),
        	                {value,{_,_SUrl}} = lists:keysearch("x-storage-url",1,ReturnHeaders),
				Client ! {_SUrl,_AuthToken},
				loop(User,Pass,_AuthToken,_SUrl);

			true -> 
				case httpc:request(get,{Url,[Token]},[],[]) of
                                	{ok,{{_,Code,_},_,_}} when Code > 199 , Code < 299 ->	
							Client ! {Url,Token},
							loop(User,Pass,Token,Url);
	                                {ok,{{_,401,_},_,_}}  ->
							Headers = [{"X-Storage-User",User},{"X-Storage-Pass",Pass}],
			                                {ok,{{_,200,_}, ReturnHeaders, _Body}} = httpc:request(get, { "http://files-stg.spilcloud.com/auth/v1.0",Headers},[],[]),
	                       			        {value,_AuthToken} = lists:keysearch("x-auth-token",1,ReturnHeaders),
			                                {value,{_,_SUrl}} = lists:keysearch("x-storage-url",1,ReturnHeaders),
			                                Client ! {_SUrl,_AuthToken},
	                       			        loop(User,Pass,_AuthToken,_SUrl);
	                                {ok,{{_,_Code,_},_,_}} ->
                                                        Client ! {error,_Code},
							loop(User,Pass,Token,Url);
					{_} ->
						Client ! {error, "Could not contact the server"},
						loop(User,Pass,Token,Url)
				end
                        end;
		{Client,whatugot} ->
			Client ! {Url,Token},
			loop(User,Pass,Token,Url);
		{Client,_} ->
			Client ! {error,"what?"},
			loop(User,Pass,Token,Url)
	end.


init() ->
	% Here we should load the configuration from a config file
	inets:start(),
	loop("test_albert:albert","geheim123",{},"").
