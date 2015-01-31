-module(logserver).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, 
terminate/2, code_change/3]).

-export([start/0, sendlog/2]).

-include_lib("amqp_client/include/amqp_client.hrl").

% These are all wrappers for calls to the server
start() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
sendlog(Where, Msg) -> gen_server:call(?MODULE, {sendlog, Where, Msg}).	

% This is called when a connection is made to the server
init([]) ->
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
  
   {ok,AmqpCon} = amqp_connection:start	(AmqpParams),

   {ok, AmqpCon}.

% handle_call is invoked in response to gen_server:call
handle_call({sendlog, Where, Msg}, _From, AmqpCon) ->
	LogLevel = ["info","warn","error"],
	Response = case lists:member(Where, LogLevel) of
		true ->
			case Msg =:= "" of
			   false -> 
		 	     send_log(Where,Msg,AmqpCon),
			     {ok,"log has been successfully insert in '" ++ Where ++ 
"' queue."};
 			   true ->
				{error,"The message parameter is empty."}
			end;
		false ->
			{error,"log leven '" ++ Where ++ "' is not valid"}
	end,
	{reply, Response,AmqpCon};
handle_call(_Message, _From, AmqpCon) ->
	{reply, error, AmqpCon}.

send_log(Where,Msg,AmqpCon) ->
      {ok, Channel} =
     	amqp_connection:open_channel(AmqpCon),

      QName = list_to_binary(Where),
      Payload = list_to_binary(Msg),
   
      amqp_channel:call(Channel, #'queue.declare'{queue = QName}),

      amqp_channel:cast(Channel,
                      #'basic.publish'{
                        exchange = <<"">>,
                        routing_key = QName},
                      #amqp_msg{payload = Payload}),
	   ok = amqp_channel:close(Channel).

% We get compile warnings from gen_server unless we define these
handle_cast(_Message, AmqpCon) -> {noreply, AmqpCon}.
handle_info(_Message, AmqpCon) -> {noreply, AmqpCon}.
terminate(_Reason, _AmqpCon) -> ok.
code_change(_OldVersion,AmqpCon, _Extra) -> {ok, AmqpCon}.
