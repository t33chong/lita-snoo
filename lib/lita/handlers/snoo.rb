require 'uri'

module Lita
  module Handlers
    class Snoo < Handler
      config :domains, type: Array, default: ["imgur.com"]

      route(/(#{URI.regexp})/, :url_search, command: false)
      route(/^(?:reddit|snoo)\s+(#{URI.regexp})/i, :url_search, command: true,
            help: {t("help.snoo_url_key") => t("help.snoo_url_value")})
      route(/^\/?r\/(\S+)\s*(.*)/i, :subreddit, command: true,
            help: {t("help.snoo_sub_key") => t("snoo_sub_value")})

      def url_search(response)
        domains = /#{config.domains.map {|d| Regexp.escape(d)}.join("|")}/
        url = response.matches.first.first.split("#").first
        # Lita::Message#command?
        if response.message.command?
          response.reply api_search(url, true)
        elsif domains =~ url
          post = api_search(url)
          response.reply post if post
        end
      end

      def subreddit(response)
      end

      private
      def api_search(url, command=false)
        http_response = http.get(
          "https://www.reddit.com/search.json",
          q: "url:'#{url}'",
          sort: "top",
          t: "all"
        )
        posts = MultiJson.load(http_response.body)["data"]["children"]
        if posts.empty?
          if command
            return "No reddit posts found for #{url}"
          else
            return nil
          end
        end
        format_post(posts.first)
      end

      private
      def format_post(post)
        title = post["data"]["title"]
        author = post["data"]["author"]
        subreddit = post["data"]["subreddit"]
        date = Time.at(post["data"]["created"]).to_datetime.strftime("%F")
        score = post["data"]["score"].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        ups = post["data"]["ups"].to_f
        downs = post["data"]["downs"].to_f
        percent = "%.f" % (ups / (ups + downs) * 100)
        id = post["data"]["id"]
        nsfw = post["data"]["over_18"] ? "[NSFW] " : ""
        "#{nsfw}#{title} - #{author} on /r/#{subreddit}, #{date} (#{score} points, #{percent}% upvoted) http://redd.it/#{id}"
      end

    end

    Lita.register_handler(Snoo)
  end
end
