defmodule Areas.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, [name: :areas])
  end

  @doc """
    Prepare the worlds supervisor.
  """
  def init(params) do
    children = [worker(Area, [], [])]
    supervise(children, strategy: :simple_one_for_one)
  end
end
