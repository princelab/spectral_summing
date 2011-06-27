Gem::Specification.new do |s|
	s.name = %q{ms-spectral_summing}
	s.version = "0.0.2"
	s.date = %q{2011-06-27}
	s.authors = "Ryan M Taylor"
	s.email = "ryanmt@byu.net"
	s.summary = "Ms-spectral_summing provides a utility for the combination of multiple scans from mzXML files into a single MGF file.  It provides both an API and a generic use via the command line.  This relies upon the proven utility of the ms-msrun library."
	s.homepage = %q{https://github.com/princelab/spectral_summing}
	s.description = "This is the utility built for summing of individual MS(n) spectra in order to bolster the signal of weak fragmentation.  It provides an API and a command-line interface for general use."
	s.files = [ "README.rdoc", "LICENSE.txt", 'lib/spectral_summing.rb', 'bin/spectral_summing.rb']
end
