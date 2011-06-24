Spectrum = Struct.new(:spectrum, :scan_num, :scan_time, :scan_range, :precursor_mass, :charge_states, :intensities, :mz_values)

class Parser
	attr_accessor :spectra
	def initialize(file)
		parse(file)
	end
	def parse(file)
		require 'ms/msrun'
		@spectra = []
		Ms::Msrun.open(file) do |ms|
			ms.each(:ms_level => 2) do |scan|
				@spectra << Spectrum.new(scan, scan.num, scan.time, (scan.start_mz..scan.end_mz), scan.precursor.mz, scan.precursor.charge_states, scan.spectrum.intensities, scan.spectrum.mzs)
			end
		end
	end
end

class Combiner 
	Defaults = {:bin_window => 0.1, :window_size => 4, :precursor_mass_tolerance_in_ppm =>	10, :tolerant => false}
	attr_accessor :output_spectra
	def initialize(spectra, opts = {})
		@spectra = spectra
		@opts = Defaults.merge(opts)
	end
	def combine(spectrum1, spectrum2)
		tolerance = calculate_daltons_from_ppm(spectrum1.precursor_mass, @opts[:precursor_mass_tolerance_in_ppm] )
		if tolerance.include?(spectrum2.precursor_mass) or @opts[:tolerant]
			bin(spectrum1.mz_values, spectrum1.intensities, spectrum2.mz_values, spectrum2.intensities)
		end
	end
	def bin(x1,y1,x2,y2) # What should this return?
		endpoints = (x1+x2).each.minmax
		bin_width = @opts[:bin_window]
		num_bins = ((endpoints.last - endpoints.first)/bin_width).ceil
		data_x = [endpoints.first+bin_width/2.0]
		data_y = Array.new(num_bins, 0)
		j, k = 0,0; one = [x1,y1]; two = [x2,y2]
		data_y[0] = ( x1.first == endpoints.first ? y1.first : y2.first )
		(1..num_bins).each do |i|
			data_x[i] = data_x[i-1] + bin_width
			check = data_x[i] + bin_width/2.0
			puts "check= #{check}"
			if one.first[j]
				while one.first[j] < check 
					puts 'while loop 1 init'
					p one.first[j]
					p one.last[j]

					data_y[i] += one.last[j]
					j += 1
					break if one.first[j].nil?
				end
			end
			if two.first[k]
				while two.first[k] < check
					puts 'while loop 2 init'
					p two.first[k] 
					p two.last[k]
					data_y[i] += two.last[k]
					k += 1
					break if two.first[k].nil?
				end
			end
		end
		[data_x, data_y]
	end
	def calculate_daltons_from_ppm(mass, ppm)
		diff = ppm*mass/1e6
		(mass-diff)..(mass+diff)
	end
end

=begin
x1 = Array.new(2,1)
y1 = Array.new(2,2)
x2 = Array.new(2,3)
y2 = Array.new(2,4)
a = Combiner.new('hello')
p a.bin(x1,y1,x2,y2)

=end
