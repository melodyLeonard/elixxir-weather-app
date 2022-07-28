defmodule Metex do
  def temperatures_of(cities) do
    cordinator_pid =
      spawn(Metex.Cordinator, :loop, [[], Enum.count(cities)])
        cities |> Enum.each(fn city ->
        worker_pid = spawn(Metex.Worker, :loop, [])
      send worker_pid, {cordinator_pid, city}
    end)
  end
end
