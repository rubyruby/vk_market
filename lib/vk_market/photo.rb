module VkMarket
  class Photo
    def initialize
    end

    attr_accessor :id, :album_id, :owner_id, :user_id, :src, :src_big,
                  :src_small, :src_xbig, :src_xxbig, :width, :height, :text,
                  :date

    def parse(options)
      @id = options['pid']
      @album_id = options['aid']
      @owner_id = options['owner_id']
      @user_id = options['user_id']
      @src = options['src']
      @src_big = options['src_big']
      @src_small = options['src_small']
      @src_xbig = options['src_xbig']
      @src_xxbig = options['src_xxbig']
      @width = options['width']
      @height = options['height']
      @text = options['text']
      @date = options['date']
    end

    class << self
      def parse(options)
        photo = Photo.new
        photo.parse(options)
        photo
      end
    end
  end
end
