defmodule Kindlenotes2evernote.CLI do
  @tmp_file "res.txt"

  def main(args) do
    args |> parse_args |> process
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [file: :string], aliases: [f: :file])
    opts
  end

  defp process([]) do
    IO.puts("No arguments given")
  end

  defp process(opts) do
    File.stream!(opts[:file], [:utf8], :line)
    |> clean_entry
    |> split_highlights
    |> Stream.flat_map(&parse_highlight(&1))
    |> Stream.filter(fn hl -> hl.content.highlight != "" end)
    |> regoup_by_title
    |> write_to_evernote
  end

  defp clean_entry(source) do
    Stream.map(source, &String.replace(&1, "\uFEFF", ""))
    |> Stream.map(&String.trim/1)
  end

  defp split_highlights(source) do
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
    Stream.chunk_while(source, [], chunk_fn, after_fn)
  end

  defp parse_highlight(notes) do
    Stream.map(notes, fn v ->
      %{
        title: Enum.fetch!(v, 1),
        content: %{info: Enum.fetch!(v, 2), highlight: Enum.fetch!(v, 3)}
      }
    end)
  end

  defp regoup_by_title(element) do
    Enum.group_by(element, &Map.get(&1, :title), &Map.get(&1, :content))
  end

  defp write_to_evernote(notes) when is_map(notes) do
    Enum.each(notes, fn {k, v} -> write_note(k, v) end)
  end

  defp write_note(title, content) do
    text =
      Enum.map(content, fn note -> Map.get(note, :info) <> "\n" <> Map.get(note, :highlight) end)
      |> Enum.join("\n\n")

    converted = :erlyconv.from_unicode(:cp1252, text)
    File.write(@tmp_file, converted)
    EvernoteService.create_note(@tmp_file, title)
    File.rm(@tmp_file)
  end
end
