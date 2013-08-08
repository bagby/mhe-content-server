require 'net/http'
require 'uri'
require 'uuidtools'

run ->(env) {
  uri = URI.join('http://en.wikipedia.org', env['PATH_INFO'])
  uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, uri.to_s)
  response = Net::HTTP.get_response(uri)
  html = response.body
  bodypos = html.index("</body>")
  snippet = <<-HTML
<script type="text/javascript" src="http://mhe-metadata-server.herokuapp.com/asset-tagger.js"></script>
<script type="text/javascript">
  MheMetadata.loadContentId('#{uuid}');
</script>
HTML
  html.insert(bodypos, snippet) if bodypos
  [200, {'Content-Type' => 'text/html'}, [response.body]]
}
