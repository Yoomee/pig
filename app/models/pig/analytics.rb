module Pig
  class Analytics

    attr_reader :referrers

    def initialize(results)
      @referrers = results.group_by(&:source).map { |x| Referrer.new(x) }
    end

    def total
      @referrers.collect(&:total).sum
    end

    def as_json(options={})
      {
        total: total,
        referrers: @referrers
      }
    end

  end

  class Referrer
    def initialize(referrer)
      @name = referrer[0]
      @keywords = referrer[1].map { |x| Keyword.new(x) }
    end

    def total
      @keywords.collect(&:total).sum
    end

    def as_json(options={})
      {
        name: @name,
        total: total,
        keywords: @keywords
      }
    end

  end

  class Keyword

    attr_reader :word, :total

    def initialize(keyword)
      @word = keyword.keyword
      @total = keyword.pageviews.to_i
    end

    def as_json(options={})
      {
        total: @total,
        word: @word
      }
    end
  end

end
