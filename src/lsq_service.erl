-module(lsq_service). -export([
    init/1,
    allowed_methods/2,
    to_html/2 ]).

-include_lib("webmachine/include/webmachine.hrl").

init([]) ->
    {ok, undefined}.

allowed_methods(ReqData,Context)->
{ ['GET'],ReqData,Context }.

to_html(ReqData, State) ->
   Start = get_timestamp(),
 	
   Level = string:to_lower(wrq:get_qs_value("level","",ReqData)),
   Msg = wrq:get_qs_value("msg","",ReqData),
   {_,Result} = logserver:sendlog(Level,Msg),

   Stop = get_timestamp(),
   
   io:fwrite("finish request(miliseconds): "),
   io:write(Stop-Start),
   
   {"<html><body>" ++ Result ++ "</body></html>",ReqData,State}.  


get_timestamp() ->
	{Mega, Sec, Micro} = os:timestamp(),
	(Mega*1000000 + Sec)*1000 + round(Micro/1000). 
