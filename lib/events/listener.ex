defmodule Props.EventListener do
  defstruct auth: nil,
            id: nil
end

defmodule Server.Event do
  defstruct cast: nil, contents: nil, error: nil, origin: nil, to: nil
end

defmodule Events.Listener do
  use GenServer
  use Mixins.Packets
  use Mixins.SocketWriter
  use Mixins.Store

  def start_link(id) do
    GenServer.start_link(__MODULE__, %Props.EventListener{id: id}, [name: String.to_atom("events_#{id}")])
  end

  def handle_cast({:init}, state) do
    Say.pretty("Event listener for client #{state.id} has been started.", :green)
    {:noreply, state}
  end

  @doc """
    Authenticate with the given params.
  """
  def handle_cast({:auth, updated}, state) do
    {:noreply, Map.merge(state, %{auth: updated})}
  end

  @doc """
    Deliver a parsed socket message to the appropriate server.
  """
  def handle_cast({:event, message, token, origin}, state) do
    event = from_list(message, origin)

    case event do
      %{ cast: :login, to: :auth } ->
        p = expect_from(event, {:email, :password})
        GenServer.cast(:auth, {:login, p, self()})

      %{ cast: :register, to: :auth } ->
        p = expect_from(event, {:email, :password})
        GenServer.cast(:auth, {:register, p})

      %{ to: :world } ->
        authenticated_action(event, token, state)

      %{ to: :worlds } ->
        authenticated_action(event, token, state)

      _ ->
       IO.puts "Socket message received: #{message}"
    end

    {:noreply, state}
  end

  # Handle a socket message from an authenticated client.
  defp authenticated_action(event, token, state) do
    can_pass = authenticated?(event.origin, state, token)

    if can_pass do
      case event do
        %{ cast: :join, to: :world } ->
          p = expect_from(event, {:world_id})
          GenServer.cast(String.to_atom("world_#{p.contents.world_id}"), {:join, p})
        %{ cast: :move, to: :world } ->
          p = expect_from(event, {:world_id, :direction})
          GenServer.cast(String.to_atom("world_#{p.contents.world_id}"), {:move, p})
        %{ cast: :get, to: :worlds } ->
          GenServer.cast(:tree, {:get, :worlds, event})
      end
    else
      write_to(event.origin, %{
        cast: :error,
        namespace: :global,
        value: "Not authenticated."
      })
    end
  end

  defp authenticated?(source, state, token) do
    state.auth == token
  end

  # Coerce a packet list into a map with keynames.
  defp expect_from(event, schema) do
    results = Enum.reduce(
      Enum.map(0..length(Tuple.to_list(schema)) - 1,
              fn(i) -> Map.put(%{}, elem(schema, i), elem(event.contents, i)) end),
      fn(first, second) -> Map.merge(first, second) end)

    %{event | contents: results}
  end
end
