defmodule App.Stats do
  use GenServer
  require Logger
  require DogStatsd

  @prefix "elixir_lang_bot."

  # Public API

  def start_link do
    Logger.info "Started stats server"

    host = Application.get_env(:app, :statsd_host)
    port = 8125
    {:ok, statsd} = DogStatsd.new(host, port)
    GenServer.start_link __MODULE__, statsd, name: __MODULE__
  end

  def init(statsd) do
    {:ok, statsd}
  end

  def increment(name, opts \\ %{}) do
    GenServer.cast __MODULE__, {:increment, {name, opts}}
  end

  def set(value, name, opts \\ %{}) do
    GenServer.cast __MODULE__, {:set, {name, value, opts}}
  end

  def event(title, message, opts \\ %{}) do
    GenServer.cast __MODULE__, {:event, {title, message, opts}}
  end

  # Private API

  def handle_cast({:increment, {name, opts}}, statsd) do
    DogStatsd.increment statsd, @prefix <> name, opts
    {:noreply, statsd}
  end

  def handle_cast({:set, {name, value, opts}}, statsd) do
    DogStatsd.set statsd, @prefix <> name, value, opts
  end

  def handle_cast({:event, {title, message, opts}}, statsd) do
    DogStatsd.event statsd, title, message, opts
    {:noreply, statsd}
  end
end
