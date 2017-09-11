defmodule Fig do
	defmacro __using__(opts) do
		quote do

		end
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

defmodule Fig.Example do
	import Fig

	defconfig foo: "bar"

end
