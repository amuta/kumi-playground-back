class KumiCompile
  def self.call(src)
    begin
      ast,_ = Kumi::Frontends::Text.load(src:)
      res = Kumi::Analyzer.analyze!(ast, side_tables: true)
      js_src = res.state[:javascript_codegen_files]["codegen.js"]
      ruby_src = res.state[:ruby_codegen_files]&.dig("codegen.rb")
      schema_digest = res.state[:schema_digest]

      { ok: true, js_src: js_src, ruby_src: ruby_src, schema_digest: schema_digest }
    rescue => e
      Rails.logger.error "Kumi compilation failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      { ok: false, errors: [e.message] }
    end
  end
end
