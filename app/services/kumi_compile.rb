class KumiCompile
  def self.call(src)
    begin
      ast,_ = Kumi::Frontends::Text.load(src:)
      res = Kumi::Analyzer.analyze!(ast, side_tables: true)
      js_src = res.state[:javascript_codegen_files]["codegen.mjs"]
      ruby_src = res.state[:ruby_codegen_files]&.dig("codegen.rb")
      schema_digest = res.state[:schema_digest]

      input_form_schema = res.state[:input_form_schema]
      output_schema = res.state[:output_schema]
      lir_text = format_lir(res.state[:lir_module]) if res.state[:lir_module]

      {
        ok: true,
        js_src: js_src,
        ruby_src: ruby_src,
        schema_digest: schema_digest,
        input_form_schema: input_form_schema,
        output_schema: output_schema,
        lir: lir_text
      }
    rescue => e
      Rails.logger.error "Kumi compilation failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      { ok: false, errors: [e.message] }
    end
  end

  private

  def self.format_lir(lir_module)
    return nil unless lir_module
    Kumi::Support::LIRPrinter.print(lir_module, show_stamps: true, show_locations: false)
  end
end
