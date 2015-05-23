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
        subreddit = response.matches.first.first
        arg = response.matches.first[1]
        if arg.length > 0
          if /^\d+$/ =~ arg
            n = arg.to_i
            if n.between?(1, 25)
              response.reply api_subreddit(subreddit, n)
            else
              response.reply "Please specify a number between 1 and 25"
            end
          else
            response.reply api_subreddit_search(subreddit, arg)
          end
        else
          response.reply api_subreddit(subreddit, rand(1..25))
        end
      end

      private
      def api_search(query)
        http_response = http.get(
          "https://www.reddit.com/search.json",
          q: query,
          sort: "top",
          t: "all"
        )
        return nil if http_response.status != 200
        posts = MultiJson.load(http_response.body)["data"]["children"]
        return nil if posts.empty?
        format_post(posts.first)
      end

      private
      def api_subreddit(subreddit, n)
        http_response = http.get("https://www.reddit.com/r/#{subreddit}.json")
        return "/r/#{subreddit} is a private subreddit" if http_response.status == 403
        return "/r/#{subreddit} is an invalid subreddit" if http_response.status != 200
        posts = MultiJson.load(http_response.body)["data"]["children"]
        return "No posts found under /r/#{subreddit}" if posts.empty?
        return "/r/#{subreddit} doesn't have that many posts" if posts.length < n
        format_post(posts[n-1])
      end

      private
      def api_subreddit_search(subreddit, query)
        http_response = http.get(
          "https://www.reddit.com/r/#{subreddit}/search.json",
          q: query,
          restrict_sr: true,
          sort: "relevance",
          t: "all"
        )
        return "/r/#{subreddit} is a private subreddit" if http_response.status == 403
        return "/r/#{subreddit} is an invalid subreddit" if http_response.status != 200
        posts = MultiJson.load(http_response.body)["data"]["children"]
        return "No posts found for '#{query}' in /r/#{subreddit}" if posts.empty?
        format_post(posts.first)
      end

      private
      def format_post(post)
        title = post["data"]["title"]
        author = post["data"]["author"]
        subreddit = post["data"]["subreddit"]
        date = Time.at(post["data"]["created"]).to_datetime.strftime("%F")
        score = post["data"]["score"].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        id = post["data"]["id"]
        nsfw = post["data"]["over_18"] ? "[NSFW] " : ""
        "#{nsfw}#{title} - #{author} on /r/#{subreddit}, #{date} (#{score} points) http://redd.it/#{id}"
      end

    end

    Lita.register_handler(Snoo)
  end
end
