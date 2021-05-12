# frozen_string_literal: true

module Decidim
  # Extending Diffy gem to accomodate the needs of app/cells/decidim/diff_cell.rb
  module DiffyExtension
    # HtmlFormatter that returns basic html output (no inline highlighting)
    # and does not escape HTML tags.
    class UnescapedHtmlFormatter < Diffy::HtmlFormatter
      # We exclude the tags `del` and `ins` so the diffy styling does not apply.
      TAGS = (UserInputScrubber.new.tags.to_a - %w(del ins)).freeze

      def to_s
        if @options[:highlight_words]
          str = wrap_lines(highlighted_words)
        else
          str = wrap_lines(@diff.map { |line| wrap_line(line) })
        end

        ActionView::Base.new.sanitize(str, tags: TAGS)
      end

      def highlighted_words
        chunks = @diff.each_chunk.
          reject{|c| c == '\ No newline at end of file'"\n"}

        processed = []
        lines = chunks.each_with_index.map do |chunk1, index|
          next if processed.include? index
          processed << index
          chunk1 = chunk1
          chunk2 = chunks[index + 1]
          if not chunk2
            next chunk1
          end

          dir1 = chunk1.each_char.first
          dir2 = chunk2.each_char.first
          case [dir1, dir2]
          when ['-', '+']
            if chunk1.each_char.take(3).join("") =~ /^(---|\+\+\+|\\\\)/ and
                chunk2.each_char.take(3).join("") =~ /^(---|\+\+\+|\\\\)/
              chunk1
            else
              line_diff = Diffy::Diff.new(
                                          split_characters(chunk1),
                                          split_characters(chunk2),
                                          Diffy::Diff::ORIGINAL_DEFAULT_OPTIONS
                                          )
              hi1 = reconstruct_characters(line_diff, '-')
              hi2 = reconstruct_characters(line_diff, '+')
              processed << (index + 1)
              [hi1, hi2]
            end
          else
            chunk1
          end
        end.flatten
        lines.map{|line| line.each_line.map(&:chomp).to_a if line }.flatten.compact.
          map{|line|wrap_line(line) }.compact
      end

      def split_characters(chunk)
        chunk.gsub(/^./, '').each_line.map do |line|
          if @options[:ignore_crlf]
            (line.chomp.split('') + ['\n']).map{|chr| chr }
          else
            chars = line.sub(/([\r\n]$)/, '').split('')
            # add escaped newlines
            chars << '\n'
          end
        end.flatten.join("\n") + "\n"
      end
    end

    # Adding a new method to Diffy::Format so we can pass the
    # `:unescaped_html` option when calling Diffy::Diff#to_s.
    Diffy::Format.module_eval do
      def unescaped_html
        UnescapedHtmlFormatter.new(self, options.merge(:highlight_words => true)).to_s
      end
    end

    # The private "split" method SplitDiff needs to be overriden to take into
    # account the new :unescaped_html format, and the fact that the tags
    # <ins> <del> are not there anymore
    Diffy::SplitDiff.module_eval do
      private

      def split
        return [split_left, split_right] unless @format == :unescaped_html

        [unescaped_split_left, unescaped_split_right]
      end

      def unescaped_split_left
        @diff.gsub(%r{<li class="ins">([\s\S]*?)</li>}, "")
      end

      def unescaped_split_right
        @diff.gsub(%r{<li class="del">([\s\S]*?)</li>}, "")
      end
    end
  end
end
