require 'spec_helper'

describe "Parser" do 
	it 'generates arrays of Structs containing the necessary data' do # should make it easy to graph anything I want with that structure
		@test = TESTFILES + '/test.mzXML'
		@result = Parser.new(@test)
		@result.spectra.class.should.equal Array
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
	end
	it 'bins the spectra correctly' do 
		a = Combiner.new 'hello'
		c = a.bin(@x1,@y1,@x2,@y2)
		x = c.first
		y = c.last
		(0..c.first.length).each do |i|
			puts "#{x[i]}, #{y[i]}"
		end
	end
  it 'aligns the two spectras' do 
	end
	it 'sums the intensity values and produces a combined spectra' do 
	end
end
