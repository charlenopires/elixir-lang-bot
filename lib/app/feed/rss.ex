defmodule App.Feed.Rss do
  alias App.Feed.Formatter

  defmacro __using__(_opts) do
    quote do
      require Logger
      import App.Feed.Rss
      alias App.Persistor
      alias App.Feed.Formatter
      alias App.Stats

      # Public API

      def init do
        Persistor.load_stash @feed_id
      end

      def tick do
        Logger.info "Tick for :#{@feed_id}"

        retreive_feed(@url)
        |> dates_to_timestamp
        |> sort_entries
        |> filter_posted
        |> send_to_channel
      end

      # Private API

      def dates_to_timestamp(feed) do
        fun = case @date_format do
          "rfc3339" ->
            &Formatter.from_rfc3339_to_unix/1
          _ ->
            &Formatter.from_rfc2822_to_unix/1
        end

        feed
        |> Enum.map(fn entry ->
          Map.update(entry, :updated, 0, fun)
        end)
      end

      defp sort_entries(feed) do
        feed
        |> Enum.sort_by(&(Map.fetch!(&1, :updated)), &>=/2)
      end

      defp filter_posted(feed) do
        last_timestamp = case get_last_timestamp() do
          {:error, :none} ->
            Logger.warn "There was no last timestamp for :#{@feed_id}, so we use zero"

            # If there's no last timestamp, assume it's zero so the feed can be
            # populated
            0

          {:ok, value} ->
            value
        end

        Logger.info "Last timestamp for :#{@feed_id} was #{last_timestamp}"

        feed
        |> Enum.filter(fn entry ->
          entry.updated > last_timestamp
        end)
      end

      defp send_to_channel([]), do: Stats.increment("feeds.#{@feed_id}.noop")
      defp send_to_channel(feed) do
        Stats.increment "feeds.#{@feed_id}.update"

        last_entry = feed
                     |> Enum.reverse
                     |> Enum.map(&send_entry/1)
                     |> List.last

        set_last_timestamp last_entry.updated
      end

      defp send_entry(entry) do
        text = Formatter.format_entry entry, @render_mode

        Nadia.send_message @channel, text, parse_mode: @render_mode
        Stats.increment "feeds.#{@feed_id}.entries"

        entry
      end

      # Helpers

      defp get_last_timestamp do
        Persistor.get @feed_id, "last_timestamp"
      end

      defp set_last_timestamp(nil), do: nil
      defp set_last_timestamp(timestamp) do
        Logger.info "Setting :#{@feed_id} last timestamp to #{timestamp}"

        Persistor.set @feed_id, "last_timestamp", timestamp
      end
    end
  end

  def retreive_feed(url) do
    url
    |> get_feed
    |> parse_feed
  end

  defp get_feed(url) do
    {:ok, response} = HTTPoison.get url
    %{body: body} = response
    body
  end

  defp parse_feed(feed) do
    {:ok, feed, _} = FeederEx.parse feed
    feed.entries
  end
end
