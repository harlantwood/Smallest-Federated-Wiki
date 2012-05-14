# Originally from http://tumble.mlcastle.net/post/17704454324/a-lightweight-migrations-system-for-couchrestrails
#
# The framework for *running* migrations is in migrator.rake; this is
# where the migrations go.
#
# Don't describe migrations (with the rake 'desc' thing) individually
# so they don't show up in rake -T
#

namespace :migrations do
  # Note: this is just a sample; for changes this trivial, you should just
  # create a CouchRest property with a default value instead.
  task "001 Do Something Exciting" do
    MyClass.all.each do |obj|
      obj["excitement_level"] = 100
      obj.save
    end
  end
end