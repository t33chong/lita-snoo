require "spec_helper"

describe Lita::Handlers::Snoo, lita_handler: true do

  it { is_expected.to route("http://i.imgur.com/Eh3HkJ9.jpg").to(:ambient_url) }
  it { is_expected.to route("http://imgur.com/Eh3HkJ9").to(:ambient_url) }
  it { is_expected.to route("http://imgur.com/gallery/jS4pO").to(:ambient_url) }
  it { is_expected.to route("http://imgur.com/a/pAJJi").to(:ambient_url) }
  it { is_expected.to route("https://www.flickr.com/photos/walkingsf/4671581511").to(:ambient_url) }

  it { is_expected.to route_command("reddit http://accent.gmu.edu/").to(:url) }
  it { is_expected.to route_command("SNOO http://accent.gmu.edu/").to(:url) }

  it { is_expected.to route_command("/r/AskReddit").to(:subreddit) }
  it { is_expected.to route_command("R/AskReddit 1").to(:subreddit) }
  it { is_expected.to route_command("/r/linguistics lambda calculus").to(:subreddit) }

  context "with the default config" do

    describe "#ambient_url" do

      it "returns the top reddit post for a detected imgur.com link" do
        send_message "i hella miss the city yadadamean http://imgur.com/Eh3HkJ9"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-1\d \(\d{1,3},\d{3}\ points\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "returns the top reddit post for a detected i.imgur.com link" do
        send_message "http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-1\d \(\d{1,3},\d{3}\ points\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "does not return anything for a detected imgur link if it has not been submitted to reddit" do
        send_message "http://imgur.com/noa9Jcb"
        expect(replies.count).to eq 0
      end

      it "does not return anything for a detected non-imgur link" do
        send_message "https://www.flickr.com/photos/walkingsf/4671581511"
        expect(replies.count).to eq 0
      end

      it "marks NSFW posts" do
        send_message "http://i.imgur.com/t15BFZh.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).to start_with("[NSFW] ")
      end

      it "strips anything following # from URLs" do
        send_message "http://i.imgur.com/Eh3HkJ9.jpg#.png"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-1\d \(\d{1,3},\d{3}\ points\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "unescapes strings that have been HTML-escaped" do
        send_message "http://i.imgur.com/HdIgRSq.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).not_to match(/&amp;/)
      end

    end

    describe "#url" do

      it "returns the top reddit post for a given link" do
        send_command "reddit http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-1\d \(\d{1,3},\d{3}\ points\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "returns an appropriate message for a given link if it has not been submitted to reddit" do
        send_command "snoo http://imgur.com/noa9Jcb"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^No reddit posts found for http:\/\/imgur\.com\/noa9Jcb$/)
      end

    end

    describe "#subreddit" do

      it "returns a random post from the top 25 for a given subreddit" do
        send_command "/r/askreddit"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^.+ - \S+ on \/r\/AskReddit, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points\) http:\/\/redd\.it\/\w+$/)
      end

      it "returns the nth post for a given subreddit when n is specified" do
        send_command "/r/AskReddit 2"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^.+ - \S+ on \/r\/AskReddit, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points\) http:\/\/redd\.it\/\w+$/)
      end

      it "returns the most relevant result for a given subreddit-specific search query" do
        send_command "/r/linguistics lambda calculus"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Intro to lambda calculus \(for linguists!\) - leftoversalad on \/r\/linguistics, 2015-02-1\d \(\d+ points\) http:\/\/redd\.it\/2w4ir4$/)
      end

      it "returns an appropriate message when no results can be found for a given subreddit-specific search query" do
        send_command "/r/linguistics ChuqKmv8oRQdHqp7"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^No posts found for 'ChuqKmv8oRQdHqp7' in \/r\/linguistics$/)
      end

      it "returns an appropriate message when the subreddit in a given subreddit-specific search query does not exist" do
        send_command "/r/ChuqKmv8oRQdHqp7 linguistics"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^\/r\/ChuqKmv8oRQdHqp7 is an invalid subreddit$/)
      end

      it "marks NSFW posts" do
        send_command "/r/spacedicks"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^\[NSFW\] .+ - \S+ on \/r\/spacedicks, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points\) http:\/\/redd\.it\/\w+$/)
      end

      it "returns an appropriate message when the given subreddit does not exist" do
        send_command "/r/ChuqKmv8oRQdHqp7"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^\/r\/ChuqKmv8oRQdHqp7 is an invalid subreddit$/)
      end

      it "returns an appropriate message when the given subreddit is empty" do
        send_command "/r/thingsjonsnowknows"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^No posts found under \/r\/thingsjonsnowknows$/)
      end

      it "returns an appropriate message when the given subreddit is private" do
        send_command "/r/amaninacan"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^\/r\/amaninacan is a private subreddit$/)
      end

      it "returns an appropriate message when the given subreddit has fewer than n posts" do
        send_command "/r/Onepostsubreddits 25"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^\/r\/Onepostsubreddits doesn't have that many posts$/)
      end

      it "returns an appropriate message when n is not between 1 and 25" do
        send_command "/r/AskReddit 26"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Please specify a number between 1 and 25$/)
      end

    end

  end

  context "with custom domains defined in the config" do

    before(:each) do
      registry.config.handlers.snoo.domains = ["flickr.com", "gmu.edu"]
    end

    describe "#ambient_url" do

      it "returns the top reddit post for a detected link on a custom domain" do
        send_message "https://www.flickr.com/photos/walkingsf/4671581511 not surprised about union square, trying to maneuver through all the tourists with their phones out gives me a bad case of irritable powell syndrome"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Where photos in San Francisco are taken by tourists \(red\) vs locals \(blue\) - hfutrell on \/r\/sanfrancisco, 2015-05-1\d \(\d{3} points\) http:\/\/redd\.it\/35yr3b$/)
      end

      it "returns the top reddit post for a detected link on a different custom domain" do
        send_message "http://accent.gmu.edu/"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Ever wonder what an Armenian accend sounds like\? How about a Swahili Accent\? This site has them all\. - topemo on \/r\/reddit\.com, 2006-04-0\d \(\d{2} points\) http:\/\/redd\.it\/3udn$/)
      end

      it "does not return anything for a detected link on a custom domain if it has not been submitted to reddit" do
        send_message "https://www.flickr.com/photos/apelad/2812456702"
        expect(replies.count).to eq 0
      end

      it "does not return anything for an imgur link" do
        send_message "http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 0
      end

    end

    describe "#url" do

      it "only returns one post when a given link is in the list of custom domains" do
        send_command "snoo https://www.flickr.com/photos/walkingsf/4671581511"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Where photos in San Francisco are taken by tourists \(red\) vs locals \(blue\) - hfutrell on \/r\/sanfrancisco, 2015-05-1\d \(\d{3} points\) http:\/\/redd\.it\/35yr3b$/)
      end

      it "returns an appropriate message for a given link if it has not been submitted to reddit" do
        send_command "snoo http://imgur.com/noa9Jcb"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^No reddit posts found for http:\/\/imgur\.com\/noa9Jcb$/)
      end

    end

  end

end
