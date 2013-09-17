require "yaml"
require "net/http"
require "uri"
require "pp"
require "json"

$config = YAML.load(open('config.yml'))

def main
  items = []
  Dir.glob($config['th_path'] + "/**/*.dtd") do |th_path|
    th_path_array = th_path.split(/\//)
    en_path = $config['en_path'] + "/" + th_path_array[2] + "/locales/en-US/" + File.join(th_path_array[3..-1])
    if File.exists?(en_path)
      th_tr = read_dtd(th_path)
      en_tr = read_dtd(en_path) 
      items += cook(en_tr, th_tr, th_path, "DTD")
    end
  end

  Dir.glob($config['th_path'] + "/**/*.properties") do |th_path|
    th_path_array = th_path.split(/\//)    
    en_path = $config['en_path'] + "/" + th_path_array[2] + "/locales/en-US/" + File.join(th_path_array[3..-1])
    if File.exists?(en_path)
      th_tr = read_prop(th_path)
      en_tr = read_prop(en_path) 
      items += cook(en_tr, th_tr, th_path, "PROP")
    end
    
  end
  puts JSON.dump(items)
end

def cook(en_tr, th_tr, th_path, type)
  tr_items = []
  en_hash = {}
  en_tr.each do |tr|
    en_hash[tr["key"]] = tr["value"]
  end
  th_tr.each do |tr|
    if en_hash.has_key?(tr["key"])
      item = {en: en_hash[tr["key"]], th: tr["value"], key: tr["key"], th_path: th_path, type: type}
      tr_items << item
    end
  end
  tr_items
end

def read_dtd(path)
  translations = []
  File.open(path) do |file|
    raw = file.read
    uri = URI($config["dtd_reader_url"])
    Net::HTTP.start(uri.host, uri.port) do |http|
      res = http.post(uri.path, raw) 
      translations = JSON.parse(res.body)
    end 
  end
  translations
end

def read_prop(path)
  translations = []
  File.open(path) do |file|
    while file.gets
      line = $_.chomp
      if not line =~ /^#/ and not line =~ /^\s*$/
        k, v = line.split("=")
        translations << {"key" => k, "value" => v}
      end
    end
  end
  translations
end

main
