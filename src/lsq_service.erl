-module(lsq_service). -export([
    init/1,
    allowed_methods/2,
    content_type_provided/2,
    to_html/2
 ]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

-spec init(list()) -> {ok, term()}.
init([]) ->
    {ok, undefined}.

allowed_methods(ReqData,Context)->
{ ['GET'],ReqData,Context }.

content_type_provided(rd,ctx)->
	{[{"text/html",to_html}],rd,ctx}.

-spec to_html(wrq:reqdata(), term()) -> {iodata(), wrq:reqdata(), term()}.
to_html(ReqData, State) ->

   Level = string:to_lower(wrq:get_qs_value("level","",ReqData)),
   Msg = wrq:get_qs_value("msg","",ReqData),

   Payload = list_to_binary(Msg),
   QName = list_to_binary(Level),

   {ok, App}      = application:get_application(?MODULE),
   {ok, RMQ_host} = application:get_env(App, rmq_host),
   {ok, RMQ_port} = application:get_env(App, rmq_port),
   {ok, RMQ_user} = application:get_env(App, rmq_user),
   {ok, RMQ_pass} = application:get_env(App, rmq_pass),   


   case Level == "info" orelse Level == "warn" orelse Level == "error" of
  	true -> 
	   {ok, Connection} =
        	amqp_connection:start(#amqp_params_network{
							host = RMQ_host, 
							port = RMQ_port,
							username = list_to_binary(RMQ_user),
							password = list_to_binary(RMQ_pass)
							}),

	    {ok, Channel} = amqp_connection:open_channel(Connection),

	    amqp_channel:call(Channel, #'queue.declare'{queue = QName}),

	    amqp_channel:cast(Channel,
                      #'basic.publish'{
                        exchange = <<"">>,
                        routing_key = QName},
                      #amqp_msg{payload = Payload}),

	    ok = amqp_channel:close(Channel),
	    ok = amqp_connection:close(Connection);
	false -> 
		false
    end,

    {"<html><body>Log service is running.</body></html>",ReqData,State}.

	
