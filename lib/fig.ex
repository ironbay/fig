defmodule Fig.Legacy do
	defmacro __using__(opts) do
		quote do

		end
	end

	defmacro config([{root, value}]) do
		{map, _} =
			value
			|> Code.eval_quoted

		flattened =
			map
			|> Dynamic.flatten
			|> Enum.map(fn {key, value} -> [key, [root] ++ key, value] end)
			|> Enum.map(fn [key, full, value] -> [key, full |> Enum.join("_") |> String.to_atom, value] end)

		result =
			flattened
			|> Enum.map(fn [_, full, value] ->
					uppercase =
						full
						|> Atom.to_string
						|> String.upcase
				quote do
					def unquote(full)() do
						System.get_env(unquote(uppercase)) || unquote(value)
					end
				end
			end)

		[
			quote do
				def unquote(root)() do
					unquote(flattened)
					|> Enum.reduce(%{}, fn [key, full, _], collect ->
						Dynamic.put(collect, key, apply(__MODULE__, full, []))
					end)
				end
			end
			| result
		]
	end

	defmacro defconfig(opts) do
		case Enum.at(opts, 0) do
			{name, {env, default}} -> Fig.create(name: name, env: env, default: default)
			{name, value} -> Fig.create(name: name, env: name |> Atom.to_string |> String.upcase, default: value)
		end
	end

	def create([name: name, env: env, default: default]) do
		quote do
			def unquote(name)() do
				unquote(env)
				|> System.get_env || unquote(default)
			end
		end
	end
end
