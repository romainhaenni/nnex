defmodule NNex.Utils do
  def struct_keys(module), do: Map.keys(module.__struct__) |> List.delete(:__struct__)

  def create_unique_id(), do: UUID.uuid1()

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list
    |> :erlang.list_to_pid
  end
end
