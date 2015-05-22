require 'uri'

module Lita
  module Handlers
    class Snoo < Handler
      config :domains, type: Array, default: ["imgur.com"]

      route(/(#{URI.regexp})/, :ambient_url, command: false)
      route(/^(?:reddit|snoo)\s+(#{URI.regexp})/i, :url, command: true,
            help: {t("help.snoo_url_key") => t("help.snoo_url_value")})
      route(/^\/?r\/(\S+)\s*(.*)/i, :subreddit, command: true,
            help: {t("help.snoo_sub_key") => t("snoo_sub_value")})

      def ambient_url(response)
        domains = /#{config.domains.map {|d| Regexp.escape(d)}.join("|")}/
        url = response.matches.first.first.split("#").first
        if domains =~ url
          post = api_search("url:'#{url}'")
          response.reply post if post
        end
      end

      def url(response)
        url = response.matches.first.first.split("#").first
        post = api_search("url:'#{url}'")
        if post
          response.reply post
        else
          response.reply "No reddit posts found for #{url}"
        end
      end

      def subreddit(response)
      end

      private
      def api_search(query)
        http_response = http.get(
          "https://www.reddit.com/search.json",
          q: query,
          sort: "top",
          t: "all"
        )
        posts = MultiJson.load(http_response.body)["data"]["children"]
        return nil if posts.empty?
        format_post(posts.first)
      end

      private
      def api_subreddit()
      end

      private
      def api_subreddit_search()
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
