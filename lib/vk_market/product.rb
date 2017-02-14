module VkMarket
  class Product
    def initialize
      @photo_paths = []
      @albums_ids = []
      @position = 50
    end

    attr_accessor :id, :owner_id, :title, :description, :price, :currency,
                  :category, :date, :availability, :albums_ids, :photos,
                  :photo_paths, :photo_path, :deleted, :last_photo_updated_at,
                  :last_vk_photo, :position

    def parse(options)
      @id = options['id']
      @owner_id = options['owner_id']
      @title = options['title']
      @description = options['description']
      @price = options['price']['amount']
      @currency = options['price']['currency']['id']
      @category = options['category']['id']
      @date = options['date']
      @availability = options['availability']
      @albums_ids = options['albums_ids'] if options['albums_ids']
      photos = options['photos'].map { |json| Photo.parse(json) }
      # @last_vk_photo = photos.map(&:date).max # unsupported :(
      photos = photos.map(&:id)
      @photo_id = photos.shift
      @photo_ids = photos
    end

    def to_params(extra = {})
      {
        name: @title,
        description: @description,
        category_id: @category,
        price: @price,
        deleted: @deleted,
        main_photo_id: @photo_id,
        photo_ids: @photo_ids
      }.merge(extra)
    end

    def save_images(market)
      unless @photo_path.to_s.empty?
        @photo_id = market.upload(@photo_path, nil, 1)
        @photo_path = nil
      end
      if @photo_paths.size > 0
        @photo_paths = @photo_paths[0..3]
        @photo_ids = @photo_paths.map do |photo_path|
          market.upload(photo_path, nil, 0)
        end
        @photo_paths = []
      end
    end

    def sync_albums(market, old_albums = [])
      if old_albums && old_albums.any?
        market.remove_from_album(self, old_albums - @albums_ids)
      else
        old_albums = []
      end
      market.add_to_album(self, @albums_ids - old_albums)
    end

    def fill_missing(other)
      @photo_id = other.photo_id
      @photo_ids = other.photo_ids
    end

    class << self
      def parse(options)
        product = Product.new
        product.parse(options)
        product
      end
    end
  end
end
