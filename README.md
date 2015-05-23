# lita-snoo

[![Build Status](https://travis-ci.org/tristaneuan/lita-snoo.png?branch=master)](https://travis-ci.org/tristaneuan/lita-snoo)
[![Coverage Status](https://coveralls.io/repos/tristaneuan/lita-snoo/badge.png)](https://coveralls.io/r/tristaneuan/lita-snoo)

**lita-snoo** is a handler for [Lita](https://github.com/jimmycuadra/lita) that fetches posts from a given subreddit, and finds the original reddit posts for imgur (or custom) URLs it detects.

## Installation

Add lita-snoo to your Lita instance's Gemfile:

``` ruby
gem "lita-snoo"
```

## Configuration

### Optional attributes

* `domains` (`Array` of `String`s) - An array of domains that, if matched by a detected URL, will return a corresponding reddit post. Default: `["imgur.com"]`

``` ruby
Lita.configure do |config|
  config.handlers.snoo.domains = ["imgur.com", "youtube.com"]
end
```

## Usage

Lita will automatically detect links from imgur (or any domains you've defined in the config) and return the corresponding reddit post if it exists.
```
<me>   http://i.imgur.com/Eh3HkJ9.jpg
<lita> Looking down San Francisco's California Street towards the Bay Bridge. - zauzau on /r/pics, 2014-10-18 (4,927 points) http://redd.it/2jl5np
```

You can also ask her to retrieve a reddit post for a given URL directly.
```
<me>   lita: reddit https://www.flickr.com/photos/walkingsf/4671581511
<lita> Where photos in San Francisco are taken by tourists (red) vs locals (blue) - hfutrell on /r/sanfrancisco, 2015-05-14 (267 points) http://redd.it/35yr3b
```

Sending Lita a subreddit command will display a random post from the front page of that subreddit.
```
<me>   lita: /r/todayilearned
<lita> TIL Mozart had a "startling fondness" for poop jokes, which is preserved in his surviving letters. - DJDomTom on /r/todayilearned, 2015-05-23 (1,918 points) http://redd.it/36w2xp
```

If you specify a numerical argument N, she will return the Nth post.
```
<me>   lita: /r/Fitness 1
<lita> New to Fittit? We saw you coming and have collected answers to your questions right here! - eric_twinge on /r/Fitness, 2014-05-08 (2,161 points) http://redd.it/2501op
```

Specifying a string argument will search for that text within the given subreddit and return the top result.
```
<me>   lita: /r/sanfrancisco bart map
<lita> In all of our dreams...the BART map imagined in 1956 - magicgrl111 on /r/sanfrancisco, 2012-10-16 (320 points) http://redd.it/11lbe5
```

## License

[MIT](http://opensource.org/licenses/MIT)
