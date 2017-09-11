defmodule Fig do
	defmacro __using__(opts) do
		quote do

		end
	end

	defmacro defconfig(name, opts = [env: env, default: default]) do
		quote do
			def unquote(name) do
				unquote(env)
				|> System.get_env || unquote(default)
			end
		end
	end
end

defmodule Fig.Example do
	import Fig

	defconfig foo, env: "FOO", default: "bar"

end
