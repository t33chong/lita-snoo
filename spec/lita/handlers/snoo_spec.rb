require "spec_helper"

describe Lita::Handlers::Snoo, lita_handler: true do

  it { is_expected.to route("http://i.imgur.com/Eh3HkJ9.jpg").to(:url_search) }
  it { is_expected.to route("http://imgur.com/Eh3HkJ9").to(:url_search) }
  it { is_expected.to route("http://imgur.com/gallery/jS4pO").to(:url_search) }
  it { is_expected.to route("http://imgur.com/a/pAJJi").to(:url_search) }
  # TODO: comma-separated imgur IDs?
  it { is_expected.to route_command("reddit http://accent.gmu.edu/").to(:url_search) }
  it { is_expected.to route_command("snoo http://accent.gmu.edu/").to(:url_search) }

  it { is_expected.to route_command("/r/AskReddit").to(:subreddit) }
  it { is_expected.to route_command("r/AskReddit 1").to(:subreddit) }

  describe "#url_search" do

    context "with the default config" do

      it "returns the top reddit post for a detected imgur link" do
        send_message "i hella miss the city yadadamean http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-17 \(\d{1,3},\d{3}\ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "returns the top reddit post for each detected imgur link that has been submitted to reddit when there are multiple links" do
        send_message "http://i.imgur.com/Eh3HkJ9.jpg http://imgur.com/noa9Jcb http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 2
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-17 \(\d{1,3},\d{3}\ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/2jl5np$/)
        expect(replies.last).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-17 \(\d{1,3},\d{3}\ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "does not return anything for a detected imgur link if it has not been submitted to reddit" do
        send_message "http://imgur.com/noa9Jcb"
        expect(replies.count).to eq 0
      end

      it "marks NSFW posts" do
        send_message "http://i.imgur.com/t15BFZh.jpg"
        expect(replies.count).to eq 0
        expect(replies.first).to start_with("[NSFW] ")
      end

      it "sends only one response when called directly with an imgur link" do
        send_message "reddit http://i.imgur.com/Eh3HkJ9.jpg"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-17 \(\d{1,3},\d{3}\ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/2jl5np$/)
      end

      it "strips anything following # from image URLs" do
        send_message "http://i.imgur.com/Eh3HkJ9.jpg#.png"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Looking down San Francisco's California Street towards the Bay Bridge\. - zauzau on \/r\/pics, 2014-10-17 \(\d{1,3},\d{3}\ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/2jl5np$/)
      end

    end

    context "with custom domains defined in the config" do

      before(:all) do
        registry.config.handlers.snoo.domains = ["flickr.com", "gmu.edu"]
      end

      it "returns the top reddit post for a detected link on a custom domain" do
        send_message "https://www.flickr.com/photos/walkingsf/4671581511 not surprised about union square, trying to maneuver through all the tourists with their phones out gives me a bad case of irritable powell syndrome"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Where photos in San Francisco are taken by tourists \(red\) vs locals \(blue\) - hfutrell on \/r\/sanfrancisco, 2015-05-14 \(\d{3} points, \d{1,3}% upvoted\) http:\/\/redd\.it\/35yr3b$/)
      end

      it "returns the top reddit post for each detected link on a custom domain that has been submitted to reddit when there are multiple links" do
        send_message "https://www.flickr.com/photos/walkingsf/4671581511 http://accent.gmu.edu/"
        expect(replies.count).to eq 2
        expect(replies.first).to match(/^Where photos in San Francisco are taken by tourists \(red\) vs locals \(blue\) - hfutrell on \/r\/sanfrancisco, 2015-05-14 \(\d{3} points, \d{1,3}% upvoted\) http:\/\/redd\.it\/35yr3b$/)
        expect(replies.last).to match(/^Ever wonder what an Armenian accend sounds like\? How about a Swahili Accent\? This site has them all\. - topemo on \/r\/reddit\.com, 2006-04-03 \(\d{2} points, \d{1,3}% upvoted\) http:\/\/redd\.it\/3udn$/)
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

    context "when called directly" do

      it "returns the top reddit post for a given link" do
        send_command "reddit http://accent.gmu.edu/"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^Ever wonder what an Armenian accend sounds like\? How about a Swahili Accent\? This site has them all\. - topemo on \/r\/reddit\.com, 2006-04-03 \(\d{2} points, \d{1,3}% upvoted\) http:\/\/redd\.it\/3udn$/)
      end

      it "returns an appropriate message for a given link if it has not been submitted to reddit" do
        send_command "snoo http://imgur.com/noa9Jcb"
        expect(replies.count).to eq 1
        expect(replies.first).to match(/^No reddit posts found for http:\/\/imgur\.com\/noa9Jcb$/)
      end

    end

  end

  describe "#subreddit" do

    it "returns a random post from the top 25 for a given subreddit" do
      send_command "/r/askreddit"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^.+ - \w+ on \/r\/AskReddit, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/\w+$/)
    end

    it "returns the top post for a given subreddit when top is specified" do
      send_command "r/askreddit top"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^.+ - \w+ on \/r\/AskReddit, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/\w+$/)
    end

    it "returns the nth post for a given subreddit when n is specified" do
      send_command "/r/AskReddit 2"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^.+ - \w+ on \/r\/AskReddit, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/\w+$/)
    end

    it "marks NSFW posts" do
      send_command "/r/spacedicks"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^\[NSFW\] .+ - \w+ on \/r\/spacedicks, \d{4}-\d{2}-\d{2} \((?:\d|,)+ points, \d{1,3}% upvoted\) http:\/\/redd\.it\/\w+$/)
    end

    it "returns an appropriate message when the given subreddit does not exist" do
      send_command "/r/ChuqKmv8oRQdHqp7"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^No posts found under \/r\/ChuqKmv8oRQdHqp7$/)
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
      send_command "/r/thingsjonsnowknows 5"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^\/r\/thingsjonsnowknows doesn't have that many posts$/)
    end

    it "returns an appropriate message when n is not between 1 and 25" do
      send_command "/r/AskReddit 26"
      expect(replies.count).to eq 1
      expect(replies.first).to match(/^Please specify a number between 1 and 25$/)
    end

  end

end
