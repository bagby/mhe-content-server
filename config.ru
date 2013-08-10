require 'net/http'
require 'uri'
require 'uuidtools'

class WikiProxy
  def call(env)
    request = Rack::Request.new(env)

    unless request.get?
      return [405, {'content-length' => '0'}, ['']]
    end

    if request.path == '/w/api.php'
      return [200, {'content-type' => 'application/json; charset=utf-8', 'content-length' => '2'}, ['{}']]
    end

    uri      = URI.join('http://en.wikipedia.org', request.path)
    uuid     = make_uuid(uri)
    response = Net::HTTP.get_response(uri)

    code    = response.code.to_i
    body    = process_body(response, uuid)
    headers = process_headers(response, request.host_with_port, body.bytesize)

    [code, headers, [body]]
  end

  def process_body(response, uuid)
    body = response.body
    return body unless response.content_type == 'text/html'

    headpos = body.index("</head>")
    return body unless headpos

    style = <<-HTML
<style type="text/css">
#mw-navigation { display: none; }
div#content, div#footer { margin-left: 260px; }
.metadata { display: none; }
</style>
HTML
    body.insert(headpos, style)

    bodypos = body.index("</body>")
    return body unless bodypos

    snippet = <<-HTML
<script type="text/javascript" src="http://mhe-metadata-server.herokuapp.com/asset-tagger.js"></script>
<script type="text/javascript">
  MheMetadata.loadContentId('#{uuid}');
</script>
HTML
    body.insert(bodypos, snippet)
  end

  def process_headers(response, host_with_port, body_bytesize)
    headers = {}
    response.each_header do |key, value|
      next if key == 'content-length'
      if key == 'location'
        value.gsub!(/en\.wikipedia\.org/, host_with_port)
      end
      headers[key] = value
    end
    headers['content-length'] = body_bytesize.to_s
    headers
  end

  def make_uuid(uri)
    UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, uri.to_s)
  end
end

run WikiProxy.new
