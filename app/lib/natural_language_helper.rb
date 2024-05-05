# frozen_string_literal: true

class NaturalLanguageHelper
  FILTERS = [
    (LanguageFilter::Filter.new matchlist: :hate, creative_letters: true),
    (LanguageFilter::Filter.new matchlist: :profanity, creative_letters: true),
    (LanguageFilter::Filter.new matchlist: :sex, creative_letters: true),
    (LanguageFilter::Filter.new matchlist: :violence, creative_letters: true),
    (LanguageFilter::Filter.new matchlist: %w[nigger retard murder kys hate idiot], creative_letters: true),
  ].freeze

  # Method to suppress warnings temporarily
  def self.without_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbosity
  end

  def self.contains_offensive_language(text)
    normalized_text = normalize_text(text)
    without_warnings do
      FILTERS.each do |filter|
        return true if filter.match? normalized_text
      end
    end
    false
  end

  def self.sanitize(text)
    # Ensure the text is mutable by duplicating it first
    sanitized_text = text.dup
    # Normalize the text to handle leetspeak and other obfuscations
    normalized_text = normalize_text(sanitized_text)

    without_warnings do
      FILTERS.each do |filter|
        # Update sanitized_text only if it matches the offensive pattern
        if filter.match?(normalized_text)
          sanitized_text = filter.sanitize(sanitized_text)
        end
      end
    end

    sanitized_text
  end

  # Normalize the text by translating leetspeak and removing non-alphabetical characters
  def self.normalize_text(text)
    text = text.gsub(/[4@]/, 'a')
               .gsub(/8/, 'b')
               .gsub(/\(/, 'c')
               .gsub(/[3]/, 'e')
               .gsub(/[6]/, 'g')
               .gsub(/[#]/, 'h')
               .gsub(/[1!|]/, 'i')
               .gsub(/[0]/, 'o')
               .gsub(/[5$]/, 's')
               .gsub(/[7+]/, 't')
               .gsub(/2/, 'z')
               .gsub(/[_]/, ' ') # Remove underscores and other non-word characters
    text.downcase
  end
end
