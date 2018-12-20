defmodule GRPC.Client.Stream do
  @moduledoc """
  A struct that *streaming* clients get from rpc function calls and use to send further requests.

  ## Fields

    * `:channel` - `GRPC.Channel`, the channel established by client
    * `:payload` - data used by adapter in a request
    * `:path` - the request path to sent
    * `:marshal` - a function encoding the request
    * `:unmarshal` - a function decoding the reply
    * `:req_stream` - indicates if request is streaming
    * `:res_stream` - indicates if reply is streaming
  """

  @typep marshal :: (struct -> binary)
  @typep unmarshal :: (binary -> struct)
  @typep stream_payload :: any
  @type t :: %__MODULE__{
          channel: GRPC.Channel.t(),
          service_name: String.t(),
          method_name: String.t(),
          grpc_type: atom,
          rpc: tuple,
          payload: stream_payload,
          path: String.t(),
          marshal: marshal,
          unmarshal: unmarshal,
          server_stream: boolean,
          canceled: boolean,
          __interface__: map
        }
  defstruct channel: nil,
            service_name: nil,
            method_name: nil,
            grpc_type: nil,
            rpc: nil,
            payload: %{},
            path: nil,
            marshal: nil,
            unmarshal: nil,
            server_stream: nil,
            # TODO: it's better to get canceled status from adapter
            canceled: false,
            __interface__: %{send_request: &__MODULE__.send_request/3, recv: &GRPC.Stub.do_recv/2}

  @doc false
  def put_payload(%{payload: payload} = stream, key, val) do
    payload = if payload, do: payload, else: %{}
    %{stream | payload: Map.put(payload, key, val)}
  end

  @doc false
  @spec send_request(GRPC.Client.Stream.t(), struct, Keyword.t()) :: GRPC.Client.Stream.t()
  def send_request(%{marshal: marshal, channel: channel} = stream, request, opts) do
    message = marshal.(request)
    send_end_stream = Keyword.get(opts, :end_stream, false)
    channel.adapter.send_data(stream, message, send_end_stream: send_end_stream)
  end
end
