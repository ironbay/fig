defmodule Fig do
  defmacro __using__(_opts) do
    quote do
      import Fig

      @definitions %{}

      def get(application, [key | path]) do
        application
        |> Application.get_env(key)
        |> Dynamic.get(path)
      end

      @before_compile Fig
    end
  end

  defmacro config(application, items) do
    {map, _} = Code.eval_quoted(items)

    funs =
      map
      |> Dynamic.flatten()
      |> Enum.map(fn {path, value} ->
        full =
          [application | path]
          |> Enum.join("_")
          |> String.to_atom()

        quote do
          def unquote(full)() do
            get(unquote(application), unquote(path))
          end
        end
      end)

    layers =
      map
      |> Dynamic.layers()
      |> Stream.filter(fn
        {[], _} -> false
        _ -> true
      end)
      |> Enum.map(fn {path, value} ->
        full =
          [application | path]
          |> Enum.join("_")
          |> String.to_atom()

        IO.inspect(value)

        quote do
          def unquote(full)() do
            get(unquote(application), unquote(path))
          end
        end
      end)

    [
      quote do
        @definitions Map.put(@definitions, unquote(application), unquote(items))
      end,
      quote do
        def unquote(application)() do
          Application.get_all_env(unquote(application)) |> Enum.into(%{})
        end
      end
    ] ++ funs ++ layers
  end

  defmacro __before_compile__(_env) do
    quote do
      def definitions, do: @definitions

      def load(loader) do
        loader.load(definitions())
      end
    end
  end
end

defmodule Fig.Example do
  use Fig

  config :test, %{
    a: %{
      cool: "nice",
      fine: "lol"
    },
    b: nil
  }
end

defmodule Fig.Loader.Env do
  def load(definitions) do
    definitions
    |> Dynamic.flatten()
    |> Enum.reduce(%{}, fn {path, value}, collect ->
      Dynamic.put(collect, path, Dynamic.default(variable(path), value))
    end)
    |> Stream.flat_map(fn {application, entries} ->
      Enum.map(entries, fn {key, value} -> {application, key, value} end)
    end)
    |> Enum.each(fn {application, key, value} -> Application.put_env(application, key, value) end)
  end

  defp variable(path) do
    str =
      path
      |> Enum.join("_")
      |> String.upcase()
      |> System.get_env()

    try do
      {result, _} = Code.eval_string(str)
      result
    rescue
      _ -> str
    end
  end
end
