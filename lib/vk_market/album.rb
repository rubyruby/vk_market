module VkMarket
  class Album
    def initialize
    end

    attr_accessor :id, :owner_id, :title, :count, :updated_time

    def parse(options)
      @id = options['id']
      @owner_id = options['owner_id']
      @title = options['title']
      @count = options['count']
      @updated_time = options['updated_time']
    end

    class << self
      def parse(options)
        album = Album.new
        album.parse(options)
        album
      end
    end
  end
end
