module VkMarket
  class ProductsSet
    def initialize
      @products = []
      @albums = []
      @report = []
    end

    attr_accessor :products, :albums, :report

    def read_from_shop(market)
      @market = market
      @products = @market.get
      @albums = @market.get_albums
    end

    def sync_market(other)
      raise StandardError, 'No market assigned with this set' unless @market
      @market.log 'sync start'
      save_new_and_update_old_products(other)
      mark_as_deleted_missing_products(other)
      reorder_products_in_albums(other)
      @market.log 'sync end'
    end

    def find_product_by_id(product_id)
      return nil if product_id.nil?
      @products.find { |p| p.id == product_id }
    end

    def products_by_alumbs
      hash = {}
      @products.each do |product|
        product.albums_ids.each do |album|
          hash[album] ||= []
          hash[album] << product
        end
      end
      hash
    end

    def after_save(&block)
      @after_save_callback = block
    end

    private

    def save_new_and_update_old_products(other)
      other.products.each do |product|
        original = find_product_by_id(product.id)
        if original
          update(product, original)
        else
          # maybe it is deleted?
          deleted_product = @market.get_by_id(product.id)
          if deleted_product
            @products << deleted_product
            update(product, deleted_product)
          else
            insert(product)
          end
        end
        @after_save_callback.call(product) if @after_save_callback
      end
    end

    def mark_as_deleted_missing_products(other)
      @products.each do |product|
        new_product = other.find_product_by_id(product.id)
        next if new_product
        product.deleted = 1
        @market.edit(product)
      end
    end

    def reorder_products_in_albums(other)
      other.products_by_alumbs.each do |album, products|
        @market.log 'Reorder album?'
        next if products.map(&:position).uniq.size < 2
        @market.log "orders: #{products.map(&:position).join(',')}"
        list = products.sort_by(&:position)
        list.select(&:saved).reduce do |after, this|
          # "insert #{this} after #{after}"
          begin
            @market.reorder_items(album, this.id, after: after.id)
          rescue VkontakteApi::Error => exception
            @market.log exception
            @report << [this, exception.message]
          end
          this
        end
      end
    end

    def update(product, original)
      product.fill_missing(original)
      @market.edit(product)
      product.sync_albums(@market, original.albums_ids)
      @report << [product, :updated]
      product.saved = true
    rescue VkontakteApi::Error => exception
      @market.log exception
      @report << [product, exception.message]
    end

    def insert(product)
      @market.add(product)
      product.sync_albums(@market, [])
      @report << [product.title, :created]
      product.saved = true
    rescue VkontakteApi::Error => exception
      @market.log exception
      @report << [product, exception.message]
    end
  end
end
