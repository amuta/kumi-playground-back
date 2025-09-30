class KumiCompile
  def self.call(src)
    ast = Kumi::Parser::TextParser.parse(src)
    res = Kumi::Analyzer.analyze!(ast, side_tables: true)
    js_src = res.state[:javascript_codegen_files]["codegen.js"]

    { ok: true, js_src: js_src }
  rescue => e
    { ok: false, errors: e.message }
  end
end
