module VkMarket
  class ProductsSet
    def initialize
      @products = []
      @albums = []
    end

    attr_accessor :products, :albums

    def read_from_shop(market)
      @market = market
      @products = @market.get
      @albums = @market.get_albums
    end

    def sync_market(other)
      raise StandardError, 'No market assigned with this set' unless @market
      save_new_and_update_old_products(other)
      mark_as_deleted_missing_products(other)
      reorder_products_in_albums(other)
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

    private

    def save_new_and_update_old_products(other)
      other.products.each do |product|
        original = find_product_by_id(product.id)
        if original
          update(product, original)
        else
          # maybe it is deleted?
          deleted_product = @market.get_by_id(product.id)
          @products << deleted_product
          if deleted_product
            update(product, deleted_product)
          else
            @market.add(product)
          end
        end
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
        list = products.sort_by(&:position)
        list.reduce do |after, this|
          # "insert #{this} after #{after}"
          @market.reorder_items(album, this.id, after: after.id)
          this
        end
      end
    end

    def update(product, original)
      product.fill_missing(original)
      @market.edit(product)
      product.sync_albums(@market, original.albums_ids)
    end
  end
end
