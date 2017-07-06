#wkhtmltopdf-binary makes sures that this binary is installed to the rvm bin directory
#rvm makes sure that the bin directories of rvm are added to your PATH
#so please DON'T set this yourself when using the gem wkhtmltopdf-binary!
WickedPdf.config = {
  :exe_path => "#{ENV['GEM_HOME']}/bin/wkhtmltopdf"
}
