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
      snast_text = format_snast(res.state[:snast_module])

      {
        ok: true,
        js_src: js_src,
        ruby_src: ruby_src,
        schema_digest: schema_digest,
        input_form_schema: input_form_schema,
        output_schema: output_schema,
        lir: lir_text,
        snast: snast_text
      }
    rescue => e
      Rails.logger.error "Kumi compilation failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      error_info = parse_error_location(e.message)
      { ok: false, errors: [error_info] }
    end
  end

  private

  def self.parse_error_location(message)
    # Try to extract from "file:line:column:" prefix first
    if message =~ /^\S+:(\d+):(\d+):/
      line = ::Regexp.last_match(1).to_i
      column = ::Regexp.last_match(2).to_i
      # Strip the prefix from message
      full_message = message.sub(/^\S+:\d+:\d+:\s+/, '')
      # Extract just the error text (before code frame)
      error_text = extract_error_text(full_message)

      {
        message: full_message,
        error_text: error_text,
        line: line,
        column: column
      }
    # Fall back to "line=N column=M" format
    elsif message =~ /line=(\d+)\s+column=(\d+)/
      line = ::Regexp.last_match(1).to_i
      column = ::Regexp.last_match(2).to_i
      full_message = message.gsub(/\s+at\s+\S+\s+line=\d+\s+column=\d+/, '').strip
      error_text = extract_error_text(full_message)

      {
        message: full_message,
        error_text: error_text,
        line: line,
        column: column
      }
    else
      { message: message }
    end
  end

  def self.extract_error_text(message)
    # Extract lines before the code frame
    # Code frame lines have format: "N |", "  |", or "➤ N |"
    lines = message.split("\n")
    error_lines = []

    lines.each do |line|
      # Stop at code frame lines (contain " |" or start with ➤ or just numbers and pipe)
      break if line.match?(/\|\s/) || line.match?(/^\s+\|/) || line.match?(/^➤/)
      error_lines << line
    end

    error_lines.join("\n").strip
  end

  def self.format_lir(lir_module)
    return nil unless lir_module
    Kumi::Support::LIRPrinter.print(lir_module, show_stamps: true, show_locations: false)
  end

  def self.format_snast(snast_module)
    Kumi::Support::SNASTPrinter.print(snast_module)
  end
end
