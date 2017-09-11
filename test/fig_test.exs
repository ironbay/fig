defmodule FigTest do
  use ExUnit.Case
  doctest Fig

  test "greets the world" do
    assert Fig.hello() == :world
  end
end
