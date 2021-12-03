require 'uri'
require 'net/http'
require 'openssl'
require 'set'
require 'json'

class SearchProgram

	def self.search_online search_text 
		print_result(HttpService.google_search(replace_white_space search_text))
		TextAnalyser.build search_text
	end

	def self.search_local search_text 
		print_result(search_for_local_files_and_folders search_text)
		TextAnalyser.build search_text
	end

	private

	def self.print_result result 
		p result
	end

	def self.replace_white_space search_text
		search_text.gsub(/\s+/, '+')
	end

  def self.search_for_local_files_and_folders search_text
		dir_array = Dir.glob("#{Dir.pwd}/**/*")
		hashed_dir = Set.new dir_array
		(hashed_dir.select { |s| s.include?("#{search_text}")}).first(3)
  end

end

class HttpService

	BASE_GOOGLE_SEARCH_URL = "https://google-search3.p.rapidapi.com/api/v1/search/q="
	KEY = ''
	
  def self.google_search(search_text, result_limit = 3)
  	url = URI(BASE_GOOGLE_SEARCH_URL+"#{search_text}&num=#{result_limit}")

  	client = build_client(url)
  	request = build_request(url)
  	response = client.request(request)
		(JSON.parse response.read_body)["results"]
  end

  private

  def self.build_client url
  	http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		http
  end

  def self.build_request url 
		request = Net::HTTP::Get.new(url)
		request["x-user-agent"] = 'desktop'
		request["x-proxy-location"] = 'US'
		request["x-rapidapi-host"] = 'google-search3.p.rapidapi.com'
		request["x-rapidapi-key"] = KEY
		request
  end

end

class TextAnalyser
	
	def self.build text
		@text = text
	  calculate_and_print_analyzed_text
	end

	private

	def self.calculate_and_print_analyzed_text
		p "Statistik for din søgning: #{@text}"
		p "Antal tegn: #{@text.length}"
		p "Antal bogstaver/tegn/tal: #{character_count_nospaces}"
		p "Antal sammenhængende ord/tal: #{word_count}"
		p "Gennemsnitlig sammenhængende ord/tal længde: #{average_word_lentgh}"
		p "Key/Value Bogstav/Forekomst af bogstav: " 
		p calculate_amount_of_unique_chars get_uniqe_letter_chars
		p "Key/Value Tal/Forekomst af tal: "
		p calculate_amount_of_unique_chars get_uniqe_numbers
		p "Key/Value Tegn/Forekomst af tegn: " 
		p calculate_amount_of_unique_chars get_uniqe_special_chars
	end

	def self.calculate_amount_of_unique_chars array_of_chars
		(is_number? array_of_chars.first) ? (calculate_amount_numbers array_of_chars) : (calculate_amount_letters_and_special array_of_chars)
	end

	def self.calculate_amount_numbers array_of_chars
		hash = {}
		array_of_chars.each do |char|
			hash[char] = @text.scan(/(?=#{char})/).count
		end
		hash
	end

	def self.calculate_amount_letters_and_special array_of_chars
		hash = {}
		array_of_chars.each do |char|
			hash[char] = @text.count(char)
		end
		hash
	end

	def self.character_count_nospaces
		@text.gsub(/\s+/, '').length
	end

	def self.word_count
		@word_count ||= @text.split.length
	end

	def self.all_words
		@all_words ||= @text.scan(/\w+/) 
	end

	def self.average_word_lentgh
		all_words.join.length.to_f / word_count
	end

	def	self.get_uniqe_numbers
		@text.scan(/\d+/).uniq
	end
	
	def	self.get_uniqe_special_chars
		@text.scan(/[^\w\s]/).uniq
	end
	
	def	self.get_uniqe_letter_chars
		@text.scan(/[a-zA-Z]/).uniq
	end

	def self.is_number? string
  	true if Float(string) rescue false
	end 

end
