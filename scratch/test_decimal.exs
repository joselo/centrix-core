
Mix.install([:decimal])

d = Decimal.from_float(10.5) |> Decimal.round(2)
IO.inspect(Decimal.to_string(d, :normal), label: "10.5 rounded 2")

d2 = Decimal.new("10.50")
IO.inspect(Decimal.to_string(d2, :normal), label: "10.50 new")

d3 = Decimal.new("10") |> Decimal.round(2)
IO.inspect(Decimal.to_string(d3, :normal), label: "10 rounded 2")
