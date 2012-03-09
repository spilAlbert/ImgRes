%% @author Mochi Media <dev@mochimedia.com>
%% @copyright imgRes Mochi Media <dev@mochimedia.com>

%% @doc Callbacks for the imgRes application.

-module(imgRes_app).
-author("Mochi Media <dev@mochimedia.com>").

-behaviour(application).
-export([start/2,stop/1]).


%% @spec start(_Type, _StartArgs) -> ServerRet
%% @doc application start callback for imgRes.
start(_Type, _StartArgs) ->
    imgRes_deps:ensure(),
    imgRes_sup:start_link().

%% @spec stop(_State) -> ServerRet
%% @doc application stop callback for imgRes.
stop(_State) ->
    ok.
