require 'nokogiri'
require 'anemone'
require 'pry'
# 巡回起点となるURL
URL = 'https://mamoria.jp/mycaremane'.freeze

area_urls = []
prefecture_urls = []
city_urls = []
# サイト内を巡回する記述
Anemone.crawl(URL, depth_limit: 0, delay: 2) do |anemone|
  # 各ページごとに巡回するリンク先を指定することができる。
  anemone.focus_crawl do |page|
    # 次にクロールする候補リスト
    page.links.keep_if do |link|
      link.to_s.match(%r{mycaremane/[0-9]{1,2}})
    end
    page.links.each do |link|
      area_urls << link
    end
  end
end

area_urls.each do |area|
  Anemone.crawl(area, depth_limit: 0, delay: 2) do |anemone|
    anemone.focus_crawl do |page|
      page.links.keep_if do |link|
        link.to_s.match(%r{mycaremane/[0-9]{1,2}/[0-9]{5}})
      end
      page.links.each do |link|
        prefecture_urls << link
      end
    end
  end
end

prefecture_urls.each do |prefecture|
  Anemone.crawl(prefecture, depth_limit: 1, delay: 2, skip_query_strings: true) do |anemone|
    anemone.focus_crawl do |page|
      page.links.keep_if do |link|
        link.to_s.match(%r{mycaremane/[0-9]{1,2}/[0-9]{5}/[0-9]})
      end
      page.links.each do |link|
        city_urls << link
        logger.debug('~~~~~~画像受け取り~~~~~')
        logger.debug(city_urls)
        logger.debug('~~~~~~画像受け取り~~~~~')
      end
    end

    PATTERN = %r[mycaremane/[0-9]{1,2}/[0-9]{5}/[0-9]].freeze

    anemone.on_pages_like(PATTERN) do |page|
      url = page.url.to_s

      str = url.to_s

      html = URI.parse(url).open
      # ここからスクレイピングの記述
      doc = Nokogiri::HTML.parse(html, nil, 'UTF-8')

      name = doc.xpath('/html/body/div[4]/div/div[2]/div[1]/h1').text
      pos = doc.xpath('/html/body/div[4]/div/div[2]/table[1]/tbody/tr[3]/td/text()[1]').text
      post = pos.strip
      postcode = post.match(/[0-9]{7}/)
      add = doc.xpath('/html/body/div[4]/div/div[2]/table[1]/tbody/tr[3]/td/text()[2]').text
      address = add.strip
      tel = doc.xpath('/html/body/div[4]/div/div[2]/table[1]/tbody/tr[4]/td').text
      fax = doc.xpath('/html/body/div[4]/div/div[2]/table[1]/tbody/tr[5]/td').text
      staff_number = doc.xpath('/html/body/div[4]/div/div[2]/table[4]/tbody/tr[1]/td/p').text
      company = doc.xpath('/html/body/div[4]/div/div[2]/table[5]/tbody/tr[2]/td').text
      office_url = doc.xpath('/html/body/div[4]/div/div[2]/table[1]/tbody/tr[6]/td/a').text
      # 正規表現でURLから5桁市区町村コードを抜き出す
      if str =~ %r{/(\d{5})(/|$)}
        city_number = Regexp.last_match(1)
        p Regexp.last_match(1)
      end

      offices = Office.new(name: name,
                           postcode: postcode,
                           tel: tel,
                           fax: fax,
                           address: address,
                           staff_number: staff_number,
                           company: company,
                           url: office_url,
                           city_number: city_number)
      offices.save(validate: false)

      # 事業所画像テーブルの雛形を作成
      id = offices.id
      office_images_position = %i[top left right]
      office_images_position.each do |position|
        i = position == :top ? 5 : 1
        i.times { |_x| OfficeImage.create!(position: position, office_id: id) }
      end
    end
  end
end
