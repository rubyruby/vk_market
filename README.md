# VkMarket

This gem used to sync your products with VK Market

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vk_market'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vk_market

It is important to use latest version of `vkontakte_api` gem with `market.` namespace support. Be sure you required the latest version in your Gemfile

```ruby
gem 'vkontakte_api', github: '7even/vkontakte_api'
```

## Usage

First call intializer with your VK APP credentials

```ruby
market = VkMarket::Market.new(options, shop_id)
```

`shop_id` is some negative number with group id
`options` is a hash with string keys:
* `'app_id'` is provided by VK App settings
* `'app_secret'` is provided by VK App settings
* `'redirect_uri'` any url when userless authentication

You can also setup logger to debug what's happens

```ruby
market.logger = Logger.new($stdout)
```

Next you must authenticate. This gem support userless authentication by typing login and password in login form. It is not good solution but it is only way for unapproved VK application to authenticate without youser.

```ruby
market.auth(options)
```

`options` is a hash with string keys:
* `'login'` is email or phone for vk login
* `'password'` is vk password

After authentication you must generate two product sets. One is product set from vk.com market

```ruby
products = VkMarket::ProductsSet.new
products.read_from_shop(market)
```

Second is your actual products list

```ruby
my_products = VkMarket::ProductsSet.new
```

You can fill it with VkMarket::Product instances

```ruby
product = VkMarket::Product.new
product.title = 'Product title'
product.description = 'Product description'
product.id = 574_442 # id of product if it was previously synced. Left it blank to create new product
product.category = 601 # id of category from VK Market categories list
product.price = 199
product.deleted = 0
product.photo_path = 'path/to/main/image.jpg'
product.photo_paths << 'path/to/some/extra/image.jpg' # up to 4 extra images allowed
product.albums_ids = [2] # list of album ids
product.position = 10 # position used for reorder product in albums. Product with mininal position is on top
my_products.products << product # add new product to ProductSet
```

The last step is to run sync on you old products with new set

```ruby
products.sync_market(my_products)
```

## Contributing

Bug reports and pull requests are welcome on ruslan@13f.ru.
