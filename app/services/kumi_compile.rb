class KumiCompile
  def self.call(src)
    begin
      ast,_ = Kumi::Frontends::Text.load(src:)
      res = Kumi::Analyzer.analyze!(ast, side_tables: true)
      js_src = res.state[:javascript_codegen_files]["codegen.js"]

      { ok: true, js_src: js_src }
    rescue => e
    require "pry"
    binding.pry
      Rails.logger.error e
      { ok: false, errors: e.message }
    end
  end
end
