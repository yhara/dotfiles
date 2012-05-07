def mac?
  false #TODO
end

gems = %w(reposh git-hub rak ifchanged myrurema heroku mechanize gisty rainbow rbenv-rehash)
gems.concat %w(powder graph) if mac?

cmd = "gem i #{gems.join ' '}"
puts cmd
system cmd
