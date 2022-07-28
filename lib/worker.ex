defmodule Metex.Worker do
 def loop(results \\ [], results_expected) do
    receive do
      {:ok, result} ->
        new_results = [result|results]
          if results_expected == Enum.count(new_results) do
            send self(), :exit
          end
            loop(new_results, results_expected)
          :exit ->
            IO.puts(results |> Enum.sort |> Enum.join(", "))
        _ ->
      loop(results, results_expected)
    end
  end

  def loop do
    receive do
      {sender_pid, location} ->
        send(sender_pid, {:ok, temperature_of(location)})
      _ ->
        IO.puts "don't know how to process this message"
      end
    loop()
  end

  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get |>parse_response
    case result do
      {:ok, temp} ->
        "#{location}: #{temp}°C"
      {:error, reason} ->
        "#{location}: #{reason}"
    end
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
  end

  # Parse response
  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Jason.decode! |> compute_temperature
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 404}}) do
   response = body |> Jason.decode!
   {:error, response["message"]}
  end

  defp parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp parse_response(_) do
    {:error, "Could not get data"}
  end

  # compute temperature
  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15 |> Float.round(1))
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  # return api key
  defp apikey do
    "921af0c39ce77d837a1dc8315547be5f"
  end
end
