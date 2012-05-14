# Originally from http://tumble.mlcastle.net/post/17704454324/a-lightweight-migrations-system-for-couchrestrails
#
# The framework for *running* migrations is in migrator.rake; this is
# where the migrations go.
#
# Don't describe migrations (with the rake 'desc' thing) individually
# so they don't show up in rake -T
#
# Running: foreman run rake couch:migrate --trace

namespace :couch do

  namespace :migrations do
    task "001 create_metadata_view" do
      design = CouchStore.get_or_create_design 'pages-metadata'
      design['views']['all'] = {
        :map => "
            function(doc) {
              if (doc.type == 'Page')
                emit(doc._id, [doc.updated_at, doc.site, doc.name])
            }
          "
      }
      design.save
    end
  end

end
