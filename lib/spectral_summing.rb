#!/usr/bin/env ruby
Spectrum = Struct.new( :scan_num, :scan_time, :scan_range, :precursor_mass, :charge_states, :intensities, :mz_values)

class Parser
	attr_accessor :spectra
	def initialize(file)
		@file = file
	end
	def parse(file = nil)
		file ||= @file
		require 'ms/msrun'
		@spectra = []
		Ms::Msrun.open(file) do |ms|
			ms.each(:ms_level => 2) do |scan|
				@spectra << Spectrum.new(scan, scan.num, scan.time, (scan.start_mz..scan.end_mz), scan.precursor.mz, scan.precursor.charge_states, scan.spectrum.intensities, scan.spectrum.mzs)
			end
		end
	end
	def parse_by_scan_num(scan_nums, file = nil)
		file ||= @file
		require 'ms/msrun'
		@spectra = []
		Ms::Msrun.open(file) do |ms|
			scan_nums.map(&:to_i).map do |scan_num|
				scan = ms.scan(scan_num)
				@spectra << Spectrum.new(scan.num, scan.time, (scan.start_mz..scan.end_mz), scan.precursor.mz, scan.precursor.charge_states, scan.spectrum.intensities, scan.spectrum.mzs)
			end
		end
	end
end

class Combiner 
	Defaults = {:bin_window => 0.1, :window_size => 4, :precursor_mass_tolerance_in_ppm =>	10, :tolerant => false}
	attr_accessor :output_spectra
	def initialize(spectra = nil, opts = {})
		@spectra = spectra
		@opts = Defaults.merge(opts)
	end
	def combine(spectrum1, spectrum2)
		tolerance = calculate_daltons_from_ppm(spectrum1.precursor_mass, @opts[:precursor_mass_tolerance_in_ppm] )
		if tolerance.include?(spectrum2.precursor_mass) or @opts[:tolerant]
			data_arr = summer(spectrum1.mz_values, spectrum1.intensities, spectrum2.mz_values, spectrum2.intensities)
		end
		data_arr
	end
	def summer(x1,y1,x2,y2) # What should this return?
		endpoints = (x1+x2).each.minmax
		bin_width = @opts[:bin_window]
		num_bins = ((endpoints.last - endpoints.first)/bin_width).ceil
		data_x = [endpoints.first+bin_width/2.0]
		data_y = Array.new(num_bins, 0)
		j, k = 0,0
		one = [x1,y1]; two = [x2,y2]
		if x1.first == endpoints.first
			data_x[0] = x1.first
			data_y[0] += y1.first
			y1[0] = 0
		elsif x2.first == endpoints.first
			data_x[0] = x2.first
			data_y[0] += y2.first
			y2[0] = 0
		end
		(1..num_bins-1).each do |i|
			data_x[i] = data_x[i-1] + bin_width 
			check = data_x[i] + bin_width/2.0
			#puts "check= #{check}"
			if one.first[j]
				while one.first[j] < check 
					data_y[i] += one.last[j]
					j += 1
					break if one.first[j].nil?
				end
			end
			if two.first[k]
				while two.first[k] < check
					data_y[i] += two.last[k]
					k += 1
					break if two.first[k].nil?
				end
			end
		end
		[data_x, data_y]
	end
	def combine_for_more_combining(spectrum1, spectrum2)
		arr = combine(spectrum1, spectrum2)
		joined_spectrum = Spectrum.new()
		joined_spectrum.precursor_mass = (spectrum1.precursor_mass + spectrum2.precursor_mass)/2.0
		joined_spectrum.mz_values = arr.first
		joined_spectrum.intensities = arr.last
# Spectrum = Struct.new(:scan_num, :scan_time, :scan_range, :precursor_mass, :charge_states, :intensities, :mz_values)
		joined_spectrum
	end
	def calculate_daltons_from_ppm(mass, ppm)
		diff = ppm*mass/1e6
		(mass-diff)..(mass+diff)
	end
	def to_mgf(spectrum, filename)
		File.open(filename,'w') do |out|
			out.puts "BEGIN IONS"
			out.puts "TITLE=Spec1:#{spectrum.precursor_mass}_#{spectrum.charge_states.first}"
			out.puts "CHARGE=#{spectrum.charge_states.to_s}+"
			# our current mzML parser doesn't have scan.time implemented...
			spectrum.mz_values.each_with_index do |mz, i|
				intensity = spectrum.intensities[i]
				out.puts "#{"%.5f" % mz}/t#{"%.5f" % intensity}" unless intensity == 0
			end
			out.puts "END IONS"
		end
	end
	def combine_to_mgf(spectrum1, spectrum2, filename)   # Thanks JOHN!!! Ms-Msrun 0.3.6
		results = combine(spectrum1, spectrum2)
		File.open(filename, 'w') do |out|
			out.puts "BEGIN IONS"
			out.puts "TITLE=Spec1:#{spectrum1.precursor_mass}_Spec2:#{spectrum2.precursor_mass}.#{spectrum1.scan_num}_#{spectrum2.scan_num}_#{spectrum1.charge_states.first}"
			out.puts "CHARGE=#{spectrum1.charge_states.to_s}+"
			# our current mzML parser doesn't have scan.time implemented...
			results.first.each_with_index do |mz, i|
				intensity = results.last[i]
				out.puts "#{"%.5f" % mz}/t#{"%.5f" % intensity}" unless intensity == 0
			end
			out.puts "END IONS"
		end
	end
end

if ARGV.size == 0 or ARGV.size % 2 != 0
	puts "Usage: #{__FILE__} input_file.mzXML scan_nums.txt input_file2.mzXML scan_nums2.txt ... "
	puts "NOTE: scan_nums.txt files must have a new line break between each integer value."
	puts 'Returns input_file_input_file2_..._input_file(n).mgf'
	exit
else
	mzXMLs = []
	scan_nums = []
	while ARGV.size > 0
		mzXMLs << ARGV.shift
		scan_nums << ARGV.shift
	end
	scan_nums.map {|file|	IO.readlines(file) }
# Parse the files and put the data into spectra objects, held within the list of all spectra to combine.
	spectras = []
	mzXML.each_with_index do |file, i|
		@parse_object = Parser.new(file)
		@parse_object.parse_by_scan_num(scan_nums[i])
		spectras << @parse_object.spectra
	end
	combined_spectrum = spectras.shift
	combiner = Combiner.new(combined_spectrum)
	spectras.each do |spectrum|
		combined_spectrum = combiner.combine_for_more_combining(combined_spectrum, spectrum)
	end
	combiner.to_mgf(combined_spectrum, 'combined_multiple_files.mgf')
end

		


	
