module VkMarket
  class Auth
    def initialize(market, secret)
      @market = market
      @secret = secret
    end

    def authorizate_with_url_and_mechanize(scope = [:market, :photos])
      receive_url(scope)
      fill_password
      parse_token
    end

    attr_reader :token

    private

    def receive_url(scope)
      @market.log 'AUTH: begin'
      @state = Digest::MD5.hexdigest(rand.to_s)
      @url = VkontakteApi.authorization_url(
        scope: scope,
        state: @state,
        type: :client
      )
      @market.log "AUTH: go to url: #{@url}"
    end

    def fill_password
      # Fake auth using login and password
      @market.log 'AUTH: using mechanize to visit in'
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows Chrome'
      login_page = @agent.get(@url)
      fill_login_form(login_page)
    end

    def fill_login_form(login_page)
      login_form = login_page.forms.first
      @market.log 'AUTH: form received'
      login_form.email = @secret['login']
      login_form.pass = @secret['password']
      @response_page = login_form.submit
    end

    def parse_token
      @market.log "AUTH: Redirected to #{@response_page.uri}"
      unless @response_page.uri.fragment
        resp = @response_page.body
        @market.log "Auth required allowing something!"
        if resp =~ /href = "(.*)"/
          @response_page = @agent.get($1)
        else
          raise StandardError, "Unhandled redirect result\n #{@response_page.body}"
        end
      end
      auth_params = CGI.parse(@response_page.uri.fragment)
      @token = auth_params['access_token'].first

      @market.log "AUTH: token received: #{@token}"
    end
  end
end
