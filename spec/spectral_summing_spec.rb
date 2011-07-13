require 'spec_helper'

describe "Parser" do 
	it 'generates arrays of Structs containing the necessary data' do # should make it easy to graph anything I want with that structure
		@test = TESTFILES + '/test.mzXML'
		@result = Parser.new(@test)
		@result.parse
		@result.spectra.class.should.equal Array
	end
	it 'also can only catch the spectra objects that correlate with a given scan number' do 
		@mzXML = TESTFILES + '/test.mzXML'
		@txt = TESTFILES + '/test.txt'
		@parser = Parser.new(@mzXML)
		scan_nums = @parser.parse_scan_nums(@txt)
		scan_nums.class.should.equal Array
		p scan_nums
		@parser.parse_by_scan_num(scan_nums)
		spectra = @parser.spectra
		spectra.class.should.equal Array
	end
end
=begin
describe 'Comparer' do 
	it 'takes two spectra, returns a correlation score' do 
	end
	it 'reduces the weight of differences in intensity' do
	end
	it 'determines the number of matches to expect based upon the mass of the precursor' do 
	end
	it 'tolerates #{Precision} error in the precursor masses (normally this can be 1 m/z wide' do 
	end
	it 'expects RT differences to fall within a nominal window, unless comparing between scans' do
	end
end
=end
describe "Combiner" do
	before do 
		@x1 = [167.08880615234375, 175.2530517578125, 177.22677612304688, 181.20526123046875, 182.240478515625, 183.1397247314453, 183.90548706054688, 185.23345947265625, 186.3767852783203, 187.24366760253906]
		@y1 = [2.614011764526367, 19.853052139282227, 5.9615044593811035, 6.357842445373535, 5.079195022583008, 2.2274322509765625, 8.529345512390137, 22.411785125732422, 1.846116065979004, 2.229602575302124]
		@x2 = [187.24366760253906, 191.0662384033203, 195.14126586914062, 197.20376586914062, 199.3022918701172, 200.21475219726562, 201.06857299804688, 202.2320556640625, 203.39401245117188, 205.27679443359375, 207.0498809814453, 208.42347717285156]
		@y2 = [100000, 1.4693498611450195, 4.156303882598877, 39.14124298095703, 16.008852005004883, 5.559536457061768, 1.8495380878448486, 2.0385212898254395, 2.418201208114624, 1.8486547470092773, 7.051799297332764, 2.423830032348633]
		@combiner = Combiner.new 'hello'
		@c = @combiner.summer(@x1,@y1,@x2,@y2)
	end
	it 'bins and sums the spectra correctly' do 
#		x = @c.first
#		y = @c.last
#		(0..@c.first.length-1).each do |i|
#			puts "#{x[i]}, #{y[i]}"
#		#	puts "#{x[i+1]}, #{y[i+1]}"
#		#	puts "#{x[i+2]}, #{y[i+2]}"
#		end
		@c.last[202].should.equal 100002.2296025753
	end
#  it 'aligns the two spectras' do 
#	end
#	it 'sums the intensity values and produces a combined spectra' do 
#	end
	it 'generates an mgf file' do 
		test = TESTFILES + '/test.mzXML'
		@result = Parser.new(test)
		@result.parse_by_scan_num([1,2,3])
		p @result.spectra
		puts @result.spectra.size
		@result.spectra.each_with_index do |a, i|
			puts a.precursor_mass
			puts i
		end
			@combiner.combine_to_mgf(@result.spectra[192], @result.spectra[194], 'testing.mgf')
	end
end
=begin
describe 'bin_for_chris' do 
	before do 
		@x1 = [167.08880615234375, 175.2530517578125, 177.22677612304688, 181.20526123046875, 182.240478515625, 183.1397247314453, 183.90548706054688, 185.23345947265625, 186.3767852783203, 187.24366760253906]
		@y1 = [2.614011764526367, 19.853052139282227, 5.9615044593811035, 6.357842445373535, 5.079195022583008, 2.2274322509765625, 8.529345512390137, 22.411785125732422, 1.846116065979004, 2.229602575302124]
		@x2 = [187.24366760253906, 191.0662384033203, 195.14126586914062, 197.20376586914062, 199.3022918701172, 200.21475219726562, 201.06857299804688, 202.2320556640625, 203.39401245117188, 205.27679443359375, 207.0498809814453, 208.42347717285156]
		@y2 = [100000, 1.4693498611450195, 4.156303882598877, 39.14124298095703, 16.008852005004883, 5.559536457061768, 1.8495380878448486, 2.0385212898254395, 2.418201208114624, 1.8486547470092773, 7.051799297332764, 2.423830032348633]
		@combiner = Combiner.new 'hello'
		@c = @combiner.summer(@x1,@y1,@x2,@y2)
		@chris = @combiner.bin_for_chris([[@x1, @y1],[@x2, @y2]])
	end
	it 'works' do 
		@chris.size.should.equal 2
	end
end
=end
