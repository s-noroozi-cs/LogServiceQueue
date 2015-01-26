-module(lsq_service). 

-export([
    init/1
    ,allowed_methods/2
    ,to_html/2
 ]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

init([]) ->
   {ok,undefine}.


allowed_methods(ReqData,Context)->
    {['GET'],ReqData,Context}.

get_timestamp() ->
   {Mega, Sec, Micro} = os:timestamp(),
   (Mega*1000000 + Sec)*1000 + round(Micro/1000). 

to_html(ReqData, State) ->
   io:fwrite("\n--->"),
   io:write(get_timestamp()),
   
   Level = string:to_lower(wrq:get_qs_value("level","",ReqData)),
   Msg = wrq:get_qs_value("msg","",ReqData),

   Payload = list_to_binary(Msg),
   QName = list_to_binary(Level),

   {ok, App}      = application:get_application(?MODULE),
   {ok, RMQ_host} = application:get_env(App, rmq_host),
   {ok, RMQ_port} = application:get_env(App, rmq_port),
   {ok, RMQ_user} = application:get_env(App, rmq_user),
   {ok, RMQ_pass} = application:get_env(App, rmq_pass),   

   AmqpParams = #amqp_params_network {
	username = RMQ_user,
	password = RMQ_pass,
	host = RMQ_host,
	port = RMQ_port
	},


   case Level == "info" orelse Level == "warn" orelse Level == "error" of
  	true -> 
	  %% {ok, Connection} =
      	  %%      amqp_connection:start(#amqp_params_network{
	  %%						host = RMQ_host, 
	  %%						port = RMQ_port,
	  %%						username = RMQ_user,
	  %%						password = RMQ_pass
 	  %%						}),

	    {ok, Channel} = 
			rmqp_get_channel(AmqpParams),
			%%amqp_connection:open_channel(Connection),

	    amqp_channel:call(Channel, #'queue.declare'{queue = QName}),

	    amqp_channel:cast(Channel,
                      #'basic.publish'{
                        exchange = <<"">>,
                        routing_key = QName},
                      #amqp_msg{payload = Payload});

	    %%ok = amqp_channel:close(Channel);
	    %%ok = amqp_connection:close(Connection);
	false -> 
		false
    end,

    io:fwrite("\n<---"),
    io:write(get_timestamp()),

    {"<html><body>Log service is running.</body></html>",ReqData,State}.

	
rmqp_get_channel(AmqpParams)->

   case maybe_new_pid({AmqpParams, connection},
	   fun() -> amqp_connection:start(AmqpParams) end) of
	{ok, Client} ->
	    maybe_new_pid({AmqpParams, channel},
	        fun() -> amqp_connection:open_channel(Client) end);
	Error ->
	    Error
    end.
   
maybe_new_pid(Group, StartFun) ->
	case pg2:get_closest_pid(Group) of
	     {error, {no_such_group, _}} ->
	          pg2:create(Group),
	          maybe_new_pid(Group, StartFun);
	     {error, {no_process, _}} ->
	        case StartFun() of
	          {ok, Pid} ->
	            pg2:join(Group, Pid),
	            {ok, Pid};
 	          Error ->
	            Error
		end;
	   Pid ->
	      {ok, Pid}
	end.
