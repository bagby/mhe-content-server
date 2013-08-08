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
  headers = response.to_hash.inject({}) {|h,p| h[p[0]] = p[1].first; h}
  headers.delete('content-length')
  headers['location'].gsub!(/en\.wikipedia\.org/, env['HTTP_HOST']) if headers.key? 'location'
  html.insert(bodypos, snippet) if bodypos
  [response.code, headers, [html]]
}
