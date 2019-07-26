defmodule Kindlenotes2evernote.CLI do
  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [file: :string], aliases: [f: :file])
    opts
  end

  def process([]) do
    IO.puts("No arguments given")
  end

  def process(opts) do
    chunk_fn = fn
      elem, [] ->
        {:cont, [elem]}

      element, acc ->
        if String.match?(element, ~r{^==========$}) do
          # new highlight
          {:cont, [acc], []}
        else
          # append to current highlight
          {:cont, Enum.reverse([element | acc])}
        end
    end

    after_fn = fn chunk -> {:cont, chunk, []} end

    File.stream!(opts[:file], [:utf8], :line)
    |> Enum.map(&String.replace(&1, "\uFEFF", ""))
    |> Enum.map(&String.trim/1)
    |> Enum.chunk_while([], chunk_fn, after_fn)
    |> Enum.each(&write_note/1)
  end

  def write_note(element) do
    Enum.group_by(element, fn v -> Enum.fetch!(v, 1) end, fn v ->
      Enum.slice(v, 2, Enum.count(v))
    end)
    |> IO.inspect()
  end
end
