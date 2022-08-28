module Pig::ImageHelper
  # TODO: get this working
  # def holding_image(geo_string, options = {})
  #   filename = File.dirname(__FILE__) + "/../../assets/images/holding.png"
  #   image_tag(Dragonfly[:images].fetch(filename).thumb(geo_string).url, options)
  # end

  def image_placeholder(geo_string, options = {})
    width, height = width_height_from_geo_string(geo_string)
    if options.delete(:photo)
      image_url = 'http://lorempixel.com'.tap do |url|
        url << '/g' if options.delete(:grayscale)
        url << "/#{width}/#{height}"
        categories = %w(abstract animals business cats city food nightlife fashion people nature sports technics transport)
        url << "/#{options.delete(:category).presence || categories.sample}"
        url << "/#{options.delete(:number)}" if options[:number].present?
        url << "/#{options.delete(:text)}" if options[:text].present?
      end
    else
      image_url = 'https://via.placeholder.com/'.tap do |url|
        url << [width, height].compact.join('x')
        url << "&text=#{CGI.escape(options.delete(:text))}" if options[:text].present?
      end
    end
    options[:image_url] ? '' : image_tag(image_url, options)
  end

  def dragonfly_image_tag(*args)
    options = args.extract_options!
    image = args[0]
    geo_string = args[1]
    url = geo_string.blank? ? image.url : image.thumb(geo_string).url
    image_tag(url, options)
  end

  def image_for(*args)
    options = args.extract_options!
    object = args[0]
    geo_string = args[1]
    width, _height = width_height_from_geo_string(geo_string)
    options.reverse_merge!(alt: "#{(truncate(object.to_s || '', length: (width || 50).to_i / 6))}", method: 'image')
    image = object.send(options.delete(:method)) if object
    if image
      Pig::ImageDownloader.download_image_if_missing(image) if Rails.env.development?
      dragonfly_image_tag(image, geo_string, options)
    elsif object.respond_to?(:default_image) && object.default_image
      dragonfly_image_tag(object.default_image, geo_string, options)
    else
      options[:text] = options.delete(:placeholder_text)
      image_placeholder(geo_string, options)
    end
  end

  def width_height_from_geo_string(geo_string)
    res = geo_string.blank? ? nil : geo_string.match(/(\d+)x?(\d*)/)
    res ? [(res[1].blank? ? nil : res[1].to_i), (res[2].blank? ? nil : res[2].to_i)] : [nil, nil]
  end
end
