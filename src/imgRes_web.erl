%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc Web server for imgRes.

-module(imgRes_web).
-author("Mochi Media <dev@mochimedia.com>").

-export([start/1, stop/0, loop/2]).


%% External API

start(Options) ->
    {DocRoot, Options1} = get_option(docroot, Options),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end, 
    mochiweb_http:start([{name, ?MODULE}, {loop, Loop} | Options1]),
    client:start(erlang:whereis(?MODULE)).
    %io:format("~n~n hey, I'm here ~p~n~n",[erlang:whereis(?MODULE)]). %%Aqui llamar a start client con el pid de erlang:whereis(?MODULE)

stop() ->
    mochiweb_http:stop(?MODULE).


loop(Req, DocRoot) ->
    "/" ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
		  	"imgresize" ->
			        Req:ok({"text/html", [], <<"<html><body><h1>File Upload</h1>
                                        <form enctype=\"multipart/form-data\" action=\"/imgresize\" method=\"post\">
                                        <label for=\"file\">File:</label>
                                        <input type=\"file\" name=\"file\" id=\"file\"/>
					Action<input type=\"text\" name=\"action\" />
					SizeX<input type=\"text\" name=\"sizex\" />
					SizeY<input type=\"text\" name=\"sizey\" />
                                        <input type=\"submit\" name=\"upload\" value=\"Upload\" />
                                        </form>
                                        </body></html>">>});
                    _ ->
                        Req:serve_file(Path, DocRoot)
                end;
            'POST' ->
                case Path of
			"imgresize" ->
				upload_photo(Req);

                    _ ->
                        Req:not_found()
                end;
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

%% Internal API

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

handle_file(Filename,ContentType) ->
	% Random filename in tmp folder
	TempFilename = "/tmp/" ++ atom_to_list(?MODULE) ++ integer_to_list(erlang:phash2(make_ref())),
	{ok, File} = file:open(TempFilename, [raw,write]),
	chunk_handler(Filename, ContentType, TempFilename, File).

% We are returning a function here
chunk_handler(Filename, ContentType, TempFilename, File) ->
	fun(Next) ->
		case Next of
			eof -> 
				file:close(File),
				{Filename,ContentType, TempFilename};
			Data ->
				file:write(File,Data),
				chunk_handler(Filename, ContentType, TempFilename, File)
		end
	end.


upload_photo(Req) ->
    FileHandler = fun(Filename, ContentType) -> handle_file(Filename, ContentType) end,
    Files = mochiweb_multipart:parse_form(Req, FileHandler),
    {Filename,_ ,Location} = proplists:get_value("file", Files),
    Action = {proplists:get_value("action", Files),proplists:get_value("sizex", Files),proplists:get_value("sizey", Files)},
    %client:start(),
    client:add_event(Filename,Location,Action),
    [NewPath] = evserv:listen(Filename,5),
    Req:ok({"text/html", [], "<p>Thank you for " ++ Filename ++ "</p> <p> <img src=\"" ++ element(3,NewPath) ++ "\"<img> </p><p>  <a href=\"imgresize\">Upload another?</a></p>"}).



%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

you_should_write_a_test() ->
    ?assertEqual(
       "No, but I will!",
       "Have you written any tests?"),
    ok.

-endif.
