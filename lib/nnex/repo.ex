defmodule NNex.Repo do
  use GenServer
  
  alias :mnesia, as: Mnesia
  alias NNex.{Utils}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :repo)
  end

  def init(_args) do
    create_database()

    {:ok, %{}}
  end

  def new(struct) do
    GenServer.call(:repo, {:new, struct})
  end

  def create(struct) do
    GenServer.call(:repo, {:create, struct})
  end

  def save(struct) do
    GenServer.call(:repo, {:save, struct})
  end

  def find(module, id) do
    GenServer.call(:repo, {:find, module, id})
  end

  def handle_call({:new, struct}, _from, repo) do
    id = Utils.create_unique_id()

    {:reply, %{struct | id: id}, repo}
  end

  def handle_call({:create, struct}, _from, repo) do
    id = Utils.create_unique_id()

    struct_to_save = %{struct | id: id}

    {:atomic, :ok} =
      Mnesia.transaction(fn ->
        Mnesia.write({struct_to_save.__struct__, id, struct_to_save})
      end)

    {:reply, struct_to_save, repo}
  end

  def handle_call({:find, module, id}, _from, repo) do
    {:atomic, resultset} =
      Mnesia.transaction(fn ->
        Mnesia.read({module, id})
      end)
    
    case List.first(resultset) do
      {_, _, found_struct} -> 
        {:reply, found_struct, repo}

      nil ->
        {:reply, [], repo}
    end
  end

  def handle_call({:save, struct}, _from, repo) do
    {:atomic, :ok} =
      Mnesia.transaction(fn ->
        Mnesia.write({struct.__struct__, struct.id, struct})
      end)

    {:reply, struct, repo}
  end

  def terminate(:normal, _repo) do
    Mnesia.stop()
    Mnesia.delete_schema([node()])
  end

  def reset() do
    Mnesia.stop()
    Mnesia.delete_schema([node()])
  end

  def create_database() do
    Mnesia.create_schema([node()])
    Mnesia.start()
    ~w(Agent Cortex Neuron Sensor Actuator Population Specie)
    |> Enum.map(&Mnesia.create_table(String.to_atom("Elixir.NNex.#{&1}"), [attributes: [:id, :struct]]))
  end
end
