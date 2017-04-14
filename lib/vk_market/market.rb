module VkMarket
  class Market
    def initialize(secret, shop)
      raise ArgumentError, 'shop_id must be negative' if shop.to_i >= 0
      @shop = shop
      raise ArgumentError, 'app_id missing' if secret['app_id'].to_s.empty?
      raise ArgumentError, 'app_secret missing' if secret['app_secret'].to_s.empty?
      raise ArgumentError, 'redirect_uri missing' if secret['redirect_uri'].to_s.empty?
      VkontakteApi.configure do |config|
        config.app_id = secret['app_id']
        config.app_secret = secret['app_secret']
        config.redirect_uri = secret['redirect_uri']
      end
    end

    def logger=(logger)
      @logger = logger
      VkontakteApi.configure do |config|
        config.logger = logger
        config.log_requests  = true
        config.log_errors    = true
        config.log_responses = false
      end
    end

    def log(data)
      return unless @logger
      @logger.info data
    end

    def auth(secret)
      @auth = Auth.new(self, secret)
      @auth.authorizate_with_url_and_mechanize
      @vk = VkontakteApi::Client.new(@auth.token)
    end

    def auth_browser
      @auth = Auth.new(self)
      url = @auth.authorizate_with_browser
      {
        url: url,
        state: @auth.state
      }
    end

    def auth_code(code)
      @vk = VkontakteApi.authorize(code: code)
      @vk.is_app_user?
    end

    def get
      log 'get products (0.1.8)'
      loaded = 0
      per_page = 200
      list = []
      count = 1
      while count > loaded
        products = @vk.market.get(owner_id: @shop, extended: true, count: per_page, offset: loaded)
        count = products.shift
        products.each do |json|
          list << Product.parse(json)
        end
        loaded += per_page
        log "parsed #{loaded} of #{count}"
        sleep 0.4
      end
      list
    end

    def add(product)
      product.save_images(self)
      sleep 0.4
      resp = @vk.market.add(product.to_params(owner_id: @shop))
      product.id = resp['market_item_id']
    rescue NoMethodError
      if @failed
        return
      else
        @failed = true
        sleep 1
        retry
      end
    end

    def edit(product)
      product.save_images(self)
      if product.id.to_i.zero?
        raise ArgumentError, "You've requested update for product without id!"
      end
      sleep 0.3
      @vk.market.edit(product.to_params(owner_id: @shop, item_id: product.id))
    end

    def get_by_id(product_id)
      sleep 0.3
      list = @vk.market.get_by_id(item_ids: "#{@shop}_#{product_id}", extended: true)
      count = list.shift
      return nil if count < 1 # maybe it's empty?
      return nil if list[0]['id'].to_i < 1 # or maybe it has no id?
      Product.parse(list[0])
    end

    def get_albums
      log 'get albums'
      sleep 0.3
      albums = @vk.market.get_albums(owner_id: @shop)
      albums.shift
      albums.map { |json| Album.parse(json) }
    end

    def add_album(album)
      @vk.market.add_album(owner_id: @shop, title: album.title)
    end

    def add_to_album(product, album_ids)
      return unless album_ids && album_ids.any?
      sleep 0.3
      @vk.market.add_to_album(owner_id: @shop,
                              item_id: product.id,
                              album_ids: album_ids.join(','))
    end

    def remove_from_album(product, album_ids)
      return unless album_ids && album_ids.any?
      sleep 0.3
      @vk.market.remove_from_album(owner_id: @shop,
                                   item_id: product.id,
                                   album_ids: album_ids.join(','))
    end

    def reorder_items(album, product, options = {})
      sleep 0.3
      @vk.market.reorder_items(
        options.merge(owner_id: @shop, album_id: album, item_id: product)
      )
    end

    def upload(file, content_type = 'image/jpg', main_photo = 0)
      # get upload url
      sleep 0.3
      resp = @vk.photos.get_market_upload_server(group_id: -@shop, main_photo: main_photo)

      # make upload to url
      url = resp['upload_url']
      if content_type.nil?
        content_type = @photo_path =~ /\.png/ ? 'image/png' : 'image/jpeg'
      end
      sleep 0.3
      img = VkontakteApi.upload(url: url, photo: [file, content_type])

      # save photo as market photo
      sleep 0.3
      saved = @vk.photos.save_market_photo(img.merge(group_id: -@shop))
      raise StandardError, "Image upload failed for #{file}" if saved.size.zero?

      # return int id of photo
      saved[0]['pid']
    end
  end
end
