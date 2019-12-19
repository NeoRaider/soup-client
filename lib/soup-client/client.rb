require 'faraday'
require 'nokogiri'
require 'http-cookie'

module Soup
  class Client
    attr_accessor :login, :password

    def initialize(login, password)
      @login    = login
      @password = password
      @jar      = HTTP::CookieJar.new
    end

    def faraday(url)
      Faraday.new(url) do |b|
        b.use Faraday::Request::UrlEncoded
        b.use Faraday::Response::Logger
        b.use Faraday::Adapter::NetHttp
      end
    end

    def handle_cookies(page)
      @jar.parse(page.headers["set-cookie"], page.env.url)
      return page
    end

    def get_token(url)
      page = nil
      loop do
        agent = faraday url
        page = handle_cookies(agent.get do |req|
          req.headers["Cookie"] = HTTP::Cookie.cookie_value @jar.cookies(url)
        end)
        break unless page.status == 302
        url = page.headers['location']
      end

      html = Nokogiri::HTML(page.body)
      html.css("meta[name='csrf-token']")[0]['content']
    end

    def post(url, data)
      agent = faraday url
      handle_cookies(agent.post(url, data) do |req|
        req.headers["Cookie"] = HTTP::Cookie.cookie_value @jar.cookies(url)
      end)
    end

    def login
      token = get_token 'https://www.soup.io/login'

      data = { auth: token, authenticity_token: token, login: @login, password: @password, commit: 'Log in' }
      page = post 'https://www.soup.io/login', data
      raise 'Login failed.' unless page.status >= 200 && page.status < 400
    end

    def get_default_request
      token = get_token "https://#{@login}.soup.io/"

      {
        'utf8' => '✓',
        'authenticity_token' => token,
        'post[source]' => '',
        'post[body]' => '',
        'post[id]' => '',
        'post[parent_id]' => '',
        'post[original_id]' => '',
        'post[edited_after_repost]' => '',
        'nsfw' => 'on',
        'redirect' => '',
        'commit' => 'Save'
      }
    end

    def post_submit(request)
      page = post "https://#{@login}.soup.io/save", request
      raise 'Post failed.' unless page.status >= 200 && page.status < 400
    end

    def new_link(url, title = '', description = '')
      request = get_default_request()
      request['post[type]'] = 'PostLink'
      request['post[source]'] = url
      request['post[title]'] = title
      request['post[body]'] = description

      post_submit(request)
    end

    def new_image(url, source = '', description = '')
      request = get_default_request()
      request['post[type]'] = 'PostImage'
      request['post[url]'] = url
      request['post[source]'] = source
      request['post[body]'] = description

      post_submit(request)
    end

    def new_text(text, title = '')
      request = get_default_request()
      request['post[type]'] = 'PostRegular'
      request['post[title]'] = title
      request['post[body]'] = text

      post_submit(request)
    end

    def new_quote(quote, source)
      request = get_default_request()
      request['post[type]'] = 'PostQuote'
      request['post[body]'] = quote
      request['post[title]'] = source

      post_submit(request)
    end

    def new_video(youtube_url, description = '')
      request = get_default_request()
      request['post[type]'] = 'PostVideo'
      request['post[embedcode_or_url]'] = youtube_url
      request['post[body]'] = description

      post_submit(request)
    end
  end
end
