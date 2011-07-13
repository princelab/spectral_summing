#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: spectral_summing.rb input_file.mzXML scan_nums.txt input_file2.mzXML scan_nums2.txt ..."
	opts.separator "NOTE: scan_nums.txt files must have a new line break between each integer value."
	opts.separator 'Returns: input_file_input_file2_..._input_file(n).mgf'
	if ARGV.size == 0
		puts opts
		exit
	end
	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end
	opts.on("-h", "--help", "Show this message") do 
		puts opts
		exit
	end
	opts.on('-c', '--charge N', Integer, "Set the maximum charge state") do |c|
		options[:max_charge] = c
	end
	opts.on("-b", "--bin_size N", Float, "Set the bin size in daltons") do |b|
		options[:bin_size] = b
	end
	opts.on("-p", "--ppm N", Float, "Set the precursor mass window in ppm") do |p|
		options[:precursor_mass_tolerance_in_ppm] = p
	end
	opts.on("-t", "--[no-]tolerant", "Set 'tolerant' option for precursor mass on or off (Default is on)") do |t|
		options[:tolerant] = t
	end
end.parse!
	

Spectrum = Struct.new( :scan_num, :scan_time, :scan_range, :precursor_mass, :charge_states, :precursor_intensity, :intensities, :mz_values)

class Parser
	attr_accessor :spectra, :spectrum
	def initialize(file)
		@file = file
	end
	def parse(file = nil)
		file ||= @file
		require 'ms/msrun'
		@spectra = []
		Ms::Msrun.open(file) do |ms|
			ms.each(:ms_level => 2) do |scan|
				@spectra << Spectrum.new(scan.num, scan.time, (scan.start_mz..scan.end_mz), scan.precursor.mz, scan.precursor.charge_states, scan.precursor.intensity, scan.spectrum.intensities, scan.spectrum.mzs)
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
				@spectra <<  Spectrum.new(scan.num, scan.time, (scan.start_mz..scan.end_mz), scan.precursor.mz, scan.precursor.charge_states, scan.precursor.intensity, scan.spectrum.intensities, scan.spectrum.mzs)
			end
		end
	end
	def parse_scan_nums(file)
		IO.readlines(file).each(&:chomp)
	end
end

class Combiner 
	Defaults = {:bin_window => 0.4, :window_size => 4, :precursor_mass_tolerance_in_ppm =>	10, :tolerant => true, :noise_threshold => 1, :max_charge => 6}
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
	def summer(x1,y1,x2,y2)
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
	def bin_for_chris(array) # arr must contain pairs of data [[x1,y1], [x2,y2], ... ]				# THIS IS STILL A WORK IN PROGRESS
		endpoints = array.map{|arr| arr.first}.reduce(:+).each.minmax
		#puts "__________________________ENDPOINTS_______________________________"
		#p endpoints
		array = array.map{|arr| arr.first.zip(arr.last)}
		#puts "__________________________ARRAYmap zipped_______________________________"
		#p array
		bin_width = @opts[:bin_window]
		num_bins = ((endpoints.last - endpoints.first)/bin_width).ceil
		out_arr = [ ]		#[[mz_value, [arr_of_intensities]], ]
		bottom = endpoints.last
		top = bottom + bin_width
		(0..num_bins-1).each do |i|
			out_arr[i] = [ endpoints.first+i*bin_width, [] ]
			array.each do |arr|
				
			end
		end
	end
	def combine_for_more_combining(spectrum1, spectrum2)
		arr = combine(spectrum1, spectrum2)
		joined_spectrum = Spectrum.new()
		joined_spectrum.precursor_mass = (spectrum1.precursor_mass + spectrum2.precursor_mass)/2.0
		joined_spectrum.mz_values = arr.first
		joined_spectrum.intensities = arr.last
		joined_spectrum.charge_states = (spectrum1.charge_states + spectrum2.charge_states).uniq if spectrum1.charge_states and spectrum2.charge_states
# Spectrum = Struct.new(:scan_num, :scan_time, :scan_range, :precursor_mass, :charge_states, :intensities, :mz_values)
		joined_spectrum
	end
	def calculate_daltons_from_ppm(mass, ppm)
		diff = ppm*mass/1e6
		(mass-diff)..(mass+diff)
	end
	def to_mgf(spectrum, filename)
		charges = spectrum.charge_states ||= (1..@opts[:max_charge]).to_a
		File.open(filename,'w') do |out|
			charges.uniq.each do |charge|
				out.puts "BEGIN IONS"
				out.puts "TITLE=Spec1:#{spectrum.precursor_mass}_#{spectrum.charge_states}"
				out.puts "CHARGE=#{charge}+"
				out.puts "PEPMASS=#{spectrum.precursor_mass} #{spectrum.precursor_intensity}"
				# our current mzML parser doesn't have scan.time implemented...
				threshold = @opts[:noise_threshold]
				outs = spectrum.mz_values.zip(spectrum.intensities)
				while outs.size > 10000
					outs.reject! {|a|	a.last < threshold }
					threshold += 0.5
				end
				outs.each do |arr|
					out.puts "#{"%.5f" % arr.first} #{"%.5f" % arr.last}"
				end
				out.puts "END IONS"
			end #charges
		end
	end
	def combine_to_mgf(spectrum1, spectrum2, filename)   # Thanks JOHN!!! Ms-Msrun 0.3.6
		results = combine(spectrum1, spectrum2)
		File.open(filename, 'w') do |out|
			out.puts "BEGIN IONS"
			out.puts "TITLE=Spec1:#{spectrum1.precursor_mass}_Spec2:#{spectrum2.precursor_mass}.#{spectrum1.scan_num}_#{spectrum2.scan_num}_#{spectrum1.charge_states.first}"
			out.puts "CHARGE=1+"
			out.puts "PEPMASS=#{spectrum1.precursor_mass} #{spectrum1.precursor_intensity + spectrum2.precursor_intensity}"
			# our current mzML parser doesn't have scan.time implemented...
			threshold = opts[:noise_threshold]
			outs = spectrum.mz_values.zip(spectrum.intensities)
			while outs.size > 10000
				outs.reject! {|a|	a.last < threshold }
				threshold += 0.5
			end
			outs.each do |arr|
				out.puts "#{"%.5f" % arr.first} #{"%.5f" % arr.last}"
			end
			out.puts "END IONS"
		end
	end
end
if $0 == __FILE__
	puts "Working" if options[:verbose]
	#puts "ARGV.size = #{ARGV.size}" if options[:verbose]
	if ARGV.size % 2 == 0
		mzXMLs = []
		scan_num_files = []
		while ARGV.size > 0
			mzXMLs << ARGV.shift
			scan_num_files << ARGV.shift
		end
		scan_nums = scan_num_files.map {|file| IO.readlines(file).each(&:chomp) }.reject(&:nil?)
# Parse the files and put the data into spectra objects, held within the list of all spectra to combine.
		spectras = []
		mzXMLs.each_with_index do |file, i|
			@parse_object = Parser.new(file)
			@parse_object.parse_by_scan_num(scan_nums[i])
			spectras << @parse_object.spectra
		end
		spectras.flatten!
		combined_spectrum = spectras.shift
		combiner = Combiner.new(combined_spectrum, options)
		spectras.each do |spectrum|
			combined_spectrum = combiner.combine_for_more_combining(combined_spectrum, spectrum)
		end
		combiner.to_mgf(combined_spectrum, "#{File.basename(mzXMLs.first,'.mzXML')}_combined.mgf")
	else 
		puts "None or not enough files given, use call `#{__FILE__} --help` for more information"
	end
end
		


	
